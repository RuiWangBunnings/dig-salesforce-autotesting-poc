/*******************************************************************************************************
* Class Name        : SM_UpdateSObjectsQueueableTest
* Description       : Test class of SM_UpdateSObjectsQueueable
* Author            : Simplus - MS
* Created On        : 09/12/2021
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus - MS          09/12/2021      1000                Initial version
******************************************************************************************************/
@isTest
public class SM_UpdateSObjectsQueueableTest {
    
    @testSetup static void dataSetup() {
        
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
                                            
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].OwnerId = users[0].ID;
        accounts[0].Home_Store__c = storeList[0].Id;
        accounts[0].Powerpass_Account_Manager__c = 'Test';
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].OwnerId = users[1].ID;
        accounts[1].Home_Store__c = storeList[0].Id;
        accounts[1].Powerpass_Account_Manager__c = 'Test';

        insert accounts;
    }

    static testmethod void testQueueable() {
        // query for test data to pass to queueable class
        List<Account> accounts = [select id, name from account];
        // Create our Queueable instance
        SM_UpdateSObjectsQueueable sObjectspQueueable = new SM_UpdateSObjectsQueueable(accounts,'Test Class', TRUE, 'Account');
        
        Test.startTest();
        System.enqueueJob(sObjectspQueueable);
        system.debug('accounts :: '+accounts);
        Test.stopTest();
    }
}