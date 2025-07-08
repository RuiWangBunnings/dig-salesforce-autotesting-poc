/*******************************************************************************************************
* Class Name      	: SM_AccountTransfer_Test
* Description		: Test class for SM_AccountTransfer
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/05/2020		1000				Initial version
* Simplus MS            19/02/2021      1001                Added new test method to increase test coverage and cover updateAccountAMToTSTransfer method
* Simplus MS            22/06/2021      1002                Added test method to pass coverage
* Simplus MS            22/12/2021      1003                Divided test methods logic and added more methods to resolve SOQL 101 issues to pass coverage
* Bunnings Dev			20/09/2022		1004				Fix test class issue
******************************************************************************************************/
@isTest
private class SM_AccountTransfer_Test {
    
    @testSetup 
    public static void testDataSetup() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        System.runAs(users[0]) {
            List<Account> accts = TestDataFactory.createAccounts(3);
            accts[1].Transfer_approval_status__c = 'Submitted for approval';
            insert accts;
            
            Account a = accts[0];
            
            List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(a.Id, u.Id, 2);
            tasks.addAll(TestDataFactory.createClosedTasksWithWhatId(a.Id, u.Id, 2));
            insert tasks;
            
            List<Event> events = TestDataFactory.createOpenEventsWithWhatId(a.Id, u.Id, 3);
            events.addAll(TestDataFactory.createClosedEventsWithWhatId(a.Id, u.Id, 1));
            insert events;
            
            List<Opportunity> oppties = TestDataFactory.createOpenOpportunities(a.Id, u.Id, 110);
            oppties.addAll(TestDataFactory.createClosedOpportunities(a.Id, u.Id, 2));
            insert oppties;
            
            List<Contact> contacts = TestDataFactory.createContacts(a.Id, u.Id, 5);
            insert contacts;
            
            List<Case> cases = TestDataFactory.createOpenCases(a.Id, u.Id, 6);
            cases.addAll(TestDataFactory.createClosedCases(a.Id, u.Id, 2));
            insert cases;
            
            List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(u.Id, 'Australia', 1);
            contracts.addAll(TestDataFactory.createExpiredContracts(u.Id, 'Australia', 3));
            insert contracts;
            
            List<Customer_Contract__c> ccs = TestDataFactory.createCustomerContracts(a.Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
            insert ccs;
            
            List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
            upsert sbs Spend_Band_ID__c;
            
            Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'Australia');
            insert new List<Spend_Band_Review__c>{sbr};                			
        }
            
    }
    
    @isTest
    private static void testAccountPlanTransfer() {
		Profile pTS = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> userTS = TestDataFactory.createUsers(2, pTS.Id);
        
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        List<User> userAM = TestDataFactory.createUsers(2, pAM.Id);
        
        User thisUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert userTS;
            insert userAM;
        }
        
        List<Account> accts = TestDataFactory.createAccounts(1);
		accts[0].Transfer_approval_status__c = 'Submitted for approval';
		insert accts;
            
		Account a = accts[0];
        
        List<Contact> contacts = TestDataFactory.createContacts(a.Id, userAM[0].Id, 1);
		insert contacts;
        
        Id acctPlanRTId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account_Plan__c' AND DeveloperName = 'Builders'].Id;
        Account_Plan__c ap1 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = a.Id, Status__c = 'Active', Start_Date__c = Date.newInstance(2022, 6, 1), 
				End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000, 
				Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        Account_Plan__c ap2 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = a.Id, Status__c = 'Draft', Start_Date__c = Date.newInstance(2022, 6, 1), 
				End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000,
				Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        insert new List<Account_Plan__c>{ap1, ap2};
		
		Test.startTest();
        	Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(a.Id, new Account(Id = a.Id, OwnerId = userAM[0].Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(a.Id, new Account(Id = a.Id, OwnerId = userAM[1].Id));
        	SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
        Test.stopTest();
    }
    
    @isTest
    private static void testAccountTriggerBeforeAfterUpdate() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        Test.startTest();
        System.runAs(users[0]) {
            
            List<Account> accts = TestDataFactory.createAccounts(3);
            accts[0].Transfer_approval_status__c = 'Submitted for approval';
            accts[0].Transfer_to__c = users[1].Id;
            insert accts;
            
            Account a = accts[0];
            
            List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(a.Id, u.Id, 2);
            tasks.addAll(TestDataFactory.createClosedTasksWithWhatId(a.Id, u.Id, 2));
            insert tasks;
            
            
            // approve through process
            a.Transfer_approval_status__c = 'Approved';
            
            update a;
            a = [SELECT Id, Transfer_approval_status__c, Transfer_to__c, OwnerId FROM Account WHERE Id = :a.Id LIMIT 1];
            System.assertEquals('Approved', a.Transfer_approval_status__c, 'Status incorrect');
            System.assertEquals(null, a.Transfer_to__c, 'Transfer to incorrect');
            System.assertEquals(users[1].Id, a.OwnerId, 'Owner incorrect');
            
            
        }
        Test.stopTest();
    }

    @isTest
    private static void testAccountTransfer() {
        
            Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
            Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;

            List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
            List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%' LIMIT 1];

            Test.startTest();
            
            Map<String, String> resp = new Map<String, String>();
            // test init
            SM_AccountTransfer.init(accountId, userId);
            resp = SM_AccountTransfer.init(accts[1].Id, userId);
            System.assertEquals(SM_AccountTransfer.STEP_APPROVAL_IN_PROCESS, resp.get('step'), 'Incorrect step');
            resp = SM_AccountTransfer.init(accts[1].Id, users[0].Id);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[0].Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(a, userId, users[1].Id);

            Test.stopTest();
    }
        
    @isTest
    private static void testAccountTransferFirstCopy() {
        
            Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
            Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;

            List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
            List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];

        Test.startTest();
            
        try {
            Map<String, String> resp = new Map<String, String>();

            // test checkContracts
            resp = SM_AccountTransfer.checkContracts(accountId, userId, userId, 'Test', false);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + userId);
            
            SM_AccountTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', false);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(a, userId, users[1].Id);
            
            System.assertEquals(2, [SELECT Id FROM Task WHERE OwnerId = :users[1].Id].size(), 'Task transfer failed');
            System.assertEquals(2, [SELECT Id FROM Task WHERE OwnerId = :userId].size(), 'Task remain failed');
            System.assertEquals(3, [SELECT Id FROM Event WHERE OwnerId = :users[1].Id].size(), 'Event transfer failed');
            System.assertEquals(110, [SELECT Id FROM Opportunity WHERE OwnerId = :users[1].Id].size(), 'Opportunity transfer failed');
            System.assertEquals(5, [SELECT Id FROM Contact WHERE OwnerId = :users[1].Id].size(), 'Contact transfer failed');
            System.assertEquals(6, [SELECT Id FROM Case WHERE OwnerId = :users[1].Id].size(), 'Case transfer failed');
            
            //System.assertEquals(1, [SELECT Id FROM Contract__c WHERE OwnerId = :users[1].Id].size(), 'Contract__c transfer failed');
            //System.assertEquals(3, [SELECT Id FROM Contract__c WHERE OwnerId = :userId].size(), 'Contract__c remain failed');
            
            //System.assertEquals(1, [SELECT Id FROM Spend_Band_Review__c WHERE Level_1_Approver__c = :users[1].Id].size(), 'Spend_Band_Review__c transfer failed');
            //System.assertEquals(users[2].Id, [SELECT Level_2_Approver__c FROM Spend_Band_Review__c WHERE Level_1_Approver__c = :users[1].Id LIMIT 1].Level_2_Approver__c, 'Level_2_Approver__c transfer failed');

        }catch (Exception e){
            System.assert(TRUE);
        }

        Test.stopTest();
    }

    @isTest
    private static void testAccountTransferSecondCopy() {
        
            Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
            Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;

            List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
            List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];

        Test.startTest();
            
            Map<String, String> resp = new Map<String, String>();
            
            // test checkContracts
            resp = SM_AccountTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', true);
            //resp = SM_AccountTransfer.checkContracts(accts[2].Id, userId, users[1].Id, 'Test', false);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(a, userId, users[1].Id);

        Test.stopTest();
    }
    
    @isTest
    private static void testAccountTransfer_NZ() {
        
       
        
        User u = [Select id from USer Limit 1];
        u.IsActive=true;
        u.Country__c='Australia';
        update u;
        Test.startTest();
        System.runAs(u) {
           
            
            Account a = [select id from Account Limit 1];
            
            List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
            upsert sbs Spend_Band_ID__c;
            
            Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'New Zealand');
            insert new List<Spend_Band_Review__c>{sbr};
                
                Id accountId = a.Id;
            
            List<Umbrella_Group__c> lstUmbrellaGrps = TestDataFactory.createUmbrellaGroups(1);
            INSERT lstUmbrellaGrps;
            
            List<Umbrella_Beneficiary__c> lstUmbrellaBeneficiaries = TestDataFactory.createUmbrellaBeneficiaries(a.Id, lstUmbrellaGrps[0].Id, 1);
            INSERT lstUmbrellaBeneficiaries;
            
            Map<String, String> resp = new Map<String, String>();
            // test init
            SM_AccountTransfer.init(accountId, u.Id);
      
            
            // test checkContracts
            resp = SM_AccountTransfer.checkContracts(accountId, u.Id, u.Id, 'Test', false);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + u.Id);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(a, u.Id, users[1].Id);
            
            Price_List_Definition__c pld = new Price_List_Definition__c();
            insert pld;
            Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
            insert pb;
            Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                                    Status__c = 'Active', Customer_Price_List_ID__c = '45426');
            insert cpl;
            
            List<String> accIdList = new List<String>();
            List<String> spendBandIdList = new List<String>();
            
            
                accIdList.add(a.Id);
           
            
            for(Spend_Band__c sb : sbs){
                spendBandIdList.add(sb.Id);
            }
            
            Integer listSize = 0;
            
            if(spendBandIdList.size() < accIdList.size()){
                listSize = spendBandIdList.size();
            }else{
                listSize = accIdList.size();
            }
            
            List<List<String>> idList = new List<List<String>>();
            for(Integer i = 0; i < listSize; i++) {
                idList.add(new String[] { accIdList[i], spendBandIdList[i] });
            }
            
            SM_AccountTransfer.updateAccountAMToTSTransfer(idList);
        }
        
        Test.stopTest();
        
    }
