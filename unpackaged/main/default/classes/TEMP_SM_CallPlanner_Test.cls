/*******************************************************************************************************
* Class Name      	: TEMP_SM_CallPlanner_Test
* Description		: Test class for CallPlanner_ManualCreateBatch, CallPlanner_ManualDeleteBatch, TEMP_SM_CallPlanner
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS         	15/11/2021		1000				Initial version
* Bunnings Dev			27/09/2022		2000				Fix test class issue
*****************************************************************************************************/
@isTest
public class TEMP_SM_CallPlanner_Test {

    @testSetup static void setup() {

        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        User u = TestDataFactory.createUsers(1, p.Id)[0];
        insert u;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // create call targets
            List<Call_Targets__c> targets = new List<Call_Targets__c>{
                new Call_Targets__c(Team_Member__c = u.Id, Start_Date__c = Date.today())
            };
            insert targets;
        }
        
        System.runAs(u) {
            // create accounts
            Id accountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AU_Prospect').getRecordTypeId();
            List<Account> accounts = TestDataFactory.createAccounts(3);
            for(Account a : accounts) {
                a.RecordTypeId = accountRTId;
            }
            insert accounts;
            
            // create contacts
            Id userId = UserInfo.getUserId();
            List<Contact> contacts = new List<Contact>();
            contacts.addAll(TestDataFactory.createContacts(accounts[0].Id, userId, 1));
            contacts.addAll(TestDataFactory.createContacts(accounts[1].Id, userId, 2));
            contacts.addAll(TestDataFactory.createContacts(accounts[2].Id, userId, 3));
            insert contacts;
            contacts[0].Target_Call_Frequency__c = 'Daily';
            contacts[0].Recurrence__c = Date.today().addYears(1);
            contacts[0].First_Day__c = Date.today();
            update contacts[0];
            insert SM_CallPlanner.createEvents('test', u.Id, contacts[0].Id, accounts[0].Id, Date.today(), Date.today().addDays(30), 'Daily', '');
        }
    }
    
    @isTest
    static void testBatchDelete() {
        Database.executeBatch(new CallPlanner_ManualDeleteBatch(0), 100);
    }

    @isTest
    static void testBatchInsert() {
        Database.executeBatch(new CallPlanner_ManualCreateBatch(), 20);
    }

    @isTest
    public static void testExecutePlan() {
        Test.startTest();

            // prepare account
            Account a = [SELECT Id FROM Account LIMIT 1];
            a.Share_of_Wallet__c = 50;
    
            List<Contact> contacts = [SELECT Id, AccountId,Name,First_Day__c,OwnerId,Recurrence__c,Target_Call_Frequency__c,Call_Days__c FROM Contact LIMIT 10];
            List<Contact> oldContacts = new List<Contact>();
            List<Contact> newContacts = new List<Contact>();
                
            // new contact
            newContacts.add(new Contact(Id = contacts[0].Id, AccountId = contacts[0].AccountId,
            Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30));
            // delete contact
            oldContacts.add(new Contact(Id = contacts[1].Id, AccountId = contacts[1].AccountId,
            Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30));
            
    
            // update first day
            Contact c = new Contact(Id = contacts[2].Id, AccountId = contacts[2].AccountId,
            Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30);
            oldContacts.add(c);
            c = c.clone(true, true, false, false);
            c.First_Day__c = Date.today() + 10;
            newContacts.add(c);
    
            Contact cont1 = new Contact(AccountId = contacts[0].AccountId, Phone = '34343431', LastName = 'Data', Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), 
                                        Recurrence__c = Date.today() );
            insert cont1;
            
            Contact cont2 = new Contact(AccountId = contacts[0].AccountId, Phone = '34343432', LastName = 'Data', Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), 
                                        Recurrence__c = Date.today() +30);
            insert cont2;
            
            Contact cont3 = new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), 
                                        Recurrence__c = Date.today() +30);
            insert cont3;
            
            oldContacts.add(cont1);
            oldContacts.add(cont2);
            oldContacts.add(cont3);
            Contact cont4 = new Contact(AccountId = contacts[0].AccountId, Phone = '34343433', LastName = 'Data', Target_Call_Frequency__c = 'Weekly', First_Day__c = Date.today(), 
                                        Recurrence__c = Date.today() +30);
            insert cont4;
            newContacts.add(cont4);
            
            cont2 = cont2.clone(true, true, false, false);
            cont2.First_Day__c = Date.today() - 10;
            newContacts.add(cont2);
            
            cont3 = cont3.clone(true, true, false, false);
            cont3.Target_Call_Frequency__c = 'Weekly';
            newContacts.add(cont3);
            
            cont4 = cont4.clone(true, true, false, false);
            cont4.Recurrence__c = Date.today() + 10;
            oldContacts.add(cont4);
            
            TEMP_SM_CallPlanner.executePlans(new List<Account>{a}, oldContacts, newContacts);

        Test.stopTest();
    }
    
    @isTest
    public static void testOtherMethods() {
        
        Test.startTest();
            // prepare account
            Account a = [SELECT Id FROM Account LIMIT 1];
            a.Share_of_Wallet__c = 50;
    
            List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 10];
            List<Contact> oldContact = new List<Contact>{new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), 
                                                                  Recurrence__c = Date.today() +34)};
            insert oldContact;
        
            List<Contact> newContact = new List<Contact>{new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = 'Weekly', First_Day__c = Date.today(), 
                                                       Recurrence__c = Date.today() +30)};
            insert newContact;
        
            Contact Cont = new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = null, First_Day__c = Date.today(), 
                                                       Recurrence__c = Date.today() +30);
            insert Cont;
        
            String subject = Cont.Account.Name + ' - ' + Cont.Name;
            Id eventOwnerId = Cont.Account.OwnerId;
            Id accountId = Cont.AccountId;
        Test.stopTest();
    }
}