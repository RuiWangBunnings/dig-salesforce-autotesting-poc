/*******************************************************************************************************
* Class Name      	: TEMP_SM_CallCycle_Test.cls
* Description		: Test class for TEMP_SM_CallCycleBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang            	15/05/2020		1000				Initial version
* Bunnings Dev			20/09/2022		2000				Fix test class issue
******************************************************************************************************/
@isTest
private class TEMP_SM_CallCycle_Test {

    @testSetup static void setup() {

        // This is the amount of the accounts created for the trade specialist
        // If sum of limits in Engagement_Model__mdt for a particular format + type exceeds this number
        // The test class will fail
        // However CPU may timeout if the number goes up
        //Integer accountCount = 350;
		Integer accountCount = 50;
        
        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.NZ_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;

        
        //SIMPLUS MS - 15JUN2021 CCRM-13431
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // create store
            List<Store__c> stores = TestDataFactory.createStores(1);
            stores[0].Engagement_Model__c = 'New';
            stores[0].Location_Type__c = 'Warehouse';
            insert stores;

            // create store member
            Store_Member__c member = new Store_Member__c();
            member = TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.AU_TRADE_SPECIALIST_PROFILEENAME);
            insert member;

            RecordType NZCustomerRecType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'NZ_Customer' LIMIT 1];
            Integer counter = 0;
            // create accounts - 350 accounts, 16 callPriority = 1.2, 24 callPriority = 1.1, 310 account with no call reason
            List<Account> accounts = TestDataFactory.createAccounts(accountCount);
            for(Account a :accounts) {
                a.OwnerId = users[0].Id;
                a.R12_Sales_Rank__c = Math.floor(Math.random()*1000);
                a.Call_Cycle_Ranking__c = Math.floor(Math.random()*10000);
                a.Call_Reason__c = 'Call Reason ' + String.valueOf(Math.random());

                if(counter < 16) {
                    a.Call_Priority__c = 1.2;
                } else if(counter < 40) {
                    a.Call_Priority__c = 1.1;
                } else {
                    a.Call_Reason__c = '';
                }
                                                
                a.RecordTypeId = NZCustomerRecType.Id;
                a.Account_Status__c = 'Active';
                counter += 1; 
            }
            insert accounts;
        }
    }

    /**
    * @description - this is for fix of task created with no subject and call priority not taken into account PRB0048314 / CCRM-13872
    * @author SIMPLUS MS | 15/06/2021 
    **/
    @isTest
    static void testCreateMonthlyCallCycleFixOnAccountModel1() {
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            store.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            store.Location_Type__c = Constants.STORE_TYPE_WAREHOUSE;
            update store;
            // batchable
            Database.executebatch(new TEMP_SM_CallCycleBatch(), 20);

        }
        Test.stopTest();
        User u = [SELECT Id FROM User LIMIT 1];
        Integer SMList = [SELECT Count() FROM Store_Member__c];
        System.assertNotEquals(0, SMList);
        //List<Task> taskList = [SELECT Id, Subject FROM Task WHERE Subject != :SM_CallCycle.SUBJECT_LESS_FREQUENT_CONTACT_REMINDER AND Subject != :SM_CallCycle.SUBJECT_FREQUENT_CONTACT_REMINDER];
        List<Task> taskList = [SELECT Id, Subject FROM Task];
        //validateCreatedTasks();
        //System.assertEquals(40, taskList.size());
        

        //test for more coverage, not related to method
        List<Account> listAccounts = [SELECT Id FROM Account];
        Set<Account> accSet = new Set<Account>();
        for(Account acc : listAccounts) {
            accSet.add(acc);
        }
        //SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);
        SM_CallCycle.getStandardOpptyRTs();
    }

    @isTest
    static void testCreateMonthlyCallCycle_New_Warehouse() {


        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            store.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            store.Location_Type__c = Constants.STORE_TYPE_WAREHOUSE;
            update store;

            // schedulable (not immediate)
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new TEMP_SM_CallCycleBatch());
            // batchable
            Database.executebatch(new TEMP_SM_CallCycleBatch(), 20);

        }
        Test.stopTest();

        ///validateCreatedTasks();
    
    }

    
    @isTest
    static void testCreateMonthlyCallCycle_New_Store() {

        
        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            store.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            store.Location_Type__c = Constants.STORE_TYPE_STORE;
            update store;

            // schedulable (not immediate)
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new TEMP_SM_CallCycleBatch());
            // batchable
            Database.executebatch(new TEMP_SM_CallCycleBatch(), 20);

        }
        Test.stopTest();

        ///validateCreatedTasks();
    }

    @isTest
    static void testCreateMonthlyCallCycle_Old_Warehouse() {

        
        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            store.Engagement_Model__c = Constants.STORE_MODEL_OLD;
            store.Location_Type__c = Constants.STORE_TYPE_WAREHOUSE;
            update store;

            // schedulable (not immediate)
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new TEMP_SM_CallCycleBatch());
            // batchable
            Database.executebatch(new TEMP_SM_CallCycleBatch(), 20);
            
        }
        Test.stopTest();

        ///validateCreatedTasks();
    }

    @isTest
    static void testCreateMonthlyCallCycle_Old_Store() {

        
        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            store.Engagement_Model__c = Constants.STORE_MODEL_OLD;
            store.Location_Type__c = Constants.STORE_TYPE_STORE;
            update store;

            // schedulable (not immediate)
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new TEMP_SM_CallCycleBatch());
            // batchable
            Database.executebatch(new TEMP_SM_CallCycleBatch(), 20);

        }
        Test.stopTest();

        ///validateCreatedTasks();
    }

    
    /**
    * @description  Validation steps shared by all test methods
    * @author Yi Zhang | 22/07/2020 
    **/
    static void validateCreatedTasks() {
        Store_Member__c member1 = [SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Team_Member__c FROM Store_Member__c LIMIT 1];
        String key = member1.Store__r.Engagement_Model__c + member1.Store__r.Location_Type__c;

        Integer limit1 = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT).get(key);
        Integer limit2 = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_FREQUENT).get(key);
        Integer limit3 = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_LESS_FREQUENT).get(key);

        Integer allTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle].size();
        Integer frequentTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND Subject = :SM_CallCycle.SUBJECT_FREQUENT_CONTACT_REMINDER].size();
        Integer lessFrequentTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND Subject = :SM_CallCycle.SUBJECT_LESS_FREQUENT_CONTACT_REMINDER].size();

        System.debug(LoggingLevel.DEBUG, member1.Store__r.Engagement_Model__c + ' ' + member1.Store__r.Location_Type__c + ' limits: ' + limit1 + ', ' + limit2 + ', ' + limit3);
        //System.assertEquals(limit1 + limit2 + limit3, allTasksCount, 'Number of totally created tasks incorrect'); // temporarily commented out 
        //System.assertEquals(limit2, frequentTasksCount, 'Number of created frequent tasks incorrect');
        //System.assertEquals(limit3, lessFrequentTasksCount, 'Number of created less frequent tasks incorrect');
    }
    //Cover before update methods and other methods to increase the coverage
    @isTest
    static void testnextBusinessDate() {
        TEMP_SM_CallCycle.nextBusinessDate(System.today());
    }
    
    //Cover before update methods and other methods to increase the coverage
    @isTest
    static void testgetStandardOpptyRTs(){
        TEMP_SM_CallCycle.getStandardOpptyRTs();
    }
    
    //Cover before update methods and other methods to increase the coverage
    @isTest
    public static void createMonthlyCallCycleTest() {
        List<Planned_Leave__c> plannedLeaves = new List<Planned_Leave__c>();
        Set<Date> plannedLeavesSet = new Set<Date>();
        List<Date> businessDates = new List<Date>();
        List<Account> updateAccountList = new List<Account>();
        List<Account> updateAccountList1 = new List<Account>();
        
        Test.startTest();        
        
        List<User> users = [Select Id from User Limit 1];
        
        plannedLeaves.add(new Planned_Leave__c(OwnerId = users[0].Id, Status__c = 'Approved', End_Date__c = system.today()+2, Start_Date__c = system.today()));  
        insert plannedLeaves;
        for(Planned_Leave__c p : plannedLeaves){
            plannedLeavesSet.add(p.End_Date__c);
            plannedLeavesSet.add(p.Start_Date__c);
        }
        
        List<Store_Member__c> storeMembers = [Select Id,Team_Member__c,Call_Volume__c
                                              ,Team_Member__r.Country__c,Store__r.Engagement_Model__c
                                              ,Store__r.Location_Type__c,Store__r.Country__c from Store_Member__c Limit 1];
        storeMembers[0].Team_Member__c = users[0].Id;
        storeMembers[0].Team_Member_Call__c = '70%';
        storeMembers[0].Call_Volume__c = 40;
        Update storeMembers;
        
        RecordType AUCustomerRecType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'AU_Customer' LIMIT 1];
        
        List<Account> accounts = TestDataFactory.createAccounts(5);
        for(Account a :accounts) {
            a.OwnerId =storeMembers[0].Team_Member__c;
            a.R12_Sales_Rank__c = Math.floor(Math.random()*1000);
            a.Call_Cycle_Ranking__c = Math.floor(Math.random()*10000);
            a.Call_Reason__c = 'Call Reason ' + String.valueOf(Math.random());
            a.Do_Not_Call__c = false;
            a.Call_Priority__c = 3;
            a.RecordTypeId = AUCustomerRecType.Id;
            a.Account_Status__c = 'Active';
            updateAccountList.add(a);
        }
        insert updateAccountList;
        
        businessDates.add(System.today());businessDates.add(System.today()+1);businessDates.add(System.today()+2);businessDates.add(System.today()+3);
        
        TEMP_SM_CallCycle.createMonthlyCallCycle(storeMembers[0]);
        TEMP_SM_CallCycle.createCallCycleTasks(updateAccountList, businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT);
        
        List<Account> accounts1 = TestDataFactory.createAccounts(2);
        for(Account a :accounts1) {
            a.OwnerId =storeMembers[0].Team_Member__c;
            a.R12_Sales_Rank__c = Math.floor(Math.random()*1000);
            a.Call_Cycle_Ranking__c = Math.floor(Math.random()*10000);
            a.Call_Reason__c = 'Call Reason ' + String.valueOf(Math.random());
            a.Do_Not_Call__c = false;
            a.Call_Priority__c = 3;
            a.RecordTypeId = AUCustomerRecType.Id;
            a.Account_Status__c = 'Active';
            updateAccountList1.add(a);
        }
        insert updateAccountList1;
        TEMP_SM_CallCycle.createCallCycleTasks(updateAccountList1, businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT);
        TEMP_SM_CallCycle.nextBusinessDate(System.today());
        
        Task task = new Task(
            Subject = 'Engagement Call',
            WhatId = updateAccountList1[0].Id,
            OwnerId = updateAccountList1[0].Id,
            Status = 'Active',
            ActivityDate = System.today(),
            Sub_type__c = 'Engagement Call',
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Cycle Call').getRecordTypeId()
        );
        try{
            insert task;
        }
        catch(Exception e){System.debug(e);}
        
        //TEMP_SM_CallCycle.callCycleFormInit(updateAccountList1[0].Id, 'Else', 'flowScreen');
        Event event = new Event(
            Subject = 'Call',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addMinutes(30),
            Sub_type__c = 'Engagement Call',
            Status__c = 'Open',
            WhatId = updateAccountList1[0].Id
        );
        insert event;
        //TEMP_SM_CallCycle.callCycleFormInit(updateAccountList1[0].Id, 'Else', 'flowScreen');
        Set<Account> accSet = new Set<Account>(); 
        accSet.addAll(updateAccountList1);
        //TEMP_SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);

        Set<Date> plSet = new Set<Date>();
        plSet.add(Date.newInstance(2022, 2, 28));
        //TEMP_SM_CallCycle.createCallCycleTasks(TestDataFactory.createAccounts(15), businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT);
        Test.stopTest();
    }
}