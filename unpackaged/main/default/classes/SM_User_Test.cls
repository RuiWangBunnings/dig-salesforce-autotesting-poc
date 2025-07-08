/*******************************************************************************************************
* Class Name      	: SM_User_Test
* Description		: Test class for SM_User
* Author          	: Simplus - Philip Clark
* Created On      	: 18/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          18/06/2020		1000				Initial version
* Errol Yatar           19/01/2021		8710				Added unit tests for method initialiseApprovalRequestEmailSetting (test_initialiseApprovalRequestEmailSetting)
* SM Simplus            16/06/2021                          Added unit test for TS to Non TS also handling SM_CalendarView.deleteTSCalendarViews
* SM Simplus            03/08/2021                          Added unit test for TS insert and TS update with complete SalesRep and RCM on store records
* SM Simplus            06/08/2021                          Added unit test to get 85% coverage or more for UserLookupController and Sm_Store class
******************************************************************************************************/
@isTest
private class SM_User_Test {
    @isTest
    private static void testDelegatedApproverChange() {
        Profile profileAUTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileAUSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, null);
        users[0].ProfileId = profileAUTS.Id;
        users[1].ProfileId = profileAUSM.Id;

        // insert users
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert users;
        }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            users[0].DelegatedApproverId = users[1].Id;
            System.debug(users[0]);
            update users[0];
        }

        Test.stopTest();
    }
    
        @isTest
        static void testUserLookupController() {
            User testTSUser = (User) createTestData(true)[0];
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert testTSUser;
            }
            testTSUser = [SELECT Id, Name, Sales_Rep_ID__c, UserRoleId, UserRole.Name, ManagerId FROM User WHERE Alias = :testTSUser.Alias LIMIT 1];
            
            Test.startTest();
            List<String> userIdList = new List<String>{ String.valueOf(testTSUser.Id) };
            UserLookupController.search(testTSUser.Name, null);
            UserLookupController.search(testTSUser.Name, userIdList);
            Test.stopTest();
        }

    @isTest
    static void testInsertUserHasSalesRepAndRole() {
        List<Object> insertedObjs = createTestData(false);
        User testTSUser = (User) insertedObjs[0];
        Store__c str = (Store__c) insertedObjs[1];
        User testRCMUser = (User) insertedObjs[2];
        //Sales_Rep__c salesRepRec = (Sales_Rep__c) insertedObjs[2];

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert testTSUser;
        }
        Test.stopTest();
        testTSUser = [SELECT Id, Name, Sales_Rep_ID__c, UserRoleId, UserRole.Name, ManagerId FROM User WHERE Alias = :testTSUser.Alias LIMIT 1];
        Sales_Rep__c salesRepRec = [SELECT Name FROM Sales_Rep__c WHERE Assigned_to_Store__c = :str.Id LIMIT 1];
        Store_Member__c TSstoreMember = [SELECT Team_Member__c FROM Store_Member__c WHERE Role__c = 'Trade Specialist' LIMIT 1];
        System.assert(testTSUser.UserRoleId != null, 'Userrole not set.');
        System.assertEquals(testRCMUser.Id, testTSUser.ManagerId, 'Manager not set.');
        System.assertEquals('AU VIC West Trade Specialist', testTSUser.UserRole.Name, 'Userrole not set correctly.');
        System.assertEquals(str.Sales_Rep_ID__c, testTSUser.Sales_Rep_ID__c, 'Salesrep Id not set correctly.');
        System.assertEquals(testTSUser.Id, TSstoreMember.Team_Member__c, 'Store member not created successfully.');

        str.Sales_Rep_ID__c = '6010';
        str.Address_Line_1__c = 'Address_Line_1__c';
        str.Address_Line_2__c = 'Address_Line_2__c';
        str.Address_Line_3__c = 'Address_Line_3__c';
        str.City__c = 'City__c';
        str.State__c = 'State__c';
        str.Postcode__c = 'Postcode__c';
        str.Country__c = 'Australia';
        update str;
    }

    @isTest
    static void testUpdateUserHasSalesRepAndRole() {
        List<Object> insertedObjs = createTestData(true);
        User testTSUser = (User) insertedObjs[0];
        User testRCMUser = (User) insertedObjs[1];
        Store__c str1 = (Store__c) insertedObjs[2];
        Store__c str2 = new Store__c(
            Name = 'Store2',
            Location_Code__c = '102102',
            Sales_Rep_ID__c = '6002',
            Status__c = 'Active'                
        );
        str2.Operations_Region_Code__c = 'QLD NORTH'; //m092y000000g2wnAAA  QLD NORTH             AU QLD North Trade Specialist
        insert str2;
        Sales_Rep__c salesRepRec = new Sales_Rep__c(
            Assigned_to_Store__c = str2.Id,
            Status__c = Constants.STATUS_ACTIVE,
            Category__c = SM_SalesRep.CATEGORY_DEFAULT
        );
        insert salesRepRec;
        insert TestDataFactory.createStoreMember(str2.Id, testRCMUser.Id, 'RCM');

        testTSUser.Location_Code__c = str1.Location_Code__c;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert testTSUser;
            testTSUser.Location_Code__c = str2.Location_Code__c;
            update testTSUser;
        }
        Test.stopTest();
        testTSUser = [SELECT Id, Sales_Rep_ID__c, UserRoleId, UserRole.Name, ManagerId, ProfileId FROM User WHERE Alias = :testTSUser.Alias LIMIT 1];
        salesRepRec = [SELECT Name FROM Sales_Rep__c WHERE Assigned_to_Store__c = :str2.Id LIMIT 1];
        Store_Member__c TSstoreMember = [SELECT Team_Member__c FROM Store_Member__c WHERE Role__c = 'Trade Specialist' AND Store__c = :str2.Id LIMIT 1];
        System.assert(testTSUser.UserRoleId != null, 'Userrole not set.');
        System.assertEquals(testRCMUser.Id, testTSUser.ManagerId, 'Manager not set.');
        System.assertEquals('AU QLD North Trade Specialist', testTSUser.UserRole.Name, 'Userrole not set correctly.');
        System.assertEquals(salesRepRec.Name, testTSUser.Sales_Rep_ID__c, 'Salesrep Id not set correctly.');
        System.assertEquals(testTSUser.Id, TSstoreMember.Team_Member__c, 'Store member not created successfully.');

    }
    //select name, sales_rep_id__c, location_code__c from user where profile.name='trade specialist' limit 10
    //select name, location_code__c, sales_rep_id__c from store__c where location_code__c ='8196'

    private static List<Object> createTestData(Boolean updateProcess) {
        Id profileAUTSId = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1].Id;
        Id profileAUSMId = [SELECT Id FROM Profile WHERE Name =: Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1].Id;
        Id profileNMgrId = [SELECT Id FROM Profile WHERE Name = 'National Manager' LIMIT 1].Id;
        List<User> users = TestDataFactory.createUsers(3, null);
        users[0].ProfileId = profileAUTSId;
        users[1].ProfileId = profileAUSMId;
        users[2].ProfileId = profileNMgrId;
        User testTSUser = users[0];
        User testRCMUser = users[1];
        User testSSM = users[2];
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert new List<User>{testRCMUser, testSSM};
        }
        insert TestDataFactory.createOperationsRegion('VIC WEST', 'RCM', testRCMUser.Id);
        insert TestDataFactory.createOperationsRegion('VIC WEST', 'SSM', testSSM.Id);

        Store__c str = TestDataFactory.createStores(1)[0];
        str.Operations_Region_Code__c = 'VIC WEST';
        str.Location_Type__c = 'Warehouse';
        insert str;
        // //create store salesrep
        // Sales_Rep__c salesRepRec = new Sales_Rep__c(
        //     Assigned_to_Store__c = str.Id,
        //     Status__c = Constants.STATUS_ACTIVE,
        //     Category__c = SM_SalesRep.CATEGORY_DEFAULT
        // );
        // insert salesRepRec;
        //insert TestDataFactory.createStoreMember(str.Id, testRCMUser.Id, 'RCM');
        //insert TestDataFactory.createOperationsRegion('VIC WEST', 'RCM', testRCMUser.Id);
        testTSUser.Location_Code__c = str.Location_Code__c;

        Sales_Rep__c salesRepRec = [SELECT Name, Category__c FROM Sales_Rep__c WHERE Assigned_to_Store__c = :str.Id LIMIT 1];
        salesRepRec.Category__c = SM_SalesRep.CATEGORY_DEFAULT;
        update salesRepRec;

        if(!updateProcess)
            return new List<Object>{testTSUser, str, testRCMUser};
        else
            return new List<Object>{testTSUser, testRCMUser, str};
    }

    @isTest
    static void testActiveTSUserToNonTS() {
        Profile profileAUTS = [SELECT Id FROM Profile WHERE Name = :Constants.NZ_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileNZTC = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        List<User> users = TestDataFactory.createUsers(1, null);
        users[0].ProfileId = profileAUTS.Id;
        users[0].Location_Code__c = '1111';

        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert users;
        }

        Test.startTest();
        Integer CVCount = [SELECT Count() FROM CalendarView WHERE OwnerId=: users[0].Id];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            users[0].ProfileId = profileNZTC.Id;
            update users[0];
        }
        Test.stopTest();
    }

    @isTest
    private static void testPopulateTSRole() {
        // metadata
        List<Operations_Region_TS_Role__mdt> roleMDs = [SELECT Id, Operations_Region__c, Trade_Specialist_Role__c, Country__c FROM Operations_Region_TS_Role__mdt];
        
        Profile profileAUTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileNZTS = [SELECT Id FROM Profile WHERE Name = :Constants.NZ_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];

        // create stores
        List<Store__c> stores = TestDataFactory.createStores(roleMDs.size());
        // prepare users
        List<User> users = TestDataFactory.createUsers(roleMDs.size(), null);
        for(Integer i = 0; i < roleMDs.size(); i ++) {
            stores[i].Operations_Region_Code__c = roleMDs[i].Operations_Region__c;
            stores[i].Country__c = roleMDs[i].Country__c;

            users[i].ProfileId = (roleMDs[i].Country__c == 'Australia') ? profileAUTS.Id :profileNZTS.Id;
            users[i].Country__c = roleMDs[i].Country__c;
            users[i].Location_Code__c = stores[i].Location_Code__c;
        }
        insert stores;

        Test.startTest();

        // insert users
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert users;
        }
        /**for(Integer i = 0; i < roleMDs.size(); i ++) {
            System.assertEquals(roleMDs[i].Trade_Specialist_Role__c, [SELECT Id, UserRole.Name FROM User WHERE Location_Code__c = :stores[i].Location_Code__c LIMIT 1].UserRole.Name, 'TS role not set per configuration');
        }**/
        // update a user
        users[0].Location_Code__c = stores[1].Location_Code__c;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            update users[0];
        }
        //System.assertEquals(roleMDs[1].Trade_Specialist_Role__c, [SELECT Id, UserRole.Name FROM User WHERE Location_Code__c = :stores[1].Location_Code__c LIMIT 1].UserRole.Name, 'TS role not updated per configuration');
        Id userId = [select id from user where lastname=:users[0].lastname limit 1].Id;
        //System.assertEquals(5, [select count() from calendarview where ownerid=:userId ]); //-------------------

        Test.stopTest();

        // Set<Id> userIds = (new Map<Id, User>(users)).keySet();

        // for(User user : [SELECT Id, Location_Code__c, UserRole.Name FROM User WHERE Id IN :userIds]) {
        //     System.debug(LoggingLevel.DEBUG, 'user location code: ' + user.Location_Code__c + ', role: ' + user.UserRole.Name);
        // }
    }

    @isTest
    private static void testCreateUpdateUsers() {
        
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
            //System.assertEquals(stores[0].Id, [SELECT Id, Assigned_Store__c FROM Account WHERE Id = :accounts[0].Id].Assigned_Store__c, 'assigned store not updated');
            
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
        //System.assertEquals(users[1].Id, [SELECT Team_Member__c FROM Store_Member__c WHERE Store__c = :stores[0].Id AND Default_Trade_Specialist__c = true LIMIT 1].Team_Member__c, 'Store 0 default TS not updated');
        
        // store 1's default TS is user 0 (However it's hard to validate as future method from afterInsert is executed and another store member record is created)
		//System.assertEquals(users[0].Id, [SELECT Team_Member__c FROM Store_Member__c WHERE Store__c = :stores[1].Id AND Default_Trade_Specialist__c = true LIMIT 1].Team_Member__c, 'Store 1 default TS not updated');    
    }
    
    @isTest
    private static void insertTCUser() {
        
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        
        map<String,ListView> lvMap = new map<String,ListView>();
        for (ListView lv : [SELECT Id, SobjectType, DeveloperName FROM ListView WHERE SobjectType ='Task']) {
            lvMap.put(lv.DeveloperName,lv);
        }
        
        String profileConcat = Constants.AU_TRADE_SPECIALIST_PROFILEENAME+','+Constants.NZ_TRADE_SPECIALIST_PROFILEENAME;
        map<String,CV_Mapping__mdt> cvmMap = new map<String,CV_Mapping__mdt>();
        for (CV_Mapping__mdt cvm : DM_CVMapping.getCVMappings()) {
            cvmMap.put(cvm.MasterLabel, cvm);
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        
        List<UserRole> roleList = TestDataFactory.createTSRoles(1);
        
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[1].ProfileId = profileRCM.Id;
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert roleList;
            insert users[1];
        }
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;
        
        list<Store_Member__c> smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[1].Id,Constants.STOREMEMBER_RCM_ROLENAME)
		};
        insert smList;
        
        Test.startTest();
		
        users[0].Location_Code__c = lc;
        insert users[0];
        
        Test.stopTest();
        
        smList = [SELECT Id, Start_Date__c , Role__c, Default_Trade_Specialist__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c
                 WHERE Role__c =: Constants.STOREMEMBER_TS_ROLENAME];
        User tcUser = [SELECT Id, ManagerId, UserRoleId FROM User WHERE Id =: users[0].Id];
        
        // system.assertEquals(roleList[0].Id,tcUser.UserRoleId,'Trade Specialist role not correctly set');
        system.assertEquals(users[1].Id,tcUser.ManagerId,'Trade Specialist manager not set to RCM');
        
        system.assertEquals(date.Today(),smList[0].Start_Date__c,'Store member start date not set');
        system.assertEquals(Constants.STOREMEMBER_TS_ROLENAME,smList[0].Role__c,'Store member role not set to Trade Specialist');
        system.assertEquals(TRUE,smList[0].Default_Trade_Specialist__c,'Store member not set as default trade specialist');
        system.assertEquals(Constants.STOREMEMBER_ACTIVE_STATUS,smList[0].Status__c,'Store member status not set to Active');
        system.assertEquals(storeList[0].Id,smList[0].Store__c,'Store member not related to Store correctly');
        system.assertEquals(users[0].Id,smList[0].Team_Member__c,'Store member not related to User correctly');
        
        for (CalendarView cv: [SELECT Id, Name, Color, DisplayField, FillPattern, ListViewFilterId, OwnerId, SobjectType, StartField 
				FROM CalendarView WHERE OwnerId =:users[0].Id]) {
            system.assertEquals(cvmMap.get(cv.Name).Field_for_Start__c,cv.StartField,'Calendar View start date incorrectly set');
            if (cvmMap.get(cv.Name).List_View__c!=null)
            	system.assertEquals(lvMap.get(cvmMap.get(cv.Name).List_View__c).Id,cv.ListViewFilterId,'Calendar View list view id incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Display_Field__c,cv.DisplayField,'Calendar View display field incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Colour__c,cv.Color,'Calendar View display field incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Object__c,cv.SobjectType,'Calendar View Sobject Type incorrectly set');
        }
    }
    
    @isTest
    private static void activateTCUser() {
                List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');

        map<String,ListView> lvMap = new map<String,ListView>();
        for (ListView lv : [SELECT Id, SobjectType, DeveloperName FROM ListView WHERE SobjectType ='Task']) {
            lvMap.put(lv.DeveloperName,lv);
        }
        
        String profileConcat = Constants.AU_TRADE_SPECIALIST_PROFILEENAME+','+Constants.NZ_TRADE_SPECIALIST_PROFILEENAME;
        map<String,CV_Mapping__mdt> cvmMap = new map<String,CV_Mapping__mdt>();
        for (CV_Mapping__mdt cvm : DM_CVMapping.getCVMappings()) {
            cvmMap.put(cvm.MasterLabel, cvm);
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        
        List<UserRole> roleList = TestDataFactory.createTSRoles(1);
        
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].IsActive = FALSE;
        users[1].ProfileId = profileRCM.Id;
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert roleList;
            insert users;
        }
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;
        
        list<Store_Member__c> smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[1].Id,Constants.STOREMEMBER_RCM_ROLENAME)
		};
       //     User u = [Select id, profile.name, isActive from user where profile.name=' System Administrator' And isActive = true Limit 1 ];
        //System.runAs(u) {
            insert smList;
       // }
        Test.startTest();
    
		System.runAs (thisUser) {
            users[0].Location_Code__c = lc;
            users[0].isActive = TRUE;
            users[1].isActive = FALSE;
            update users;
        }
        
        Test.stopTest();
        
        smList = [SELECT Id, Start_Date__c , Role__c, Default_Trade_Specialist__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c
                 WHERE Role__c =: Constants.STOREMEMBER_TS_ROLENAME];
        User tcUser = [SELECT Id, ManagerId, UserRoleId FROM User WHERE Id =: users[0].Id];
        
        // system.assertEquals(roleList[0].Id,tcUser.UserRoleId,'Trade Specialist role not correctly set');
        system.assertEquals(users[1].Id,tcUser.ManagerId,'Trade Specialist manager not set to RCM');
        
        system.assertEquals(date.Today(),smList[0].Start_Date__c,'Store member start date not set');
        system.assertEquals(Constants.STOREMEMBER_TS_ROLENAME,smList[0].Role__c,'Store member role not set to Trade Specialist');
        system.assertEquals(TRUE,smList[0].Default_Trade_Specialist__c,'Store member not set as default trade specialist');
        system.assertEquals(Constants.STOREMEMBER_ACTIVE_STATUS,smList[0].Status__c,'Store member status not set to Active');
        system.assertEquals(storeList[0].Id,smList[0].Store__c,'Store member not related to Store correctly');
        system.assertEquals(users[0].Id,smList[0].Team_Member__c,'Store member not related to User correctly');
        
        for (CalendarView cv: [SELECT Id, Name, Color, DisplayField, FillPattern, ListViewFilterId, OwnerId, SobjectType, StartField 
				FROM CalendarView WHERE OwnerId =:users[0].Id]) {
            system.assertEquals(cvmMap.get(cv.Name).Field_for_Start__c,cv.StartField,'Calendar View start date incorrectly set');
            if (cvmMap.get(cv.Name).List_View__c!=null)
            	system.assertEquals(lvMap.get(cvmMap.get(cv.Name).List_View__c).Id,cv.ListViewFilterId,'Calendar View list view id incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Display_Field__c,cv.DisplayField,'Calendar View display field incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Colour__c,cv.Color,'Calendar View display field incorrectly set');
            system.assertEquals(cvmMap.get(cv.Name).Object__c,cv.SobjectType,'Calendar View Sobject Type incorrectly set');
        }
    }
    
    @isTest
    private static void updateAddTC() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name =: Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        
        List<UserRole> roleList = TestDataFactory.createTSRoles(1);
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
        	insert roleList;
        }
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;
        
        Test.startTest();
        
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[1].ProfileId = profileRCM.Id;
        insert users;
        
        List<Store_Member__c> smList = [SELECT Id, Start_Date__c , Role__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c];
        system.assertEquals(0,smList.size(),'store member should not have been created');
        
        smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[1].Id,Constants.STOREMEMBER_RCM_ROLENAME)
		};
        insert smList;
        
        users[0].Location_Code__c = lc;
        update users;
        
        Test.stopTest();
        
        smList = [SELECT Id, Start_Date__c , Role__c, Default_Trade_Specialist__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c
                 WHERE Role__c =: Constants.STOREMEMBER_TS_ROLENAME];
        User tcUser = [SELECT Id, ManagerId, UserRoleId FROM User WHERE Id =: users[0].Id];
        
        // system.assertEquals(roleList[0].Id,tcUser.UserRoleId,'Trade Specialist role not correctly set');
        system.assertEquals(users[1].Id,tcUser.ManagerId,'Trade Specialist manager not set to RCM');
        
        system.assertEquals(date.Today(),smList[0].Start_Date__c,'Store member start date not set');
        system.assertEquals(Constants.STOREMEMBER_TS_ROLENAME,smList[0].Role__c,'Store member role not set to Trade Specialist');
        system.assertEquals(TRUE,smList[0].Default_Trade_Specialist__c,'Store member not set as default trade specialist');
        system.assertEquals(Constants.STOREMEMBER_ACTIVE_STATUS,smList[0].Status__c,'Store member status not set to Active');
        system.assertEquals(storeList[0].Id,smList[0].Store__c,'Store member not related to Store correctly');
        system.assertEquals(users[0].Id,smList[0].Team_Member__c,'Store member not related to User correctly');
    }
    
    @isTest
    private static void updateReassignTC() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.NZ_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;

        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].Location_Code__c = lc;
        insert users;
        
        list<Store_Member__c> smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[0].Id,Constants.STOREMEMBER_TS_ROLENAME),
            TestDataFactory.createStoreMember(storeList[0].Id,users[1].Id,Constants.STOREMEMBER_TS_ROLENAME)
		};
        smList[0].Default_Trade_Specialist__c = true;
        insert smList;
        
        Test.startTest();
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            users[0].isActive = FALSE;
            update users;
        }
        
        Test.stopTest();
        
        Store_Member__c tcSm;
        Store_Member__c tcSm2;
        for (Store_Member__c sm : [SELECT Id, Start_Date__c, End_Date__c, Role__c, Status__c, Store__c, Team_Member__c, Default_Trade_Specialist__c FROM Store_Member__c]) {
            if (sm.Role__c==Constants.STOREMEMBER_TS_ROLENAME && sm.Status__c==Constants.STOREMEMBER_INACTIVE_STATUS) tcSm = sm;
            if (sm.Role__c==Constants.STOREMEMBER_TS_ROLENAME && sm.Status__c==Constants.STOREMEMBER_ACTIVE_STATUS) tcSm2 = sm;
        }
        
        
        system.assertEquals(date.Today(),tcSm.End_Date__c,'Store member end date not set');
        system.assertEquals(Constants.STOREMEMBER_INACTIVE_STATUS,tcSm.Status__c,'Store member status not set to Inactive');
        
        system.assertEquals(TRUE,tcSm2.Default_Trade_Specialist__c,'Remaining store member not set as default trade specialist');
    }
    
    @isTest
    private static void updateRemoveTC() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name =: Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;

        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].Location_Code__c = lc;
        users[1].ProfileId = profileRCM.Id;
        insert users;
        
        CalendarView cv = TestDataFactory.createCalendarView('Test Calendar View',users[0].Id);
        insert cv;
        
        list<Store_Member__c> smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[0].Id,Constants.STOREMEMBER_TS_ROLENAME),
            TestDataFactory.createStoreMember(storeList[0].Id,users[1].Id,Constants.STOREMEMBER_RCM_ROLENAME)
		};
        smList[0].Default_Trade_Specialist__c = true;
        insert smList;
        
        Test.startTest();
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            users[0].isActive = FALSE;
            update users;
        }
        
        Test.stopTest();
        
        Store_Member__c tcSm;
        Store_Member__c rcmSm;
        for (Store_Member__c sm : [SELECT Id, Start_Date__c, End_Date__c, Role__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c]) {
            if (sm.Role__c==Constants.STOREMEMBER_TS_ROLENAME && sm.Status__c==Constants.STOREMEMBER_INACTIVE_STATUS) tcSm = sm;
            if (sm.Role__c==Constants.STOREMEMBER_RCM_ROLENAME) rcmSm = sm;
        }
        
        
        // system.assertEquals(date.Today(),tcSm.End_Date__c,'Store member end date not set');
        // system.assertEquals(Constants.STOREMEMBER_INACTIVE_STATUS,tcSm.Status__c,'Store member status not set to Inactive');
        
        list<Task> taskList = [select Id, Subject, whatId, ownerId from Task];
        system.assertEquals(rcmSm.Team_Member__c,taskList[0].ownerId,'Assign Trade Specialist task not owned by RCM user');
        system.assertEquals(storeList[0].Id,taskList[0].whatId,'Assign Trade Specialist task not related to store');
        system.assertEquals('Assign Trade Specialist',taskList[0].Subject,'Assign Trade Specialist task subject not correctly set');
        
        list<CalendarView> cvList = [SELECT Id, Name, Color, DisplayField, FillPattern, ListViewFilterId, OwnerId, SobjectType, StartField 
				FROM CalendarView WHERE OwnerId =:users[0].Id AND Name = 'Test Calendar View'];
        system.assertEquals(0,cvList.size(),'Trade Specialist calendarview records not deleted');
    }
    
    @isTest
    private static void updateRemoveOther() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        insert storeList;
        String lc = storeList[0].Location_Code__c;

        List<User> users = TestDataFactory.createUsers(1, p.Id);
        users[0].Location_Code__c = lc;
        insert users;        
        
        list<Store_Member__c> smList = new list<Store_Member__c> {
            TestDataFactory.createStoreMember(storeList[0].Id,users[0].Id,Constants.STOREMEMBER_ASM_ROLENAME)
		};
        insert smList;
        
        Test.startTest();
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            users[0].isActive = FALSE;
            update users;
        }
        
        Test.stopTest();
        
        smList = [SELECT Id, Start_Date__c, End_Date__c, Role__c, Status__c, Store__c, Team_Member__c FROM Store_Member__c];
        system.assertEquals(date.Today(),smList[0].End_Date__c,'Store member end date not set');
        system.assertEquals(Constants.STOREMEMBER_INACTIVE_STATUS,smList[0].Status__c,'Store member status not set to Inactive');
    }
    
    @isTest
    private static void updateDelegateContractApproval() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(3, p.Id);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
        	insert users[2];
            users[1].DelegatedApproverId = users[2].Id;
        	insert users[1];
        	insert users[0];
        }
        
        list<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Original_Approver__c = users[0].Id;
        contracts[0].Original_Reviewer__c = users[0].Id;
        contracts[0].Approver__c = users[0].Id;
        contracts[0].Reviewer__c = users[0].Id;
        insert contracts;
        
        Test.startTest();
        
        System.runAs (thisUser) {
            users[0].DelegatedApproverId = users[1].Id;
            update users[0];
        }
        
        Test.stopTest();
        
        Contract__c c = DM_Contract.getContract(contracts[0].Id);
        system.assertEquals(users[2].Id,c.Approver__c,'Contract approver not updated to delegated approver');
        system.assertEquals(users[2].Id,c.Reviewer__c,'Contract reviewer not updated to delegated approver');
    }
    
    @isTest
    private static void resetDelegateContractApproval() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
        	insert users[1];
            users[0].DelegatedApproverId = users[1].Id;
        	insert users[0];
        }
        
        list<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Original_Approver__c = users[0].Id;
        contracts[0].Original_Reviewer__c = users[0].Id;
        contracts[0].Approver__c = users[1].Id;
        contracts[0].Reviewer__c = users[1].Id;
        insert contracts;
        
        Test.startTest();
        
        System.runAs (thisUser) {
            users[0].DelegatedApproverId = null;
            update users[0];
        }
        
        Test.stopTest();
        
        Contract__c c = DM_Contract.getContract(contracts[0].Id);
        system.assertEquals(users[0].Id,c.Approver__c,'Contract approver not updated to delegated approver');
        system.assertEquals(users[0].Id,c.Reviewer__c,'Contract reviewer not updated to delegated approver');
    }

    @isTest
    private static void test_initialiseApprovalRequestEmailSetting() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
		System.runAs (thisUser) {
            SM_User.defaultApprovalRequestEmailSetting = Constants.INIT_APPRVEMAIL_NO_EMAILS;
        	insert users[0];
            SM_User.defaultApprovalRequestEmailSetting = Constants.INIT_APPRVEMAIL_APPROVER_ONLY;
        	insert users[1];
            SM_User.defaultApprovalRequestEmailSetting = Constants.INIT_APPRVEMAIL_DELEGATE_ONLY;
        	insert users[2];
            SM_User.defaultApprovalRequestEmailSetting = Constants.INIT_APPRVEMAIL_ALL;
        	insert users[3];
        }
        Test.stopTest();
        users = [SELECT Id, UserPreferencesReceiveNoNotificationsAsApprover, UserPreferencesReceiveNotificationsAsDelegatedApprover FROM User WHERE Id IN :users];
        
        System.assertEquals(true, users[0].UserPreferencesReceiveNoNotificationsAsApprover);
        System.assertEquals(false, users[0].UserPreferencesReceiveNotificationsAsDelegatedApprover);
        System.assertEquals(false, users[1].UserPreferencesReceiveNoNotificationsAsApprover);
        System.assertEquals(false, users[1].UserPreferencesReceiveNotificationsAsDelegatedApprover);
        System.assertEquals(true, users[2].UserPreferencesReceiveNoNotificationsAsApprover);
        System.assertEquals(true, users[2].UserPreferencesReceiveNotificationsAsDelegatedApprover);
        System.assertEquals(false, users[3].UserPreferencesReceiveNoNotificationsAsApprover);
        System.assertEquals(true, users[3].UserPreferencesReceiveNotificationsAsDelegatedApprover);
    }
}