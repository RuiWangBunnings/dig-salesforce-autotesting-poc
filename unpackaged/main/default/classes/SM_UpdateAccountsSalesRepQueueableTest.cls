/*******************************************************************************************************
* Class Name        : SM_UpdateAccountsSalesRepQueueableTest
* Description       : Test class of SM_UpdateAccountsSalesRepQueueable
* Author            : Simplus - MS
* Created On        : 05/11/2021
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus - MS          05/11/2021      1000                Initial version
******************************************************************************************************/
@isTest
public class SM_UpdateAccountsSalesRepQueueableTest {
    
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
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].OwnerId = users[1].ID;

        insert accounts;
    }

    static testmethod void testQueueable() {
        // query for test data to pass to queueable class
        List<Account> accounts = [select id, name from account];
        // Create our Queueable instance
        SM_UpdateAccountsSalesRepQueueable salesRepQueueable = new SM_UpdateAccountsSalesRepQueueable(accounts);
        
        Test.startTest();
        System.enqueueJob(salesRepQueueable);
        Test.stopTest();
    }
}