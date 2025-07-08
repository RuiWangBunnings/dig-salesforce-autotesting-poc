/*******************************************************************************************************
* Class Name        : CallTargetsTriggerHandler
* Description       : Trigger Handler for Call_Targets__c
* Author            : Simplus - Yi Zhang
* Created On        : 2020-06-18
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-18      1000                Initial version
******************************************************************************************************/
public with sharing class CallTargetsTriggerHandler {
    public static final String MESSAGE_ACTIVE_TARGET_ALREADY_EXIST = 'An active target already exists for this user. Please end date the existing target before creating a new one.';
    public static final String MESSAGE_DATE_RANGE_OVERLAPS = 'This date range overlaps with an existing target. Please modify the date range to proceed.';
    
    /**
    * @description 
    * @author Yi Zhang | 19/06/2020 
    * @param newList 
    * @return void 
    **/
    public static void beforeInsert(List<Call_Targets__c> newList) {
        validateEndDates(newList);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 18/06/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void beforeUpdate(Map<Id, Call_Targets__c> oldMap, Map<Id, Call_Targets__c> newMap) {
        validateEndDates(newMap.values());
    }

    /**
    * @description 
    * @author Yi Zhang | 18/06/2020 
    * @param newList 
    **/
    public static void validateEndDates(List<Call_Targets__c> newList) {
        // business logic
        // gather AMs
        Set<Id> accountManagerIds = new Set<Id>();
        Set<Id> callTargetsIds = new Set<Id>();
        for(Call_Targets__c t : newList) {
            accountManagerIds.add(t.Team_Member__c);
            if(String.isNotBlank(t.Id)) {
                callTargetsIds.add(t.Id);
            }
        }
        // find existing call targets (excluding inserted / updated ones)
        // and group them by account manager Id
        Map<Id, List<Call_Targets__c>> relatedTargetsMap = new Map<Id, List<Call_Targets__c>>();
        for(Call_Targets__c exT : DM_CallTargets.getRelatedCallTargets(accountManagerIds, callTargetsIds)) {
            if(relatedTargetsMap.containsKey(exT.Team_Member__c) == false) {
                relatedTargetsMap.put(exT.Team_Member__c, new List<Call_Targets__c>());
            }
            relatedTargetsMap.get(exT.Team_Member__c).add(exT);
        }

        // loop through newly created / update call targets to find out:
        // - any existing one that also has null end date
        // - any existing one that has overlaps
        for(Call_Targets__c t : newList) {
            // System.debug('new record Id: ' + t.Id);
            if(relatedTargetsMap.containsKey(t.Team_Member__c) == true) {
                // new target is without end date
                if(t.End_Date__c == null) {
                    for(Call_Targets__c exT : relatedTargetsMap.get(t.Team_Member__c)) {
                        if(exT.End_Date__c == null) {
                            t.addError(MESSAGE_ACTIVE_TARGET_ALREADY_EXIST);
                            break;
                        } else if(t.Start_Date__c <= exT.End_Date__c) {
                            t.addError(MESSAGE_DATE_RANGE_OVERLAPS);
                            break;
                        }
                    }
                // new target is with end date
                } else {
                    for(Call_Targets__c exT : relatedTargetsMap.get(t.Team_Member__c)) {
                        // System.debug('existing record Id: ' + exT.Id);
                        if(exT.End_Date__c == null && exT.Start_Date__c <= t.End_Date__c) {
                            t.addError(MESSAGE_DATE_RANGE_OVERLAPS);
                            break;
                        } else if(exT.End_Date__c != null) {
                            if(exT.Start_Date__c > t.End_Date__c || t.Start_Date__c > exT.End_Date__c) {
                                // all good
                            } else {
                                // System.debug('t.Start_Date__c: ' + t.Start_Date__c);
                                // System.debug('t.End_Date__c: ' + t.End_Date__c);
                                // System.debug('exT.Start_Date__c: ' + exT.Start_Date__c);
                                // System.debug('exT.End_Date__c: ' + exT.End_Date__c);
                                t.addError(MESSAGE_DATE_RANGE_OVERLAPS);
                                break;
                            }
                        } 
                    }
                }
            }
        }
    }
}