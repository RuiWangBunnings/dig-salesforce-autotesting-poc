/*******************************************************************************************************
* Class Name      	: DefaultTSPlannedLeaveBatch_Test
* Description		: Test class for DefaultTSPlannedLeaveBatch
* Author          	: Simplus - MS
* Created On      	: 02/12/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			    Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            02/12/2021		1000				Initial version
******************************************************************************************************/
@isTest
public with sharing class DefaultTSPlannedLeaveBatch_Test {
    
    @TestSetup
    static void TestSetupMethod() {
        
        // create store
        List<Store__c> stores = TestDataFactory.createStores(2);
        stores[0].Operations_Region_Code__c = 'NSW';
        stores[0].Location_Code__c = '2000';
        stores[1].Operations_Region_Code__c = 'NSW';
        stores[1].Location_Code__c = '2001';
        insert stores;
        
        Profile profileTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(4, null);
        // user 0 & 1 for 1st store
        users[0].ProfileId = profileTS.Id;
        users[0].Location_Code__c = stores[0].Location_Code__c;
        users[1].ProfileId = profileTS.Id;
        users[1].Location_Code__c = stores[0].Location_Code__c;
        // user 2 for 2nd store
        users[2].ProfileId = profileTS.Id;
        users[2].Location_Code__c = stores[1].Location_Code__c;
        // user 3 for 2nd store (RCM role)
        users[3].ProfileId = profileRCM.Id;
        users[3].Location_Code__c = stores[1].Location_Code__c;
        insert users;
        
        // create store members
        List<Store_Member__c> members = new List<Store_Member__c>();
        members.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
        members.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
        members.add(TestDataFactory.createStoreMember(stores[0].Id, users[3].Id, Constants.STOREMEMBER_RCM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(stores[1].Id, users[2].Id, Constants.STOREMEMBER_TS_ROLENAME));
        members.add(TestDataFactory.createStoreMember(stores[1].Id, users[3].Id, Constants.STOREMEMBER_RCM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(stores[1].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
        members[0].Default_Trade_Specialist__c = true;
        members[2].Default_Trade_Specialist__c = true;
        members[0].Team_Member_Call__c = '10%';
        members[1].Team_Member_Call__c = '20%';
        members[2].Team_Member_Call__c = '30%';
        members[3].Team_Member_Call__c = '40%';
        members[4].Team_Member_Call__c = '50%';
        members[5].Team_Member_Call__c = '60%';
        insert members;
        
        // create Planned Leaves for store members
        List<Planned_Leave__c> plannedLeaves = new List<Planned_Leave__c>();
        plannedLeaves.add(new Planned_Leave__c(End_Date__c=System.today(), Start_Date__c=System.today(), Approver_Comment__c='Approved',
                                               Status__c='Approved', OwnerId=users[0].Id, Approver__c=UserInfo.getUserId()));
        plannedLeaves.add(new Planned_Leave__c(End_Date__c=System.today(), Start_Date__c=System.today(), Approver_Comment__c='Approved',
                                               Status__c='Approved', OwnerId=users[2].Id, Approver__c=UserInfo.getUserId()));
        insert plannedLeaves;
        
    }
    
    @isTest 
    private static void testUpdateDefaultTSOfStore() {
        
        Test.startTest();
        Database.executeBatch(new DefaultTSPlannedLeaveBatch());
        Test.stopTest();
        
    }
}