/**
*   =====================================================================================
*   Trigger Name        : ContactTriggerTest
*   Description         : Contact trigger test
*   Author              : Simplus - Haider Raza
*   Created On          : 15/04/2020
*   Modification Log    :
*   =====================================================================================
*   Developer       Date            Modification ID         Description
*   =====================================================================================
*   Haider Raza     15/04/2020     1000                    Initial version
*   Simplus MS		21/09/2021	   1001				       CCRM15-83 (AC3) : Set marketing account flag before insert
*   =====================================================================================
**/
@IsTest
private class ContactTriggerTest {
    /**
*  Method name  :  dataSetup
*  Description  :  Setup data for test class
*  Author       :  Haider Raza
**/
    static void dataSetup() {
        List<Contact> contacts = new List<Contact>{TestDataFactory.createStandardContact()};
            contacts.add(TestDataFactory.createStandardContact());
        contacts.add(TestDataFactory.createStandardContact());
        contacts.add(TestDataFactory.createStandardContact());
        
        List<Account> accounts = TestDataFactory.createAccounts(3);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].Type = 'CASH';
        accounts[0].Business_Email_Address__c = 'test.email@gmail.com';
        accounts[0].Verified_Email__c = TRUE;
        
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].Type = 'CREDIT';
        accounts[1].Business_Email_Address__c = 'test1.email@gmail.com';
        accounts[1].Verified_Email__c = TRUE;
        
        accounts[2].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[2].Type = '30DAY';
        accounts[2].Business_Email_Address__c = 'test2.email@gmail.com';
        accounts[2].Verified_Email__c = TRUE;
        insert accounts;
        
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Trade Specialist'].Id;
        Id userId = [SELECT Id, Username FROM User WHERE ProfileId =: profileId LIMIT 1].Id;
        
        contacts[0].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'AU AR Contact');
        contacts[0].FirstName = 'Simplus-testing';
        contacts[0].LastName = 'Testcontact';
        contacts[0].AccountId = accounts[0].Id;
        contacts[0].Marketing_Contact__c = TRUE;
        contacts[0].Receive_Marketing__c = TRUE;
        contacts[0].Verified_Email__c = TRUE;
        contacts[0].Email = 'test.email@gmail.com';
        contacts[0].Receive_Marketing_Last_Update_By__c = SM_Configs__c.getInstance().Integration_User_Id__c;
        
        contacts[1].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'NZ AR Contact');
        contacts[1].Marketing_Contact__c = TRUE;
        contacts[1].AccountId = accounts[1].Id;
        contacts[1].Receive_Marketing__c = TRUE;
        contacts[1].Email = 'test1.email@gmail.com';
        contacts[1].Receive_Marketing_Last_Update_By__c = Userinfo.getUserId();
        
        contacts[2].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'AU AR Contact');
        contacts[2].Marketing_Contact__c = TRUE;
        contacts[2].AccountId = accounts[2].Id;
        contacts[2].Receive_Marketing__c = FALSE;
        contacts[2].Email = 'test2.email@gmail.com';
        contacts[2].Receive_Marketing_Last_Update_By__c = SM_Configs__c.getInstance().Marketing_Connect_User_Id__c;
        
        contacts[3].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'AU AR Contact');
        contacts[3].Marketing_Contact__c = TRUE;
        contacts[3].AccountId = accounts[2].Id;
        contacts[3].Receive_Marketing__c = FALSE;
        contacts[3].Email = 'test2.email@gmail.com';
        contacts[3].Receive_Marketing_Last_Update_By__c = userId;
        
        update contacts;
    }
    
    @IsTest
    static void testBehavior() {
        List<Contact> contacts = new List<Contact>{TestDataFactory.createStandardContact()};
            contacts.add(TestDataFactory.createStandardContact());
        
        contacts[0].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'AU AR Contact');
        contacts[0].FirstName = 'Simplus-test';
        contacts[0].LastName = 'contact';
        contacts[1].RecordTypeId = CSUtils.getRecordTypeId('Contact', 'AU CRM Contact');
        update contacts;
        
        Test.startTest();
        Database.delete(contacts, false);
        Test.stopTest();
        
        System.assert([SELECT Id FROM Contact].size() == 1);
    }
    
    /**
* @description Set Marketing Cloud flags for CCRM15-83
* @author Simplus MS | 21/06/2021 | 21/09/2021
**/
    @isTest(SeeAllData=true)
    static void setMarketingFlagsTest() {
        //dataSetup();
        Test.startTest();
        
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Integrations User'].Id;
        User integUser = [SELECT Id, Username FROM User WHERE ProfileId =: profileId LIMIT 1];

        List<Contact> lstContacts = [SELECT Id, Marketing_Contact__c, Receive_Marketing__c,phone FROM Contact limit 200];
        for(Contact con: lstContacts){
            if(!con.Receive_Marketing__c){
                con.Receive_Marketing__c = TRUE;
                con.phone = 'Test DAta12';
            }
        }
        
        System.runAs (integUser) {
            try{
                update lstContacts;
            }
            Catch(Exception exp){
                system.debug('Exception '+exp);
            }
        }
        Test.stopTest();
    }
}