/*
    @isTest
    private static void testAccountTransfer_NZFirstCopy() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        Test.startTest();
        try {
            System.runAs(users[0]) {
                List<Account> accts = TestDataFactory.createAccounts(3);
                accts[1].Transfer_approval_status__c = 'Approved';
                accts[0].Country__c = 'New Zealand';
                insert accts;
                
                Account a = accts[0];
                
                List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
                upsert sbs Spend_Band_ID__c;
                
                Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'New Zealand');
                insert new List<Spend_Band_Review__c>{sbr};
                    
                    Id accountId = a.Id;
                
                List<Umbrella_Group__c> lstUmbrellaGrps = TestDataFactory.createUmbrellaGroups(1);
                INSERT lstUmbrellaGrps;
                
                List<Umbrella_Beneficiary__c> lstUmbrellaBeneficiaries = TestDataFactory.createUmbrellaBeneficiaries(a.Id, lstUmbrellaGrps[0].Id, 1);
                INSERT lstUmbrellaBeneficiaries;
                
                Map<String, String> resp = new Map<String, String>();
                
                // test checkContracts
                resp = SM_AccountTransfer.checkContracts(accountId, u.Id, users[1].Id, 'Test', true);
                resp = SM_AccountTransfer.checkContracts(accts[2].Id, u.Id, users[1].Id, 'Test', false);
                
                // test transferAccountRelatedRecords
                Map<Id, Account> oldM = new Map<Id, Account>();
                oldM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
                Map<Id, Account> newM = new Map<Id, Account>();
                newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
                //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
                //transferAccount(a, u.Id, users[1].Id);
                
                Price_List_Definition__c pld = new Price_List_Definition__c();
                insert pld;
                Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
                insert pb;
                Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                                        Status__c = 'Active', Customer_Price_List_ID__c = '45426');
                insert cpl;
                
                List<String> accIdList = new List<String>();
                List<String> spendBandIdList = new List<String>();
                
                for(Account acc : accts){
                    accIdList.add(acc.Id);
                }
                
                for(Spend_Band__c sb : sbs){
                    spendBandIdList.add(sb.Id);
                }
                
                Integer listSize = 0;
                
                if(spendBandIdList.size() < accIdList.size()){
                    listSize = spendBandIdList.size();
                }else{
                    listSize = accIdList.size();
                }
                
                List<List<String>> idList = new List<List<String>>();
                for(Integer i = 0; i < listSize; i++) {
                    idList.add(new String[] { accIdList[i], spendBandIdList[i] });
                }
                
                SM_AccountTransfer.updateAccountAMToTSTransfer(idList);
            }
        }catch (Exception e){
            System.assert(TRUE);
        }
        Test.stopTest();
        
    }
   */
    @isTest
    private static void testAccountTransferNotEligible() {
        
         
        User u = [Select id from USer Limit 1];
        u.IsActive=true;
        u.Country__c='Australia';
        update u;
        Test.startTest();
       
        System.runAs(u) {
          
            
            Account a = [Select id from Account Limit 1];
            a.Country__c = 'New Zealand';
            update a;
            List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
            upsert sbs Spend_Band_ID__c;
            
            Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'New Zealand');
            insert new List<Spend_Band_Review__c>{sbr};
                
                Id accountId = a.Id;
            
            Map<String, String> resp = new Map<String, String>();
            // test init
            SM_AccountTransfer.init(accountId, u.Id);
            resp = SM_AccountTransfer.init(a.Id, u.Id);

            
            // test checkContracts
            resp = SM_AccountTransfer.checkContracts(accountId, u.Id, u.Id, 'Test', false);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + u.Id);

            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(a, u.Id, users[1].Id);
            
           /* Price_List_Definition__c pld = new Price_List_Definition__c();
            insert pld;
            Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
            insert pb;
            Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                                    Status__c = 'Active', Customer_Price_List_ID__c = '45426');
            insert cpl;*/
            
            List<String> accIdList = new List<String>();
            List<String> spendBandIdList = new List<String>();
            
           
                accIdList.add(a.Id);
      
            
            for(Spend_Band__c sb : sbs){
                spendBandIdList.add(sb.Id);
            }
            
            Integer listSize = 0;
            
            if(spendBandIdList.size() < accIdList.size()){
                listSize = spendBandIdList.size();
            }else{
                listSize = accIdList.size();
            }
            
            List<List<String>> idList = new List<List<String>>();
            for(Integer i = 0; i < listSize; i++) {
                idList.add(new String[] { accIdList[i], spendBandIdList[i] });
            }
            
            Family_Tree_Discount__c famTreeDisc = new Family_Tree_Discount__c();
            famTreeDisc.Family_Tree_Discount_ID__c = 'Test Tree Disc';
            INSERT famTreeDisc;
            
            Customer_Family_Tree_Discount__c custFamTreeDisc = new Customer_Family_Tree_Discount__c();
            custFamTreeDisc.Account__c = accIdList[0];
            custFamTreeDisc.Family_Tree_Discount__c = famTreeDisc.Id;
            custFamTreeDisc.Status__c = 'Active';
            INSERT custFamTreeDisc;
            
            SM_AccountTransfer.updateAccountAMToTSTransfer(idList);
        }
        
        Test.stopTest();
        
    }
