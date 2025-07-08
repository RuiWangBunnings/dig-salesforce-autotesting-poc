@isTest
public class SM_CallPlannerBatchDMLTest {  
    
    @testsetup
    public static void testSetData() {     
        List<Account> accounts = TestDataFactory.createAccounts(1);        
        insert accounts;
        
        Id userId = UserInfo.getUserId();
        
        List<Contact> contacts = new List<Contact>();
        contacts.addAll(TestDataFactory.createContacts(accounts[0].Id, userId, 30));
        insert contacts;  
        
    }    
    
    @isTest
    public static void testInsertBatchScenario() {        
        
        Account a = [SELECT Id FROM Account LIMIT 1];       
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 10];
        List<Contact> newContacts = new List<Contact>();      
        for(integer i=0; i<10; i++){
            newContacts.add(new Contact
                            (AccountId = contacts[i].AccountId
                             , LastName = 'tL'+i
                             , Email ='abc'+i+'@gmail.com'
                             , Target_Call_Frequency__c = 'Daily'
                             , First_Day__c = Date.today()
                             , Recurrence__c = Date.today() +30));
        }         
        insert newContacts; 
        
        Test.startTest();
        Map<Id, Contact> newContactMap = new Map<Id, Contact>(newContacts);        
        List<String> accountIds = new List<String>();
        for(Contact c : newContactMap.values()) {
            accountIds.add(c.AccountId);
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>(DM_Account.getAccounts(accountIds));        
        List<Event> newEvents = new List<Event>();        
        for(Id contactId: newContactMap.keySet()) {
            Contact newContact = newContactMap.get(contactId);                
            String subject = accountMap.get(newContact.AccountId).Name + ' - ' + newContact.Name;
            Id eventOwnerId = accountMap.get(newContact.AccountId).OwnerId;
            Id accountId = newContact.AccountId;            
            newEvents.addAll(SM_CallPlanner.createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
        } 
        
        newEvents = SM_CallPlanner.checkDMLOperationRecords(newEvents, true);
       // system.debug('size of 89  '+newEvents.size());        
        SM_CallPlannerBatchDML CPB = new SM_CallPlannerBatchDML(newEvents, true, false);
        SM_CallPlannerBatchDML CPB1 = new SM_CallPlannerBatchDML(newEvents, false, false);
        ID BatchId = Database.executeBatch(CPB, 500);        
        Database.executeBatch(CPB1,500); 
        Test.stopTest();        
       // system.assertequals(230, newEvents.size());
    }
    
    
    @isTest
    public static void testDeleteBatchScenario() {
        
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
        
        delete oldContacts;
        
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
}