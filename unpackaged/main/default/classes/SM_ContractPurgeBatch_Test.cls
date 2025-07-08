/*******************************************************************************************************
* Class Name      	: SM_ContractPurgeBatch_Test
* Description		: Test class for SM_ContractPurgeBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 10/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              10/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_ContractPurgeBatch_Test {
    @isTest
    public static void testContractPurgeBatch() {
        // setup data
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Status__c = 'Active'),
            new Contract__c(Name = 'C2', Status__c = 'Active'),
            new Contract__c(Name = 'C3', Status__c = 'Active'),
            new Contract__c(Name = 'C4', Status__c = 'Active'),
            new Contract__c(Name = 'C5', Contract_Approval_Status__c = Constants.CONTRACT_APPROVAL_STATUS_DELETED)
        };
        insert contracts;

        Test.startTest();
        // schedulable (not immediate)
        Id jobId = System.schedule('Contract Purge Test', 
            '0 0 3 * * ?', 
            new SM_ContractPurgeBatch());
        // batchable
        Database.executebatch(new SM_ContractPurgeBatch());
        Test.stopTest();
        // assertions 
        System.assertEquals(4, [SELECT COUNT() FROM Contract__c], 'contract not purged properly');
    }
}