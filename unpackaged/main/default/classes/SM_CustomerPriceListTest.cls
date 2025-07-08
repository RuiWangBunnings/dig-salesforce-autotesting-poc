/*******************************************************************************************************
* Class Name      	: SM_CustomerPriceListTest
* Description		: Test class for SM_CustomerPriceList
* Author          	: Simplus MS
* Created On      	: 16/12/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           16/12/2020		1000				Initial version
* Simplus MS           14/05/2021		2000				modifications CCRM-13728
******************************************************************************************************/
@isTest
private class SM_CustomerPriceListTest {
    
    class SecondCallBadMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('{}');
            res.setStatusCode(200);            
            if (req.getEndpoint().endsWith('UPDATE')) {
                res.setStatusCode(202);
            }
            return res;
        }
    }        
    
    @isTest
    private static void test_invokeCustomerPriceListServiceAssignment_StatusSuccess(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c from Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674',
                                                                            'CountryCode' => 'AU'});

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));

        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(maptoSerialize, true);

        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerPriceListServiceAssignment_StatusError(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c from Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674',
                                                                            'CountryCode' => 'AU'});

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));

        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(maptoSerialize, true);

        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerPriceListServiceAssignment1(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c from Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674',
                                                                            'CountryCode' => 'AU'});

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SecondCallBadMock());

        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(maptoSerialize, true);

        Test.stopTest();
    }    
    
    @isTest
    private static void test_invokeCustomerPriceListServiceAssignment2(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c from Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674',
                                                                            'CountryCode' => 'AU'});

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));
        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(maptoSerialize, true);
        
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"', 202, false));
        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(maptoSerialize, true);        

        Test.stopTest();
    }       
    
     @isTest
    private static void test_invokeCustomerPriceListServiceDeletion_StatusSuccess(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('PriceListId' , [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c);
        maptoSerialize.put('AccountId' , [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'AU');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));

        SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(new Map<Id, Map<String, String>>{cpl.id=>maptoSerialize}, true);

        Test.stopTest();
    }
    
     @isTest
    private static void test_invokeCustomerPriceListServiceDeletion1(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('PriceListId' , [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c);
        maptoSerialize.put('AccountId' , [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'AU');

        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new SecondCallBadMock());
		SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(new Map<Id, Map<String, String>>{cpl.id=>maptoSerialize}, true);      
        
        Test.stopTest();
    }    
    
    @isTest
    private static void test_invokeCustomerPriceListServiceDeletion2(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('PriceListId' , [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c);
        maptoSerialize.put('AccountId' , [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'AU');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));
        SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(new Map<Id, Map<String, String>>{cpl.id=>maptoSerialize}, true);
        
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"', 202, false));
		SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(new Map<Id, Map<String, String>>{cpl.id=>maptoSerialize}, true);

        Test.stopTest();
    }          
}