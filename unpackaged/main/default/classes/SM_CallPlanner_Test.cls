/*******************************************************************************************************
* Class Name        : SM_CallPlanner_Test
* Description       : Test class for SM_CallPlanner
* Author            : Simplus - Yi Zhang
* Created On        : 02/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              02/07/2020      1000                Initial version
* Bunnings Dev			05/07/2022		2000				SFSUP-852 - Fix test class issue
******************************************************************************************************/
@isTest
public class SM_CallPlanner_Test {

    @testSetup static void setup() {
       
        UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'North West Victoria AM' LIMIT 1];
        
        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        User u = TestDataFactory.createUsers(1, p.Id)[0];
        insert u;
        u.UserRoleId = ur.Id;
        update u;      
                
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // create call targets
            List<Call_Targets__c> targets = new List<Call_Targets__c>{
                new Call_Targets__c(Team_Member__c = u.Id, Start_Date__c = Date.today())
            };
            insert targets;                        
        }
        System.runAs(u) {
            // create accounts
            Id accountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AU_Customer').getRecordTypeId();
            List<Account> accounts = TestDataFactory.createAccounts(3);
            for(Account a : accounts) {
                //a.RecordTypeId = accountRTId; // SFSUP-852
                a.Country__c = 'Australia';
            }
            insert accounts;
            // create contacts            
            Id userId = UserInfo.getUserId();
            List<Contact> contacts = new List<Contact>();
            contacts.addAll(TestDataFactory.createContacts(accounts[0].Id, userId, 1));
            contacts.addAll(TestDataFactory.createContacts(accounts[1].Id, userId, 2));
            contacts.addAll(TestDataFactory.createContacts(accounts[2].Id, userId, 3));
            insert contacts;
        }
    }

    @isTest
    public static void testGetContacts() {

        Test.startTest();
        SM_CallPlanner.CallPlannerWrapper resp = SM_CallPlanner.getContacts(UserInfo.getUserId());
        User am = [SELECT Id FROM User WHERE Profile.Name = 'Account Manager' LIMIT 1];
        List<Call_Targets__c> targetsList = new List<Call_Targets__c>();
        Call_Targets__c target1 = new Call_Targets__c(Team_Member__c = am.Id, Start_Date__c = Date.today(), End_Date__c = null);
        targetsList.add(target1);
        Call_Targets__c target2 = new Call_Targets__c(Team_Member__c = am.Id, Start_Date__c = Date.today(), End_Date__c = Date.today()+2);
        targetsList.add(target2);
        insert targetsList;
        resp = SM_CallPlanner.getContacts(am.Id);
        Test.stopTest();
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
        
        SM_CallPlanner.executePlans(new List<Account>{a}, oldContacts, newContacts);

       /* List<Contact> oldCont = new List<Contact>{new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), 
                                                              Recurrence__c = Date.today() +34)};
        insert oldCont;
        List<Contact> newCont = new List<Contact>();
            Contact cont = new Contact(AccountId = contacts[0].AccountId, Phone = '3434343', LastName = 'Data', Target_Call_Frequency__c = 'Weekly', First_Day__c = Date.today(), 
                                                   Recurrence__c = Date.today() +30);
        insert cont;
        newCont.add(cont);
        oldCont.add(cont);
        SM_CallPlanner.executePlans(new List<Account>{a}, oldCont, newCont);*/
        
        //SM_CallPlanner.executePlans(new List<Account>{a}, oldContacts, newContacts);
        Test.stopTest();
    }
    
    @isTest
    public static void testDeleteScenario() {
                
        Account a = [SELECT Id FROM Account LIMIT 1];       
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 10];
        List<Contact> oldContacts = new List<Contact>();
        List<Contact> newContacts = new List<Contact>();
        
        newContacts.add(new Contact(Id = contacts[0].Id, AccountId = contacts[0].AccountId,
                                    Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30));        
        oldContacts.add(new Contact(Id = contacts[1].Id, AccountId = contacts[1].AccountId,
                                    Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30));
        
        // update first day
        Contact c = new Contact(Id = contacts[2].Id, AccountId = contacts[2].AccountId,
                                Target_Call_Frequency__c = 'Daily', First_Day__c = Date.today(), Recurrence__c = Date.today() +30);
        oldContacts.add(c);
        c = c.clone(true, true, false, false);
        c.First_Day__c = Date.today() + 10;
        newContacts.add(c);
        
        //delete oldContacts; // SFSUP-852
                
        Test.startTest();        
        List<String> deleteEventClauses = new List<String>();        
        deleteEventClauses.add(SM_CallPlanner.generateClause(c.Id, oldContacts[0].First_Day__c, oldContacts[0].Recurrence__c));
        
        string deleteEventQuery;
        String DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        System.debug('deleteEventClauses '+deleteEventClauses);
        if(deleteEventClauses.size() > 0) {
            DateTime now = DateTime.now();
            deleteEventQuery = 'SELECT Id ' 
                + 'FROM Event '
                + 'WHERE Planned_Call__c = true ' 
                + 'AND Status__c = \'Open\' ' 
                + 'AND StartDateTime >= ' + now.formatGmt(DATETIME_FORMAT) + ' '
                + 'AND (' + String.join(deleteEventClauses, ' OR ') + ')';
        }        
        List<Event> eventsToDelete = new List<Event> ();
        eventsToDelete = Database.query(deleteEventQuery);
        eventsToDelete = SM_CallPlanner.checkDMLOperationRecords(eventsToDelete, false);        
        system.debug('size of 99  '+eventsToDelete.size());        
        SM_CallPlannerBatchDML DCPB = new SM_CallPlannerBatchDML(eventsToDelete,false, false);
        ID BatchId = Database.executeBatch(DCPB, 500);    
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
        // SM_CallPlanner.rebaseStartDate(newContact[0].First_Day__c, oldContact[0].Recurrence__c, newContact[0].Target_Call_Frequency__c);
        SM_CallPlanner.formatStartDate(Date.today());
        SM_CallPlanner.createEvents(subject,eventOwnerId,Cont.Id,accountId,Cont.First_Day__c,Cont.Recurrence__c,Cont.Target_Call_Frequency__c,Cont.Call_Days__c);
        Test.stopTest();
    }
}