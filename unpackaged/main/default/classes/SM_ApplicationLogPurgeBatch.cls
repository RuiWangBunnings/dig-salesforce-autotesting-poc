/*******************************************************************************************************
* Class Name      	: SM_ApplicationLogPurgeBatch
* Description		: A Batchable, Schedulable to purge ApplicationLog__c older than 60 days
* Author          	: Simplus - Yi Zhang
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              05/06/2020		1000				Initial version
******************************************************************************************************/
global class SM_ApplicationLogPurgeBatch implements Database.Batchable<sObject>, Schedulable {
    String query;

    global SM_ApplicationLogPurgeBatch() {
        query = 'SELECT Id FROM ApplicationLog__c WHERE CreatedDate < LAST_N_DAYS:60 ';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param BC 
    * @param scope 
    **/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // execute code
        try {
            delete scope;
        } catch(Exception e) {
            ApplicationLogger.log('SM_ApplicationLogPurgeBatch.execute', 'ApplicationLog__c', 'Batch Job', e);
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param BC 
    **/
    global void finish(Database.BatchableContext BC) {
        // finish code
    }
    
    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param SC 
    **/
    global void execute(SchedulableContext SC) {
        database.executebatch(new SM_ContractPurgeBatch(), 1000);
    }
}