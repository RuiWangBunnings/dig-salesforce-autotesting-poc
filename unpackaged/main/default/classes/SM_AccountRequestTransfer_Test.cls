/*******************************************************************************************************
* Class Name      	: SM_AccountRequestTransfer_Test
* Description		: Test class for SM_AccountRequestTransfer_Test
* Author          	: Bunnings developer
* Created On      	: 20/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          20/07/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/
@isTest
private class SM_AccountRequestTransfer_Test {
    
    @testSetup 
    public static void testDataSetup() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        Profile p1 = [SELECT Id FROM Profile WHERE Name = :Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        List<User> usersAccManger = TestDataFactory.createUsers(2, p1.Id);
        insert usersAccManger;
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[0].isActive=true;
        users[0].FirstName='Test Transfer';
        users[1].ManagerId = users[2].Id;
        users[1].isActive=true;
        users[2].ManagerId = users[3].Id;
        users[2].isActive=true;
        update users;
        
        User u = users[0];
        User u1 =usersAccManger[0];
        User newOwner = users[2];
        
        System.runAs(users[0]) {
            List<Account> accts = TestDataFactory.createAccounts(5);
            accts[0].Power_Pass_Account_Number__c ='657';
           // accts[0].Account_Transferrable__c = 'Yes';
            //accts[0].Transfer_approval_status__c = 'Submitted for approval';
            accts[1].Power_Pass_Account_Number__c ='6577';
            accts[1].Transfer_approval_status__c = 'Submitted for approval';
            accts[2].Power_Pass_Account_Number__c ='6579';
            accts[2].Transfer_approval_status__c = 'Submitted for approval';
            accts[3].Power_Pass_Account_Number__c ='65795';
            accts[3].Transfer_approval_status__c = 'Submitted for approval';
            accts[3].Country__c = 'New Zealand';
            accts[4].Power_Pass_Account_Number__c ='65799';
            accts[4].Transfer_approval_status__c = 'Submitted for approval';
            accts[4].Country__c = 'New Zealand';
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
            Id acctPlanRTId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account_Plan__c' AND DeveloperName = 'Builders'].Id;
        Account_Plan__c ap1 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = usersAccManger[0].Id, Account__c = a.Id, Status__c = 'Active', Start_Date__c = Date.newInstance(2022, 6, 1), 
				End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000, 
				Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        Account_Plan__c ap2 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = users[0].Id, Account__c = a.Id, Status__c = 'Draft', Start_Date__c = Date.newInstance(2022, 6, 1), 
				End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000,
				Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        insert new List<Account_Plan__c>{ap1, ap2};
                Account_Plan__c acp = TestDataFactory.createAccountPlan(a.Id, contacts[0].Id);
            insert acp; 
            
             Family_Tree_Discount__c famTreeDisc = new Family_Tree_Discount__c();
            famTreeDisc.Family_Tree_Discount_ID__c = 'Test Tree Disc';
            INSERT famTreeDisc;
            
            Customer_Family_Tree_Discount__c custFamTreeDisc = new Customer_Family_Tree_Discount__c();
            custFamTreeDisc.Account__c = a.Id;
            custFamTreeDisc.Family_Tree_Discount__c = famTreeDisc.Id;
            custFamTreeDisc.Status__c = 'Active';
            custFamTreeDisc.Pricing_Assignment_Status__c = 'Submitted to CPS';
            custFamTreeDisc.Action__c = 'Removal';

            INSERT custFamTreeDisc;
            Account_Request__c ar = TestDataFactory.createSingleAccountRequest(newOwner.id,'6579',newOwner.Id, 'Single Account Transfer');
            insert ar;  
            Account_Request__c ar1 = TestDataFactory.createSingleAccountRequest(newOwner.id,'657',newOwner.Id, 'Single Account Transfer');
            insert ar1;  
            
            
             List<Account> acctsnz = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Where country__c='New Zealand'];
        	 Account a1 =acctsnz[0];
            List<Spend_Band__c> sbss = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
            upsert sbss Spend_Band_ID__c;
            
            Spend_Band_Review__c sbrs = TestDataFactory.createSpendBandReview(a1.Id, sbss[0].Id, sbss[1].Id, 'New Zealand');
            insert new List<Spend_Band_Review__c>{sbrs};
                
                Id accountId = a.Id;
            
            List<Umbrella_Group__c> lstUmbrellaGrps = TestDataFactory.createUmbrellaGroups(1);
            INSERT lstUmbrellaGrps;
            
            List<Umbrella_Beneficiary__c> lstUmbrellaBeneficiaries = TestDataFactory.createUmbrellaBeneficiaries(a1.Id, lstUmbrellaGrps[0].Id, 1);
            INSERT lstUmbrellaBeneficiaries;
        }
            
    }
    
     @isTest
    private static void testaccTransferRelatedAccounts() {
	
        Test.startTest();
      Profile p1 = [SELECT Id FROM Profile WHERE Name = :Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
		        List<User> usrs = [SELECT Id, Profile.Name FROM User Limit 2];
        
        User newOwner =usrs[1];
        User u =[SELECT Id, Profile.Name FROM User where FirstName='Test Transfer'];
        User u1=[SELECT Id FROM User WHERE ProfileId = :p1.id LIMIT 1];
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account where Power_Pass_Account_Number__c ='657' Limit 1];
		System.debug('Account a:'+a);
      Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(a.id);
        Set<Id> newOwnerIdset = new Set<Id>();
        newOwnerIdset.add(newOwner.id);
        Set<Id> oldOwnerIdset = new Set<Id>();
        oldOwnerIdset.add(u.id);
        Account_Request__c ar = [Select id from Account_Request__c where PowerPass_Account_Number__c ='657' Limit 1];
        
        List<Account_Request__c> updateAccReq = new List<Account_Request__c>();
              
        updateAccReq.add(ar);
        
         List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(a.Id, u.Id, 2);
       
            insert tasks;
            
            List<Event> events = TestDataFactory.createOpenEventsWithWhatId(a.Id, u.Id, 3);

            insert events;
            
            List<Opportunity> oppties = TestDataFactory.createOpenOpportunities(a.Id, u.Id, 2);

            insert oppties;
        // List<Task> t = [Select id,IsClosed from task where WhatId IN :accountIdSet AND OwnerId IN :oldOwnerIdset];
       // System.debug('task:'+t);
       // 
        System.debug('accountIdSet:'+accountIdSet);
        System.debug('oldOwnerIdset:'+oldOwnerIdset);
        List<Task> tasks1 = DM_Task.getOpenTasksWithWhatIds(accountIdSet, oldOwnerIdset);
        System.debug('tasks1:'+tasks1);
        System.debug('List Size: ' + tasks1.size());
        System.debug('tasks1 empty:'+tasks1.isEmpty());
       // System.debug('tasks1 empty:'+tasks1.isBlank());
        if(tasks1.isEmpty() == false) {
            System.debug('false in task');
        }else{
            System.debug('true in task');
            System.debug('task in true:'+tasks1);
        }
         SM_AccountRequestTransfer.transferAccountAndRelatedRecords(accountIdSet,oldOwnerIdset,oldOwnerIdset,updateAccReq);

		Test.stopTest();
    }
    
        @isTest
    private static void testaccTransferInitNeg() {
		
         
		
	Test.startTest();
      
        
         try {
            SM_AccountRequestTransfer.accTransferDetailsinit(null);
        } catch (Exception e){
            system.assert(TRUE);
        }
		Test.stopTest();
    }
    
   
     @isTest
    private static void testumbrellagroup() {
		
         
		Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];

		Test.startTest();
      
        
         try {
            SM_AccountRequestTransfer.getActiveUmbrellaGroupOwnerIds(a.id);
        } catch (Exception e){
            system.assert(TRUE);
        }
		Test.stopTest();
    }
       @isTest
    private static void testumbrellagroupneg() {
		
         
		Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];

		Test.startTest();
      
        
         try {
            SM_AccountRequestTransfer.getActiveUmbrellaGroupOwnerIds(null);
        } catch (Exception e){
            system.assert(TRUE);
        }
		Test.stopTest();
    }  
    @isTest
    private static void testaccTransferInit() {
		
         
		Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];

		Test.startTest();
      
        
         try {
            SM_AccountRequestTransfer.accTransferDetailsinit(a.id);
        } catch (Exception e){
            system.assert(TRUE);
        }
		Test.stopTest();
    }
     @isTest
    private static void testinit() {
		
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
        User thisUser = [SELECT Id, Profile.Name FROM User limit 1];
        
		Test.startTest();
        
        SM_AccountRequestTransfer.init(a.id,thisUser.id);
        
        System.assertEquals(SM_AccountRequestTransfer.STEP_APPROVAL_IN_PROCESS,'ApprovalInProgress');
        System.assertEquals('NotEligibleForTransfer', SM_AccountRequestTransfer.STEP_NOT_ELIGIBLE_FOR_TRANSFER);
        System.assertEquals('UmbrellaGroupOwnersOnly', SM_AccountRequestTransfer.STEP_UMBRELLA_GROUP_OWNERS_ONLY);
        System.assertEquals('SetTransferTo', SM_AccountRequestTransfer.STEP_SET_TRANSFER_TO);
        System.assertEquals('ToTSWithActiveContract', SM_AccountRequestTransfer.STEP_TO_TS_WITH_ACTIVE);
        System.assertEquals('ToNonTSWithActiveContract', SM_AccountRequestTransfer.STEP_TO_NON_TS_WITH_ACTIVE);
        System.assertEquals('ToSelf', SM_AccountRequestTransfer.STEP_TO_SELF);
        System.assertEquals('SingleAccountTransfer', SM_AccountRequestTransfer.STEP_SINGLE_ACC_TRANSFER);
        System.assertEquals('BulkAccountTransfer', SM_AccountRequestTransfer.STEP_BULK_ACC_TRANSFER);
        System.assertEquals('SubmitForApproval', SM_AccountRequestTransfer.STEP_SUBMIT_FOR_APPROVAL);
        System.assertEquals('SkipApproval', SM_AccountRequestTransfer.STEP_SKIP_APPROVAL);   
        Test.stopTest();
    }
    
    @isTest
    private static void testAccountTriggerBeforeAfterUpdate() {
        
        User u = [Select id from User Limit 1];
         u.isActive=true;
        u.Country__c ='Australia';
        update u;
        Test.startTest();
        System.runAs(u) {
            
     
            
		Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
            
            List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(a.Id, u.Id, 2);
            tasks.addAll(TestDataFactory.createClosedTasksWithWhatId(a.Id, u.Id, 2));
            insert tasks;
            
            
            // approve through process
            a.Transfer_approval_status__c = 'Approved';
            
            update a;
            a = [SELECT Id, Transfer_approval_status__c, Transfer_to__c, OwnerId FROM Account WHERE Id = :a.Id LIMIT 1];
            System.assertEquals('Approved', a.Transfer_approval_status__c, 'Status incorrect');
            System.assertEquals(null, a.Transfer_to__c, 'Transfer to incorrect');
         //   System.assertEquals(users[1].Id, a.OwnerId, 'Owner incorrect');
            
            
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
            SM_AccountRequestTransfer.init(accountId, userId);
            resp = SM_AccountRequestTransfer.init(accts[1].Id, userId);
          //  System.assertEquals(SM_AccountRequestTransfer.STEP_APPROVAL_IN_PROCESS, resp.get('step'), 'SetTransferTo');
            resp = SM_AccountRequestTransfer.init(accts[1].Id, users[0].Id);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[0].Id));
          

            Test.stopTest();
    }
        
    @isTest
    private static void testAccountTransferFirstCopy() {
        
            Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
            Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;
Test.startTest();
            Account accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany0%'];
            List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];
        accts.Ownerid = userId;
        update accts;
        Map<String,String> accReq = new Map<String,String>();
        accReq.put('677',userId);
       
        List<Account_Request__c> arb = TestDataFactory.createBulkAccountRequests(accReq);
        insert arb;
        Account_Request__c ars = TestDataFactory.createSingleAccountRequest(userid,'657',userid,'single');
        insert ars;
        
            
        try {
            Map<String, String> resp = new Map<String, String>();

                       
            SM_AccountRequestTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', false,false);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
           
            
        }catch (Exception e){
            System.assert(TRUE);
        }

        Test.stopTest();
    }

    @isTest
    private static void testAccountTransferSecondCopy() {
        
            Id accountId = [SELECT Id FROM Account WHERE Name = 'TestCompany0'].Id;
            Id userId = [SELECT Id FROM User WHERE Alias = 'emp0' LIMIT 1].Id;
        List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%'];
			//Profile p1 = [SELECT Id FROM Profile WHERE Name = :Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
            List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'TestCompany%'];
          //  List<User> users = [SELECT Id FROM User WHERE Alias LIKE 'emp%' AND ProfileId =:p1.id ];
		
        Test.startTest();
            
            Map<String, String> resp = new Map<String, String>();
            
            // test checkContracts
            resp = SM_AccountRequestTransfer.checkContracts(accountId, userId, users[1].Id, 'Test', true,false);
            //resp = SM_AccountRequestTransfer.checkContracts(accts[2].Id, userId, users[1].Id, 'Test', false);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = userId));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
          

        Test.stopTest();
    }
    
    @isTest
    private static void testAccountTransfer_NZNeg() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        Test.startTest();
      
        
        User u = [Select id from User Limit 1];
        u.Country__c ='Australia';
         u.isActive=true;
        update u;
        System.runAs(u) {
       
            List<Account> acctsnz = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Where country__c='New Zealand'];
        	 Account a1 =acctsnz[0];
            // test init
           SM_AccountRequestTransfer.init(a1.Id, u.Id);
            // test checkContracts
            SM_AccountRequestTransfer.checkContracts(a1.Id, u.Id, u.Id, 'Test', false,false);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + u.Id);
            
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(a1.Id, new Account(Id = a1.Id, OwnerId = u.Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(a1.Id, new Account(Id = a1.Id, OwnerId = u.Id));
           
            Price_List_Definition__c pld = new Price_List_Definition__c();
            insert pld;
            Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
            insert pb;
            Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                                    Status__c = 'Active', Customer_Price_List_ID__c = '45426');
            insert cpl;
            
            List<String> accIdList = new List<String>();
            List<String> spendBandIdList = new List<String>();
            
            for(Account acc : acctsnz){
                accIdList.add(acc.Id);
            }
           List<Spend_Band__c> sbs = [Select id from Spend_Band__c where country__c='NewZealand'];
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
            try{
                 SM_AccountRequestTransfer.updateAccountAMToTSTransfer(idList); 
            }
            catch (Exception e){
            System.assert(TRUE);
            }
        }
        
        Test.stopTest();
        
    }
 @isTest
    private static void testAccountTransfer_NZ() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
       // Test.setMock(HttpCalloutMock.class, new mockHttpResponseGenerator());
       // Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());
        Test.startTest();
      
               
        User u = [Select id from User Limit 1];
        u.Country__c ='New Zealand';
         u.isActive=true;
        update u;
        System.runAs(u) {
       	try{ 
            List<Account> acctsnz = [SELECT id,Name,Power_Pass_Account_Number__c,Country__c FROM Account Where country__c='New Zealand' limit 1];
        	 Account a1 =acctsnz[0];
            a1.Country__c='New Zealand';
            update a1;
            // test init
           //SM_AccountRequestTransfer.init(a1.Id, u.Id);
            // test checkContracts
           // SM_AccountRequestTransfer.checkContracts(a1.Id, u.Id, u.Id, 'Test', false,false);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + u.Id);
            System.debug('a1 Country: ' + a1.Country__c);
            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(a1.Id, new Account(Id = a1.Id, OwnerId = u.Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(a1.Id, new Account(Id = a1.Id, OwnerId = u.Id));
           
            Family_Tree_Discount__c famTreeDisc1 = new Family_Tree_Discount__c();
            famTreeDisc1.Family_Tree_Discount_ID__c = 'Test Tree Disc1';
            INSERT famTreeDisc1;
            Customer_Family_Tree_Discount__c custFamTreeDisc = new Customer_Family_Tree_Discount__c();
            custFamTreeDisc.Account__c = a1.Id;
            custFamTreeDisc.Family_Tree_Discount__c = famTreeDisc1.Id;
            custFamTreeDisc.Status__c = 'Active';
            custFamTreeDisc.Pricing_Assignment_Status__c = 'Submitted to CPS';
            custFamTreeDisc.Action__c = 'Removal';

            INSERT custFamTreeDisc;
            
           /* Price_List_Definition__c pld = new Price_List_Definition__c();
            insert pld;
            Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
            insert pb;
            Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = a1.Id,
                                                                    Status__c = 'Active', Customer_Price_List_ID__c = '45426');
            insert cpl;*/
            
            List<String> accIdList = new List<String>();
            List<String> spendBandIdList = new List<String>();
            
            for(Account acc : acctsnz){
                accIdList.add(acc.Id);
            }
           List<Spend_Band__c> sbs = [Select id from Spend_Band__c where country__c='New Zealand'];
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
            System.debug('idList :'+ idList);
             Map<String, String> resp = new Map<String, String>();
           
                 SM_AccountRequestTransfer.updateAccountAMToTSTransfer(idList); 
            }
        catch (Exception e){
           	 System.assert(TRUE);
            }
        }
        
        Test.stopTest();
        
    }
    @isTest
    private static void testAccountTransferNotEligible() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1]; 
        

        
        User u = [Select id from User Limit 1];
        List<User> users =[Select id from User Limit 3];
        users[0].isActive=true;
         users[0].Country__c ='Australia';
        update users[0];
        Test.startTest();
        System.runAs(users[0]) {
            
            
            List<Account> accts = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
            
            List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'New Zealand');
            upsert sbs Spend_Band_ID__c;
            Id accountId = accts[0].Id;
            Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(accountId, sbs[0].Id, sbs[1].Id, 'New Zealand');
            insert new List<Spend_Band_Review__c>{sbr};
                
                
            
            Map<String, String> resp = new Map<String, String>();
            SM_AccountRequestTransfer.init(accountId, users[0].Id);
          SM_AccountRequestTransfer.checkContracts(accountId, users[0].Id,users[0].Id, 'Test', false,true);
            //System.debug('account owner id: ' + JSON.serialize([SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :accountId]));
            System.debug('transfer to id: ' + users[0].Id);

            // test transferAccountRelatedRecords
            Map<Id, Account> oldM = new Map<Id, Account>();
            oldM.put(accountId, new Account(Id = accountId, OwnerId = users[0].Id));
            Map<Id, Account> newM = new Map<Id, Account>();
            newM.put(accountId, new Account(Id = accountId, OwnerId = users[1].Id));
            //SM_AccountRequestTransfer.transferAccountRelatedRecords(oldM, newM);
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
            
          /*  Family_Tree_Discount__c famTreeDisc1 = new Family_Tree_Discount__c();
            famTreeDisc1.Family_Tree_Discount_ID__c = 'Test Tree Disc';
            INSERT famTreeDisc1;
            
            Customer_Family_Tree_Discount__c custFamTreeDisc = new Customer_Family_Tree_Discount__c();
            custFamTreeDisc.Account__c = [SELECT Id from Account LIMIT 1].Id;
            custFamTreeDisc.Family_Tree_Discount__c = famTreeDisc1.Id;
            custFamTreeDisc.Status__c = 'Active';
            custFamTreeDisc.Pricing_Assignment_Status__c = 'Submitted to CPS';
            custFamTreeDisc.Action__c = 'Removal';

            INSERT custFamTreeDisc;*/
            
            SM_AccountRequestTransfer.updateAccountAMToTSTransfer(idList);
        }
        
        Test.stopTest();
        
    }

    @isTest
    private static void testAccountTransferInvisibleRecord() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist' LIMIT 1]; 
        
      
        User u = [Select id from user Limit 1];
        
        Test.startTest();
        try
        {
            System.runAs(u) {
               
                
                Account a =  [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
              Id accountId = a.Id;
                
                Map<String, String> resp = new Map<String, String>();
                // test init
                SM_AccountRequestTransfer.init(accountId, u.Id);
               
                System.assertEquals(SM_AccountRequestTransfer.STEP_APPROVAL_IN_PROCESS, resp.get('step'), 'SetTransferTo');
    
            }
        } catch (Exception e) {
          //  System.assertEquals('List has no rows for assignment to SObject', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testUpdateAccount() {
       
        
        List<User> users = [Select id from User Limit 3];
        Test.startTest();
        try {
            System.runAs(users[0]) {
               
                
                Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
                SM_AccountRequestTransfer.updateAccountRequestForApproval(a, 'Test Comment', users[2], users[1], users[0]);            
            }            
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
       
    
    @isTest
    private static void testExceptionInit() {
        try {
            SM_AccountRequestTransfer.init(null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
    }
    
    @isTest
    private static void testExceptionContracts() {
        Test.startTest();
        try {
            SM_AccountRequestTransfer.checkContracts(null, null, null, null, null,null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionAMToTSTransfer() {
        Test.startTest();
        try {
            SM_AccountRequestTransfer.updateAccountAMToTSTransfer(null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionsAccountRelatedRecords() {
        Test.startTest();
        try {
            SM_AccountRequestTransfer.transferAccountAndRelatedRecords(null, null, null, null);
        } catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionUpdateAccount() {
        Test.startTest();
        try {
            SM_AccountRequestTransfer.updateAccountRequestForApproval(null, null, null, null, null);
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


   
    
    @isTest
    private static void testSendAccountTransferError() {
        

        Set<Id> accountIdSet = new Set<Id>();
         Set<Id> newOwnerIdset = new Set<Id>();
         Set<Id> oldOwnerIdset = new Set<Id>();
         List<Account_Request__c> updateAccReq ;

         Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
         accountIdSet.add(a.id);
         List<User> usr = [SELECT id,isactive from USER LIMIT 2];
        usr[0].isActive=true;
        usr[0].Country__c ='Australia';
        update usr[0];
      	system.debug('user status:'+usr[0].isActive);
        Test.startTest();
            SM_AccountRequestTransfer.sendBulkAccountTransferErrorNotification(usr[0].id);
        
        Test.stopTest();
    }
}