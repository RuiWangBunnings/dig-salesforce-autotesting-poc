/*******************************************************************************************************
* Class Name      	: SM_CustomerFamilyTreeDiscountTest
* Description		: Test class for SM_CustomerFamilyTreeDiscount
* Author          	: Bunnings Dev
* Created On      	: 22/02/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     22/02/2023		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_CustomerFamilyTreeDiscountTest {

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
    private static void test_invokeCustomerFamilyTreeDiscountServiceServiceAssignment_StatusSuccess(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;

        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;

        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;

        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Family_Tree_Discount__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Family_Tree_Discount__c, new Map<String, String>{'CustomerId' => '3467367', 
            'FamilyTreeDiscountId' => [SELECT Customer_Family_Tree_Id__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Customer_Family_Tree_Id__c,
            'AccountId' => [SELECT Account__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Account__c, 'TMNumber' => '67674',
            'CountryCode' => 'NZ'});

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
            SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceServiceAssignment(maptoSerialize);
        Test.stopTest();
    }

    @isTest
    private static void test_invokeCustomerFamilyTreeDiscountServiceServiceAssignment_StatusError(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;

        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;

        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;

        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Family_Tree_Discount__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Family_Tree_Discount__c, new Map<String, String>{'CustomerId' => '3467367', 
            'FamilyTreeDiscountId' => [SELECT Customer_Family_Tree_Id__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Customer_Family_Tree_Id__c,
            'AccountId' => [SELECT Account__c FROM Customer_Family_Tree_Discount__c LIMIT 1].Account__c, 'TMNumber' => '67674',
            'CountryCode' => 'NZ'});

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 400, false));
            SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceServiceAssignment(maptoSerialize);
        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerFamilyTreeDiscountServiceDeletion_StatusSuccess(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;
                        
        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('FamilyTreeDiscountId' , cftd.Id);
        maptoSerialize.put('AccountId' , cftd.Account__c);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'NZ');

        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 200, false));
        	SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(new Map<Id, Map<String, String>>{cftd.id=>maptoSerialize});
        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerFamilyTreeDiscountServiceDeletion_StatusError(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;
                        
        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('FamilyTreeDiscountId' , cftd.Customer_Family_Tree_Id__c);
        maptoSerialize.put('AccountId' , accounts[0].Id);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'NZ');

        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));
        	SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(new Map<Id, Map<String, String>>{cftd.id=>maptoSerialize});                    
        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerFamilyTreeDiscountServiceDeletion_OtherError(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;
                        
        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;
        
        Map<String, String> maptoSerialize = new Map<String, String>();
        maptoSerialize.put('CustomerId' , '3467367');
        maptoSerialize.put('FamilyTreeDiscountId' , cftd.Customer_Family_Tree_Id__c);
        maptoSerialize.put('AccountId' , accounts[0].Id);
        maptoSerialize.put('TMNumber' , '67674');
		maptoSerialize.put('CountryCode' , 'NZ');

        Test.startTest();        
            Test.setMock(HttpCalloutMock.class, new SecondCallBadMock());
            SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(new Map<Id, Map<String, String>>{cftd.id=>maptoSerialize});        
            Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));
        	SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(new Map<Id, Map<String, String>>{cftd.id=>maptoSerialize});
        
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"', 400, false));
			SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(new Map<Id, Map<String, String>>{cftd.id=>maptoSerialize});
        Test.stopTest();
    }
    
    @isTest
    private static void test_invokeCustomerFamilyTreeDiscountServiceServiceAssignment_OtherError(){
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Family_Tree_Discount__c ftd = new Family_Tree_Discount__c(Name = 'Test Family Tree Discount', Country__c = 'New Zealand', Status__c = 'Active', Family_Tree_Discount_Id__c = String.valueOf(Math.random()));
        insert ftd;
                        
        Customer_Family_Tree_Discount__c cftd = new Customer_Family_Tree_Discount__c(Account__c = [SELECT Id FROM Account LIMIT 1].Id, Family_Tree_Discount__c = ftd.Id, Status__c = 'Active', Customer_Family_Tree_Id__c = '456987');
        insert cftd;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put(cftd.Family_Tree_Discount__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => cftd.Customer_Family_Tree_Id__c,
			'AccountId' => accounts[0].Id, 'TMNumber' => '67674',
			'CountryCode' => 'NZ'});

        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"}', 202, false));
        	SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceServiceAssignment(maptoSerialize);
        
        	Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"example":"test"', 202, false));
        	SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceServiceAssignment(maptoSerialize);        
        Test.stopTest();
    }
    
}