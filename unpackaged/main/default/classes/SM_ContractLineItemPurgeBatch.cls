/*******************************************************************************************************
* Class Name      	: SM_ContractLineItemPurgeBatch
* Description		: Batch / Schedule class to purge contract line items
* Author          	: Simplus - Yi Zhang
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              05/06/2020		1000				Initial version
******************************************************************************************************/
global class SM_ContractLineItemPurgeBatch implements Database.Batchable<sObject>, Schedulable {
    
    String query;

    global SM_ContractLineItemPurgeBatch() {
        query = 'SELECT Id FROM Contract_Line_Item__c '
         + ' WHERE Contract__r.Contract_Approval_Status__c = \'' + Constants.CONTRACT_APPROVAL_STATUS_DELETED + '\''
         + ' OR ( '
         + ' Contract__r.Status__c = \'' + Constants.CONTRACT_STATUS_ACTIVE + '\' '
         + ' AND ( '
         + ' ( '
         + ' Line_Type__c = \'' + Constants.CLI_LINE_TYPE_CONTRACT + '\' '
         + ' AND End_Date__c < TODAY '
         + ' ) '
         + ' OR ( '
         + ' Line_Type__c = \'' + Constants.CLI_LINE_TYPE_AMENDMENT + '\' '
         + ' AND Line_Status__c = \'' + Constants.CLI_LINE_STATUS_COMPLETED + '\' '
         + ' ) '
         + ' ) '
         + ' ) ';

         /**
         [
            SELECT Id 
            FROM Contract_Line_Item__c
            WHERE Contract__r.Contract_Approval_Status__c = 'Deleted' 
            OR (
                Contract__r.Status__c = 'Active'
                AND (
                    (
                        Line_Type__c = 'Contract' 
                        AND End_Date__c < TODAY
                    )
                    OR (
                        Line_Type__c = 'Amendment'
                        AND Line_Status__c = 'C'
                    )
                )
            )
         ] 
         */
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param BC 
    * @param scope 
    * @return void 
    **/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // execute code
        try {
            delete scope;
        } catch(Exception e) {
            ApplicationLogger.log('SM_ContractLineItemPurgeBatch.execute', 'Contract_Line_Item__c', 'Batch Job', e);
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param BC 
    * @return void 
    **/
    global void finish(Database.BatchableContext BC) {
        // finish code
        // invoke another batch to purge deleted contracts
        database.executeBatch(new SM_ContractPurgeBatch());
    }
    
    /**
    * @description 
    * @author Yi Zhang | 05/06/2020 
    * @param SC 
    * @return void 
    **/
    global void execute(SchedulableContext SC) {
        database.executebatch(new SM_ContractLineItemPurgeBatch(), 1000);
    }
}