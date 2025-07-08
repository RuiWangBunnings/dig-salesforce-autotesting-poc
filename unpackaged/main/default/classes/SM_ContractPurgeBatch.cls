/*******************************************************************************************************
* Class Name      	: SM_ContractPurgeBatch
* Description		: Batch / Schedule class to purge contracts of which approval status is deleted
* Author          	: Simplus - Yi Zhang
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              05/06/2020		1000				Initial version
******************************************************************************************************/
global class SM_ContractPurgeBatch implements Database.Batchable<sObject>, Schedulable {
    String query;

    global SM_ContractPurgeBatch() {
        query = 'SELECT Id FROM Contract__c '
         + 'WHERE Contract_Approval_Status__c = \'' + Constants.CONTRACT_APPROVAL_STATUS_DELETED + '\'';
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
            ApplicationLogger.log('SM_ContractPurgeBatch.execute', 'Contract__c', 'Batch Job', e);
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
        database.executebatch(new SM_ContractPurgeBatch());
    }
}