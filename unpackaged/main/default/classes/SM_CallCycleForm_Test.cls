/*******************************************************************************************************
* Class Name      	: SM_CallCycle_Test
* Description		: Test class for SM_CallCycle, for Call Cycle Form part, not the algorithm part
* Author          	: Simplus - Yi Zhang
* Created On      	: 01/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              01/10/2020		1000				Initial version
******************************************************************************************************/
@isTest
private class SM_CallCycleForm_Test {
    @isTest
    static void testCallCycleFormInitAndUpdate() {
        // stores
        List<Store__c> stores = TestDataFactory.createStores(1);
        insert stores;
        // insert account
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].Power_Pass_Account_Number__c = String.valueOf(Math.random());
        accounts[0].Home_Store__c = stores[0].Id;
        insert accounts;
        Account a = accounts[0];
        User u = new User(Id = UserInfo.getUserId());
        // Tasks, events, contacts
        List<Task> tasks = new List<Task>();
        tasks.add(new Task(RecordTypeId = DM_RecordType.rtId_Task_CallCycle, WhatId = a.Id, OwnerId = u.Id, Subject = 'Call',
                           Status = 'Open', Sub_type__c = 'Engagement Call', ActivityDate = Date.today().addDays(10)));
		List<Event> events = new List<Event>();
        events.add(new Event(StartDateTime = Datetime.now().addDays(10), DurationInMinutes = 30, Sub_type__c = 'Engagement Call', 
                             Status__c = 'Open', WhatId = a.Id, OwnerId = u.Id, Subject = 'Call'));
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName = 'CCF Contact', LastName = 'LN', 
                             Email = 'test@acme.com', AccountId = a.Id));
        
        Test.startTest();
        SM_CallCycle.callCycleFormInit(a.Id, 'Small', 'flowScreen');
        SM_CallCycle.callCycleFormInit(a.Id, 'Large', 'flowScreen');
        SM_CallCycle.callCycleFormInit(a.Id, 'Large', 'recordPage');
        insert tasks;
        insert events;
        SM_CallCycle.callCycleFormInit(a.Id, 'Small', 'flowScreen');
        SM_CallCycle.callCycleFormInit(a.Id, 'Large', 'flowScreen');
        SM_CallCycle.callCycleFormInit(a.Id, 'Large', 'recordPage');
        
        
        try {
            SM_CallCycle.updateAccountAndActivity(a, tasks[0], events[0], new Task(ActivityDate = Date.today().addDays(11)), 'Account', 'Australia', a.Id, 'test@acme.com');
        } catch(Exception e) {
            // no contact in the system
        }
        insert contacts;
        events[0].Id = null;
        SM_CallCycle.updateAccountAndActivity(a, tasks[0], events[0], new Task(ActivityDate = Date.today().addDays(11)), 'Account', 'Australia', a.Id, 'test@acme.com');
        SM_CallCycle.updateAccountAndActivity(a, tasks[0], events[0], new Task(ActivityDate = Date.today().addDays(11)), 'Contact', 'Australia', contacts[0].Id, 'test@acme.com');
        Test.stopTest();
    }
}