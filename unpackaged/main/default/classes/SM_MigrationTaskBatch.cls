/*******************************************************************************************************
* Class Name      	: SM_MigrationTaskBatch
* Description		: Batch / Schedule class for Task related post migration actions
* Author          	: Simplus - Purba Ghosh
* Created On      	: 21/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Purba Ghosh           21/09/2020		1000				Initial version
******************************************************************************************************/
global class SM_MigrationTaskBatch implements Database.Batchable<sObject>, Schedulable {

    String query;

    global SM_MigrationTaskBatch() {
        // Scope is every task of type call cycle call that is loaded into the system on day 0.
        query = 'SELECT Id, AccountId, ActivityDate, RecordTypeId FROM Task' +
                ' WHERE RecordTypeId = \'' + DM_RecordType.rtId_Task_CallCycle + '\' ';
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
    public void execute(Database.BatchableContext BC, List<Task> scope) {
        try {
            // Update the Scheduled Engagement Call field on the the related Account
            // with the ActivityDate when it is a task of type Call Cycle Call
            Map<Id,Task> mapTask = new Map<Id,Task>(scope);
            TaskTriggerHandler.updateRelatedAccountScheduledEngagementCall(mapTask);  
        } catch(Exception e) {
            ApplicationLogger.log('SM_MigrationTaskBatch', 'Task', 'Batch', e);
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
        Database.executeBatch(new SM_MigrationTaskBatch(), 1000);
    }
}