/*******************************************************************************************************
* Class Name        : CustomerFTDTriggerHandlerTest
* Description       : Customer Family Tree Discount trigger handler test class
* Author            : Bunnings Dev
* Created On        : 28/02/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     28/02/2023      1000                Initial version
******************************************************************************************************/
@isTest
private class CustomerFTDTriggerHandlerTest {
    
    @isTest
    private static void test_CFTDAssignment() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Send_Data_to_CPS__c = true;
        accounts[0].Country__c = 'New Zealand';
        insert accounts;

        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;

        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active',
            Customer_Family_Tree_Id__c = '', Pricing_Assignment_Status__c = null, Action__c = 'Assignment');
        insert cftd;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
        	cftd.Pricing_Assignment_Status__c = 'Submitted to CPS';
        	cftd.Action__c = 'Assignment';
        	update cftd;            
        Test.stopTest();
    }
    
    @isTest
    private static void test_CFTDRemoval() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Send_Data_to_CPS__c = true;
        accounts[0].Country__c = 'New Zealand';
        insert accounts;
        
        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;

        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active',
            Customer_Family_Tree_Id__c = 'T123', Pricing_Assignment_Status__c = null, Action__c = 'Assignment');
        insert cftd;
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
        	cftd.Pricing_Assignment_Status__c = 'Pending Removal Approval';
        	cftd.Action__c = 'Removal';
        	update cftd;            
        Test.stopTest();
    }
    
}