/*******************************************************************************************************
* Class Name        : TEMP_SM_QuoteBatch_Test
* Description       : Test class for TEMP_SM_QuoteBatch
* Author            : Simplus MS
* Created On        : 11/10/2021
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer            Date             Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           11/10/2021       1000                Initial version
******************************************************************************************************/
@isTest
private with sharing class TEMP_SM_QuoteBatch_Test {
    
    @testSetup
    static void setup(){
        
        //Create Account
        List<Account> accts = TestDataFactory.createAccounts(1);
        insert accts;
        
        //Create Oppty
        List<Opportunity> opps = TestDataFactory.createOpenOpportunities(accts[0].Id, UserInfo.getUserId(), 3);
        insert opps;
        
        //Create Store
        List<Store__c> stores = TestDataFactory.createStores(1);
        insert stores;
        
        //Create Quotes
        List<Quote> quotes = new List<Quote> {
            new Quote(OpportunityId = opps[0].Id, COS_ID__c='1', RecordTypeId = CSUtils.getRecordTypeId('Quote', 'COS Quote'), 
                      Name = '3553', Assigned_Store__c=stores[0].Id, Status='Submitted', ExpirationDate=Date.today()),
                      new Quote(OpportunityId = opps[1].Id, COS_ID__c='26', RecordTypeId = CSUtils.getRecordTypeId('Quote', 'COS Quote'), 
                                Name = '2244', Assigned_Store__c=stores[0].Id, Status='Cancelled', ExpirationDate=Date.today())
                };
        insert quotes;
        
        //Update Opp to populate COS_Opportunity_ID__c
        String COS_OPP_ID_PREFIX = Label.BN_OPP_ID_Prefix;
        List<Opportunity> oppList = [SELECT Id, COS_Opportunity_ID__c FROM Opportunity LIMIT 10];
        for(Integer i = 1; i < quotes.size(); i++){
            oppList[i].COS_Opportunity_ID__c = COS_OPP_ID_PREFIX + quotes[i].COS_ID__c;
        }
        
        update oppList;

        //Create Staging Quotes
        List<Staging_Object__c> stgQuotes = new List<Staging_Object__c>();
        
        //Staging Quotes with matching COS ID to test UPDATE operation
        for(Integer i=0;i<3;i++) {
            Staging_Object__c stgObj = new Staging_Object__c();
            stgObj.Object_Name__c = 'Quote';
            stgObj.Status__c = 'Open';
            //stgObj.OpportunityId__c = opps[3].Id;
            stgObj.Type__c = 'Quote';
            stgObj.Country__c = 'Australia';
            stgObj.Assigned_Store__c = stores[0].Id;
            stgObj.COS_ID__c = String.valueOf(i);
            stgObj.COS_Number__c = String.valueOf(i) + 20;
            stgObj.COS_Date__c = Date.today()+3;
            stgObj.Quote_Status__c = 'Submitted';
            stgObj.Comments__c = 'Sample comment';
            stgObj.Record_Type__c = CSUtils.getRecordTypeId('Quote', 'COS Quote');
            stgObj.Expiration_Date__c = Date.today()+5;
            stgObj.COS_Token__c = '645774'+i;
            stgObj.Error_Message__c = 'Sample Error Message';
            
            stgQuotes.add(stgObj);
        }

        //Staging Quote with missing fields to test ERROR operation
        stgQuotes.add(new Staging_Object__c(Object_Name__c = 'Quote',
                                           Status__c = 'Open',
                                           Assigned_Store__c = stores[0].Id,
                                           COS_ID__c = '2',
                                           OpportunityId__c = opps[2].Id));
        
        insert stgQuotes;
    }
    
    @isTest static void testSyncQuotes() {
        
        Test.startTest();
        Database.executeBatch(new TEMP_SM_QuoteBatch());
        Test.stopTest();
        
        Set<String> completedCOSIds = new Set<String>();
        Set<String> withErrorCOSIds = new Set<String>();
        List<Staging_Object__c> scope = [SELECT COS_ID__c, Status__c FROM Staging_Object__c WHERE Object_Name__c = 'Quote' AND COS_ID__c != null];
        
        for(Staging_Object__c so : scope) {
            if(so.Status__c == 'Completed') {
                completedCOSIds.add(so.COS_ID__c);
            } else {
                withErrorCOSIds.add(so.COS_ID__c);
            }
        }
        
        Integer quotesProcessed = [SELECT COS_ID__c FROM Quote WHERE COS_ID__c IN :completedCOSIds].size();
        Integer quotesFailed = scope.size() - quotesProcessed;
        
        //Asserts number of processed staging records and actual number of Quote records
        System.assertEquals(completedCOSIds.size(), quotesProcessed, 'Quote records processed does not match number of completed staging records');
        System.assertEquals(withErrorCOSIds.size(), quotesFailed -1, 'Failed Quote records does not match number of staging records with error');
    }
    
    @isTest static void testFailedOppInsert(){
        List<Staging_Object__c> stQuotes = [SELECT COS_ID__c, Status__c,Expiration_Date__c FROM Staging_Object__c WHERE Object_Name__c = 'Quote' AND COS_ID__c != null];
        
        for(Staging_Object__c stQuote : stQuotes){
            stQuote.Expiration_Date__c = null;
        }
        
        update stQuotes;
        
        Test.startTest();
        Database.executeBatch(new TEMP_SM_QuoteBatch());
        Test.stopTest();
        
        Set<String> completedCOSIds = new Set<String>();
        Set<String> withErrorCOSIds = new Set<String>();
        List<Staging_Object__c> scope = [SELECT COS_ID__c, Status__c FROM Staging_Object__c WHERE Object_Name__c = 'Quote' AND COS_ID__c != null];
        
        for(Staging_Object__c so : scope) {
            if(so.Status__c == 'Completed') {
                completedCOSIds.add(so.COS_ID__c);
            } else {
                withErrorCOSIds.add(so.COS_ID__c);
            }
        }
        
        Integer quotesProcessed = [SELECT COS_ID__c FROM Quote WHERE COS_ID__c IN :completedCOSIds].size();
        Integer quotesFailed = scope.size() - quotesProcessed;
        
        //Asserts number of processed staging records and actual number of Quote records
        System.assertEquals(completedCOSIds.size(), quotesProcessed, 'Quote records processed does not match number of completed staging records');
        System.assertEquals(withErrorCOSIds.size(), quotesFailed-1, 'Failed Quote records does not match number of staging records with error');
    }
    
    @isTest static void testRunBatchWithParams(){
        Test.startTest();
       	Database.executeBatch(new TEMP_SM_QuoteBatch('Test Batch 1'));
        Test.stopTest();
        
        Set<String> completedCOSIds = new Set<String>();
        Set<String> withErrorCOSIds = new Set<String>();
        List<Staging_Object__c> scope = [SELECT COS_ID__c, Status__c FROM Staging_Object__c WHERE Object_Name__c = 'Quote' AND COS_ID__c != null];
        
        for(Staging_Object__c so : scope) {
            if(so.Status__c == 'Completed') {
                completedCOSIds.add(so.COS_ID__c);
            } else {
                withErrorCOSIds.add(so.COS_ID__c);
            }
        }
        
        Integer quotesProcessed = [SELECT COS_ID__c FROM Quote WHERE COS_ID__c IN :completedCOSIds].size();
        Integer quotesFailed = scope.size() - quotesProcessed;
        
        //Asserts number of processed staging records and actual number of Quote records
        System.assertEquals(completedCOSIds.size(), quotesProcessed, 'Quote records processed does not match number of completed staging records');
        System.assertEquals(withErrorCOSIds.size(), quotesFailed-1, 'Failed Quote records does not match number of staging records with error');
    }
    
}