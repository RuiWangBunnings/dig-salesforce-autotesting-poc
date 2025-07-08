/*******************************************************************************************************
* Class Name      	: SM_BulkAccountTransferBatchTest
* Description		: Test class for SM_BulkAccountTransferBatch
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           27/04/2021		1000				Initial version 
* Simplus MS 		   19/01/2022		1001				Increased test code coverage
******************************************************************************************************/

@isTest
private class SM_BulkAccountTransferBatchTest {
      
    @isTest
    private static void test_transferAllAccounts() {
        String createdDate = String.valueOf(System.today());
        
		Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, p.Id);
                        
        User thisUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
        }
        
        
        //List<Account> accounts = TestDataFactory.createAccounts(200);
        List<Account> accounts = TestDataFactory.createAccounts(100);
        List<Account> toInsert = new List<Account>();
        for (Account acct: accounts ){
            acct.OwnerId = UserInfo.getUserId();
            acct.R12_Sales__c = 1;
            acct.PowerPass_Account_Created_Date__c = System.Today();
            toInsert.add(acct);
        }
        insert toInsert;
        
        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: toInsert[0].Id];

        List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(acc[0].OwnerId, 'Australia', 1);
        insert contracts;

        List<Id> contractIdList = new List<Id>();
        for(Contract__c contract : contracts){
            contractIdList.add(contract.Id);
        }

        List<Customer_Contract__c> customerContract = TestDataFactory.createCustomerContracts((String)acc[0].Id, contractIdList);
        insert customerContract;

        List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId((String)acc[0].Id, acc[0].OwnerId, 1);
        insert tasks;
        
        List<Event> events = TestDataFactory.createOpenEventsWithWhatId(acc[0].Id, acc[0].OwnerId, 3);
        events.addAll(TestDataFactory.createClosedEventsWithWhatId(acc[0].Id, acc[0].OwnerId, 1));
        insert events;

        List<Opportunity> oppts = TestDataFactory.createOpenOpportunities(acc[0].Id, acc[0].OwnerId, 1);
        insert oppts;

        List<Contact> contacts = TestDataFactory.createContacts(acc[0].Id, acc[0].OwnerId, 1);
        insert contacts;

        List<Case> cases = TestDataFactory.createOpenCases(acc[0].Id, acc[0].OwnerId, 1);
        insert cases;

        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;

        Spend_Band_Review__c sbr = TestDataFactory.createSpendBandReview(acc[0].Id, sbs[0].Id, sbs[1].Id, 'Australia');
        insert new List<Spend_Band_Review__c>{sbr};
            
        String filter = '[{"fieldName":"R12_Sales__c","operator":">=","value":"0","type":"number","index":10},{"fieldName":"BillingPostalCode","operator":"","value":"","index":20},{"fieldName":"Assigned_Store__c","operator":"=","index":30},{"fieldName":"Secondary_Segment__c","operator":"=","index":40}]';
                        
        Test.startTest();
        	Database.executebatch(new SM_BulkAccountTransferBatch('transferAllAccounts', null, UserInfo.getUserId(), users[0].Id, users[0].Id, 'Test',  createdDate, '<=', filter));
        Test.stopTest();
    }
    
    @isTest
    private static void test_transferSelectedAccounts() {
        String createdDate = String.valueOf(System.today());
        
		Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        
        User thisUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
        } 
        
        //List<Account> accounts = TestDataFactory.createAccounts(200);
        List<Account> accounts = TestDataFactory.createAccounts(100);
        List<Account> toInsert = new List<Account>();
        for (Account acct: accounts ){
            acct.OwnerId = UserInfo.getUserId();
            acct.R12_Sales__c = 1;
            acct.PowerPass_Account_Created_Date__c = System.Today();
            toInsert.add(acct);
        }
        insert toInsert;

        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: toInsert[0].Id];

        Test.startTest();
        Database.executebatch(new SM_BulkAccountTransferBatch('transferSelectedAccounts', acc, UserInfo.getUserId(), users[0].Id, users[0].Id, 'Test',  createdDate, '<=', null));
        Test.stopTest();
    }
    
    @isTest
    private static void test_transferAccountPlan_AM() {
        String createdDate = String.valueOf(System.today());
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> userTS = TestDataFactory.createUsers(2, p.Id);
        
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        List<User> userAM = TestDataFactory.createUsers(2, pAM.Id);
        
        User thisUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert userTS;
            insert userAM;
        }
        
        List<Account> accounts = TestDataFactory.createAccounts(1);
        List<Account> toInsert = new List<Account>();
        for (Account acct: accounts ){
            acct.OwnerId = userAM[0].Id;
            acct.R12_Sales__c = 1;
            acct.PowerPass_Account_Created_Date__c = System.Today();
            toInsert.add(acct);
        }
        insert toInsert;
        
        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: toInsert[0].Id];
        
        List<Contact> contacts = TestDataFactory.createContacts(toInsert[0].Id, toInsert[0].OwnerId, 1);
        insert contacts;
        /*
        Id acctPlanRTId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account_Plan__c' AND DeveloperName = 'Builders'].Id;
        Account_Plan__c ap1 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = toInsert[0].Id, Status__c = 'Active', Start_Date__c = Date.newInstance(2022, 6, 1), 
			End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000, Beaumont_Tiles__c = 55,
			S_I__c = 45, Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        Account_Plan__c ap2 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = toInsert[0].Id, Status__c = 'Draft', Start_Date__c = Date.newInstance(2022, 6, 1), 
			End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000, Beaumont_Tiles__c = 55,
			S_I__c = 45, Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        insert new List<Account_Plan__c>{ap1, ap2};
		*/ 
		Test.startTest();
        	Database.executebatch(new SM_BulkAccountTransferBatch('transferSelectedAccounts', acc, userAM[0].Id, userAM[1].Id, userAM[1].Id, 'Test',  createdDate, '<=', null));
        Test.stopTest();
    }
    
    @isTest
    private static void test_transferAccountPlan_TS() {
        String createdDate = String.valueOf(System.today());
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> userTS = TestDataFactory.createUsers(1, p.Id);
        
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        List<User> userAM = TestDataFactory.createUsers(1, pAM.Id);
        
        User thisUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert userTS;
            insert userAM;
        }
        
        List<Account> accounts = TestDataFactory.createAccounts(1);
        List<Account> toInsert = new List<Account>();
        for (Account acct: accounts ){
            acct.OwnerId = userAM[0].Id;
            acct.R12_Sales__c = 1;
            acct.PowerPass_Account_Created_Date__c = System.Today();
            toInsert.add(acct);
        }
        insert toInsert;
        
        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: toInsert[0].Id];
        
        List<Contact> contacts = TestDataFactory.createContacts(toInsert[0].Id, toInsert[0].OwnerId, 1);
        insert contacts;

        Id acctPlanRTId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account_Plan__c' AND DeveloperName = 'Builders'].Id;
        Account_Plan__c ap1 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = toInsert[0].Id, Status__c = 'Active', Start_Date__c = Date.newInstance(2022, 6, 1), 
			End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000,
			Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        Account_Plan__c ap2 = new Account_Plan__c(RecordTypeId = acctPlanRTId, OwnerId = userAM[0].Id, Account__c = toInsert[0].Id, Status__c = 'Draft', Start_Date__c = Date.newInstance(2022, 6, 1), 
			End_Date__c = Date.newInstance(2022, 12, 31), Contact__c = contacts[0].Id, Call_Cycle_Frequency__c = 'Weekly', Potential_Value_PA__c = 50000,
			Target_Wallet_Share__c = 35, Target_Segment_A__c = 'Slab', Target_Product_A__c = 'Concrete Products');
        insert new List<Account_Plan__c>{ap1, ap2};

		Test.startTest();
        	Database.executebatch(new SM_BulkAccountTransferBatch('transferSelectedAccounts', acc, userAM[0].Id, userTS[0].Id, userAM[0].Id, 'Test',  createdDate, '<=', null));
        Test.stopTest();
    }
    
}