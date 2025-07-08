/*******************************************************************************************************
* Class Name      	: CustomerPriceListTriggerHandlerTest
* Description		: CustomerPriceList test class
* Author          	: Simplus MS
* Created On      	: 17/12/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           17/12/2020		1000				Initial version - CCRM-297
* Simplus MS           14/05/2021		2000				modifications CCRM-13728
* Simplus MS           29/06/2021		3000    		 	modifications CCRM-13792
* Jasper R Galapon	   03/01/2024		4000				modifications BUNDIG-26295
******************************************************************************************************/
@isTest
private class CustomerPriceListTriggerHandlerTest {
    @isTest
    private static void test_CPLDeletion(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;

        Test.startTest();
        	// BUNDIG-26295
            //Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Successfull validation of customer assignment to pricelist"}', 200, false));
            cpl.Action__c = 'Removal';
            cpl.Pricing_Assignment_Status__c = 'Submitted to CPS';
            cpl.Start_Date__c = System.Date.today().addDays(5);
            update cpl;
        Test.stopTest();
    }
    
    @isTest
    private static void test_CPLAssignment(){
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].Send_Data_to_CPS__c = true;
        insert accounts;
        
        accounts[1].Contract_Group__c = accounts[0].Id;
        update accounts[1];
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = accounts[1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '', 
                                                                Pricing_Assignment_Status__c=null, Action__c='Assignment');
        insert cpl;
        
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '', 
                                                                Pricing_Assignment_Status__c=null, Action__c='Removal');
        insert cpl1;

        Test.startTest();
            // BUNDIG-26295
            //Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Successfull validation of customer assignment to pricelist"}', 200, false));        
        
            cpl1.End_Date__c = System.today().addDays(30);
            cpl1.Change_Requested_On__c = System.today();
            cpl1.Action__c = 'Assignment';
            cpl1.Pricing_Assignment_Status__c = 'Submitted to CPS';
            update cpl1;
            cpl1.Status__c = 'Inactive';
            cpl1.Action__c = 'Assignment';
            update cpl1;
        Test.stopTest();
    }
    
    @isTest
    private static void test_afterUpdate() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Send_Data_to_CPS__c = true;
        insert accounts;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id,
			Status__c = 'Expired', Customer_Price_List_ID__c = '45426', Start_Date__c = Date.today() - 1, End_Date__c = Date.today() + 400);
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id,
			Status__c = 'Active', Customer_Price_List_ID__c = '45427', Start_Date__c = Date.today() - 1, End_Date__c = Date.today() + 365);
        insert new List<Customer_Price_List__c>{cpl1, cpl2};
                                        
		Test.startTest();
        	List<Customer_Price_List__c> cpl = [SELECT Id, CPL_Status__c FROM Customer_Price_List__c];        	
        	cpl[0].Status__c = 'Active';
        	update cpl;        	
        Test.stopTest();
    }
    
    @isTest
    private static void test_afterDelete() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Send_Data_to_CPS__c = true;
        insert accounts;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id,
			Status__c = 'Expired', Customer_Price_List_ID__c = '45426', Start_Date__c = Date.today() - 1, End_Date__c = Date.today() + 400);
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id,
			Status__c = 'Active', Customer_Price_List_ID__c = '45427', Start_Date__c = Date.today() - 1, End_Date__c = Date.today() + 365);
        insert new List<Customer_Price_List__c>{cpl1, cpl2};
                                        
		Test.startTest();
        	List<Customer_Price_List__c> cpl = [SELECT Id, CPL_Status__c FROM Customer_Price_List__c LIMIT 1];
        	delete cpl;        	
        Test.stopTest();
    }
}