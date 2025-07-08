/*******************************************************************************************************
* Class Name      	: SM_SyncCallVolumesBatchTest
* Description		: Test class of SM_SyncCallVolumesBatch
* Author          	: Simplus - MS
* Created On      	: 16/12/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            16/12/2021		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_SyncCallVolumesBatchTest {
    
    @testSetup
    static void insertTestData() {

        // create store
        List<Store__c> stores = TestDataFactory.createStores(1);
        stores[0].Engagement_Model__c = 'Old';
        stores[0].Location_Type__c = 'Warehouse';
        stores[0].Country__c = 'Australia';
        stores[0].Store_Call__c = '70%';
        insert stores;

        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].Location_Code__c = stores[0].Location_Code__c;
        users[0].Team_Member_ID__c = '112233';
        users[1].Location_Code__c = stores[0].Location_Code__c;
        users[1].Team_Member_ID__c = '222344';

        insert users;

        // create store member
        List<Store_Member__c> storeMembers = new List<Store_Member__c>();
        storeMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
        storeMembers[0].Team_Member_Call__c = '70%';
        storeMembers[0].Call_Volume__c = 40;
        storeMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
        insert storeMembers;
    }
    
    @isTest
    static void testBatchable() {
        
        Test.startTest();
        
        SM_SyncCallVolumesBatch batchClass = new SM_SyncCallVolumesBatch();
        Id batchId = Database.executeBatch(batchClass);
        
        List<Store__c> stores = [Select Id, Store_Call__c, Engagement_Model__c, Location_Type__c, Country__c From Store__c];
        List<Store_Member__c> storeMembers = [Select Id, Call_Volume__c, Team_Member_Call__c From Store_Member__c Where Store__c IN: stores];
        System.assertEquals(storeMembers[0].Call_Volume__c, SM_StoreMember.calculateCallVolume(stores[0], storeMembers[0].Team_Member_Call__c ), 'Call Volume is incorrect');
        
        Test.stopTest();

    }
}