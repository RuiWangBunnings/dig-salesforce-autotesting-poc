/*******************************************************************************************************
* Class Name      	: SM_ContractLineItemPurgeBatch_Test
* Description		: Test class for SM_ContractLineItemPurgeBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              05/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_ContractLineItemPurgeBatch_Test {

    @isTest
    public static void testContractLineItemPurgeBatch() {
        // setup data
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Status__c = 'Active'),
            new Contract__c(Name = 'C2', Status__c = 'Active'),
            new Contract__c(Name = 'C3', Status__c = 'Active'),
            new Contract__c(Name = 'C4', Status__c = 'Active'),
            new Contract__c(Name = 'C5', Contract_Approval_Status__c = Constants.CONTRACT_APPROVAL_STATUS_DELETED)
        };
        insert contracts;
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        // Active & Contract & End Date in the past (To be deleted)
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, Date.today() - 10, 200));
        // Active & Contract & End Date in the future (To stay)
        items.addAll(TestDataFactory.createContractLineItems(contracts[1].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, Date.today() + 10, 200));
        // Active & Amendment & Status = Completed (To be deleted)
        items.addAll(TestDataFactory.createContractLineItems(contracts[2].Id, Constants.CLI_LINE_TYPE_AMENDMENT, Constants.CLI_LINE_STATUS_COMPLETED, Date.today(), 20));
        // Active & Amendment & Status != Completed (To stay)
        items.addAll(TestDataFactory.createContractLineItems(contracts[3].Id, Constants.CLI_LINE_TYPE_AMENDMENT, Constants.CLI_LINE_STATUS_A, Date.today(), 25));
        // Deleted & any type (To be deleted)
        items.addAll(TestDataFactory.createContractLineItems(contracts[4].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, Date.today(), 200));
        insert items;

        Test.startTest();
        System.assertEquals(645, [SELECT COUNT() FROM Contract_Line_Item__c], 'items not setup properly');
        // schedulable (not immediate)
        Id jobId = System.schedule('Contract Line Item Purge Test', 
            '0 0 2 * * ?', 
            new SM_ContractLineItemPurgeBatch());
        // batchable
        Database.executebatch(new SM_ContractLineItemPurgeBatch(), 1000);
        Test.stopTest();
        // assert that 
        System.assertEquals(225, [SELECT COUNT() FROM Contract_Line_Item__c], 'items not purged properly');
        System.assertEquals(4, [SELECT COUNT() FROM Contract__c], 'contract not purged properly');
    }
}