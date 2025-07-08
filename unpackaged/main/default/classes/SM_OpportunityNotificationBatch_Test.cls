/*******************************************************************************************************
* Class Name      	: SM_OpportunityNotificationBatch_Test
* Description		: Test class for SM_OpportunityNotificationBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 01/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              01/10/2020		1000				Initial version
******************************************************************************************************/
@isTest
private class SM_OpportunityNotificationBatch_Test {
    @isTest
    private static void testOpportunityNotificationBatch() {
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        // create opportunities
        List<Opportunity> opps = TestDataFactory.createOpenOpportunities(accounts[0].Id, UserInfo.getUserId(), 3);
        opps[0].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_NZ_STANDARD).getRecordTypeId();
        opps[0].StageName = 'Pending';
        opps[0].CloseDate = Date.today().addDays(5);
        opps[1].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_NZ_STANDARD).getRecordTypeId();
        opps[1].StageName = 'Pending';
        opps[1].CloseDate = Date.today().addDays(20);
        opps[2].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Farm Shed Opportunity').getRecordTypeId();
        opps[2].StageName = 'Proposal Ready';
        opps[2].CloseDate = Date.today().addDays(20);
        insert opps;

        Test.startTest();
        // schedulable (not immediate)
        Id jobId = System.schedule('Opportunity Notifications Test', 
            '0 0 2 * * ?', 
            new SM_OpportunityNotificationBatch());
        // batchable
        Database.executebatch(new SM_OpportunityNotificationBatch(), 1000);
        Test.stopTest();
    }
}