/*******************************************************************************************************
* Class Name      	: cplQueueables_Test
* Description		: Test class for cplAssignValidateCustomerQueueable, cplAssignUpdateCustomerQueueable,
						cplUnassignValidateCustomerQueueable, cplUnassignUpdateCustomerQueueable, cplDeleteTempQueueable
* Author          	: Jasper R Galapon
* Created On      	: 03/01/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R Galapon		03/01/2024		1000				Initial version
******************************************************************************************************/

@isTest
public class cplQueueables_Test {
    
    @testSetup static void dataSetup() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        insert accounts;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account WHERE Name = 'TestCompany0' LIMIT 1].Id,
			Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account WHERE Name = 'TestCompany1' LIMIT 1].Id,
			Status__c = 'Active', Customer_Price_List_ID__c = '45427');
        insert new List<Customer_Price_List__c>{cpl1, cpl2};                
    }
    
    @isTest
    private static void cplAssignValidateCustomerQueueable_Success_Test() {
        
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Successfull validation of customer assignment to pricelist"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignValidateCustomerQueueable sObjectspQueueable = new cplAssignValidateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplAssignValidateCustomerQueueable_NoSuccess_Test() {
        
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E01","statusDescription":"NOT ALLOWED - CONFLICTING PRICING LEVELS"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignValidateCustomerQueueable sObjectspQueueable = new cplAssignValidateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplAssignValidateCustomerQueueable_Fail_Test() {
        
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E","statusDescription":"Successfull validation of customer assignment to pricelist"}', 202, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignValidateCustomerQueueable sObjectspQueueable = new cplAssignValidateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplAssignUpdateCustomerQueueable_Success_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Successfull validation of customer assignment to pricelist"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignUpdateCustomerQueueable sObjectspQueueable = new cplAssignUpdateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplAssignUpdateCustomerQueueable_NoSuccess_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E01","statusDescription":"NOT ALLOWED - CONFLICTING PRICING LEVELS"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignUpdateCustomerQueueable sObjectspQueueable = new cplAssignUpdateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplAssignUpdateCustomerQueueable_Fail_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E","statusDescription":"Successfull validation of customer assignment to pricelist"}', 202, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c FROM Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});        
        
        cplAssignUpdateCustomerQueueable sObjectspQueueable = new cplAssignUpdateCustomerQueueable(maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignValidateCustomerQueueable_Success_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Validation Successful"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignValidateCustomerQueueable sObjectspQueueable = new cplUnassignValidateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignValidateCustomerQueueable_NoSuccess_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E01","statusDescription":"NOT ALLOWED - CONFLICTING PRICING LEVELS"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignValidateCustomerQueueable sObjectspQueueable = new cplUnassignValidateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignValidateCustomerQueueable_Fail_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E","statusDescription":"Validation Successful"}', 202, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignValidateCustomerQueueable sObjectspQueueable = new cplUnassignValidateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignUpdateCustomerQueueable_Success_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"S","statusDescription":"Customer Unassigned from Pricelist"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignUpdateCustomerQueueable sObjectspQueueable = new cplUnassignUpdateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignUpdateCustomerQueueable_NoSuccess_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E01","statusDescription":"NOT ALLOWED - CONFLICTING PRICING LEVELS"}', 200, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignUpdateCustomerQueueable sObjectspQueueable = new cplUnassignUpdateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplUnassignUpdateCustomerQueueable_Fail_Test() {
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"E","statusDescription":"Validation Successful"}', 202, false));
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c FROM Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
			'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674', 'CountryCode' => 'AU'});    

		Map<String, String> delMap = new Map<String, String>();
        delMap.put('CustomerId' , '3467367');
        delMap.put('PriceListId' , [SELECT Customer_Price_List_ID__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Customer_Price_List_ID__c);
        delMap.put('AccountId' , [SELECT Account__c FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427' LIMIT 1].Account__c);
        delMap.put('TMNumber' , '67674');
		delMap.put('CountryCode' , 'AU');
        
        cplUnassignUpdateCustomerQueueable sObjectspQueueable = new cplUnassignUpdateCustomerQueueable(new Map<Id, Map<String, String>>{[SELECT Id FROM Customer_Price_List__c WHERE Customer_Price_List_ID__c = '45427'].Id=>delMap}, maptoSerialize);
        
        Test.startTest();
        	System.enqueueJob(sObjectspQueueable);        	
        Test.stopTest();
    }
    
    @isTest
    private static void cplDeleteTempQueueable_Test() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].Power_Pass_Account_Number__c = '8989';
        accounts[1].Power_Pass_Account_Number__c = '8990';
        insert accounts;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '8989'].Id,
			Status__c = 'Inactive', Start_Date__c = NULL, End_Date__c = NULL);
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '8990'].Id,
			Status__c = 'Inactive', Start_Date__c = Date.today() - 1, End_Date__c = Date.today() + 100);
        insert new List<Customer_Price_List__c>{cpl1, cpl2};
            
		cplDeleteTempQueueable sObjectspQueueable1 = new cplDeleteTempQueueable([SELECT Power_Pass_Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '8989'].Power_Pass_Account_Number__c);
        cplDeleteTempQueueable sObjectspQueueable2 = new cplDeleteTempQueueable([SELECT Power_Pass_Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '8990'].Power_Pass_Account_Number__c);
            
		Test.startTest();
        	System.enqueueJob(sObjectspQueueable1);
        	System.enqueueJob(sObjectspQueueable2);
        Test.stopTest();
    }
    
    @isTest
    private static void cplExceptionErrorQueueable_Test() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Map<String, Object> fieldsToUpdate = new Map<String, Object>{'Pricing_Assignment_Error_Code_Descr__c' => null, 'Pricing_Assignment_Error_Meaning__c' => null};
		Map<String, Object> appLogFields = new Map<String, Object>{'Source__c' => '1234567', 'Type__c' => 'Outbound message', 'Source_Type__c' => 'Queueable',
            'Object_Name__c' => 'Customer_Price_List__c', 'Function_Name__c' => 'cplUnAssignValidateCustomerQueueable', 'Response_Body__c' => null,
            'Method__c' => null, 'Endpoint_URL__c' => null, 'Error_Message__c' => null};
                
		cplExceptionErrorQueueable cpl = new cplExceptionErrorQueueable(accounts[0].Id, fieldsToUpdate, appLogFields);
                
		Test.startTest();
        	System.enqueueJob(cpl);
        Test.stopTest();
    }
}