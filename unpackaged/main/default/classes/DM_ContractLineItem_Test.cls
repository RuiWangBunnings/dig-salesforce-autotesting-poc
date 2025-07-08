/*******************************************************************************************************
* Class Name      	: DM_ContractLineItem_Test
* Description		: Test class for DM_ContractLineItem
* Author          	: Bunnings Dev
* Created On      	: 13/06/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     13/06/2023		1000				Initial version
* Jasper R. Galapon		11/09/2024		1001				BUNDIG-35762 - Increase test coverage
******************************************************************************************************/
@isTest
public class DM_ContractLineItem_Test {
        
    @isTest
    public static void test_getItems() {
        Test.startTest();
        	System.assertEquals(0, DM_ContractLineItem.getItems(new List<String>{'test'}).size(),'aa');
        Test.stopTest();
    }
    
    @isTest
    public static void test_getItemsForDynamicFiltering() {
        Test.startTest();
        	System.assertEquals(0, DM_ContractLineItem.getItemsForDynamicFiltering('test').size(), 'no contract line item found');
        Test.stopTest();
    }
    
    @isTest
    public static void test_getAmendmentItems() {
        Test.startTest();
        	System.assertEquals(0, DM_ContractLineItem.getAmendmentItems('test'));
        Test.stopTest();
    }

    @isTest
    public static void test_getItemsWithSpecialBuyItems() {
        Test.startTest();        	
        	System.assertEquals(0, DM_ContractLineItem.getItemsWithSpecialBuyItems('TESTID', new List<String>{'Contract'}, new List<String>{'Pending'}).size(), 'No contract found');
        Test.stopTest();
    }
    
    @isTest
    public static void test_getItem() {
        Contract__c con = new Contract__c(Name = 'Test Contract');
        insert con;
        
        Contract_Line_Item__c cli_Item = new Contract_Line_Item__c(Name = 'Test Item', Contract__c = con.Id, Contract_Item_Id__c = 'TESTITEMID');
        insert cli_Item;
        
        Test.startTest();
        	Contract_Line_Item__c cli = DM_ContractLineItem.getItem(cli_Item.Id);        	
        Test.stopTest();
        
        System.assertEquals(cli_Item.Id, cli.Id, 'The retrieved item ID should match the test item ID');
        System.assertEquals(cli_Item.Name, cli.Name, 'The retrieved item Name should match the test item Name');        
    }
    
    @isTest
    public static void test_getAmendmentItemsByReviewOrApprover() {
        Id profileId = [SELECT Id FROM Profile WHERE NAME = 'Account Manager' LIMIT 1].Id;
        List<User> users = TestDataFactory.createUsers(1, profileId);
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert users;
        }
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Contract_Name__c = 'Test Name';
		contracts[0].Reviewer__c = users[0].Id;
        contracts[0].Approver__c = users[0].Id;
		insert contracts;
        
        Contract_Line_Item__c items = new Contract_Line_Item__c(Name = 'Test Item', Line_Type__c = 'Amendment', Line_Status__c = 'A1',
			Contract_Item_Id__c = 'TestItemId', Contract__c = contracts[0].Id);
        insert items;
        
        Test.startTest();
        	List<Contract_Line_Item__c> cli = DM_ContractLineItem.getAmendmentItemsByReviewOrApprover(contracts[0].Id, new List<String>{'Amendment'}, new List<String>{'A1'}, users[0].Id);
        Test.stopTest();
        
        System.assertEquals(1, cli.size(), 'Expected 1 Contract Line Item to be returned');
    }
    
    @isTest
    public static void test_countAmendmentLines() {
        Id profileId = [SELECT Id FROM Profile WHERE NAME = 'Account Manager' LIMIT 1].Id;
        List<User> users = TestDataFactory.createUsers(1, profileId);
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert users;
        }
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Contract_Name__c = 'Test Name';
		contracts[0].Reviewer__c = users[0].Id;
        contracts[0].Approver__c = users[0].Id;
		insert contracts;
        
        Contract_Line_Item__c items = new Contract_Line_Item__c(Name = 'Test Item', Line_Type__c = 'Amendment', Line_Status__c = 'A1',
			Contract_Item_Id__c = 'TestItemId', Contract__c = contracts[0].Id, Auto_Approval_Eligibility__c = true, Auto_Approved__c = false);
        insert items;               
        
        Test.startTest();
        	List<Contract_Line_Item__c> cli = DM_ContractLineItem.countAmendmentLines(contracts[0].Id, 'A1');
        Test.stopTest();
        
        System.assertEquals(1, cli.size(), 'Expected one Contract Line Item to be returned');
    }
}