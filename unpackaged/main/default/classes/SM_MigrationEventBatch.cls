/*******************************************************************************************************
* Class Name      	: SM_MigrationEventBatch
* Description		: Batch / Schedule class for Event related post migration actions
* Author          	: Simplus - Purba Ghosh
* Created On      	: 21/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Purba Ghosh           21/09/2020		1000				Initial version
******************************************************************************************************/
global class SM_MigrationEventBatch implements Database.Batchable<sObject>, Schedulable {

    String query;

    global SM_MigrationEventBatch() {
        // Scope is every event that is loaded into the system on day 0.
        query = 'SELECT Id, AccountId, ActivityDate, EndDate, Event_Completed_Date__c,' +
                ' RecordTypeId, RecurrenceActivityId, RecurrenceInterval, Status__c, '  +
                ' Sub_type__c FROM Event';
    }

    /**
    * @description : Batch Start Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description : Batch Execute Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    * @param scope 
    **/
    public void execute(Database.BatchableContext BC, List<Event> scope) {
        try {
            // Update the Scheduled Engagement Call field on the the related Account
            // with the ActivityDate when it is an event of type Call Cycle Call
            Map<Id,Event> mapEvent = new Map<Id,Event>(scope);
            EventTriggerHandler.updateRelatedAccountScheduledEngagementCall(mapEvent);  

            // If an event is created as a result of recurrence and if the event that 
            // initiated the recurrence was loaded on Day 0 with a status completed as 
            // it is from past then we have to ensure any future dated recurrent events  
            // that are created in Salesforce are set to status open and not completed.
            // Dataload forces future recurrning events to have the same status as the
            // parent event, so we need to ensure we update the events.
            updateRecurringEventStatus(scope);

        } catch(Exception e) {
            ApplicationLogger.log('SM_MigrationEventBatch', 'Event', 'Batch', e);
        }
    }
 
    /**
    * @description : Batch Finish Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    **/
    public void finish(Database.BatchableContext BC) {
        // Actions to be carried out on finish of batch job
    }

    /**
    * @description : Batch Execute Method For Scheduling
    * @author Purba Ghosh | 21/09/2020 
    * @param SC 
    **/
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_MigrationEventBatch(), 1000);
    }

    /**
    * @description : Batch Execute Method For Scheduling
    * @author Purba Ghosh | 21/09/2020 
    * @param SC 
    **/
    public void updateRecurringEventStatus(List<Event> scope) {

        List<Event> lstEvents = new List<Event>();

        // If a future dated recurrent event is completed as a result of Day 0 data
        // load where when the parent of the recurrent sequence is loaded as completed 
        // all subsequent recurrent events created in future are also marked completed.
        // This script fixes that, it sets future dated recurrent events back to open
        // and clears of the event completed date that is copied over. 
        
        // It has been discussed that if users have completed a few future dated events ahead 
        // of Day 0 load they will also appear as open and users will have to manually complete
        // them. This is a rare case and will not affect many records.
        for(Event e : scope) {
            if(e.RecurrenceActivityId != null && e.RecurrenceInterval == null &&
               e.ActivityDate > System.Today() && e.Status__c == Constants.EVENT_STATUS_COMPLETED) {

                e.Status__c = Constants.EVENT_STATUS_OPEN;
                e.Event_Completed_Date__c = null;
                lstEvents.add(e);
               }
        }

        if(!lstEvents.isEmpty()) {
            update lstEvents;
        }
    }
}