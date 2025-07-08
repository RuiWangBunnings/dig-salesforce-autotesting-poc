/*******************************************************************************************************
* Class Name        : SM_SyncNewAMOwnedAccountBatchTest
* Description       : testing class for SM_SyncNewAMOwnedAccountBatch
* Author            : Bunnings Salesforce Team
* Created On        : 21/08/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings SFDC Team    21/08/2022      1000                Initial version
******************************************************************************************************/
@isTest
public class SM_SyncNewAMOwnedAccountBatchTest {
    @testSetup
    static void insertTestData() {   
        Profile tsProfile = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> userTS = TestDataFactory.createUsers(1, tsProfile.Id);
        userTS[0].Sales_Rep_ID__c = '995511';
        
        Profile amProfile = [SELECT Id FROM Profile WHERE Name =: Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        list<User> userAM = TestDataFactory.createUsers(1, amProfile.Id);
        userAM[0].Sales_Rep_ID__c = '995522';
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert userTS;
            insert userAM;
        }
        
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].Name = 'Dummy Account 0';
        accounts[0].Power_Pass_Account_Number__c = '000000';
        accounts[0].OwnerId = userTS[0].ID;
        accounts[0].Country__c = 'Australia';
        accounts[0].Account_Status__c = 'Active';

        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[1].Name = 'Dummy Account 1';
        accounts[1].Power_Pass_Account_Number__c = '1111111';
        accounts[1].OwnerId = userAM[0].ID;
        accounts[1].Country__c = 'Australia';
        accounts[1].Account_Status__c = 'Active';          
        
        insert accounts;
        Account ac1 = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '000000'][0];
        ac1.OwnerId = userTS[0].ID;
        update ac1;
        
        Account ac2 = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '1111111'][0];
        ac2.OwnerId = userAM[0].ID;
        update ac2;
    }
    
    @isTest
    static void testBatchable() {
        
        Test.startTest();
        
        SM_SyncNewAMOwnedAccountBatch batchClass = new SM_SyncNewAMOwnedAccountBatch();
        Id batchId = Database.executeBatch(batchClass);
        Test.stopTest();
        
        Account ac1 = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '000000'][0];
        List<Object_Event_Bridge__c> oebList1 = [SELECT Id from Object_Event_Bridge__c WHERE Record_Id__c =: ac1.Id];
        System.assertEquals(0, oebList1.size());

        Account ac2 = [SELECT Id FROM Account WHERE Power_Pass_Account_Number__c = '1111111'][0];
        List <Object_Event_Bridge__c> oebList2 = [SELECT Id from Object_Event_Bridge__c WHERE Record_Id__c =: ac2.Id];
        System.assertEquals(1, oebList2.size()); 
    }
}