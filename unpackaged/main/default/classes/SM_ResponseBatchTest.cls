/*******************************************************************************************************
* Class Name      	: SM_ResponseBatchTest
* Description		: Test class of SM_ResponseBatch
* Author          	: Simplus - MS
* Created On      	: 23/12/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            23/12/2021		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_ResponseBatchTest {
    
    @testSetup
    static void insertTestData() {
        
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        String dummyAccountId = DM_Initialisation.getCCRMInitialisation().CCRM_Dummy_Account_Id__c;

        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';
        insert storeList;
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].Location_Name__c = storeList[0].Name;
        users[1].Location_Code__c = storeList[0].Location_Code__c;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
        }
        
        Initialisation__mdt dummyAccount = Initialisation__mdt.getAll().values();	
        
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].Name = 'Testing Medallia Account 1';
        accounts[0].Power_Pass_Account_Number__c = '34656123';
        accounts[0].OwnerId = users[0].ID;
        
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].Power_Pass_Account_Number__c = '3465677';
        accounts[1].OwnerId = users[1].ID;
        
        insert accounts;
        
        Contact cont = new Contact();
        cont.LastName = 'test';
        cont.phone = '343434443';
        cont.AccountId = accounts[0].Id;
        insert cont;
        
        medallia_xm__Medallia_Feedback_Header__c header = new medallia_xm__Medallia_Feedback_Header__c();
        header.medallia_xm__Account__c = dummyAccount.CCRM_Dummy_Account_Id__c;
        insert header;
        
        medallia_xm__Medallia_Feedback_Header__c header2 = new medallia_xm__Medallia_Feedback_Header__c();
        header2.medallia_xm__Account__c = accounts[0].Id;
        insert header2;        
        
        List<medallia_xm__Medallia_Feedback__c> responses = new List<medallia_xm__Medallia_Feedback__c>();
        responses.add(new medallia_xm__Medallia_Feedback__c(Power_Pass_Account_Number__c = '3465677', medallia_xm__Account_Id__c = dummyAccount.CCRM_Dummy_Account_Id__c, medallia_xm__Medallia_Feedback_Header__c = header.Id, medallia_xm__Contact_Id__c = cont.Id, Name= 'mfTesting1'));
        insert responses;
        
        List<medallia_xm__Medallia_Feedback__c> responses2 = new List<medallia_xm__Medallia_Feedback__c>();
        responses2.add(new medallia_xm__Medallia_Feedback__c(Power_Pass_Account_Number__c = '34656123', medallia_xm__Account_Id__c = dummyAccount.CCRM_Dummy_Account_Id__c, medallia_xm__Medallia_Feedback_Header__c = header.Id, medallia_xm__Contact_Id__c = cont.Id, Name = 'mfTesting2'));
        insert responses2;        

    }

    
    @isTest
    static void testBatchable() {
        
        Test.startTest();
        
        SM_ResponseBatch batchClass = new SM_ResponseBatch();
        Id batchId = Database.executeBatch(batchClass);
        
        Test.stopTest();
        
        String dummyAccountId = DM_Initialisation.getCCRMInitialisation().CCRM_Dummy_Account_Id__c;
        
        medallia_xm__Medallia_Feedback__c mf1 = [SELECT medallia_xm__Account_Id__c, medallia_xm__Medallia_Feedback_Header__c FROM medallia_xm__Medallia_Feedback__c WHERE Name = 'mfTesting1' LIMIT 1][0];
        System.assertNotEquals(dummyAccountId, mf1.medallia_xm__Medallia_Feedback_Header__c);
        
        medallia_xm__Medallia_Feedback__c mf2 = [SELECT medallia_xm__Account_Id__c, medallia_xm__Medallia_Feedback_Header__c FROM medallia_xm__Medallia_Feedback__c WHERE Name = 'mfTesting2' LIMIT 1][0];
    	System.assertNotEquals(dummyAccountId, mf2.medallia_xm__Medallia_Feedback_Header__c);
    }
}