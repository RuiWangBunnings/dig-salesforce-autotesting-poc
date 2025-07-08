/*******************************************************************************************************
* Class Name      	: SM_CosQuoteAndOppSyncQueueable_Test
* Description		: Test class for SM_CosQuoteAndOppSyncQueueable
* Author          	: Bunnings Dev
* Created On      	: 21/08/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     21/08/2023		1000				Initial version - BUNDIG-24085
*******************************************************************************************************/
@isTest
private class SM_CosQuoteAndOppSyncQueueable_Test {

    @isTest
    public static void test_cosQuoteAndOppSyncQueueable() {
        
        // Create Opportunities
        List<Opportunity> opportunities = new List<Opportunity> {
            new Opportunity(COS_Opportunity_ID__c='1', RecordTypeId = CSUtils.getRecordTypeId('Opportunity', 'NZ Standard Opportunity'), 
            Name = 'Test Opportunity 1', StageName='Submission', Amount = 4546, CloseDate=Date.today() + 3)};
        insert opportunities;

        // Create Quote
        List<Quote> quotes = TestDataFactory.createQuotes(opportunities[0].Id, 'Enquiry', 1);

        Test.startTest();
            Map<Id, Id> mapQtOppty = new Map<Id, Id>();
            for (Quote qt : quotes)
                mapQtOppty.put(qt.Id, qt.OpportunityId);

            System.enqueueJob(new SM_CosQuoteAndOppSyncQueueable(mapQtOppty));
        Test.stopTest();
    }
}