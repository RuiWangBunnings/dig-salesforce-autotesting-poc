/*******************************************************************************************************
* Class Name      	: BulkAccountTransferControllerTest
* Description		: Test class for BulkAccountTransferController
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           06/01/2021		1000				Initial version - CCRM-170
* Simplus MS           31/01/2021       1001                New method to cover checkUserProfile logic
* Simplus MS           26/02/2021       1002                Updated test methods to cover the newly added transferAccountRelatedRecords method
* Simplus MS           27/04/2021       1003                Updated test methods to cover the newly added added parameters 
* Simplus MS           25/11/2021       1004                CCRM15-55: Bulk Account Transfer additional filters.
* Simplus MS           22/12/2021       1005                CCRM15-421 Bulk Account Transfer confirmation prompt.
* Simplus MS 		   19/01/2022		1001				Increased test code coverage
******************************************************************************************************/

@isTest
private class BulkAccountTransferControllerTest {
    
    @isTest
    private static void test_init() {

        List<Account> accounts = TestDataFactory.createAccounts(10);
        insert accounts;

        String createdDate = String.valueOf(System.today());
        
        String filter = '[{"fieldName":"R12_Sales__c","operator":"=","value":"464663","type":"number","index":10},{"fieldName":"BillingPostalCode","operator":"=","value":"363677","index":20},{"fieldName":"Primary_Segment__c","operator":"=","value":"[\\"Apprentice\\"]","type":"picklist","index":30},{"fieldName":"Secondary_Segment__c","operator":"=","value":"[\\"CCRM15-55 Segment\\"]","type":"picklist","index":40},{"fieldName":"BillingCity","operator":"%%","value":"Pune","index":50},{"fieldName":"Last_Owner_Transfer_Date__c","operator":"=","value":"2021-11-20","type":"date","index":60},{"fieldName":"Assigned_Store__c","operator":"=","value":"CCRM15-55-Store","index":70},{"fieldName":"Previous_Owner__c","operator":"%%","value":"Asma Saber","index":80},{"fieldName":"R12_Top_Spend_Location_1__c","operator":"=","value":"CCRM15-55-Store","index":90},{"fieldName":"R12_Top_Spend_Location_2__c","operator":"=","value":"CCRM15-55-Store","index":100},{"fieldName":"Umbrella_Group__c","operator":"=","value":"a0G9D000003rIDDUA2","index":110}]';

        Test.startTest();
        BulkAccountTransferController.CustomSearchWrapper response = BulkAccountTransferController.init('Account', UserInfo.getUserId(), createdDate, '>=', filter, null, null);
        String userId = UserInfo.getUserId();
        List<Account> data = BulkAccountTransferController.getAccounts(response.displayFields, userId, 0, 25, null, null, createdDate, '>=', null);

        Test.stopTest();
    }
	
    @isTest
    private static void test_checkContractsForAllAccounts(){
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
		List<User> users = TestDataFactory.createUsers(2, p.Id);
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }

        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(accounts[0].OwnerId, 'Australia', 1);
        insert contracts;

