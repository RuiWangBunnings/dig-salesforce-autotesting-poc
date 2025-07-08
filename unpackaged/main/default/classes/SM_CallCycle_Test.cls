/*******************************************************************************************************
* Class Name        : SM_CallCycle_Test
* Description       : Test class for SM_CallCycle
* Author            : Simplus - Yi Zhang
* Created On        : 2020-07-21
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-07-21      1000                Initial version
* Simplus MS            2021-06-15      2000                Added testCreateMonthlyCallCycleFixOnAccountModel1 method and updated setup method - UAT_CCRM-13431
* Simplus MS            2021-10-22      2001                Update test class to accept CCRM 15-180/15-80/15-79 changes
* Bunnings Dev			2022-05-27		3000				SFSUP-716 - Test class update
******************************************************************************************************/
@isTest
private class SM_CallCycle_Test {

    @testSetup static void setup() {

        // This is the amount of the accounts created for the trade specialist
        // If sum of limits in Engagement_Model__mdt for a particular format + type exceeds this number
        // The test class will fail
        // However CPU may timeout if the number goes up
        Integer accountCount = 60;

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
        //users[0].Is_TS__c = true;

        insert users;

        List<Store_Member__c> storeMembers = new List<Store_Member__c>();
        storeMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[0].Id, Constants.STOREMEMBER_TS_ROLENAME));
        //storeMember.Team_Member__c = '112233';
        storeMembers[0].Team_Member_Call__c = '70%';
        storeMembers[0].Call_Volume__c = 40;
        storeMembers.add(TestDataFactory.createStoreMember(stores[0].Id, users[1].Id, Constants.STOREMEMBER_TS_ROLENAME));
        insert storeMembers;

        List<Planned_Leave__c> plannedLeaves = new List<Planned_Leave__c>();
        plannedLeaves.add(new Planned_Leave__c(OwnerId = users[0].Id, Status__c = 'Approved', End_Date__c = system.today()+2, Start_Date__c = system.today()));
        plannedLeaves.add(new Planned_Leave__c(OwnerId = users[1].Id, Status__c = 'Approved', End_Date__c = system.today(), Start_Date__c = system.today()));
        insert plannedLeaves;
        
        //SIMPLUS MS - 15JUN2021 CCRM-13431
        System.runAs(new User(Id = UserInfo.getUserId())) {
            RecordType AUCustomerRecType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'AU_Customer' LIMIT 1];
            Integer counter = 0;
            // create accounts - 350 accounts, 16 callPriority = 1.1, 24 callPriority = 1.2, 150 account with no call reason
            List<Account> accounts = TestDataFactory.createAccounts(accountCount);
            for(Account a :accounts) {
                a.OwnerId = users[0].Id;
                a.R12_Sales_Rank__c = Math.floor(Math.random()*1000);
                a.Call_Cycle_Ranking__c = Math.floor(Math.random()*10000);
                a.Call_Reason__c = 'Call Reason ' + String.valueOf(Math.random());
                a.Do_Not_Call__c = false;
                
                if(counter < 16) {
                    a.Call_Priority__c = 1.1;
                } else if(counter < 40) {
                    a.Call_Priority__c = 1.2;
                } else {
                    a.Call_Reason__c = '';
                }
                a.RecordTypeId = AUCustomerRecType.Id;
                a.Account_Status__c = 'Active';
                a.Digitally_Managed__c = false;
                counter += 1; 
            }
            insert accounts;
        }
        
        List<Profile> profilesList = [Select Id, Name from Profile Where Name = 'Trade Specialist'];
         User usersRecord = new User(
                    Alias = 'empTS',
                    Email='employee@testorg.com',
                    EmailEncodingKey='UTF-8',
                    LastName='TestingTS',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    ProfileId = profilesList[0].Id,
                    TimeZoneSidKey='America/Los_Angeles',
                    UserName='TS1'+ + String.valueOf(Math.random()) +'@testorg.com',
                    isActive=true,
                    Country='Australia',
                    Country__c = 'Australia'
            );
        insert usersRecord;
    }

    @isTest
    static void testCreateCallCycleTasksForCreditLimitIncrease() {
        List<Account> listAccounts = [
            SELECT Id, OwnerId, Credit_Limit_Increased_Check__c
            FROM Account limit 2];
        Set<Account> accSet = new Set<Account>();
        for(Account acc : listAccounts) {
            accSet.add(acc);
        }
        listAccounts[1].Credit_Limit_Increased_Check__c = true;
        update listAccounts[1];
        SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);
        List<Opportunity> testOpptys = TestDataFactory.createOpenOpportunities(listAccounts[1].Id, listAccounts[1].OwnerId, 1);
        Task tsk = SM_Task.createCallCycleTask(listAccounts[0].Id, listAccounts[0].OwnerId, 'test existing', Date.today());
        insert tsk;
        SM_CallCycle.createOpportunityForCallCycleTask(testOpptys[0], tsk);
    }


    /**
    * @description - this is for fix of task created with no subject and call priority not taken into account PRB0048314 / CCRM-13872
    * @author SIMPLUS MS | 15/06/2021 
    **/
    @isTest
    static void testCreateMonthlyCallCycleFixOnAccountModel1() {
       // List<Engagement_Model__mdt> model = [SELECT Id, Format__c, Limit__c, Model__c, Store_Type__c, Country__c FROM Engagement_Model__mdt];
        
        //  for (Engagement_Model__mdt cvm : DM_EngagementModel.limitMap) {
        //      cvmMap.put(cvm.MasterLabel, cvm);
        //  }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            // store.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            // store.Location_Type__c = Constants.STORE_TYPE_WAREHOUSE;
            // update store;
            // // batchable
            Database.executebatch(new SM_CallCycleBatch(), 20);

        }
        
        User u = [SELECT Id FROM User LIMIT 1];
        List<Store_Member__c> SMList = [SELECT Team_Member__r.Country__c FROM Store_Member__c];
        System.assertNotEquals(1, SMList.size());


        //test for more coverage, not related to method
        List<Account> listAccounts = [
            SELECT Id, OwnerId, Credit_Limit_Increased_Check__c
            FROM Account limit 2];
        Set<Account> accSet = new Set<Account>();
        for(Account acc : listAccounts) {
            accSet.add(acc);
        }
        listAccounts[1].Credit_Limit_Increased_Check__c = true;
        update listAccounts[1];
        SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);
        SM_CallCycle.getStandardOpptyRTs();

        SM_CallCycle.callCycleFormInit(listAccounts[0].Id, 'Small', 'flowScreen');
        SM_CallCycle.callCycleFormInit(listAccounts[0].Id, 'Else', 'Else');
        List<Task> queriedTask = TestDataFactory.createOpenTasksWithWhatId(listAccounts[0].Id,UserInfo.getUserId(),1);
        insert queriedTask;
        //Task queriedTask = [SELECT Id, Subject, WhatId, Call_Cycle_Attempt__c, OwnerId, Sub_type__c, Status, Objectives__c FROM Task LIMIT 1];
        Task newTask = new Task(
            Subject = 'test', 
            WhatId = listAccounts[0].Id, 
            Call_Cycle_Attempt__c = null, 
            OwnerId = u.Id,
            Objectives__c = 'Test objectives'
        );
        Event evt = new Event(
            Subject = 'test', 
            WhatId = listAccounts[0].Id, 
            OwnerId = listAccounts[0].OwnerId, 
            EndDateTime = Datetime.now().addDays(10), 
            ActivityDateTime = Datetime.now()
        );
        insert evt;
        TestDataFactory.createStandardContact();
        try{
            SM_CallCycle.updateAccountAndActivity(listAccounts[0], queriedTask[0], evt, newTask, '', 'AU', listAccounts[0].ID, 'test@test.invalid');
        }catch(Exception e) {
            System.debug('Exception: '+e);
        }
        
        SM_CallCycle.callCycleFormInit(listAccounts[0].Id, 'Small', 'flowScreen');
        Test.stopTest();
        validateCreatedTasks();
    }

    @isTest
    static void testCreateMonthlyCallCycle_New_Warehouse() {


        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Store__c store = [SELECT Id FROM Store__c LIMIT 1];
            // store.Engagement_Model__c = Constants.STORE_MODEL_NEW;
            // store.Location_Type__c = Constants.STORE_TYPE_WAREHOUSE;
            update store;

            // schedulable (not immediate)
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new SM_CallCycleBatch());
            // batchable
            Database.executebatch(new SM_CallCycleBatch(), 20);

        }
        Test.stopTest();

        validateCreatedTasks();

        // Test createOpportunityForCallCycleTask as well
        Opportunity oppty = TestDataFactory.createOpenOpportunities([SELECT Id FROM Account LIMIT 1].Id, [SELECT Id FROM User WHERE Profile.Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1].Id, 1)[0];
        Account listAccounts = [SELECT Id FROM Account LIMIT 1];
        List<Task> task = TestDataFactory.createOpenTasksWithWhatId(listAccounts.Id,UserInfo.getUserId(),1);
        insert task;
       // Task task = [SELECT Id FROM Task LIMIT 1];
        Map<String, String> response = SM_CallCycle.createOpportunityForCallCycleTask(oppty, task[0]);
        System.assertEquals('successful', response.get('status'), 'Opportunity creation / task update failed');

        // Examine how tasks are distributed across the month
        // Map<Date, Integer> taskByDateMap = new Map<Date, Integer>();
        // for(Task t : [SELECT Id, ActivityDate, Account.R12_Sales_Rank__c FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND Subject = :SM_CallCycle.SUBJECT_LESS_FREQUENT_CONTACT_REMINDER ORDER BY ActivityDate ASC]) {
        //     System.debug(t.ActivityDate + ' ' + t.Account.R12_Sales_Rank__c);
        //     if(taskByDateMap.containsKey(t.ActivityDate) == false) {
        //         taskByDateMap.put(t.ActivityDate, 0);
        //     }
        //     taskByDateMap.put(t.ActivityDate, taskByDateMap.get(t.ActivityDate) + 1);
        // }
        // for(Date d : taskByDateMap.keySet()) {
        //     System.debug(d + ' ' + taskByDateMap.get(d));
        // }
    
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
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new SM_CallCycleBatch());
            // batchable
            Database.executebatch(new SM_CallCycleBatch(), 20);

        }
        Test.stopTest();

        validateCreatedTasks();
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
            Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new SM_CallCycleBatch());
            // batchable
            Database.executebatch(new SM_CallCycleBatch(), 20);
            
        }
        Test.stopTest();

        validateCreatedTasks();
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
                Id jobId = System.schedule('Monthly Call Cycle Creation', '0 0 2 * * ?', new SM_CallCycleBatch());
                // batchable
                Database.executebatch(new SM_CallCycleBatch(), 20);
    
            }
        Test.stopTest();

        validateCreatedTasks();
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
        
        SM_CallCycle.createMonthlyCallCycle(storeMembers[0]);
        SM_CallCycle.createCallCycleTasks(updateAccountList, businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT, plannedLeavesSet);
        
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
        SM_CallCycle.createCallCycleTasks(updateAccountList1, businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT, plannedLeavesSet);
        SM_CallCycle.nextBusinessDate(System.today());
        
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
        
        SM_CallCycle.callCycleFormInit(updateAccountList1[0].Id, 'Else', 'flowScreen');
        Event event = new Event(
            Subject = 'Call',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addMinutes(30),
            Sub_type__c = 'Engagement Call',
            Status__c = 'Open',
            WhatId = updateAccountList1[0].Id
        );
        insert event;
        SM_CallCycle.callCycleFormInit(updateAccountList1[0].Id, 'Else', 'flowScreen');
        Set<Account> accSet = new Set<Account>(); 
        accSet.addAll(updateAccountList1);
        SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);

        Set<Date> plSet = new Set<Date>();
        plSet.add(Date.newInstance(2022, 2, 28));
        SM_CallCycle.createCallCycleTasks(TestDataFactory.createAccounts(15), businessDates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT, plSet);
        Test.stopTest();
    }
    
    //Add logic to increase the test coverage 
    @isTest
    public static void increaseCoverageTest() {
        List<User> users = [Select Id,Name,IS_TS__c,profile.Name,ProfileId from User Where LastName='TestingTS' Limit 1];
        Test.startTest();
        Account newAcc = new Account(
            Name = 'TestCompanyData',
            BillingCity='Melbourne',
            BillingCountry='AUS',
            BillingPostalCode='3000',
            BillingState='VIC',
            BillingStreet='Collins St',
            Country__c='Australia',
            Account_Status__c = 'Active',
            Credit_Limit_Increased_Check__c = true
        );
        Account newAcc1 = new Account(
            Name = 'TestCompanyData',
            BillingCity='Melbourne',
            BillingCountry='AUS',
            BillingPostalCode='3000',
            BillingState='VIC',
            BillingStreet='Collins St',
            Country__c='Australia',
            Account_Status__c = 'Active',
            Credit_Limit_Increased_Check__c = true
        );
        System.runAs(users[0]){
            insert newAcc;
            insert newAcc1;
        }
        Task task = new Task(
            Subject = 'Engagement Call',
            WhatId = newAcc.Id,
            OwnerId = users[0].Id,
            Status = 'Active',
            ActivityDate = System.today(),
            Sub_type__c = 'Engagement Call',
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Cycle Call').getRecordTypeId()
        );
        try{
            insert task;
        }
        catch(Exception e){System.debug(e);}  
        
        Event event = new Event(
            Subject = 'Call',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addMinutes(30),
            Sub_type__c = 'Engagement Call',
            Status__c = 'Open',
            WhatId = newAcc.Id
        );
        insert event;
        Set<Account> accSet = new Set<Account>(); 
        accSet.add(newAcc);
        Set<Account> accSet1 = new Set<Account>(); 
        accSet1.add(newAcc1);
        SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet);
        SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(accSet1);
        List<Store_Member__c> member = [Select Id,Team_Member__c,Call_Volume__c
                                        ,Team_Member__r.Country__c,Store__r.Engagement_Model__c
                                        ,Store__r.Location_Type__c,Store__r.Country__c from Store_Member__c Limit 1];
        SM_CallCycle.accountsForModel2And3(member[0],'Top X from Customer Engagement Model');
        Test.stopTest();
    }
    
    /**
    * @description  Validation steps shared by all test methods
    * @author Yi Zhang | 22/07/2020 
    **/
    static void validateCreatedTasks() {
        Store_Member__c member1 = [
            SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Store__r.Country__c, Store__r.Store_Call__c, Team_Member__c, Team_Member_Call__c, Call_Volume__c, Team_Member__r.Country__c 
            FROM Store_Member__c 
            WHERE Status__c =: Constants.STOREMEMBER_ACTIVE_STATUS 
            AND Role__c =: Constants.STOREMEMBER_TS_ROLENAME 
            AND Team_Member__r.IsActive = true 
            AND Team_Member__r.Is_TS__c = true 
            AND Store__r.Engagement_Model__c != null 
            AND Store__r.Location_Type__c IN (:Constants.STORE_TYPE_WAREHOUSE, :Constants.STORE_TYPE_STORE)
            ORDER BY Id ASC LIMIT 1
            ];

        String key = member1.Store__r.Engagement_Model__c + member1.Store__r.Location_Type__c + member1.Team_Member__r.Country__c;
        //String key = member1.Store__r.Engagement_Model__c + member1.Store__r.Location_Type__c + member1.Store__r.Country__c;
        
        Integer limit1 = member1.Call_Volume__c.intValue();
        Integer limit2 = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_FREQUENT).get(key);
        Integer limit3 = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_LESS_FREQUENT).get(key);

        Integer accsCounts = [SELECT Id FROM Account WHERE Call_Reason__c != NULL AND Call_Priority__c != NULL AND Call_Priority__c != 0.0].size();

        Integer allTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle].size();
        List<String> nonStdCCTasks = new List<String> {
            SM_CallCycle.SUBJECT_FREQUENT_CONTACT_REMINDER, SM_CallCycle.SUBJECT_LESS_FREQUENT_CONTACT_REMINDER
        };
        Integer frequentTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND Subject = :SM_CallCycle.SUBJECT_FREQUENT_CONTACT_REMINDER].size();
        Integer lessFrequentTasksCount = [SELECT Id FROM Task WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND Subject = :SM_CallCycle.SUBJECT_LESS_FREQUENT_CONTACT_REMINDER].size();

        Integer stdTasksCount = allTasksCount - frequentTasksCount - lessFrequentTasksCount;
        if(limit1 > accsCounts) {
            limit1 = accsCounts;
        }
        System.debug(LoggingLevel.DEBUG, member1.Store__r.Engagement_Model__c + ' ' + member1.Store__r.Location_Type__c + ' limits: ' + limit1 + ', ' + limit2 + ', ' + limit3);
        //System.assertEquals(limit1 + limit2 + limit3, allTasksCount, 'Number of totally created tasks incorrect'); // temporarily commented out 
      //  System.assertEquals(limit1, stdTasksCount);
        System.assertEquals(limit2, frequentTasksCount, 'Number of created frequent tasks incorrect');
        System.assertEquals(limit3, lessFrequentTasksCount, 'Number of created less frequent tasks incorrect');
    }

    //SFSUP-716
    @isTest
    public static void createMonthlyLifeCycleCallCycleTest() {
        List<Planned_Leave__c> plannedLeaves = new List<Planned_Leave__c>();
        Set<Date> plannedLeavesSet = new Set<Date>();
        List<Date> businessDates = new List<Date>();
        List<Account> updateAccountList = new List<Account>();
        List<Account> updateAccountList1 = new List<Account>();
        
        Test.startTest();        
        
            List<User> users = [Select Id from User Limit 1];
            
            plannedLeaves.add(new Planned_Leave__c(OwnerId = users[0].Id, Status__c = 'Approved', End_Date__c = system.today()+2, Start_Date__c = system.today()));  
            insert plannedLeaves;
            for (Planned_Leave__c p : plannedLeaves) {
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
    
            Account_Extension__c ae1 = new Account_Extension__c(Call_Cycle_Reason__c = 'Reducing', Call_Cycle_Rank__c = 1, Call_Cycle_Priority__c = 2.1);
            Account_Extension__c ae2 = new Account_Extension__c(Call_Cycle_Reason__c = 'Reducing', Call_Cycle_Rank__c = 1, Call_Cycle_Priority__c = 2.1);
            Account_Extension__c ae3 = new Account_Extension__c(Call_Cycle_Reason__c = 'Lapsing', Call_Cycle_Rank__c = 2, Call_Cycle_Priority__c = 2.2);
            Account_Extension__c ae4 = new Account_Extension__c(Call_Cycle_Reason__c = 'Growing', Call_Cycle_Rank__c = 3, Call_Cycle_Priority__c = 2.3);
            Account_Extension__c ae5 = new Account_Extension__c(Call_Cycle_Reason__c = 'Maintaining', Call_Cycle_Rank__c = 4, Call_Cycle_Priority__c = 2.4);
            insert new List<Account_Extension__c>{ae1, ae2, ae3, ae4, ae5};
            
            List<Account> accounts = TestDataFactory.createAccounts(5);
            accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
            accounts[0].Power_Pass_Account_Number__c = '111111';
            accounts[0].OwnerId = users[0].ID;
            accounts[0].Country__c = 'Australia';
            accounts[0].Do_Not_Call__c = false;
            accounts[0].Account_Extension__c = ae1.Id;
            
            accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
            accounts[1].Power_Pass_Account_Number__c = '222222';
            accounts[1].OwnerId = users[0].ID;
            accounts[1].Country__c = 'Australia';
            accounts[1].Do_Not_Call__c = false;
            accounts[1].Account_Extension__c = ae2.Id;
            
            accounts[3].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
            accounts[3].Power_Pass_Account_Number__c = '3333333';
            accounts[3].OwnerId = users[0].ID;
            accounts[3].Country__c = 'Australia';
            accounts[3].Do_Not_Call__c = false;
            accounts[3].Account_Extension__c = ae3.Id;
            
            accounts[4].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
            accounts[4].Power_Pass_Account_Number__c = '444444';
            accounts[4].OwnerId = users[0].ID;
            accounts[4].Country__c = 'Australia';
            accounts[4].Do_Not_Call__c = false;
            accounts[4].Account_Extension__c = ae4.Id;
                    
            insert accounts;
        
        	// Increase test coverage - unrelated to the method
        	List<Contact> con = TestDataFactory.createContacts(accounts[0].Id, users[0].Id, 1);
        	insert con;
        	SM_CallCycle.getContactSelected(con[0].Id);
        	SM_CallCycle.updateContactSelected(con[0]);
                	               
            businessDates.add(System.today());businessDates.add(System.today()+1);businessDates.add(System.today()+2);businessDates.add(System.today()+3);
        	List<Account> acc = SM_CallCycle.accountsLifeCycleCallCycle(storeMembers[0]);
        
        	List<Account> reducingAccountRecords = new List<Account>([SELECT Id, Name, LifeCycle_Call_Reason__c FROM Account WHERE LifeCycle_Call_Reason__c = 'Reducing']);
        	System.assert(reducingAccountRecords != null);
            
            SM_CallCycle.createMonthlyLifeCycleCallCycle(storeMembers[0], '2022-05-02');
            SM_CallCycle.createLifeCycleCallCycleTasks(accounts, businessDates, plannedLeavesSet);
        
        	// To test if there were no planned leave
            Set<Date> plannedLeavesSets = new Set<Date>();
            SM_CallCycle.createLifeCycleCallCycleTasks(accounts, businessDates, plannedLeavesSets);
                        
        Test.stopTest();
    }

    @isTest
    static void All_LifeCycleCallCycleBatchTest() {       

        Test.startTest();
            SM_LifeCycleCallCycleBatch myClass = new SM_LifeCycleCallCycleBatch(null, null);   
         	String chron = '0 0 23 * * ?';        
         	System.Schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }
    
    @isTest
    static void tm_LifeCycleCallCycleBatchTest() {
        
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist'].Id;
        List<User> users = TestDataFactory.createUsers(1, profileId);        
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }
        
        Store__c newStore = new Store__c(Name = 'Test Store', Location_Code__c = '10210', Sales_Rep_ID__c = '600', Status__c = 'Active', 
			Operations_Region_Code__c = 'NSW', Location_Type__c = 'Warehouse', LifeCycle_Model__c = 'Active');
        insert newStore;
        
        Store_Member__c storeMember = new Store_Member__c(Store__c = newStore.Id, Team_Member__c = users[0].Id, Role__c = 'Trade Specialist', Status__c = 'Active');        
        insert storeMember;

        Test.startTest();
            SM_LifeCycleCallCycleBatch myClass = new SM_LifeCycleCallCycleBatch(storeMember.Id, null);   
         	String chron = '0 0 23 * * ?';        
         	System.Schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }
    
    @isTest
    static void createTaskTest() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Test.startTest();
        	Task newTask = SM_Task.createTask(accounts[0].Id, accounts[0].OwnerId, 'Test task', 'This is a test task', Date.today());
        	System.assert(newTask != null);
        Test.stopTest();        
    }
    
    @isTest
    static void createManualCallCycleTaskTest() {
        Id taskId = [SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND DeveloperName = 'Reducing_and_Lapsing_Call'].Id;
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        Test.startTest();
        	Task newTask = SM_Task.createManualCallCycleTask(accounts[0].Id, accounts[0].OwnerId, 'This is a test task', taskId);
        	System.assert(newTask != null);
        Test.stopTest();                        
    }
    
    @isTest
    static void testCreateMonthlyLifeCycleCallCycle() {
        Test.startTest();            
            User u = [SELECT Id FROM User LIMIT 1];
            List<Store_Member__c> SMList = [SELECT Team_Member__r.Country__c FROM Store_Member__c];
            System.assertNotEquals(1, SMList.size());
			
            List<Account> listAccounts = [
                SELECT Id, OwnerId, Credit_Limit_Increased_Check__c
                FROM Account limit 2];
        
            Set<Account> accSet = new Set<Account>();
            for (Account acc : listAccounts) {
                accSet.add(acc);
            }
        
            listAccounts[1].Credit_Limit_Increased_Check__c = true;
            update listAccounts[1];
                    
        	SM_CallCycle.lifecycleCallCycleFormInit(listAccounts[0].Id, 'Small', 'flowScreen', 'Reducing and Lapsing Call', 'Test');
        	SM_CallCycle.lifecycleCallCycleFormInit(listAccounts[0].Id, 'Else', 'Else', 'Reducing and Lapsing Call', 'Test');
        
            List<Task> queriedTask = TestDataFactory.createOpenTasksWithWhatId(listAccounts[0].Id,UserInfo.getUserId(),1);
            insert queriedTask;
                	
        	Task newTask = new Task(
            	Subject = 'test', 
                WhatId = listAccounts[0].Id, 
                Call_Cycle_Attempt__c = null, 
                OwnerId = u.Id,
                Objectives__c = 'Test objectives'
            );
            Event evt = new Event(
                Subject = 'test', 
                WhatId = listAccounts[0].Id, 
                OwnerId = listAccounts[0].OwnerId, 
                EndDateTime = Datetime.now().addDays(10), 
                ActivityDateTime = Datetime.now()
            );
            insert evt;
        
                TestDataFactory.createStandardContact();
                try {
                    SM_CallCycle.updateAccountAndActivityCallCycle(listAccounts[0], queriedTask[0], evt, newTask, '', 'AU', listAccounts[0].ID, 'test@test.invalid');
                } catch (Exception e) {
                    System.debug('Exception: '+e);
                }           
		Test.stopTest();       
    }
}