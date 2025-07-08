/*******************************************************************************************************
* Class Name      	: SM_Store_Test
* Description		: Test class for SM_Store
* Author          	: Simplus - Philip Clark
* Created On      	: 19/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          19/06/2020		1000				Initial version
* Yi Zhang          	19/08/2020		2000				Revamp all resulted from requirement change
* Simplus MS            22/10/2021      3000                Added test logic for CCRM15-79: Update store record to trigger recalculation of call volume on store members
******************************************************************************************************/
@isTest
private class SM_Store_Test {

    @isTest
    private static void testCreateStore() {

        // create users
        Profile profileSSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileAreaBDM = [SELECT Id FROM Profile WHERE Name = :Constants.ORG_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileCCSManager = [SELECT Id FROM Profile WHERE Name = :Constants.NATIONAL_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(5, null);
        users[0].ProfileId = profileSSM.Id;
        users[1].ProfileId = profileRCM.Id;
        users[2].ProfileId = profileAreaBDM.Id;
        users[3].ProfileId = profileCCSManager.Id;
        users[4].ProfileId = profileTS.Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        
        // create operations regions
        List<Operations_Region__c> opRegs = new List<Operations_Region__c>();
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'SSM', Team_Member__c = users[0].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'RCM', Team_Member__c = users[1].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'Area BDM', Team_Member__c = users[2].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'CCS Manager', Team_Member__c = users[3].Id));
        insert opRegs;

        // create store
        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';

        Test.startTest();
        insert storeList;
        Test.stopTest();
        System.assertEquals(4, [SELECT Id FROM Store_Member__c WHERE Store__c = :storeList[0].Id].size(), 'Store members not created as expected');
    }

    @isTest
    private static void testAfterUpdateStore() {

        // Create user with TS profile
        Profile profileTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        User usr = TestDataFactory.createUsers(1, profileTS.Id)[0];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert usr;
        }

        // Create store records with related store members and populate fields needed for call volume calculation
        List<Store__c> storeList = TestDataFactory.createStores(3);
        List<Store_Member__c> storeMemberList = new List<Store_Member__c>();

        for(Store__c st : storeList) {
            st.Country__c = Constants.COUNTRY_AU;
            st.Location_Type__c = Constants.STORE_TYPE_STORE;
            st.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            st.Store_Call__c = '50%';
        }
        insert storeList;

        for(Store__c st : storeList) {
            Store_Member__c sm = TestDataFactory.createStoreMember(st.Id, usr.Id, Constants.STOREMEMBER_TS_ROLENAME);
            sm.Team_Member_Call__c = '10%';
            storeMemberList.add(sm);
        }
        storeMemberList[0].Team_Member_Call__c = '';
        insert storeMemberList;
       
        //Create map of store records with store members for assertion
        Map<Id, Map<Id, Store_Member__c>> storeWithMembersMap = new Map<Id, Map<Id, Store_Member__c>> ();
        List<Store__c> insertedStoresWithMembers = [SELECT Id, (SELECT Id, Call_Volume__c FROM User_Stores__r) 
        FROM Store__c];
        for(Store__c st : insertedStoresWithMembers) {
            storeWithMembersMap.put(st.Id, new Map<Id, Store_Member__c>(st.User_Stores__r));
        }     

        //Update store records to trigger after update method
        for(Store__c st : storeList) {
            st.Engagement_Model__c = 'Old';
        }
        storeList[0].Engagement_Model__c = 'New'; //No record change and will be excluded
        storeList[0].Sales_Rep_ID__c = '500';
        
        Test.startTest();
        update storeList;
        Test.stopTest();

        //Retrieve list of updated store records with store members and perform assertion
        List<Store__c> updatedStoresWithMembers = [SELECT Id, (SELECT Id, Call_Volume__c FROM User_Stores__r) 
                                                   FROM Store__c WHERE Engagement_Model__c = 'Old'];
        System.assertEquals(2, updatedStoresWithMembers.size(), 'Number of store records updated does not match expected number');

        //Call volume is expected to be recalculated with the update of store engagement model
        for(Store__c st : updatedStoresWithMembers) {
            for(Store_Member__c sm : st.User_Stores__r) {
                System.assert(sm.Call_Volume__c != storeWithMembersMap.get(st.Id).get(sm.Id).Call_Volume__c, 'Call volume did not recalculate');
            }
        }
    } 
}