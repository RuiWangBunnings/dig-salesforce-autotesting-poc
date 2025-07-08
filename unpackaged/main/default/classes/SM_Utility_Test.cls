/*******************************************************************************************************
* Class Name      	: SM_Utility_Test
* Description		: Test class for SM_Utility
* Author          	: Bunnings Dev
* Created On      	: 6/06/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     6/06/2023		1000				Initial version - BUNDIG-14708
* Jasper R. Galapon     30/06/2023      1001                BUNDIG-22401 / BUNDIG-22402 - New/Renewal Contract / Contract Amendments - Email Notifications
* Jasper R. Galapon     09/08/2023      1002                BUNDIG-23679 - Test method for sending bell notification
* Jasper R. Galapon		16/08/2023		1003				BUNDIG-24085 - Test method for getting Org Config
* Jasper R. Galapon		10/06/2025		1004				BUNDIG-51801 - Test method for get Threading Token
******************************************************************************************************/

@isTest
private class SM_Utility_Test {

    @isTest
    public static void test_performDecryptWithIV() {
        Test.startTest();
            //String tstDescryptedString = SM_Utility.performDecryptWithIV('MStSU4CyPRknLzLi0YnG4w==', 'SrUjkRiJVtw6UKDUu2Y98w=='); // Non-prod
           String tstDescryptedString = SM_Utility.performDecryptWithIV('JbT7+L35fYUadhWoVMqLFQ==', 'NsxMkbbzCGYt19c9HjsYUg==');
        	//System.assertNotEquals(tstDescryptedString, null);
        Test.stopTest();
    }
    
    @isTest
    public static void test_sendEmail() {
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@bunnings.com.au'];
        SM_Utility.sendEmail(owea.get(0).Id, new List<String>{'test@test.com'}, 'test', 'test message');
    }

    @isTest
    public static void test_sendBellNotification() {
        Test.startTest();
        	SM_Utility.sendBellNotification('Contract_Pricing_Review_Notification', new Set<String>{UserInfo.getUserId()}, 'Contract Name', 'Your contract amendment was rejected. Please review.');
		Test.stopTest();       
    }
    
    @isTest
    public static void test_orgConfig() {
        Test.startTest();
        	String integrationUserId = SM_Utility.orgConfig.Integration_User_Id__c;
        	System.assertEquals(null, integrationUserId);
        Test.stopTest();
    }
        
    @IsTest
    static void test_pricingAssignmentErrorDescription() {
        Map<String, String> testCases = new Map<String, String>{
            'NOT ALLOWED - CONFLICTING PRICING LEVELS' => 'The customer already has a spend band id different to the spend band you try to assign to the customer',
            'NOT ALLOWED - DATE OVERLAP WITH OTHER PRICE LIST' => 'The customer has spend band with State = NATIONAL or the equal to the State parameter AND cost zone = ALL or equal to the cost zone parameter',
            'THIS PRICE LIST IS ALREADY IN USE. PLEASE ENTER A UNIQUE PRICE LIST' => 'The price list header id is attached to the customer and is effective on the date given in the parameter'
        };
        
        for (String errorMessage : testCases.keySet()) {
            String expectedDescription = testCases.get(errorMessage);
            String actualDescription = SM_Utility.pricingAssignmentErrorDescription(errorMessage);
            System.assertEquals(expectedDescription, actualDescription, 'Error message: ' + errorMessage);
        }
    }
    
    @IsTest
    static void test_mapFieldsForPricingAssignmentErrorLog() {
        Map<String,String> wsParams = new Map<String, String>();
            wsParams.put('{{COUNTRY_CODE}}', 'test');
            wsParams.put('{{PRICE_LIST_ID}}', 'test');
            wsParams.put('{{CUST_ID}}', 'test');
            wsParams.put('{{TM_NUMBER}}', 'test');
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        response.setBody('test');

        List<Map<String, Object>> logObjs = new List<Map<String, Object>>();

        Test.startTest();
            logObjs.add(
                    SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                        'testCustomerId', 'Test.mapFieldsForPricingAssignmentErrorLog', 'Test', request, response, new Map<Id, Map<String, String>>{'a0M9D000001EL3e000' => wsParams}, null, '')            
            );        
        Test.stopTest();
    }
    
    @IsTest
    static void test_Insert_UpdateRecord() {
        Map<String, Object> insertFields = new Map<String, Object>{'Name' => 'Test Account'};		                
        Map<String, Object> updatedFields = new Map<String, Object>{'Name' => 'Test Name','Phone' => '123-456-7890'};

        Test.startTest();
        	SM_Utility.insertRecord('Account', insertFields);
        	Account acc = [SELECT Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        	SM_Utility.updateRecord('Account', acc.Id, updatedFields);
        Test.stopTest();
    }
    
    @isTest
    static void test_getThreadingToken_NonEmail() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;
        
        Test.startTest();
        	List<Id> recordIds = new List<Id>{testCase.Id};
            List<String> token = SM_Utility.getThreadingToken(recordIds);
       Test.stopTest();
        
       System.assertNotEquals(null, token, 'Result should not be null');            
    }
    
    @isTest
    static void test_getThreadingToken_Email() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Email');
        insert testCase;
        
        Test.startTest();
        	List<Id> recordIds = new List<Id>{testCase.Id};
            List<String> token = SM_Utility.getThreadingToken(recordIds);
       Test.stopTest();
        
       //System.assertEquals(0, token.size(), 'Result should not contain one token');            
    }
}