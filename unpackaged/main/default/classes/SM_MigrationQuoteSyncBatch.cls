/*******************************************************************************************************
* Class Name      	: SM_MigrationQuoteSyncBatch
* Description		: Batch / Schedule class to sync migrated quotes with opportunities
* Author          	: Simplus - Purba Ghosh
* Created On      	: 21/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Purba Ghosh           21/09/2020		1000				Initial version
******************************************************************************************************/
global class SM_MigrationQuoteSyncBatch implements Database.Batchable<sObject>, Schedulable {

    String query;

    global SM_MigrationQuoteSyncBatch() {
        // Scope is every quote that is loaded into the system on day 0.
        query = 'SELECT Id, COS_ID__c, ExpirationDate, OpportunityId FROM Quote';
    }

    /**
    * @description : Batch Start Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description : Batch Execute Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    * @param scope 
    **/
    public void execute(Database.BatchableContext BC, List<Quote> scope) {
        try {
            syncWithOpportunity(scope);  
        } catch(Exception e) {
            ApplicationLogger.log('SM_MigrationQuoteSyncBatch', 'Quote', 'Batch', e);
        }
    }
 
    /**
    * @description : Batch Finish Method
    * @author Purba Ghosh | 21/09/2020 
    * @param BC 
    **/
    public void finish(Database.BatchableContext BC) {
        // Actions to be carried out on finish of batch job
    }

    /**
    * @description : Batch Execute Method For Scheduling
    * @author Purba Ghosh | 21/09/2020 
    * @param SC 
    **/
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_MigrationQuoteSyncBatch(), 1000);
    }

    /**
    * @description : Syncing quotes with opportunities by setting basic fields
    * @author Purba Ghosh | 21/09/2020 
    * @param Scope 
    **/
    public void syncWithOpportunity(List<Quote> lstQuotes) {

        Map<Id,Opportunity> mapOpportunities = new Map<Id,Opportunity>();
        for(Quote q : lstQuotes) {

            // As a data load exercise the quotes will be associated to its
            // respective opportunity using the COS ID as external ID.
            // Quotes are expected to be loaded with the ExpirationDate (Price Validity Date) 
            // populated.
            if(q.OpportunityId != null && q.ExpirationDate != null) {
                Opportunity objOpp = new Opportunity(Id=q.OpportunityId, SyncedQuoteId=q.Id, Primary_Quote_Expiry_Date__c =q.ExpirationDate);

                // As on Day 0, only one quote per opportunity is expected to be loaded. 
                // Thereby there is no need for any determintaion of which quote syncs
                // with the opportunity. As it is 1:1 (COS ID in quote === COS ID in Oppo)
                if(!mapOpportunities.containsKey(objOpp.Id)) {
                    mapOpportunities.put(objOpp.Id,objOpp);
                }
            }
        }

        // Update the opportunities and sync them with the identified quote
        if(!mapOpportunities.isEmpty()) {
            update mapOpportunities.values();
        }
    }
}