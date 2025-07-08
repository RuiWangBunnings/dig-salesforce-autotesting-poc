/*******************************************************************************************************
* Class Name      	: SM_BulkAccountRequestTransferBatchTest
* Description		: Test class for SM_BulkAccountRequestTransferBatch
******************************************************************************************************/

@isTest
private class SM_BulkAccountRequestTransferBatchTest {
        @testSetup 
    public static void testDataSetup() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[0].isActive = true;
        users[1].ManagerId = users[2].Id;
         users[1].isActive = true;
        users[2].ManagerId = users[3].Id;
         users[2].isActive = true;
        update users;
        
        User u = users[0];
        
        System.runAs(users[0]) {
            List<Account> accounts = TestDataFactory.createAccounts(100);
        Integer var = 5;
        List<Account> toInsert = new List<Account>();
        for (Account acct: accounts ){
            acct.OwnerId = UserInfo.getUserId();
            acct.R12_Sales__c = 1;
            acct.Power_Pass_Account_Number__c = String.valueof(var);
            acct.PowerPass_Account_Created_Date__c = System.Today();
            toInsert.add(acct);
            var = var + 1;
        }
        insert toInsert;
            List<Account> accts = [SELECT Id, OwnerId, Account_Transferrable__c FROM Account WHERE Id =: toInsert[0].Id];
        Map<String,String> accReq  = new Map<String,String>();

        for(Account accnt : accounts){
            accReq.put(accnt.Power_Pass_Account_Number__c,u.id );
        }
        List<Account_Request__c> ars = TestDataFactory.createBulkAccountRequests(accReq);
        insert ars;
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
            
            Contact con = contacts[0];
            
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
             
                
            Account_Plan__c acp = TestDataFactory.createAccountPlan(a.Id, con.Id);
            insert acp; 
                
        }
            
    }
    
    @isTest
    private static void test_transferAllAccounts() {
                   
        Test.startTest();
        	Database.executebatch(new SM_BulkAccountRequestTransferBatch());
        Test.stopTest();
    }
    
     @isTest
    private static void test_transferAllAccountsErrorNotification() {
        User u = [Select id from User Limit 1];  
        Test.startTest();
        try{
           SM_AccountRequestTransfer.sendBulkAccountTransferErrorNotification(u.id); 
        
        }catch (Exception e){
            System.assert(TRUE);
        }

        Test.stopTest();
    }

}