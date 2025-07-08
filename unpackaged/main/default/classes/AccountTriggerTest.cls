/*******************************************************************************************************
* Class Name        : AccountTriggerTest
* Description       : Account trigger test
* Author            : Simplus - Haider Raza
* Created On        : 15/04/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           15/04/2020      1000                Initial version
* Philip Clark          06/07/2020      1001                Added test coverage for ABN, ACN, GST
* Simplus MS			22/06/2021		1002		    	Increased test coverage
* Simplus MS 			23/07/2021		1003 				Increased test coverage for CCRM-13792
* Simplus MS			21/09/2021		1004				CCRM15-83 (AC3) : Set marketing account flag before insert
* Simplus MS            29/10/2021      1005                Split createChileAccCustomerContractTest method asserts queries to avoid System.LimitException: Too many SOQL queries: 101 after updates on CCRM 15-79/15-80/15-180
* Bunnings Dev			27/6/2023		1006 				BUNDIG-22457 comment out testNZProspectGSTNumber
* Jasper R. Galapon		30/09/2024		1007				Commented out testHasChildAccount to fix SOQL limit, also have added some lines/method to increase test coverage
******************************************************************************************************/
@IsTest
private class AccountTriggerTest {
    /**
    *  Method name  :  dataSetup
    *  Description  :  Setup data for test class
    *  Author       :  Haider Raza
    **/
    @testSetup static void dataSetup() {
        
        //List<User> lstUser = TestDataFactory.createUsers(1, [SELECT Id From Profile WHERE Name = 'Trade Specialist' LIMIT 1].Id);
        //insert lstUser;
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        
        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';
        insert storeList;
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(2, p.Id);
        users[0].Location_Name__c = storeList[0].Name;
        users[1].Location_Code__c = storeList[0].Location_Code__c;
        
        //Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        //list<User> userSysAd = TestDataFactory.createUsers(1, p.Id);
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
            //insert userSysAd;
        }
                                            
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].Type = 'CASH';
        accounts[0].OwnerId = users[0].ID;
        
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        accounts[1].OwnerId = users[1].ID;
        accounts[1].Type = 'CASH';

        insert accounts;
    }

    /*comment out for BUNDIG-22457
    @IsTest
    static void testBehavior() {
        List<Account> accounts = [SELECT Id, RecordType.DeveloperName FROM Account];
        List<User> users = [SELECT ID FROM User];
        
        Test.startTest();
        if(accounts.size() > 1) {
            accounts[0].OwnerID = users[1].ID;
            accounts[1].OwnerID = users[0].ID;
            accounts[0].ABN__c = '51824753556';
            accounts[0].ACN__c = '004085616';
            accounts[0].GST_Number__c = '1153x912 08';
            
            Database.update(accounts, false);
        }
        
        Database.delete(accounts, false);
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM Account].size(), 'Account not deleted');
    }
	*/
    
    @IsTest
    static void testInsert() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Name = 'TestABNACN';
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[0].ABN__c = '51824753556';
        accounts[0].ACN__c = '004085616';
        accounts[0].GST_Number__c = '1153x912 08';
        
        Test.startTest();
        
        insert accounts;
        
        Test.stopTest();

        Account acc = [SELECT Id, ABN__c, ACN__c, GST_Number__c FROM Account WHERE Id =: accounts[0].Id LIMIT 1];
        system.assertEquals('51 824 753 556',acc.ABN__c,'ABN not formatted correctly');
        system.assertEquals('004 085 616',acc.ACN__c,'ACN not formatted correctly');
        system.assertEquals('115391208',acc.GST_Number__c,'GST number not formatted correctly');
    }
	/* comment out for BUNDIG-22457
    @isTest
    static void testNZProspectGSTNumber() {

        Account a = new Account(Name = 'Test NZ Prospect GST Number', RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Prospect'), GST_Number__c = '111111111');

        Test.startTest();
        // insert with invalid number
        try {
            insert a;
        } catch(Exception e) {
            System.assert(e.getMessage().contains(AccountTriggerHandler.ERROR_INVALID_GST_NUMBER), 'Error message for invalid GST Number incorrect');
        }
        // insert with valid number
        a.GST_Number__c = '47453623';
        insert a;

        // update with invalid number
        a.GST_Number__c = '069123466';
        try {
            update a;
        } catch(Exception e) {
            System.assert(e.getMessage().contains(AccountTriggerHandler.ERROR_INVALID_GST_NUMBER), 'Error message for invalid GST Number incorrect');
        }

        Test.stopTest();
    }
	*/
    @isTest
    static void testCreditLimitIncrease() {

        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {

            List<Account> accounts = new List<Account>{
                new Account(Name = 'Credit Limit Test 6', RecordTypeId = DM_RecordType.rtId_Account_AuCustomer, Credit_Limit__c = 1000, Credit_Limit_Increased_Check__c = false, Type = Constants.ACCOUNT_TYPE_CREDIT, OwnerId = users[0].Id)
            };
            insert accounts;
            
            AccountTriggerHandler.triggerInProgress = false;

            List<Task> task = TestDataFactory.createOpenTasksWithWhatId(accounts[0].Id, UserInfo.getUserId(), 1);
            task[0].Subject = 'Engagement Call';
            task[0].Sub_type__c = 'Engagement Call';
            task[0].RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Cycle Call').getRecordTypeId();
            task[0].ActivityDate = System.today();
            try{
                insert task;
            }
            catch(Exception e){System.debug(e);}
           
            AccountTriggerHandler.triggerInProgress = false;
            accounts[0].Credit_Limit__c = 2000;
            accounts[0].Type = Constants.ACCOUNT_TYPE_30DAY;
            accounts[0].Credit_Limit_Increased_Check__c = true;
            update accounts;

            System.assertEquals(0, [SELECT Id FROM Task WHERE WhatId = :accounts[0].Id AND Subject = :SM_CallCycle.SUBJECT_CREDIT_LIMIT_INCREASED].size(), '2nd credit limit increase task created for ' + accounts[0].Name);
           }
        
        Test.stopTest();
        
    }
    
    /*@isTest
    static void testHasChildAccount() {
        List<Account> accounts = TestDataFactory.createAccounts(3);
        insert new List<Account>{accounts[0], accounts[1]};
        
        Test.startTest();
        accounts[2].ParentId = accounts[0].Id;
        insert accounts[2];
        System.assertEquals(true, [SELECT Id, Has_Child_Accounts__c FROM Account WHERE Id = :accounts[0].Id].Has_Child_Accounts__c, 'First parent has child account flag not set correctly');
        
        accounts[2].ParentId = accounts[1].Id;
        update accounts[2];
        System.assertEquals(false, [SELECT Id, Has_Child_Accounts__c FROM Account WHERE Id = :accounts[0].Id].Has_Child_Accounts__c, 'First parent has child account flag not set correctly after reparenting');
        System.assertEquals(true, [SELECT Id, Has_Child_Accounts__c FROM Account WHERE Id = :accounts[1].Id].Has_Child_Accounts__c, 'Second parent has child account flag not set correctly after reparenting');

        accounts[2].Account_Status__c = Constants.ACCOUNT_STATUS_TERMINATED;
        update accounts[2];
        System.assertEquals(false, [SELECT Id, Has_Child_Accounts__c FROM Account WHERE Id = :accounts[1].Id].Has_Child_Accounts__c, 'Second parent has child account flag not set correctly after child set to inactive');

        accounts[2].Account_Status__c = Constants.STATUS_ACTIVE;
        update accounts[2];
        System.assertEquals(true, [SELECT Id, Has_Child_Accounts__c FROM Account WHERE Id = :accounts[1].Id].Has_Child_Accounts__c, 'Second parent has child account flag not set correctly after child set to active');

        Test.stopTest();
    }*/
    
    @isTest
    static void testTerminateInactivateAccount() {
        // accounts
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        
        // events
        List<Event> events = TestDataFactory.createOpenEventsWithWhatId(accounts[0].Id, UserInfo.getUserId(), 1);
        insert events;
        // tasks
        List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(accounts[0].Id, UserInfo.getUserId(), 1);
        insert tasks;
        // umbrella group
        List<Umbrella_Group__c> groups = TestDataFactory.createUmbrellaGroups(1);
        insert groups;
        // umbrella beneficiary
        List<Umbrella_Beneficiary__c> beneficiaries = TestDataFactory.createUmbrellaBeneficiaries(accounts[0].Id, groups[0].Id, 1);
        insert beneficiaries;
        
        Test.startTest();
        accounts[0].Account_Status__c = Constants.ACCOUNT_STATUS_TERMINATED;
        update accounts[0];
        System.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :accounts[0].Id AND IsClosed = true].size(), 'Tasks should have been marked as cancelled');
        System.assertEquals(0, [SELECT Id FROM Event WHERE WhatId = :accounts[0].Id].size(), 'Events should have been deleted');
        System.assertEquals(1, [SELECT Id FROM Umbrella_Beneficiary__c WHERE Account__c = :accounts[0].Id AND Status__c = 'Inactive'].size(), 'Beneficiaries should have been inactivated');
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateManualCallCycleTask() {
        // accounts
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Business_Determined_Call_Reason__c = 'Call to check';
        insert accounts;
        
        Test.startTest();
        AccountTriggerHandler.triggerInProgress = false;
        accounts[0].Include_in_Call_Cycle__c = 'Accept';
        update accounts[0];
        System.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :accounts[0].Id].size(), 'Task should have been created');
        Test.stopTest();
    }

    @isTest
    static void testApprenticeCustomerConvert() {

        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {

            List<Account> accounts = new List<Account>{
                new Account(Name = 'Apprentice Convert Test 1', Country__c = Constants.COUNTRY_AU, Apprentice__c = true, Power_Pass_Account_Number__c = '1001', OwnerId = users[0].Id),
                new Account(Name = 'Apprentice Convert Test 2', Country__c = Constants.COUNTRY_AU, Apprentice__c = false, Power_Pass_Account_Number__c = '1002', OwnerId = users[0].Id),
                new Account(Name = 'Apprentice Convert Test 3', Country__c = Constants.COUNTRY_NZ, Apprentice__c = true, Power_Pass_Account_Number__c = '1003', OwnerId = users[0].Id),
                new Account(Name = 'Apprentice Convert Test 4', Country__c = Constants.COUNTRY_NZ, Apprentice__c = false, Power_Pass_Account_Number__c = '1004', OwnerId = users[0].Id)
            };
            insert accounts;
            
            AccountTriggerHandler.triggerInProgress = false;

            // Update apprentcie flag which will be controlled by source 
            accounts[0].Apprentice__c = false;  // Apprentice to Customer allowed
            accounts[1].Apprentice__c = true;   // Customer to Apprentice not allowed
            accounts[2].Apprentice__c = false;  // Apprentice to Customer allowed
            accounts[3].Apprentice__c = true;   // Customer to Apprentice not allowed
            update accounts;

            // Check if apprentice to customer conversion took place successfully
            System.assertEquals([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accounts[0].Id].RecordType.DeveloperName,Constants.ACCOUNT_RT_AU_CUSTOMER);
            System.assertEquals([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accounts[1].Id].RecordType.DeveloperName,Constants.ACCOUNT_RT_AU_CUSTOMER);
            System.assertEquals([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accounts[2].Id].RecordType.DeveloperName,Constants.ACCOUNT_RT_NZ_CUSTOMER);
            System.assertEquals([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accounts[3].Id].RecordType.DeveloperName,Constants.ACCOUNT_RT_NZ_CUSTOMER);
        }
        
        Test.stopTest();  
    }

    
    /**
    * @description CCRM-13792 AC2: Create Child Account Customer Contract When there are accounts 
    *                               linked via the Contract Group Association
    * @author Simplus MS | 24/06/2021 
    **/
    @isTest
    public static void createChildAccCustomerContractTest() {

        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        List<Customer_Price_List__c> cplList = new List<Customer_Price_List__c>();
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        //contracts[1].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        Test.startTest();
        insert contracts;

        List<Account> parentAccounts1 = TestDataFactory.createAccounts(1);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(2);
        insert tempUmbrellaGrp;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = parentAccounts1[0].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
     //   Customer_Price_List__c cplFuture = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = parentAccounts1[0].Id, Start_Date__c = System.today().addDays(1),
       //                                                        Status__c = 'Inactive', Customer_Price_List_ID__c = '45456');
        //cplList.add(cplFuture);
       // insert cplList;
        List<Id> accountIds1 = new List<Id>();
        for(Account acc:parentAccounts1){
            accountIds1.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContracts1 = TestDataFactory.createAccCustomerContracts(accountIds1, new List<Id>{contracts[0].Id});
        insert accCustomerContracts1;

        

        List<Account> childAccounts = TestDataFactory.createAccounts(1);
        Integer i = 0;
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccounts1[i].Id;
            i++;
        }
        insert childAccounts;
        
        List<Account> parentAccounts2 = TestDataFactory.createAccounts(1);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        UPDATE store;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        /*i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            //accParent.Powerpass_Account_Manager__c = 'Testing';
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }            
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        List<Id> accountIds2 = new List<Id>();
        for(Account acc:parentAccounts2){
            accountIds2.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContracts2 = TestDataFactory.createAccCustomerContracts(accountIds2, new List<Id>{contracts[1].Id});
        insert accCustomerContracts2;

        Integer j = 0;
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccounts2[j].Id;
            j++;
        }
        update childAccounts;

        List<Account> accList = [SELECT Id, (SELECT Id FROM Customer_Contracts__r) 
                                FROM Account
                                WHERE Name Like 'TestContract%' AND Contract_Group__c != null];
        for(Account acc:accList){
            System.assertEquals('Yes', acc.On_Contract__c, 'Child Account On Contract field is not set to Yes');
            System.assertEquals(1, acc.Customer_Contracts__r.size(), 'Child Account Customer Contracts not updated successfully');
            for(Customer_Contract__c custContract : acc.Customer_Contracts__r){
                System.assertEquals(contracts[1].Id, custContract.Contract__c, 'Old Customer Contracts not deleted successfully');
            }
        }*/
        
        AccountTriggerHandler.assignPowerpassAccount(null);
        Test.stopTest();
    }
     @isTest
    public static void customerPriceListsFromContractGroup() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        Test.startTest();

        insert accounts;
       /*Account newAcc = new Account(
            Name = 'TestCompany0000',
            BillingCity='Melbourne',
            BillingCountry='AUS',
            BillingPostalCode='3000',
            BillingState='VIC',
            BillingStreet='Collins St',
            Country__c='Australia',
            Account_Status__c = 'Active',
            Contract_Group__c = accounts[1].Id
        );
        
        insert newAcc;*/
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = accounts[0].Id,
                                                                Status__c = 'Active', Customer_Price_List_ID__c = '45426', Start_Date__c = System.today());
        insert cpl;
        accounts[0].Contract_Group__c = accounts[1].Id;
        try{
            update accounts;
        }catch(Exception e){
            System.debug(e);
        }
        
        Test.stopTest();
    }
    @isTest 
    public static void inactiveChildAccCustomerContract() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        insert accounts;
        
        Account newAcc = new Account(
            Name = 'TestCompany0000',
            BillingCity='Melbourne',
            BillingCountry='AUS',
            BillingPostalCode='3000',
            BillingState='VIC',
            BillingStreet='Collins St',
            Country__c='Australia',
            Account_Status__c = 'Active',
            Contract_Group__c = accounts[1].Id
        );
        insert newAcc;
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = newAcc.Id,
                                                                Status__c = 'Active', Customer_Price_List_ID__c = '45426', Start_Date__c = System.today());
        insert cpl;
      
        newAcc.Contract_Group__c = null;
        update newAcc;
        
    }
    @isTest 
    public static void assignPowerpassAccount() {
        Store__c store = [SELECT Id,Location_Code__c	FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        UPDATE store;
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders', Name = 'Test Segment');
        INSERT segment;
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Home_Store__c = store.Id;
        accounts[0].Power_Pass_Account_Number__c = '12121212';
        accounts[0].Secondary_Segment__c = segment.Id;
        insert accounts;

    }
    
     @isTest 
    public static void beforeUpdate() {
		Test.startTest();
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Marketing_Account__c = false;
        insert accounts;
        Contact cont = new Contact();
        cont.LastName = 'test';
        cont.phone = '343434443';
        cont.AccountId = accounts[0].Id;
        cont.Marketing_Contact__c = true;
        insert cont;
        accounts[0].Type = 'CASH';
        accounts[0].Receive_Marketing__c = true;
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        update accounts;    
        Test.stopTest();
    }
    
    
   /*isTest  
    public static void checkForApprovalRejectionComment() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist' LIMIT 1];
        List<User> usersObj = TestDataFactory.createUsers(1, p1.Id);
        insert usersObj;
        System.runAs(usersObj[0]){
            Account newAcc = new Account(
                Name = 'TestCompany0000',
                BillingCity='Melbourne',
                BillingCountry='AUS',
                BillingPostalCode='3000',
                BillingState='VIC',
                BillingStreet='Collins St',
                Country__c='Australia',
                Account_Status__c = 'Active',
                OwnerId = usersObj[0].Id
            );
            insert newAcc;
        }
        
    }*/
    
    @isTest
    public static void beforeUpdateDefaultUser() {
       //ap<String, Operations_Region_TS_Role__mdt> operationalRegionMap = Operations_Region_TS_Role__mdt.getAll();
        Test.startTest();
       /*rofile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;*/
        List<Account> accounts = [select id, OwnerId from Account ];
      
        Store__c store = [SELECT Id,Location_Code__c	FROM Store__c LIMIT 1];
        
        Store__c newStore = new Store__c(
            Name = 'Store' + String.valueOf(3),
            Location_Code__c = '10210' + String.valueOf(3),
            Sales_Rep_ID__c = '600'+ String.valueOf(3),
            Status__c = 'Active',
            Operations_Region_Code__c = 'NSW'
        );
        insert newStore;
         // create user
      //Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
     // List<User> users = TestDataFactory.createUsers(1, p.Id);
      //insert users;
        
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist' LIMIT 1];
        List<User> usersObj = TestDataFactory.createUsers(1, p1.Id);
        usersObj[0].Location_Code__c = store.Location_Code__c;//store is attach to user
        insert usersObj;
        User users1= [Select id, Location_Code__c from user where id =: usersObj[0].Id];
        accounts[0].OwnerId = users1.Id;
        update accounts;
        System.debug('accounts>>>>>> '+accounts);
        users1.Location_Code__c = newStore.Location_Code__c;
        update users1;
        
        accounts[1].Business_Email_Address__c = 'test1@test.com';
        accounts[1].Marketing_Account__c = true;
        update accounts;
        
      /*Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        List<User> users = TestDataFactory.createUsers(1, p.Id);
        insert users;
        accounts[1].OwnerId = users[0].Id;
        update accounts;*/
        Test.stopTest();
        
    }
    
  
    public static void createChildAccCustomerContractTest1() {
        
        List<Contract__c> contracts = TestDataFactory.createContracts(2);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        contracts[1].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        insert contracts;

        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = parentAccounts1[0].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Customer_Price_List__c cplFuture = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = parentAccounts1[0].Id, Start_Date__c = System.today().addDays(1),
                                                               Status__c = 'Inactive', Customer_Price_List_ID__c = '45456');
        insert cplFuture;
        
        List<Id> accountIds1 = new List<Id>();
        for(Account acc:parentAccounts1){
            accountIds1.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContracts1 = TestDataFactory.createAccCustomerContracts(accountIds1, new List<Id>{contracts[0].Id});
        insert accCustomerContracts1;

        Test.startTest();

        List<Account> childAccounts = TestDataFactory.createAccounts(5);
        Integer i = 0;
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccounts1[i].Id;
            i++;
        }
        insert childAccounts;
        
        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        UPDATE store;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            //accParent.Powerpass_Account_Manager__c = 'Testing';
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }            
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        List<Id> accountIds2 = new List<Id>();
        for(Account acc:parentAccounts2){
            accountIds2.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContracts2 = TestDataFactory.createAccCustomerContracts(accountIds2, new List<Id>{contracts[1].Id});
        insert accCustomerContracts2;

        Integer j = 0;
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccounts2[j].Id;
            j++;
        }
        update childAccounts;

        for(Account acc:childAccounts){
            acc.Contract_Group__c = null;
        }
        update childAccounts;

        List<Account> acclst = [SELECT Id, (SELECT Id FROM Customer_Contracts__r) 
                                FROM Account
                                WHERE Name Like 'TestContract%' AND Contract_Group__c != null];
        for(Account acc:acclst){
            System.assertEquals('No', acc.On_Contract__c, 'Child Account On Contract field is not set to No');
            System.assertEquals(0, acc.Customer_Contracts__r.size(), 'Child Account Customer Contracts not deleted successfully');
        }
        
        AccountTriggerHandler.assignPowerpassAccount(null);
        Test.stopTest();
    }
    
    @isTest
    public static void createParentWithPowerPassManager() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        //Store_Member__c storeMember = TestDataFactory.createStoreMember(store.Id, [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' LIMIT 1].Id, 'ASM');
        //INSERT storeMember;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
                accParent.Powerpass_Account_Manager__c = 'Manager Test';
            } else {
              accParent.Powerpass_Account_Manager__c = 'Testing';  
            }
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        
        Test.stopTest();
    }
    
     @isTest
    public static void createParentWithASMManager() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        List<User> lstUser = TestDataFactory.createUsers(1, [SELECT Id From Profile WHERE Name = 'Sales Manager' LIMIT 1].Id);
        insert lstUser;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        Store_Member__c storeMember = TestDataFactory.createStoreMember(store.Id, [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' LIMIT 1].Id, 'ASM');
        INSERT storeMember;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }
            
            accParent.Powerpass_Account_Manager__c = 'Testing'; 
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        Test.stopTest();
    }
    
      @isTest
    public static void createParentWithoutASMAndDefaultTS() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        List<User> lstUser = TestDataFactory.createUsers(1, [SELECT Id From Profile WHERE Name = 'Sales Manager' LIMIT 1].Id);
        insert lstUser;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        List<Store_Member__c> storeMemberList = [SELECT Id, Default_Trade_Specialist__c From Store_Member__c WHERE Default_Trade_Specialist__c = TRUE];
        for (Store_Member__c sm : storeMemberList) {
            sm.Default_Trade_Specialist__c = FALSE;
        }
        UPDATE storeMemberList;
                
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }
            
            accParent.Powerpass_Account_Manager__c = 'Test Account Manager'; 
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        Test.stopTest();
    }
    
      @isTest
    public static void createNZParentWithoutASMAndDefaultTS() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        for (Account acct : parentAccounts1) {
            acct.Country__c = 'New Zealand';
        }
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        List<User> lstUser = TestDataFactory.createUsers(1, [SELECT Id From Profile WHERE Name = 'Sales Manager' LIMIT 1].Id);
        insert lstUser;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        List<Store_Member__c> storeMemberList = [SELECT Id, Default_Trade_Specialist__c From Store_Member__c WHERE Default_Trade_Specialist__c = TRUE];
        for (Store_Member__c sm : storeMemberList) {
            sm.Default_Trade_Specialist__c = FALSE;
        }
        UPDATE storeMemberList;
                
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            accParent.Country__c = 'New Zealand';
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }
            
            accParent.Powerpass_Account_Manager__c = 'Test Account Manager'; 
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        Test.stopTest();
    }


     @isTest
    public static void createAccountWithoutPowerPassManager() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        List<User> lstUser = TestDataFactory.createUsers(1, [SELECT Id From Profile WHERE Name = 'Sales Manager' LIMIT 1].Id);
        insert lstUser;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        Store_Member__c storeMember = TestDataFactory.createStoreMember(store.Id, [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' LIMIT 1].Id, 'ASM');
        INSERT storeMember;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            accParent.Credit_Limit__c = 20000;
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
            }
            
            accParent.Powerpass_Account_Manager__c = 'New Test'; 
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        Test.stopTest();
    }
    
    @isTest
    public static void createNewZealandA() {        
        List<Account> parentAccounts1 = TestDataFactory.createAccounts(5);
        insert parentAccounts1;
        List<Umbrella_Group__c> tempUmbrellaGrp = TestDataFactory.createUmbrellaGroups(5);
        insert tempUmbrellaGrp;
        
        Test.startTest();

        List<Account> parentAccounts2 = TestDataFactory.createAccounts(5);
        Account clonedAccount = new Account(Name = parentAccounts2[0].Name,
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Prospect').getRecordTypeId(),
                                            BillingCity= parentAccounts2[0].BillingCity,
                                            BillingCountry= parentAccounts2[0].BillingCountry);
        insert clonedAccount;
        Store__c store = [SELECT Id FROM Store__c LIMIT 1];
        store.Engagement_Model__c = 'New';
        store.Primary_Trade_Specialist__c = [SELECT Id FROM User WHERE Profile.Name = 'Trade Specialist' LIMIT 1].Id;
        UPDATE store;
        
        //Store_Member__c storeMember = TestDataFactory.createStoreMember(store.Id, [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' LIMIT 1].Id, 'ASM');
        //INSERT storeMember;
        
        Segment__c segment = new Segment__c(Segment_Group__c = 'Builders');
        INSERT segment;
        
        integer i = 0;
        for (Account accParent : parentAccounts2) {
            accParent.Power_Pass_Account_Number__c = '1000' + String.valueOf(i);
            accParent.Type = '30Day';
            accParent.Secondary_Segment__c = segment.Id;
            accParent.Country__c = 'New Zealand';
            if (i == 0) {
                accParent.Home_Store__c = store.Id;
                accParent.Powerpass_Account_Manager__c = 'Manager Test';
            } else {
              accParent.Powerpass_Account_Manager__c = 'Testing';  
            }
            accParent.Temporary_Umbrella_Group__c = tempUmbrellaGrp[i].Id;
            i++;
        }
        insert parentAccounts2;
        
        
        Test.stopTest();
    }


    /**
    * @description CCRM-13792 Used to Increase Test coverage of DM_Account
    * @author Simplus MS | 23/07/2021 
    **/
    @isTest
    public static void testCoverageOfDMAccount() {

        List<Account> accountList = TestDataFactory.createAccounts(5);
        insert accountList;
        List<String> accountIds = new List<String>();
        for (Account acc : accountList) 
        {
            accountIds.add(acc.Id);
        }

        List<Contract__c> contracts = TestDataFactory.createContracts(2);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        insert contracts;

        List<User> lstUser = TestDataFactory.createUsers(3, [SELECT Id From Profile WHERE Name = 'Sales Manager' LIMIT 1].Id);
        insert lstUser;
        List<Id> userIds = new List<Id>();
        for (User acc : lstUser) 
        {
            userIds.add(acc.Id);
        }
        
        Test.startTest();
        DM_Account.getAccountDetails(accountList[0].Id);
        DM_Account.getAccount(accountList[0].Id);
        DM_Account.getAccounts(accountIds);
        DM_Account.getAccountWithContactsEngagementCallActivities(accountList[0].Id);
        DM_Account.getSupplierAccountsByRegion('Area 4');
        DM_Account.getAccountsWithCustomerSpecialBuys(contracts[0].Id);
        DM_Account.getCustomerAndProspectAccountsOwnedBy(lstUser[0].Id);
        DM_Account.getAccountsOwnedBy(userIds);
        Test.stopTest();
    }

    /**
    * @description Used to Increase Test coverage of AccountTriggerHandler
    * @author Simplus MS | 5/08/2021 
    **/
    @isTest
    public static void testCoverageOfAccTriggerHandler() {

        List<Account> accountList = TestDataFactory.createAccounts(5);
        insert accountList;
        Map<Id, Account> allAccountsByIds = new Map<Id, Account>();
        for (Account acc : accountList) 
        {
            allAccountsByIds.put(acc.Id, acc);
        }
        Test.startTest();
            AccountTriggerHandler.avoidDelete(accountList, allAccountsByIds);
        Test.stopTest();
    }
    
    /**
    * @description Set Marketing Cloud flags for CCRM15-83
    * @author Simplus MS | 21/06/2021 | 21/09/2021
    **/
    @IsTest
    static void setMarketingFlagsTest() {
        List<Account> accounts = TestDataFactory.createAccounts(4);
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Apprentice');
        accounts[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');
        accounts[2].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Apprentice');
        accounts[3].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Customer');
        
        for(Account acc: accounts){
            acc.Receive_Marketing__c = TRUE;
            acc.Verified_Email__c = TRUE; 
            acc.Type = 'CASH';
            acc.Type = 'CREDIT';
        }
        
        Test.startTest();        
            insert accounts;

            List<Account> accList = [SELECT Id, Marketing_Account__c FROM Account WHERE Id IN (:accounts[0].Id, :accounts[1].Id, :accounts[2].Id, :accounts[3].Id)];
            for(Account acc: accList){
                system.assertEquals(TRUE,acc.Marketing_Account__c,'Marketing Cloud flags not set correctly');
            }

            for(Account acc: accounts){
                acc.Marketing_Account__c = FALSE;
                acc.Receive_Marketing__c = FALSE;
            }

            Update accounts;

            for(Account acc: accounts){
                acc.Receive_Marketing__c = TRUE;
            }

            Update accounts;

            List<Account> accNewList = [SELECT Id, Marketing_Account__c FROM Account WHERE Id IN (:accounts[0].Id, :accounts[1].Id, :accounts[2].Id, :accounts[3].Id)];
            for(Account acc: accNewList){
                system.assertEquals(TRUE,acc.Marketing_Account__c,'Marketing Cloud flags not set correctly');
            }                
        Test.stopTest();
    }
    
    @isTest
    static void beforeDeleteTest() {        
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User adminUser = new User(ProfileId = sysAdminProfile.Id, LastName = 'TestAdmin', Email = 'testadmin@test.com', Username = 'testadmin@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST', Title = 'Title', Alias = 'alias', Country__c = 'Australia', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert adminUser;
                
        System.runAs(adminUser) {
            List<Account> testAccounts = new List<Account>();
            for(Integer i = 0; i < 3; i++) {
                testAccounts.add(new Account(Name = 'Test Account ' + i, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AU_Customer').getRecordTypeId()));
            }
            insert testAccounts;
            
            Test.startTest();
            	 Database.DeleteResult[] results = Database.delete(testAccounts, false);
            Test.stopTest();            
        }                            
    }
    
    @isTest
    static void checkNZGSTNumberTest() {
        Account acct = new Account(Name = 'Test NZ Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NZ_Prospect').getRecordTypeId(),
            GST_Number__c = '13-956-875');
            insert acct; 
        
        Test.startTest();        	
        	AccountTriggerHandler.checkNZGSTNumber(new List<Account>{acct});
        	acct.GST_Number__c = '12-345-678 ';
        	update acct;
        	Map<Id, Account> mapOldAcct = new Map<Id, Account>(new List<Account>{acct});
        	Map<Id, Account> mapNewAcct = new Map<Id, Account>(new List<Account>{acct});
        	AccountTriggerHandler.checkNZGSTNumber(mapOldAcct, mapNewAcct);
        Test.stopTest();
    }
    
    @IsTest
    static void setNewCPLTest() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Name = 'Test Account';
        accounts[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Customer');                
        insert accounts;
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        
        Customer_Price_List__c testCPL = new Customer_Price_List__c(Account__c = accounts[0].Id, Action__c = 'Assignment', Change_Requested_On__c = Date.today(),
            Price_List__c = pb.Id, Pricing_Assignment_Status__c = 'Pending Assignment Approval', Start_Date__c = Date.today(), End_Date__c = Date.today().addYears(1), Status__c = 'Active');
        insert testCPL;
        
        Date newStartDate = Date.today().addDays(30);
        
        Test.startTest();
        	Customer_Price_List__c newCPL = AccountTriggerHandler.setNewCPL(testCPL, accounts[0].Id, newStartDate);
        Test.stopTest();
    }
    
    /*@isTest
    static void isTerminatedOrInactiveTest() {
        Account acct = new Account(Name = 'Test NZ Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NZ_Prospect').getRecordTypeId(),
            Account_Status__c = 'Inactive');
                    
       	Test.startTest();
        	insert acct;
			AccountTriggerHandler.isTerminatedOrInactive(acct);
       	Test.stopTest();
    }*/
}