/*******************************************************************************************************
* Class Name      	: SM_StoreMemberTest
* Description		: Test class for SM_StoreMember
* Author          	: Simplus - MS
* Created On      	: 28/04/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			    Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            28/04/2021		1000				Initial version
* Simplus MS			03/06/2021      3000                Added Test logic for CCRM-13689 prevent multiple default TS assigned to Store
* Simplus MS 			03/06/2021 		4000 				Added Test logic for CCRM-13830 prevent multiple active Team Member per user to Store
* Simplus MS 			03/06/2021 		5000 				Added Test logic for CCRM-13832 able to uncheck the default TS and automatically checks the other active TS 
******************************************************************************************************/
@isTest
private class SM_StoreMemberTest {

    @isTest
    private static void testInsertAndUpdateStoreMembers() {
        
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
        
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(1);
 
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            accounts[0].OwnerId = users[0].Id;
            insert accounts;
            
            // create store members (to mimic the future method of creating store members in User Trigger)
            List<Store_Member__c> members = new List<Store_Member__c>();
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[1].Id, users[2].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[1].Id, users[3].Id, Constants.STOREMEMBER_RCM_ROLENAME));
            members[0].Default_Trade_Specialist__c = true;
            members[2].Default_Trade_Specialist__c = true;
            insert members;
            System.debug(LoggingLevel.DEBUG, 'members: ' + JSON.serialize(members));
            
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            users[0].Location_Code__c = stores[1].Location_Code__c;
            users[2].isActive = false;
            update users;
        }
        
        Test.stopTest();
        
        // store 0's default TS is user 1
        System.debug(LoggingLevel.DEBUG, 'Users: ' + JSON.serialize(users));
        System.debug(LoggingLevel.DEBUG, [SELECT Team_Member__c FROM Store_Member__c WHERE Store__c = :stores[0].Id AND Default_Trade_Specialist__c = true]); 
    }

    @isTest
    private static void testValidateRoleAndTeamMember() {

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
        
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(1);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            accounts[0].OwnerId = users[0].Id;
            insert accounts;
            
            // create store members (to mimic the future method of creating store members in User Trigger)
            List<Store_Member__c> members = new List<Store_Member__c>();
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[1].Id, users[2].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[1].Id, users[3].Id, Constants.STOREMEMBER_RCM_ROLENAME));
            members[0].Default_Trade_Specialist__c = true;
            members[2].Default_Trade_Specialist__c = true;
            insert members;

            List<Store_Member__c> testMembers = DM_StoreMember.getStoreMemberbyUId((new Map<Id,Store_Member__c>(members)).keySet());
            List<Store_Member__c> membersUpdate = [Select Id, Status__c, Role__c, Store__c, Default_Trade_Specialist__c FROM Store_Member__c];

            List<Store_Member__c> dupMembers = new List<Store_Member__c>();
            dupMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
            dupMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
            dupMembers.add(TestDataFactory.createStoreMember(stores[1].Id, users[2].Id, Constants.STOREMEMBER_TS_ROLENAME));
            dupMembers.add(TestDataFactory.createStoreMember(stores[1].Id, users[3].Id, Constants.STOREMEMBER_RCM_ROLENAME));
            dupMembers[0].Default_Trade_Specialist__c = true;
            dupMembers[2].Default_Trade_Specialist__c = true;

            Database.SaveResult[] result = Database.insert(dupMembers, false);

            System.assertEquals(System.Label.One_Default_TS_Per_Store,result[0].getErrors()[0].getMessage());
            System.assertEquals(System.Label.One_Active_Team_Member_Per_User,result[1].getErrors()[0].getMessage());
            System.assertEquals(System.Label.One_Default_TS_Per_Store,result[2].getErrors()[0].getMessage());
            //System.assertEquals(System.Label.One_Team_Member_Per_Role,result[3].getErrors()[0].getMessage());

            for(Store_Member__c member: membersUpdate){
                
                if(member.Store__c == stores[1].Id && member.Role__c == Constants.STOREMEMBER_TS_ROLENAME){
                    //member.Status__c = Constants.STOREMEMBER_INACTIVE_STATUS;
                    member.Default_Trade_Specialist__c = false;
                }
            }
            if(membersUpdate.size() > 0) {
                Update membersUpdate;
            }
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            users[0].Location_Code__c = stores[1].Location_Code__c;
            users[2].isActive = false;
            update users;
        }        
        Test.stopTest();
        
        List<Task> taskList = [Select Id, Subject, Description, ActivityDate From Task Limit 1];
        System.assertEquals('Assign Trade Specialist',taskList[0].Subject);

    }
    
    @isTest 
    private static void testChangingDefaultTS (){
        
        // create store
        List<Store__c> stores = TestDataFactory.createStores(2);
        stores[0].Operations_Region_Code__c = 'NSW';
        stores[0].Location_Code__c = '2000';
        insert stores;
        
        Profile profileTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(2, null);
        // user 0 and 1 for 1st store
        users[0].ProfileId = profileTS.Id;
        users[0].Location_Code__c = stores[0].Location_Code__c;
        users[1].ProfileId = profileTS.Id;
        users[1].Location_Code__c = stores[0].Location_Code__c;
        
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(1);
        
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            accounts[0].OwnerId = users[0].Id;
            insert accounts;
            
            // create store members (to mimic the future method of creating store members in User Trigger)
            List<Store_Member__c> members = new List<Store_Member__c>();
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
            members[0].Default_Trade_Specialist__c = true;
            insert members;
            System.debug('members default TS: ' + members);
            
        } 
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store_Member__c sm = [Select Id, Default_Trade_Specialist__c From Store_Member__c Where Default_Trade_Specialist__c = true limit 1];
            sm.Default_Trade_Specialist__c = FALSE;
            update sm;
        }
        
        Test.stopTest();
    }
    
    
    @isTest
    private static void testCallingMethodOfRelatedClass() {
        
        // create store
        List<Store__c> stores = TestDataFactory.createStores(2);
        stores[0].Operations_Region_Code__c = 'NSW';
        stores[0].Location_Code__c = '2000';
        stores[1].Operations_Region_Code__c = 'NSW';
        stores[1].Location_Code__c = '2001';
        insert stores;
        
        List<Id> storeIds = new List<Id>();
        storeIds.addAll((new Map<Id,Store__c>(stores)).keySet());
        DM_Store.getStoresWithActiveTSs(storeIds);
        DM_Store.getStoresWithDefaultActiveTSs(storeIds);
        DM_Store.getStoresWithActiveSMs(storeIds);
        DM_Store.getStores(storeIds);
    }
    
    @isTest
    private static void testCUDOperationsRegions() {
        // create users
        Profile profileSSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileAreaBDM = [SELECT Id FROM Profile WHERE Name = :Constants.ORG_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileCCSManager = [SELECT Id FROM Profile WHERE Name = :Constants.NATIONAL_MANAGER_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(4, null);
        users[0].ProfileId = profileSSM.Id;
        users[1].ProfileId = profileRCM.Id;
        users[2].ProfileId = profileAreaBDM.Id;
        users[3].ProfileId = profileCCSManager.Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        // create store
        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';
        insert storeList;
        
        
        // add operations regions
        List<Operations_Region__c> opRegs = new List<Operations_Region__c>();
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'SSM', Team_Member__c = users[0].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'RCM', Team_Member__c = users[1].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'Area BDM', Team_Member__c = users[2].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'CCS Manager', Team_Member__c = users[3].Id));
        
        Test.startTest();
        insert opRegs;
        
        opRegs[0].Team_Member__c = users[1].Id;
        try {
            update opRegs[0];
        } catch(Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            System.assert(e.getMessage().contains('SSM'), 'Incorrect validation error');
        }
        
        delete opRegs[3];
        
        opRegs[0].Role__c = 'CCS Manager';
        opRegs[0].Team_Member__c = users[3].Id;
        update opRegs[0];
        
        Test.stopTest();
    }
}