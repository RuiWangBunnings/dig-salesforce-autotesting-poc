/*******************************************************************************************************
* Class Name      	: SM_AssociateAccountExtensionBatch
* Description		: Batch test class
* Author          	: Bunnings Salesforce Team
* Created On      	: 25/05/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings SFDC Team 	25/05/2022		1000				Initial version for SFSUP-725
******************************************************************************************************/
@isTest
public class SM_AssociateAccountExtensionBatchTest {
    @testSetup
    static void insertTestData() {   
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(2, p.Id);
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
        }
        
        List<Account> accounts = TestDataFactory.createAccounts(5);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].Name = 'Dummy Account 1';
        accounts[0].Power_Pass_Account_Number__c = '111111';
        accounts[0].OwnerId = users[0].ID;
        accounts[0].Country__c = 'Australia';
        accounts[0].Account_Status__c = 'Active';
        
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].Name = 'Dummy Account 2';
        accounts[1].Power_Pass_Account_Number__c = '222222';
        accounts[1].OwnerId = users[1].ID;
        accounts[1].Country__c = 'Australia';
        accounts[1].Account_Status__c = 'Active';

        accounts[2].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Customer');
        accounts[2].Name = 'Dummy Account 3';
        accounts[2].Power_Pass_Account_Number__c = '333333';
        accounts[2].OwnerId = users[0].ID;
        accounts[2].Country__c = 'New Zealand';
        accounts[2].Account_Status__c = 'Active';       

        accounts[3].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Prospect');
        accounts[3].Name = 'Dummy Account 4';
        accounts[3].Power_Pass_Account_Number__c = '444444';
        accounts[3].OwnerId = users[1].ID;
        accounts[3].Country__c = 'New Zealand';
        accounts[3].Account_Status__c = 'Active';

        accounts[4].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[4].Name = 'Dummy Account 5';
        accounts[4].Power_Pass_Account_Number__c = '555555';
        accounts[4].OwnerId = users[1].ID;
        accounts[4].Country__c = 'Australia';
        accounts[4].Account_Status__c = 'Active';          
        
        insert accounts;
        
        Account_Extension__c accExt1 = New Account_Extension__c (Account_Number__c = '111111');
        insert accExt1;
        Account_Extension__c accExt2 = New Account_Extension__c (Account_Number__c = '222222');
        insert accExt2;
        Account_Extension__c accExt3 = New Account_Extension__c (Account_Number__c = '333333');
        insert accExt3;
        Account_Extension__c accExt4 = New Account_Extension__c (Account_Number__c = '444444');
        insert accExt4;
        Account_Extension__c accExt5 = New Account_Extension__c (Account_Number__c = '666665');  
        insert accExt5;
    }

    
    @isTest
    static void testBatchable() {
        
        Test.startTest();
        
        SM_AssociateAccountExtensionBatch batchClass = new SM_AssociateAccountExtensionBatch();
        Id batchId = Database.executeBatch(batchClass);
		Test.stopTest();
        
        Account ac1 = [SELECT Id, Account_Extension__r.Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '111111'][0];
        System.assertEquals('111111', ac1.Account_Extension__r.Account_Number__c);

        Account ac2 = [SELECT Id, Account_Extension__r.Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '222222'][0];
        System.assertEquals('222222', ac2.Account_Extension__r.Account_Number__c);

        Account ac3 = [SELECT Id, Account_Extension__r.Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '333333'][0];
        System.assertEquals('333333', ac3.Account_Extension__r.Account_Number__c);

        Account ac4 = [SELECT Id, Account_Extension__r.Account_Number__c FROM Account WHERE Power_Pass_Account_Number__c = '444444'][0];
        System.assertEquals('444444', ac4.Account_Extension__r.Account_Number__c);

        Account ac5 = [SELECT Id, Account_Extension__c FROM Account WHERE Power_Pass_Account_Number__c = '555555'][0];
        System.assertEquals(null, ac5.Account_Extension__c);    
    }
}