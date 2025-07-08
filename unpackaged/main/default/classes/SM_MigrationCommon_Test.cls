/*******************************************************************************************************
* Class Name      	: SM_MigrationCommon_Test
* Description		: Test class for SM_MigrationQuoteSyncBatch
                                     SM_MigrationTaskBatch
                                     SM_MigrationEventBatch
* Author          	: Simplus - Purba Ghosh
* Created On      	: 24/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Purba Ghosh           24/09/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_MigrationCommon_Test {
    @isTest
    public static void testMigrationQuoteSyncBatch() {
        //  Set up data
        List<Opportunity> lstOpportunities = new List<Opportunity>{
            new Opportunity(Name = 'COS 101', Country__c = Constants.COUNTRY_AU, StageName = 'New', CloseDate = system.today()),
            new Opportunity(Name = 'COS 102', Country__c = Constants.COUNTRY_AU, StageName = 'New', CloseDate = system.today()),
            new Opportunity(Name = 'COS 103', Country__c = Constants.COUNTRY_NZ, StageName = 'New', CloseDate = system.today())
        };
        insert lstOpportunities;

        List<Quote> lstQuotes = new List<Quote>{
            new Quote(Name = 'COS 101', Country__c = Constants.COUNTRY_AU, Type__c = 'Quote', OpportunityId = lstOpportunities[0].Id, ExpirationDate = system.today()+2),
            new Quote(Name = 'COS 102', Country__c = Constants.COUNTRY_AU, Type__c = 'Quote', OpportunityId = lstOpportunities[1].Id, ExpirationDate = system.today()+3),
            new Quote(Name = 'COS 103', Country__c = Constants.COUNTRY_NZ, Type__c = 'Quote', OpportunityId = lstOpportunities[2].Id, ExpirationDate = system.today()+4)
        };
        insert lstQuotes;
   
        Test.startTest();
        // schedulable (not immediate)
        Id jobId = System.schedule('Batch Quote Sync', 
            '0 0 3 * * ?', 
            new SM_MigrationQuoteSyncBatch());

        // batchable
        Database.executebatch(new SM_MigrationQuoteSyncBatch());
        Test.stopTest();

        // Assertions
        System.assertEquals([SELECT Id, Primary_Quote_Expiry_Date__c, SyncedQuoteId FROM Opportunity WHERE Id = :lstOpportunities[0].Id].Primary_Quote_Expiry_Date__c, [SELECT Id, ExpirationDate FROM Quote WHERE Id = :lstQuotes[0].Id].ExpirationDate);
        System.assertEquals([SELECT Id, Primary_Quote_Expiry_Date__c ,SyncedQuoteId FROM Opportunity WHERE Id = :lstOpportunities[0].Id].SyncedQuoteId, [SELECT Id FROM Quote WHERE Id = :lstQuotes[0].Id].Id);
        System.assertEquals([SELECT Id, Primary_Quote_Expiry_Date__c, SyncedQuoteId FROM Opportunity WHERE Id = :lstOpportunities[1].Id].Primary_Quote_Expiry_Date__c, [SELECT Id, ExpirationDate FROM Quote WHERE Id = :lstQuotes[1].Id].ExpirationDate);
        System.assertEquals([SELECT Id, Primary_Quote_Expiry_Date__c ,SyncedQuoteId FROM Opportunity WHERE Id = :lstOpportunities[1].Id].SyncedQuoteId, [SELECT Id FROM Quote WHERE Id = :lstQuotes[1].Id].Id);

    }

    @isTest
    public static void testMigrationTaskBatch() {
        //  Set up data
        List<Account> lstAccount = new List<Account>{
            new Account(Name = 'Test 1', Country__c = Constants.COUNTRY_AU, Power_Pass_Account_Number__c = '1001'),
            new Account(Name = 'Test 2', Country__c = Constants.COUNTRY_AU, Power_Pass_Account_Number__c = '1002'),
            new Account(Name = 'Test 3', Country__c = Constants.COUNTRY_NZ, Power_Pass_Account_Number__c = '1003'),
            new Account(Name = 'Test 4', Country__c = Constants.COUNTRY_NZ, Power_Pass_Account_Number__c = '1004')
        };
        insert lstAccount;

        List<Task> lstTasks = new List<Task>{
            new Task(Subject = 'Call Cycle 1',  WhatId =  lstAccount[0].Id, ActivityDate = system.today()+2, Priority = 'High', RecordTypeId =  DM_RecordType.rtId_Task_CallCycle),
            new Task(Subject = 'Call Cycle 2',  WhatId =  lstAccount[1].Id, ActivityDate = system.today(), Priority = 'Low', RecordTypeId =  DM_RecordType.rtId_Task_CallCycle),
            new Task(Subject = 'Call Cycle 3',  ActivityDate = system.today()+5, Priority = 'High',  RecordTypeId =  DM_RecordType.rtId_Task_CallCycle)
        };
        insert lstTasks;
    
        Test.startTest();
        // schedulable (not immediate)
        Id jobId = System.schedule('Batch Task Sync', 
            '0 0 3 * * ?', 
            new SM_MigrationTaskBatch());

        // batchable
        Database.executebatch(new SM_MigrationTaskBatch());
        Test.stopTest();

        // Assertions
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[0].Id].Scheduled_Engagement_Call__c, [SELECT Id, ActivityDate FROM Task WHERE Id = :lstTasks[0].Id].ActivityDate);
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[1].Id].Scheduled_Engagement_Call__c, [SELECT Id, ActivityDate FROM Task WHERE Id = :lstTasks[1].Id].ActivityDate);
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[2].Id].Scheduled_Engagement_Call__c, null);
    }

    @isTest
    public static void testMigrationEventBatch() {
        //  Set up data
        List<Account> lstAccount = new List<Account>{
            new Account(Name = 'Test 1', Country__c = Constants.COUNTRY_AU, Power_Pass_Account_Number__c = '1001'),
            new Account(Name = 'Test 2', Country__c = Constants.COUNTRY_AU, Power_Pass_Account_Number__c = '1002'),
            new Account(Name = 'Test 3', Country__c = Constants.COUNTRY_NZ, Power_Pass_Account_Number__c = '1003'),
            new Account(Name = 'Test 4', Country__c = Constants.COUNTRY_NZ, Power_Pass_Account_Number__c = '1004')
        };
        insert lstAccount;

        List<Event> lstEvents = new List<Event>{
            new Event(Subject = 'Call Cycle 1',  WhatId =  lstAccount[0].Id, ActivityDate = system.today()+2, RecordTypeId =  DM_RecordType.rtId_Event_Standard, DurationInMinutes = 20, ActivityDateTime = Date.today(), Sub_type__c = Constants.EVENT_PURPOSE_ENGAGEMENT_CALL),
            new Event(Subject = 'Call Cycle 2',  WhatId =  lstAccount[1].Id, ActivityDate = system.today(), RecordTypeId =  DM_RecordType.rtId_Event_Standard, DurationInMinutes = 20, ActivityDateTime = Date.today(), Sub_type__c = Constants.EVENT_PURPOSE_ENGAGEMENT_CALL),
            new Event(Subject = 'Call Cycle 3',  ActivityDate = system.today()+5, RecordTypeId =  DM_RecordType.rtId_Event_Standard, DurationInMinutes = 20, ActivityDateTime = Date.today(), Sub_type__c = Constants.EVENT_PURPOSE_ENGAGEMENT_CALL),
            new Event(Subject = 'Recurring Event', IsRecurrence = true, RecurrenceStartDateTime = Date.today() + 2, RecurrenceEndDateOnly = Date.today() + 2, RecurrenceType = 'RecursDaily', RecurrenceInterval = 1, ActivityDate = Date.today() + 2, RecordTypeId =  DM_RecordType.rtId_Event_Standard, DurationInMinutes = 20, ActivityDateTime = Date.today() + 2, Status__c = 'Completed')        
        };
        insert lstEvents;
    
        Test.startTest();
        // schedulable (not immediate)
        Id jobId = System.schedule('Batch Event Sync', 
            '0 0 3 * * ?', 
            new SM_MigrationEventBatch());

        // batchable
        Database.executebatch(new SM_MigrationEventBatch());
        Test.stopTest();

        // Assertions
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[0].Id].Scheduled_Engagement_Call__c, [SELECT Id, ActivityDate FROM Event WHERE Id = :lstEvents[0].Id].ActivityDate);
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[1].Id].Scheduled_Engagement_Call__c, [SELECT Id, ActivityDate FROM Event WHERE Id = :lstEvents[1].Id].ActivityDate);
        System.assertEquals([SELECT Id, Scheduled_Engagement_Call__c FROM Account WHERE Id = :lstAccount[2].Id].Scheduled_Engagement_Call__c, null);
    }
}