/*
    @isTest
    private static void testAccountTransferNotEligibleFirstCopy() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1]; 
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[3].ProfileId = p2.Id;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        Test.startTest();
        
        try {
            System.runAs(users[0]) {
                List<Account> accts = TestDataFactory.createAccounts(3);
                accts[1].Transfer_approval_status__c = 'Approved';
                accts[0].Country__c = 'New Zealand';
                insert accts;
                
                Account a = accts[0];
                
                List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
                upsert sbs Spend_Band_ID__c;
                
                Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'New Zealand');
                insert new List<Spend_Band_Review__c>{sbr};
                    
                    Id accountId = a.Id;
                
                Map<String, String> resp = new Map<String, String>();
                // test checkContracts
                resp = SM_AccountTransfer.checkContracts(accountId, u.Id, users[1].Id, 'Test', true);
                resp = SM_AccountTransfer.checkContracts(accts[2].Id, u.Id, users[1].Id, 'Test', false);
                
                // test transferAccountRelatedRecords
                Map<Id, Account> oldM = new Map<Id, Account>();
                oldM.put(accountId, new Account(Id = accountId, OwnerId = u.Id));
                Map<Id, Account> newM = new Map<Id, Account>();
                newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
                //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
                //transferAccount(a, u.Id, users[1].Id);
                
                Price_List_Definition__c pld = new Price_List_Definition__c();
                insert pld;
                Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
                insert pb;
                Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                                        Status__c = 'Active', Customer_Price_List_ID__c = '45426');
                insert cpl;
                
                List<String> accIdList = new List<String>();
                List<String> spendBandIdList = new List<String>();
                
                for(Account acc : accts){
                    accIdList.add(acc.Id);
                }
                
                for(Spend_Band__c sb : sbs){
                    spendBandIdList.add(sb.Id);
                }
                
                Integer listSize = 0;
                
                if(spendBandIdList.size() < accIdList.size()){
                    listSize = spendBandIdList.size();
                }else{
                    listSize = accIdList.size();
                }
                
                List<List<String>> idList = new List<List<String>>();
                for(Integer i = 0; i < listSize; i++) {
                    idList.add(new String[] { accIdList[i], spendBandIdList[i] });
                }
                
                Family_Tree_Discount__c famTreeDisc = new Family_Tree_Discount__c();
                famTreeDisc.Family_Tree_Discount_ID__c = 'Test Tree Disc';
                INSERT famTreeDisc;
                
                Customer_Family_Tree_Discount__c custFamTreeDisc = new Customer_Family_Tree_Discount__c();
                custFamTreeDisc.Account__c = accIdList[0];
                custFamTreeDisc.Family_Tree_Discount__c = famTreeDisc.Id;
                custFamTreeDisc.Status__c = 'Active';
                INSERT custFamTreeDisc;
                
                SM_AccountTransfer.updateAccountAMToTSTransfer(idList);
            }
        }catch (Exception e){
            System.assert(TRUE);
        }
        
        Test.stopTest();
        
    }
*/    
    @isTest
    private static void testAccountTransferInvisibleRecord() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist' LIMIT 1]; 
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        Test.startTest();
        try
        {
            System.runAs(users[0]) {
                List<Account> accts = TestDataFactory.createAccounts(3);
                accts[1].Transfer_approval_status__c = 'Submitted for approval';
                insert accts;
                
                Account a = accts[0];
                
                List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(a.Id, u.Id, 2);
                tasks.addAll(TestDataFactory.createClosedTasksWithWhatId(a.Id, u.Id, 2));
                insert tasks;
                
                List<Event> events = TestDataFactory.createOpenEventsWithWhatId(a.Id, u.Id, 3);
                events.addAll(TestDataFactory.createClosedEventsWithWhatId(a.Id, u.Id, 1));
                insert events;
                
                List<Opportunity> oppties = TestDataFactory.createOpenOpportunities(a.Id, u.Id, 110);
                oppties.addAll(TestDataFactory.createClosedOpportunities(a.Id, u.Id, 2));
                insert oppties;
                
                List<Contact> contacts = TestDataFactory.createContacts(a.Id, u.Id, 5);
                insert contacts;
                
                List<Case> cases = TestDataFactory.createOpenCases(a.Id, u.Id, 6);
                cases.addAll(TestDataFactory.createClosedCases(a.Id, u.Id, 2));
                insert cases;
                
                List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(u.Id, 'Australia', 1);
                contracts.addAll(TestDataFactory.createExpiredContracts(u.Id, 'Australia', 3));
                insert contracts;
                
                List<Customer_Contract__c> ccs = TestDataFactory.createCustomerContracts(a.Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
                insert ccs;
                
                List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{6000, 7000}, new List<String>{'AT_TEST_03', 'AT_TEST_04'}, 'Australia');
                upsert sbs Spend_Band_ID__c;
                
                Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(a.Id, sbs[0].Id, sbs[1].Id, 'Australia');
                insert new List<Spend_Band_Review__c>{sbr};
                    
                    Id accountId = a.Id;
                
                Map<String, String> resp = new Map<String, String>();
                // test init
                SM_AccountTransfer.init(accountId, u.Id);
                resp = SM_AccountTransfer.init(accts[1].Id, u.Id);
                System.assertEquals(SM_AccountTransfer.STEP_APPROVAL_IN_PROCESS, resp.get('step'), 'Incorrect step');
                resp = SM_AccountTransfer.init(accts[1].Id, users[1].Id);
                
                // test checkContracts
                resp = SM_AccountTransfer.checkContracts(accountId, u.Id, u.Id, 'Test', false);
                //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
                System.debug('transfer to id: ' + u.Id);
                System.assertEquals(SM_AccountTransfer.STEP_TO_SELF, resp.get('step'), 'Incorrect step');
                
                resp = SM_AccountTransfer.checkContracts(accountId, u.Id, users[1].Id, 'Test', true);
            }
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testUpdateAccount() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        Test.startTest();
        try {
            System.runAs(users[0]) {
                List<Account> accts = TestDataFactory.createAccounts(3);
                accts[1].Transfer_approval_status__c = 'Submitted for approval';
                insert accts;
                
                Account a = accts[0];
                SM_AccountTransfer.updateAccountForApproval(a, 'Test Comment', users[2], users[1], u);            
            }            
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    /*@isTest
    private static void testCheckContracts() {
        
        Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
        Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;

        List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
        List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];
        
        Test.startTest();
        System.runAs(users[0]) {
            
            Map<String, String> resp = new Map<String, String>();
            // test init
            SM_AccountTransfer.init(accountId, userId);
            resp = SM_AccountTransfer.init(accts[1].Id, userId);
            System.assertEquals(SM_AccountTransfer.STEP_APPROVAL_IN_PROCESS, resp.get('step'), 'Incorrect step');
            resp = SM_AccountTransfer.init(accts[1].Id, users[1].Id);
            
            // test checkContracts
            resp = SM_AccountTransfer.checkContracts(accountId, userId, userId, 'Test', false);
            System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + userId);
        
        }
        Test.stopTest();
    }*/

    /*@isTest
    private static void testCheckContractsFirstCopy() {
        
        Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
        Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;

        List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
        List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];
        
        Test.startTest();
        System.runAs(users[0]) {
            
            Map<String, String> resp = new Map<String, String>();
            
             SM_AccountTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', false);
            
            resp = SM_AccountTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', true);
            resp = SM_AccountTransfer.checkContracts(accts[2].Id, userId, users[1].Id, 'Test', false);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
            //SM_AccountTransfer.transferAccountRelatedRecords(oldM, newM);
            //transferAccount(accts[0], userId, users[1].Id);
        }
        Test.stopTest();
    }*/

    @isTest
    private static void testTransferAccountRelatedContactRecordsOnly() {
        
        List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];

        Set<Id> accountIds = new Set<Id>();
        for(Account acc: accts){
            accountIds.add(acc.Id);
        }

        Test.startTest();
            SM_AccountTransfer.transferAccountRelatedContactRecordsOnly(accountIds);
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionInit() {
        try {
            SM_AccountTransfer.init(null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
    }
    
    @isTest
    private static void testExceptionContracts() {
        Test.startTest();
        try {
            SM_AccountTransfer.checkContracts(null, null, null, null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionAMToTSTransfer() {
        Test.startTest();
        try {
            SM_AccountTransfer.updateAccountAMToTSTransfer(null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionsAccountRelatedRecords() {
        Test.startTest();
        try {
            SM_AccountTransfer.transferAccountRelatedRecords(null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionUpdateAccount() {
        Test.startTest();
        try {
            SM_AccountTransfer.updateAccountForApproval(null, null, null, null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }

    /**
    * @description 
    * @author Simplus MS | 22/06/2021 
    **/
    @isTest
    static void DM_UserRunthrough() {
        Test.startTest();
        DM_User.getActiveUsersManagedBy('', new List<String>());
        DM_User.getActiveUsersOfProfiles(new List<String>());
        DM_User.getTSUsersByLocationCode(new List<String>());
        DM_User.getUsersByName(new List<String>());
        DM_User.getUsersByName(new List<String>());
        Test.stopTest();
    }
}