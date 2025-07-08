/*******************************************************************************************************
* Class Name        : CallPlanLeaveTriggerHandler
* Description       : Trigger Handler for Call_Plan_Leave__c
* Author            : Simplus - Yi Zhang
* Created On        : 09/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              09/07/2020      1000                Initial version
******************************************************************************************************/
public with sharing class CallPlanLeaveTriggerHandler {
    public static final String MESSAGE_DATE_RANGE_OVERLAPS = 'This date range overlaps with an existing leave. Please modify the date range to proceed.';
    
    /**
    * @description 
    * @author Yi Zhang | 09/07/2020 
    * @param newList 
    **/
    public static void beforeInsert(List<Call_Plan_Leave__c> newList) {
        validateEndDates(newList);
    }

    /**
    * @description 
    * @author Yi Zhang | 10/07/2020 
    * @param newList 
    **/
    public static void afterInsert(List<Call_Plan_Leave__c> newList) {
        updateEventsToOnLeave(newList);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 09/07/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void beforeUpdate(Map<Id, Call_Plan_Leave__c> oldMap, Map<Id, Call_Plan_Leave__c> newMap) {
        validateEndDates(newMap.values());
    }

    /**
    * @description 
    * @author Yi Zhang | 09/07/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Call_Plan_Leave__c> oldMap, Map<Id, Call_Plan_Leave__c> newMap) {
        updateEventsStatusAndOutcome(oldMap, newMap);
    }

    /**
    * @description 
    * @author Yi Zhang | 10/07/2020 
    * @param oldList 
    **/
    public static void afterDelete(List<Call_Plan_Leave__c> oldList) {
        updateEventsToNotOnLeave(oldList);
    }

    /**
    * @description 
    * @author Yi Zhang | 13/07/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateEventsStatusAndOutcome(Map<Id, Call_Plan_Leave__c> oldMap, Map<Id, Call_Plan_Leave__c> newMap) {
        List<String> eventToOnLeaveClauses = new List<String>();
        List<String> eventToNotOnLeaveClauses = new List<String>();
        Date today = Date.today();
        for(Id leaveId : newMap.KeySet()) {
            Call_Plan_Leave__c oldLeave = oldMap.get(leaveId);
            Call_Plan_Leave__c newLeave = newMap.get(leaveId);
            // simple approach
            // make events in old leave's period NOT ON LEAVE
            // make events in new leave's period ON LEAVE
            if(newLeave.Team_Member__c != oldLeave.Team_Member__c || newLeave.Start_Date__c != oldLeave.Start_Date__c || newLeave.End_Date__c != oldLeave.End_Date__c) {

                eventToNotOnLeaveClauses.add('(OwnerId = \'' 
                + oldLeave.Team_Member__c 
                + '\' AND StartDateTime >= ' 
                + SM_CallPlanner.formatStartDate(today < oldLeave.Start_Date__c ? oldLeave.Start_Date__c : today) 
                + ' AND EndDateTime <= ' 
                + SM_CallPlanner.formatEndDate(oldLeave.End_Date__c) + ')');

                eventToOnLeaveClauses.add('(OwnerId = \'' 
                + newLeave.Team_Member__c 
                + '\' AND StartDateTime >= ' 
                + SM_CallPlanner.formatStartDate(today < newLeave.Start_Date__c ? newLeave.Start_Date__c : today) 
                + ' AND EndDateTime <= ' 
                + SM_CallPlanner.formatEndDate(newLeave.End_Date__c) + ')');
            }
        }

        if(eventToOnLeaveClauses.size() > 0) {
            updateEvents('SELECT Id ' 
            + 'FROM Event '
            + 'WHERE Planned_Call__c = true ' 
            + 'AND Status__c = \'' + Constants.EVENT_STATUS_COMPLETED + '\' ' 
            + 'AND Outcome__c = \'' + Constants.EVENT_OUTCOME_ON_LEAVE + '\' ' 
            + 'AND (' + String.join(eventToNotOnLeaveClauses, ' OR ') + ')', Constants.EVENT_STATUS_OPEN, '');

            
            updateEvents('SELECT Id ' 
            + 'FROM Event '
            + 'WHERE Planned_Call__c = true ' 
            + 'AND Status__c = \'' + Constants.EVENT_STATUS_OPEN + '\' ' 
            + 'AND (' + String.join(eventToOnLeaveClauses, ' OR ') + ')', Constants.EVENT_STATUS_COMPLETED, Constants.EVENT_OUTCOME_ON_LEAVE);
        }
    }

    /**
    * @description      Use in afterInsert
    * @author Yi Zhang | 10/07/2020 
    * @param leaves 
    **/
    public static void updateEventsToOnLeave(List<Call_Plan_Leave__c> leaves) {
        // generate query
        List<String> eventClauses = new List<String>();
        for(Call_Plan_Leave__c l : leaves) {
            eventClauses.add('(OwnerId = \'' 
            + l.Team_Member__c 
            + '\' AND StartDateTime >= ' 
            + SM_CallPlanner.formatStartDate(l.Start_Date__c) 
            + ' AND EndDateTime <= ' 
            + SM_CallPlanner.formatEndDate(l.End_Date__c) + ')');
        }
        String query = 'SELECT Id ' 
        + 'FROM Event '
        + 'WHERE Planned_Call__c = true ' 
        + 'AND Status__c = \'' + Constants.EVENT_STATUS_OPEN + '\' ' 
        + 'AND (' + String.join(eventClauses, ' OR ') + ')';

        System.debug(LoggingLevel.DEBUG, query);
        // execute query and update event
        updateEvents(query, Constants.EVENT_STATUS_COMPLETED, Constants.EVENT_OUTCOME_ON_LEAVE);
    }

    /**
    * @description      Used in afterDelete
    * @author Yi Zhang | 10/07/2020
    * @param oldList 
    **/
    public static void updateEventsToNotOnLeave(List<Call_Plan_Leave__c> oldList) {
        Date today = Date.today();
        // find leaves with team members (rarely this would happen)
        List<Call_Plan_Leave__c> leaves = new List<Call_Plan_Leave__c>();
        for(Call_Plan_Leave__c l : oldList) {
            if(String.isNotBlank(l.Team_Member__c)) {
                leaves.add(l);
            }
        }
        if(leaves.isEmpty()) {
            return;
        }

        // generate query
        List<String> eventClauses = new List<String>();
        for(Call_Plan_Leave__c l : leaves) {
            eventClauses.add('(OwnerId = \'' 
            + l.Team_Member__c 
            + '\' AND StartDateTime >= ' 
            + SM_CallPlanner.formatStartDate(today < l.Start_Date__c ? l.Start_Date__c : today) 
            + ' AND EndDateTime <= ' 
            + SM_CallPlanner.formatEndDate(l.End_Date__c) + ')');
        }
        String query = 'SELECT Id ' 
        + 'FROM Event '
        + 'WHERE Planned_Call__c = true ' 
        + 'AND Status__c = \'' + Constants.EVENT_STATUS_COMPLETED + '\' ' 
        + 'AND Outcome__c = \'' + Constants.EVENT_OUTCOME_ON_LEAVE + '\' ' 
        + 'AND (' + String.join(eventClauses, ' OR ') + ')';

        // execute query and update event
        updateEvents(query, Constants.EVENT_STATUS_OPEN, '');
    }

    /**
    * @description 
    * @author Yi Zhang | 10/07/2020
    * @param query 
    * @param newStatus 
    * @param newOutcome 
    **/
    public static void updateEvents(String query, String newStatus, String newOutcome) {
        System.debug(LoggingLevel.DEBUG, query);
        List<Event> events = Database.query(query);
        if(events.size() > 0) {
            for(Event e : events) {
                e.Status__c = newStatus;
                e.Outcome__c = newOutcome;
            }

            update events;
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 09/07/2020 
    * @param newList 
    **/
    public static void validateEndDates(List<Call_Plan_Leave__c> newList) {
        // business logic
        // gather AMs
        Set<Id> accountManagerIds = new Set<Id>();
        Set<Id> leaveIds = new Set<Id>();
        for(Call_Plan_Leave__c t : newList) {
            accountManagerIds.add(t.Team_Member__c);
            if(String.isNotBlank(t.Id)) {
                leaveIds.add(t.Id);
            }
        }
        // find existing leaves (excluding just inserted / updated ones)
        // and group them by account manager Id
        Map<Id, List<Call_Plan_Leave__c>> relatedLeavesMap = new Map<Id, List<Call_Plan_Leave__c>>();
        for(Call_Plan_Leave__c exL : DM_CallPlanLeave.getRelatedLeaves(accountManagerIds, leaveIds)) {
            if(relatedLeavesMap.containsKey(exL.Team_Member__c) == false) {
                relatedLeavesMap.put(exL.Team_Member__c, new List<Call_Plan_Leave__c>());
            }
            relatedLeavesMap.get(exL.Team_Member__c).add(exL);
        }

        // loop through newly created / update leaves to find out:
        // - any existing one that has overlaps
        for(Call_Plan_Leave__c t : newList) {
            if(t.Start_Date__c != null && t.End_Date__c != null && relatedLeavesMap.containsKey(t.Team_Member__c) == true) {
                for(Call_Plan_Leave__c exL : relatedLeavesMap.get(t.Team_Member__c)) {
                    if(!(exL.Start_Date__c > t.End_Date__c || t.Start_Date__c > exL.End_Date__c)) {
                        t.addError(MESSAGE_DATE_RANGE_OVERLAPS);
                        break;
                    } 
                }
            }
        }
    }
}