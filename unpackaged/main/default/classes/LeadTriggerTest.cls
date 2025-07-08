/*******************************************************************************************************
* Class Name      	: LeadTriggerTest
* Description		: Lead trigger test
* Author          	: Simplus - Francis Benzon
* Created On      	: 15/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        15/06/2020		1000				Initial version
* Philip Clark    	    06/07/2020		1001                Added test coverage for ABN, ACN, GST
******************************************************************************************************/
@IsTest
private class LeadTriggerTest {

    @IsTest
    static void testBehavior() {
        List<Lead> leads = new List<Lead>{TestDataFactory.createStandardLead()};

        Test.startTest();
        
        leads[0].RecordTypeId = CSUtils.getRecordTypeId('Lead', 'AU Standard Lead');
		leads[0].FirstName = 'test-class';
		leads[0].LastName = 'lead';
		leads[0].ABN__c = '51824753556';
		leads[0].ACN__c = '004085616';
		leads[0].GST_Number__c = '1153x912 08';

        update leads;
		
        Test.stopTest();

        System.assert([SELECT Id FROM Lead].size() == 1);
    }

    @IsTest
    static void testInsert() {
        List<Lead> leads = TestDataFactory.createStandardLeads(1);
        leads[0].RecordTypeId = CSUtils.getRecordTypeId('Lead', 'AU Standard Lead');
		leads[0].ABN__c = '51824753556';
		leads[0].ACN__c = '004085616';
		leads[0].GST_Number__c = '1153x912 08';

        Test.startTest();
        
        insert leads;
		
        Test.stopTest();

        Lead lead = [SELECT Id, ABN__c, ACN__c, GST_Number__c FROM Lead WHERE Id =: leads[0].Id LIMIT 1];
        system.assertEquals('51 824 753 556',lead.ABN__c,'ABN not formatted correctly');
        system.assertEquals('004 085 616',lead.ACN__c,'ACN not formatted correctly');
        system.assertEquals('115391208',lead.GST_Number__c,'GST number not formatted correctly');
    }
    
    @isTest
    static void testNZLeadGSTNumber() {
        Lead l = new Lead(FirstName = 'FN', LastName = 'Test NZ Lead GST Number', RecordTypeId = CSUtils.getRecordTypeId('Lead', 'NZ Standard Lead'), GST_Number__c = '111111111', Company = 'Test NZ Lead GST Number', Email = String.valueOf(Math.random()) + 'test@test.com');

        Test.startTest();
        // insert with invalid number
        try {
            insert l;
        } catch(Exception e) {
            System.assert(e.getMessage().contains(LeadTriggerHandler.ERROR_INVALID_GST_NUMBER), 'Error message for invalid GST Number incorrect');
        }
        // insert with valid number
        l.GST_Number__c = '47453623';
        insert l;

        // update with invalid number
        l.GST_Number__c = '069123466';
        try {
            update l;
        } catch(Exception e) {
            System.assert(e.getMessage().contains(AccountTriggerHandler.ERROR_INVALID_GST_NUMBER), 'Error message for invalid GST Number incorrect');
        }

		// insert with invalid number, but not NZ Lead Record Type
        Lead l2 = new Lead(FirstName = 'FxN', LastName = 'Test NZ Lead GST Number 2', RecordTypeId = CSUtils.getRecordTypeId('Lead', 'AU Standard Lead'), GST_Number__c = '111111111', Company = 'Test NZ Lead GST Number 2', Email = String.valueOf(Math.random()) + 'test@test.com');
        insert l2;

        Test.stopTest();
    }
}