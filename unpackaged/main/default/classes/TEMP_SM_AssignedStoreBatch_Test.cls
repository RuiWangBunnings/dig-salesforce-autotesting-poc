@isTest
private class TEMP_SM_AssignedStoreBatch_Test {
    
    @testSetup static void setup() {
        
        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // create store
            List<Store__c> stores = TestDataFactory.createStores(2);
            stores[0].Name = 'Test Store';
            stores[0].Engagement_Model__c = 'New';
            stores[0].Location_Type__c = 'Warehouse';
            stores[1].Name = 'Test Store';
            stores[1].Engagement_Model__c = 'New';
            stores[1].Location_Type__c = 'Warehouse';
            insert stores;
            
            // create store member
            Store_Member__c member = new Store_Member__c();
            member = TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.AU_TRADE_SPECIALIST_PROFILEENAME);
            insert member;
            
            //create account
            List<Account> accounts = TestDataFactory.createAccounts(2);
            for (Account acct : accounts){
                acct.OwnerId = users[0].Id;
                acct.Assigned_Store__c = stores[0].Id;
            }
            insert accounts;
        }
    }
    
    @isTest
    static void testAssignedStore() {
        Test.startTest();
        
        Database.executeBatch(new TEMP_SM_AssignedStoreBatch());
        
        Test.stopTest();
    }
    
}