        Test.startTest();
        Map<String, String> resultMap = BulkAccountTransferController.checkContractsForAllAccounts(UserInfo.getUserId(), users[0].Id);
        Test.stopTest();
    }

    @isTest
    private static void test_checkContractsForSelectedAccounts(){
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
		List<User> users = TestDataFactory.createUsers(2, p.Id);
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }

        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(accounts[0].OwnerId, 'Australia', 1);
        insert contracts;

        Test.startTest();
        Map<String, String> resultMap = BulkAccountTransferController.checkContractsForSelectedAccounts(accounts, UserInfo.getUserId(), users[0].Id);
        Test.stopTest();
    }

    @isTest
    private static void test_transferAllAccounts(){
        String createdDate = String.valueOf(System.today());
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
		List<User> users = TestDataFactory.createUsers(2, p.Id);
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }

        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        accounts[0].Transfer_approval_status__c = 'Approved';
        insert accounts;

        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: accounts[0].Id];

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
        String result = BulkAccountTransferController.transferAccounts('transferAllAccounts', null, UserInfo.getUserId(), users[0].Id, users[1].Id, 'test', createdDate, '<=', filter);
        Test.stopTest();


    }

    @isTest
    private static void test_transferSelectedAccounts(){
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
		List<User> users = TestDataFactory.createUsers(2, p.Id);
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }

        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        //accounts[0].Transfer_approval_status__c = 'Approved';
        insert accounts;

        List<Account> acc = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: accounts[0].Id];

        List<Contract__c> contracts = TestDataFactory.createNoExpiredContracts(UserInfo.getUserId(), 'Australia', 1);
        insert contracts;

        List<Id> contractIdList = new List<Id>();
        for(Contract__c contract : contracts){
            contractIdList.add(contract.Id);
        }

        List<Customer_Contract__c> customerContract = TestDataFactory.createCustomerContracts((String)acc[0].Id, contractIdList);
        insert customerContract;

        List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId((String)acc[0].Id, UserInfo.getUserId(), 1);
        insert tasks;

        List<Event> events = TestDataFactory.createOpenEventsWithWhatId((String)acc[0].Id, UserInfo.getUserId(), 1);
        insert events;

        List<Opportunity> oppts = TestDataFactory.createOpenOpportunities(acc[0].Id, UserInfo.getUserId(), 1);
        insert oppts;

        List<Contact> contacts = TestDataFactory.createContacts(acc[0].Id, UserInfo.getUserId(), 1);
        insert contacts;

        List<Case> cases = TestDataFactory.createOpenCases(acc[0].Id, UserInfo.getUserId(), 1);
        insert cases;

        List<Spend_Band__c> sb = TestDataFactory.createSpendBands(new List<Double>{6000, 7000}, new List<String>{'AT_TEST_03', 'AT_TEST_04'}, 'Australia');
        upsert sb Spend_Band_ID__c;

        List<Spend_Band_Review__c> sbreviewList = new List<Spend_Band_Review__c>{ TestDataFactory.createSpendBandReview(acc[0].Id, sb[0].Id, sb[1].Id, 'Australia') };
        insert sbreviewList;

        Test.startTest();
        String result = BulkAccountTransferController.transferAccounts('transferSelectedAccounts', acc, UserInfo.getUserId(), users[0].Id, users[1].Id, 'test', String.valueOf(System.today()), '<=', null);
        Test.stopTest();
    }

    @isTest
    private static void test_checkUserProfile() {

        List<Account> accounts = TestDataFactory.createAccounts(10);
        insert accounts;

        Profile p_lcm = [SELECT Id FROM Profile WHERE Name =: Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
		List<User> user_lcm = TestDataFactory.createUsers(1, p_lcm.Id);
		
        User thisUser_lcm = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser_lcm) {
            insert user_lcm;
        }

        Profile p_os = [SELECT Id FROM Profile WHERE Name =: Constants.ORG_SALES_MANAGER_PROFILEENAME LIMIT 1];
		List<User> user_os = TestDataFactory.createUsers(1, p_os.Id);
		
        User thisUser_os = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser_os) {
            insert user_os;
        }
        
        Test.startTest();
        BulkAccountTransferController.CustomSearchWrapper response1 = BulkAccountTransferController.checkUserProfile(user_lcm[0].Id);
        BulkAccountTransferController.CustomSearchWrapper response2 = BulkAccountTransferController.checkUserProfile(user_os[0].Id);
        Test.stopTest();
    }

    @isTest
    private static void test_findRecords() {

        List<Account> accounts = TestDataFactory.createAccounts(10);
        insert accounts;
        
        Test.startTest();
        List<sobject> response = BulkAccountTransferController.findRecords('TestCompany', 'Account');
        Test.stopTest();
    }

    @isTest
    private static void test_fetchPrimarySegment() {

        List<Segment__c> segmentList =new List<Segment__c>();
        for(Integer i=0; i <5; i++){
            segmentList.add(new Segment__c(Primary__c = 'Test Segment'+i));
        }
        insert segmentList;
        
        Test.startTest();
        List<String> response = BulkAccountTransferController.fetchPrimarySegment();
        Test.stopTest();
    }

    @isTest
    private static void test_findRecordsByNameKey() {

        List<Segment__c> segmentList =new List<Segment__c>();
        for(Integer i=0; i <5; i++){
            segmentList.add(new Segment__c(Name = 'Test Segment'+i, Primary__c = 'Test Segment'+i));
        }
        insert segmentList;
        
        Test.startTest();
        List<sObject> response = BulkAccountTransferController.findRecordsByNameKey('Test Segment', new List<Id>{segmentList[0].Id,segmentList[1].Id});
        Test.stopTest();
    }

    @isTest
    private static void test_getNewAccountOwnerName() {

        Test.startTest();
        String newAccountOwnerName = BulkAccountTransferController.getNewAccountOwnerName(UserInfo.getUserId());
        Test.stopTest();
        
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(newAccountOwnerName, currentUser.Name, 'New Account Owner Name not get correctly.');
    }
}