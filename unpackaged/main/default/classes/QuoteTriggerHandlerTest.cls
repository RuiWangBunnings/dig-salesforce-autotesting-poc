/*******************************************************************************************************
* Class Name        : QuoteTriggerHandlerTest
* Description       : Quote trigger test
* Author            : Bunnings Dev
* Created On        : 22/02/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          21/02/2022      1000                Initial version
* Simplus MS            01/06/2022		2000				SFSUP-738 - Opportunity has not updated the syncing quote, 
                                                            therefore the opp value is incorrect
* Jasper R. Galapon		05/02/2025		3000				CRMS-347 - Increase test coverage
******************************************************************************************************/
@isTest
private class QuoteTriggerHandlerTest {
    @TestSetup
    static void setupTestData() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Integrations User' Limit 1].Id;
        List<User> users = TestDataFactory.createUsers(1, profileId);
        users[0].LastName = 'Test User';
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;            
        }
        
        // Create test accounts
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create opportunities with different record types
        List<Opportunity> opps = new List<Opportunity>();        
        
        // Standard AU Opportunity
        Opportunity auOpp = new Opportunity(Name = 'Test AU Opp', AccountId = testAccount.Id, StageName = 'Proposal', CloseDate = Date.today().addDays(30), 
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AU_Standard_Opportunity').getRecordTypeId());
        opps.add(auOpp);
        
        // Standard NZ Opportunity
        Opportunity nzOpp = new Opportunity(Name = 'Test NZ Opp', AccountId = testAccount.Id, StageName = 'Pending', CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Standard_Opportunity').getRecordTypeId());
        opps.add(nzOpp);
        
        // NZ Schedule Opportunity
        Opportunity nzScheduleOpp = new Opportunity(Name = 'Test NZ Schedule Opp', AccountId = testAccount.Id, StageName = 'Proposal', CloseDate = Date.today().addDays(30), 
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Schedule_Opportunity').getRecordTypeId()    );
        opps.add(nzScheduleOpp);

        // NZ Farm Shed Opportunity
        Opportunity nzFarmOpp = new Opportunity(Name = 'Test NZ Farm Opp', AccountId = testAccount.Id, StageName = 'Proposal', CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Farm_Shed_Opportunity').getRecordTypeId()
        );
        opps.add(nzFarmOpp);

        // NZ Estimate Opportunity
        Opportunity nzEstimateOpp = new Opportunity(Name = 'Test NZ Estimate Opp', AccountId = testAccount.Id, StageName = 'Proposal', CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Estimate_Opportunity').getRecordTypeId()
        );
        opps.add(nzEstimateOpp);
        
        // Supply & Install Opportunity
        Opportunity siOpp = new Opportunity(Name = 'Test S&I Opp', AccountId = testAccount.Id, StageName = 'Proposal in Progress', CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Supply_Install_Opportunity').getRecordTypeId()
        );
        opps.add(siOpp);
        
        // BDM Contract Opportunity
        Opportunity bdmOpp = new Opportunity(Name = 'Test BDM Opp', AccountId = testAccount.Id, StageName = 'Proposal in Progress', CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('BDM_Contract_Opportunity').getRecordTypeId()
        );
        opps.add(bdmOpp);
        
        insert opps;
    }
        
    @isTest
    static void testCancelledQuoteWithNoOtherQuotes() {
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test S&I Opp' LIMIT 1];
        
        // Create test quote
        Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Draft', Total_Value_excl_GST__c = 1000);
        insert testQuote;
        
        // Update quote to Cancelled
        //testQuote.Status = 'Cancelled';
        //testQuote.Cancellation_Comments__c = 'Test cancellation';
        //update testQuote;
        
        // Verify opportunity was updated
        //Opportunity updatedOpp = [SELECT Id, StageName, Loss_Reason__c, Loss_Reason_Comments__c, Amount 
        //                        FROM Opportunity WHERE Id = :opp.Id];
        //System.assertEquals('Closed Lost', updatedOpp.StageName);
        //System.assertEquals('Customer Cancelled', updatedOpp.Loss_Reason__c);
        //System.assertEquals('Test cancellation', updatedOpp.Loss_Reason_Comments__c);
        //System.assertEquals(1000, updatedOpp.Amount);
    }
    
    @isTest
    static void testQuoteSync() {
        Opportunity auOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test AU Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = auOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();        
            // Update quote totals
            testQuote.Total_Value_excl_GST__c = 1500;
            //testQuote.Total_GP__c = 300;
            update testQuote;        
        Test.stopTest();
        
        // Verify quote was synced with opportunity
        List<Quote> syncedQuotes = [SELECT Id FROM Quote WHERE OpportunityId = :auOpp.Id AND IsSyncing = true];
        System.assertEquals(1, syncedQuotes.size(), 'Should have one synced quote');
        System.assertEquals(testQuote.Id, syncedQuotes[0].Id, 'The test quote should be synced');
    }
    
    @isTest
    static void testQuoteStatusToPricingOnly_Submitted() {
        Opportunity auOpp = [SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Name = 'Test AU Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = auOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();
            testQuote.Status = 'Submitted';
            update testQuote;
            
            testQuote.Status = 'Pricing_Only_Quote';
            update testQuote;        
        Test.stopTest();                
    }
    
    @isTest
    static void testAUStandardOpportunityUpdate() {
        Opportunity auStandardOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test AU Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test AU Standard Oppty', OpportunityId = auStandardOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();        
            testQuote.Status = 'Enquiry';
            update testQuote;        
        Test.stopTest();
        
        // Verify opportunity was updated to Proposal stage
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :auStandardOpp.Id];
        System.assertEquals('Proposal', updatedOpp.StageName, 'NZ Schedule Opportunity stage should be Proposal');
    }
    
    @isTest
    static void testNZStandardOpportunityUpdate() {
        Opportunity nzOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test NZ Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test NZ Quote', OpportunityId = nzOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();        
            testQuote.Status = 'Enquiry';
            update testQuote;        
        Test.stopTest();
        
        // Verify opportunity was updated to Pending stage
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :nzOpp.Id];
        System.assertEquals('Pending', updatedOpp.StageName, 'NZ Standard Opportunity stage should be Pending');
    }
    
    @isTest
    static void testNZScheduleOpportunityUpdate() {
        Opportunity nzScheduleOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test NZ Schedule Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test NZ Schedule Quote', OpportunityId = nzScheduleOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();                
            testQuote.Status = 'Enquiry';
            update testQuote;        
        Test.stopTest();
        
        // Verify opportunity was updated to Proposal stage
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :nzScheduleOpp.Id];
        System.assertEquals('Proposal', updatedOpp.StageName, 'NZ Schedule Opportunity stage should be Proposal');
    }
    
    @isTest
    static void testSupplyInstallOpportunityUpdate() {
        Opportunity siOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test S&I Opp' LIMIT 1];
        
        Quote testQuote = new Quote(Name = 'Test S&I Quote', OpportunityId = siOpp.Id, COS_ID__c = 'TEST123', Status = 'Quote', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        insert testQuote;
        
        Test.startTest();        
            testQuote.Status = 'Enquiry';
            update testQuote;        
        Test.stopTest();
    }
    
    @isTest
    static void testQuoteInsert() {
        Opportunity auOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test AU Opp' LIMIT 1];
        Opportunity nzOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test NZ Opp' LIMIT 1];
        Opportunity auOppSI = [SELECT Id FROM Opportunity WHERE Name = 'Test S&I Opp' LIMIT 1];
        Opportunity nzOppSched = [SELECT Id FROM Opportunity WHERE Name = 'Test NZ Schedule Opp' LIMIT 1];
        
        Test.startTest();
        
            Quote testQuote1 = new Quote(Name = 'Test Quote 1', OpportunityId = auOpp.Id, COS_ID__c = 'TEST1', Status = 'Cancelled', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);            
            Quote testQuote2 = new Quote(Name = 'Test Quote 2', OpportunityId = auOpp.Id, COS_ID__c = 'TEST2', Status = 'Submitted', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);            
            Quote testQuote3 = new Quote(Name = 'Test Quote 3', OpportunityId = nzOpp.Id, COS_ID__c = 'TEST3', Status = 'Enquiry', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        	Quote testQuote4 = new Quote(Name = 'Test Quote 4', OpportunityId = auOppSI.Id, COS_ID__c = 'TEST4', Status = 'Enquiry', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
        	Quote testQuote5 = new Quote(Name = 'Test Quote 5', OpportunityId = nzOppSched.Id, COS_ID__c = 'TEST5', Status = 'Enquiry', Total_Value_excl_GST__c = 1000, RecordTypeId = QuoteTriggerHandler.qtRtId);
            
            User user = [SELECT Id FROM User WHERE LastName = 'Test User' LIMIT 1];
            
            System.runAs(user) {
                insert new List<Quote>{testQuote1, testQuote2, testQuote3, testQuote4, testQuote5};
            }
        
        Test.stopTest();                
    }
}