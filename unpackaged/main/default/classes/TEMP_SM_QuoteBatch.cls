/*******************************************************************************************************
* Class Name        : TEMP_SM_QuoteBatch
* Description       : Temporary batch class to Insert/Update Quote for CCRM15-247
* Author            : Simplus MS
* Created On        : 08/10/2021
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer                 Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus.MS                08/10/2021      1000                Initial version
******************************************************************************************************/
global class TEMP_SM_QuoteBatch implements Database.Batchable<sObject> {

    String query;
    String queryFilter;
    public static string COS_OPP_ID_PREFIX = Label.BN_OPP_ID_Prefix;

    public class ErrorItem {
        string statusCode;
        string message;
        string[] fields = new list<String>();
    }

    public TEMP_SM_QuoteBatch(){
    }
    
    public TEMP_SM_QuoteBatch(String queryFilter) {
        this.queryFilter = queryFilter;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('batchName? ' + queryFilter);
        if(queryFilter != null){
            query = 'SELECT Id, Name, Object_Name__c, Status__c, Date_Processed__c, ' +
                'Assigned_Store__c, Shipping_Street__c, COS_Date__c, GST__c, Created_by_TM_number__c, Quote_Status__c, COS_Token__c, COS_Opportunity_ID__c, ' +
                'Customer_Order_Number__c, Updated_by_TM_Name__c, Total_Value_incl_GST__c, Type__c, Shipping_Postal_Code__c, ' +
                'Comments__c, COS_Number__c, Customer_Job_Number__c, Owned_by_restricted_team__c, Insurance__c, Shipping_State__c, ' +
                'Contact_Number__c, Shipping_Name__c, Cancellation_Comments__c, Discount_incl_GST__c, Total_Value_excl_GST__c, ' +
                'Type_of_Delivery__c, Follow_Up_Date__c, COS_ID__c, Quote_Delivery_Collection_Date__c, Contact_Name__c, Country__c, ' +
                'Record_Type__c, Expiration_Date__c, Created_by_TM_Name__c, Total_Cost_excl_GST__c, Cancellation_Reason__c, ' + 
                'Customer_Job_Address__c, Shipping_Country__c, Shipping_City__c, Total_Cost_incl_GST__c, Updated_by_TM_Number__c, OpportunityId__c, AccountID__c, ' +
                'Error_Message__c, Log_Type__c, Log_Object_Name__c, Source_Type__c, Function_Name__c ' +
                'FROM Staging_Object__c ' +
                'WHERE COS_ID__c != null AND Object_Name__c = \'Quote\' AND Status__c = \'Open\' AND Batch_Name__c =\'' + queryFilter + '\'';
        }else{
            query = 'SELECT Id, Name, Object_Name__c, Status__c, Date_Processed__c, ' +
                'Assigned_Store__c, Shipping_Street__c, COS_Date__c, GST__c, Created_by_TM_number__c, Quote_Status__c, COS_Token__c, COS_Opportunity_ID__c, ' +
                'Customer_Order_Number__c, Updated_by_TM_Name__c, Total_Value_incl_GST__c, Type__c, Shipping_Postal_Code__c, ' +
                'Comments__c, COS_Number__c, Customer_Job_Number__c, Owned_by_restricted_team__c, Insurance__c, Shipping_State__c, ' +
                'Contact_Number__c, Shipping_Name__c, Cancellation_Comments__c, Discount_incl_GST__c, Total_Value_excl_GST__c, ' +
                'Type_of_Delivery__c, Follow_Up_Date__c, COS_ID__c, Quote_Delivery_Collection_Date__c, Contact_Name__c, Country__c, ' +
                'Record_Type__c, Expiration_Date__c, Created_by_TM_Name__c, Total_Cost_excl_GST__c, Cancellation_Reason__c, ' + 
                'Customer_Job_Address__c, Shipping_Country__c, Shipping_City__c, Total_Cost_incl_GST__c, Updated_by_TM_Number__c, OpportunityId__c, AccountID__c, ' +
                'Error_Message__c, Log_Type__c, Log_Object_Name__c, Source_Type__c, Function_Name__c ' +
                'FROM Staging_Object__c ' +
                'WHERE COS_ID__c != null AND Object_Name__c = \'Quote\' AND Status__c = \'Open\' ';
        }
        System.debug('query ' +  query);
        return Database.getQueryLocator(query);
    }

    
    public void execute(Database.BatchableContext BC, List<Staging_Object__c> scope) {
        try {
            processStagingObjectQuotes(scope);
            //syncWithQuote(scope);  
        } catch(Exception e) {
            ApplicationLogger.log('TEMP_SM_QuoteBatch', 'Staging_Object__c', 'Batch', e);
        }
    }
 
    
    public void finish(Database.BatchableContext BC) {
        // Actions to be carried out on finish of batch job
    }

    /**
    * @description : CCRM15-247 - method to check if OpportunityId doesn't exist in Staging_Object__c Quote record
    *                and create opportunity from it. 
    *                Otherwise directly pass Staging Object Quote
    *                record(s) to syncWithQuote method for further processing
    * @author Simplus MS | 20/10/2021
    * @param Scope 
    **/
    public void processStagingObjectQuotes(List<Staging_Object__c> lstStagingQuotes) {
        Map<String, Id> oppRTMap = new Map<String, Id>(); 
        Map<String, String> oppStageNameMap = new Map<String, String>();
        Map<String, Opportunity> existingOppsWithSyncedQuoteMap = new Map<String, Opportunity>();
        Map<String, Opportunity> existingOppsMap = new Map<String, Opportunity>();
        Set<String> stCosIds = new Set<String>(); 
        Set<String> stCosOppIds = new Set<String>(); 
        List<Opportunity> opportunityFromStQuoteList = new List<Opportunity>();
        Map<Staging_Object__c, Opportunity> stagingObjectQuoteNewOppRecordMap = new Map<Staging_Object__c, Opportunity>();
        Map<Id, Staging_Object__c> newOppIdStQuoteMap = new Map<Id, Staging_Object__c>();
        List<Staging_Object__c> stQuotesListToSync = new List<Staging_Object__c>();
        List<Staging_Object__c> stQuotesListWithErrors = new List<Staging_Object__c>();


        oppRTMap.put('AUSTRALIA', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AU_Store_Initiated_Opportunity').getRecordTypeId());
        oppRTMap.put('NEW ZEALAND', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Store_Initiated_Opportunity').getRecordTypeId());

        oppStageNameMap.put('AUSTRALIA', 'Proposal');
        oppStageNameMap.put('NEW ZEALAND', 'Pending');

        for (Staging_Object__c stQuote : lstStagingQuotes) {
            stCosOppIds.add(COS_OPP_ID_PREFIX + stQuote.COS_ID__c);
            stCosIds.add(stQuote.COS_ID__c);
        }
        
        //prioritize the Opportunities where SyncedQuote is the quote from Staging Object
        System.debug('Querying opps using COS_ID__c');
        /*
        for (Opportunity opp : [SELECT Id, Name, SyncedQuote.COS_ID__c FROM Opportunity WHERE SyncedQuote.COS_ID__c IN :stCosIds ]) {
            existingOppsWithSyncedQuoteMap.put(opp.SyncedQuote.COS_ID__c, opp);
        }
		*/
        
        for (Quote qot : [SELECT Id, OpportunityId, COS_ID__c, Opportunity.Name, Opportunity.SyncedQuoteId FROM Quote WHERE IsSyncing=true AND COS_ID__c IN :stCosIds ]) {
            Opportunity opp = new Opportunity();
            opp.Name = qot.Opportunity.Name;
            opp.Id = qot.OpportunityId;
            opp.SyncedQuote = qot;
            existingOppsWithSyncedQuoteMap.put(qot.COS_ID__c, opp);
        }
                
        
        System.debug('Querying opps using COS_Opportunity_ID__c');
        for (Opportunity opp : [SELECT Id, Name, COS_Opportunity_ID__c FROM Opportunity WHERE COS_Opportunity_ID__c IN :stCosOppIds ]) {
            existingOppsMap.put(opp.COS_Opportunity_ID__c, opp);
        }
        
        for(Staging_Object__c stQuote : lstStagingQuotes) {
            String OppCOSId = COS_OPP_ID_PREFIX + stQuote.COS_ID__c;
            //CCRM15-247: If a Staging_Object__c Quote record has no Opportunity or there is no existing opportunity = COS_Id__c 
                        //Create a new opportunity record from Staging_Object__c Quote record.
            if((String.isblank(stQuote.OpportunityId__c))){
                if (!existingOppsWithSyncedQuoteMap.containsKey(stQuote.COS_ID__c) && !existingOppsMap.containsKey(OppCOSId)){
                    system.debug('Entry 1 :: ' +stQuote.Name);
                    Opportunity opp = new Opportunity();
                    opp.COS_Opportunity_ID__c = OppCOSId;
                    opp.Country__c = stQuote.Country__c;
                    opp.Name = stQuote.COS_Number__c;
                    opp.Originating_Store__c = stQuote.Assigned_Store__c;
                    opp.AccountId = stQuote.AccountID__c;
                    
                    if(stQuote.Quote_Status__c != null){
                        switch on stQuote.Quote_Status__c.toLowerCase() {
                            when 'submitted' {
                                opp.StageName = 'Closed Won';
                            }
                            
                            when 'pricing_only_quote','cancelled' {
                                opp.StageName = 'Closed Lost';
                            }
                            
                            when 'enquiry', 'quote' {
                                opp.StageName = oppStageNameMap.get(stQuote.Country__c.toUpperCase());
                            }
                        }   
                    }else{
                        opp.StageName = 'New';
                    }
                    
                    opp.CloseDate = stQuote.Expiration_Date__c;
                    opp.Amount = stQuote.Total_Value_Excl_Gst__c;
                    opp.Loss_Reason__c = stQuote.Cancellation_Reason__c;
                    opp.Loss_Reason_Comments__c = stQuote.Cancellation_Comments__c;
                    opp.RecordTypeId = oppRTMap.get(stQuote.Country__c.toUpperCase());
                    stagingObjectQuoteNewOppRecordMap.put(stQuote, opp);
                }else if (existingOppsWithSyncedQuoteMap.containsKey(stQuote.COS_ID__c)){
                    system.debug('Entry 2 :: ' +stQuote.Name);
                    stQuote.OpportunityId__c = existingOppsWithSyncedQuoteMap.get(stQuote.COS_ID__c).Id;
                    stQuotesListToSync.add(stQuote);
                }else if (existingOppsMap.containsKey(OppCOSId)){
                    system.debug('Entry 3 :: ' +stQuote.Name);
                    stQuote.OpportunityId__c = existingOppsMap.get(OppCOSId).Id;
                    stQuotesListToSync.add(stQuote);
                }
            }else{
                system.debug('Entry 4 :: ' +stQuote.Name);
                stQuotesListToSync.add(stQuote);
            }
        }
        if (stagingObjectQuoteNewOppRecordMap.size()>0) {         
            Database.SaveResult[] srs = Database.insert(stagingObjectQuoteNewOppRecordMap.values(), false);  
            
            Integer index = 0;
            for (Staging_Object__c key : stagingObjectQuoteNewOppRecordMap.keySet()) {
                Database.SaveResult rs = srs[index];
                if (rs.isSuccess()) {
                    newOppIdStQuoteMap.put(rs.getId(), key);
                }else{
                    Database.error err;
                    err = rs.getErrors()[0];
                    ErrorItem ei = new ErrorItem();
                    ei.statusCode = string.valueOf(err.getStatusCode());
                    ei.message = err.getMessage();
                    ei.fields = err.getFields();

                    key.Status__c = 'With Error';
                    key.Date_Processed__c = Datetime.now();
                    key.Log_Type__c = 'Exception';
                    key.Source_Type__c = 'Batch';
                    key.Log_Object_Name__c = 'Quote';
                    key.Function_Name__c = 'TEMP_SM_QuoteBatch';
                    key.Error_Message__c = ei.statusCode + ' : ' + ei.message + ' : ' + ei.fields;

                    stQuotesListWithErrors.add(key);
                }
                index++;
            }
        }

        if(stQuotesListWithErrors.size() > 0){
            try {
                Update stQuotesListWithErrors;
            } catch(Exception e) {
                ApplicationLogger.log('TEMP_SM_QuoteBatch', 'Quote', 'Batch', e);
            }
        }
        List<Staging_Object__c> stagingObjectQuoteWithOppIdList = new List<Staging_Object__c>();
        for(Id oppId : newOppIdStQuoteMap.keySet()){
            Staging_Object__c stQuote = newOppIdStQuoteMap.get(oppId);
            stQuote.OpportunityId__c = oppId;
            stagingObjectQuoteWithOppIdList.add(stQuote);
        }

        if(stagingObjectQuoteWithOppIdList.size() > 0){
            stQuotesListToSync.addAll(stagingObjectQuoteWithOppIdList);
        }

        if(stQuotesListToSync.size() > 0){
            syncWithQuote(stQuotesListToSync);
        }

    }

     /**
    * @description : Syncing Staging Object with Quotes by mapping fields
    * @author Simplus MS | 07/10/2021
    * @param Scope 
    **/
    public void syncWithQuote(List<Staging_Object__c> lstStagingQuotes) {
        Id COSQuoteRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('COS_Quote').getRecordTypeId();
        
        List<Quote> lstQuotes = new List<Quote>();
        
        for(Staging_Object__c stQuote : lstStagingQuotes) {
            if(stQuote.COS_ID__c != null && stQuote.Object_Name__c == 'Quote' && stQuote.Status__c != 'Completed') {
                lstQuotes.add(new Quote(Assigned_Store__c = stQuote.Assigned_Store__c, 
                                        ShippingStreet = stQuote.Shipping_Street__c, 
                                        COS_Date__c = stQuote.COS_Date__c,
                                        Tax = stQuote.GST__c,
                                        Created_by_TM_Number__c = stQuote.Created_by_TM_number__c,
                                        Status = stQuote.Quote_Status__c,
                                        OpportunityId = stQuote.OpportunityId__c,
                                        Customer_Order_Number__c = stQuote.Customer_Order_Number__c,
                                        Updated_by_TM_name__c = stQuote.Updated_by_TM_Name__c,
                                        Total_Value_incl_GST__c = stQuote.Total_Value_incl_GST__c,
                                        Type__c = stQuote.Type__c,
                                        ShippingPostalCode = stQuote.Shipping_Postal_Code__c,
                                        Comments__c = stQuote.Comments__c,
                                        Name = stQuote.COS_Number__c,
                                        Customer_Job_Number__c = stQuote.Customer_Job_Number__c,
                                        Owned_by_restricted_team__c = stQuote.Owned_by_restricted_team__c,
                                        Insurance__c = stQuote.Insurance__c,
                                        ShippingState = stQuote.Shipping_State__c,
                                        Phone = stQuote.Contact_Number__c,
                                        ShippingName = stQuote.Shipping_Name__c,
                                        Cancellation_Comments__c = stQuote.Cancellation_Comments__c,
                                        Discount_incl_GST__c = stQuote.Discount_incl_GST__c,
                                        Total_Value_excl_GST__c = stQuote.Total_Value_excl_GST__c,
                                        Type_of_Delivery__c = stQuote.Type_of_Delivery__c,
                                        Follow_Up_Date__c = stQuote.Follow_Up_Date__c,
                                        COS_ID__c = stQuote.COS_ID__c,
                                        Delivery_Collection_Date__c = stQuote.Quote_Delivery_Collection_Date__c,
                                        Contact_Name__c = stQuote.Contact_Name__c,
                                        Country__c = stQuote.Country__c,
                                        RecordTypeId = COSQuoteRecordTypeId,
                                        ExpirationDate = stQuote.Expiration_Date__c,
                                        Created_by_TM_Name__c = stQuote.Created_by_TM_Name__c,
                                        Total_Cost_excl_GST__c = stQuote.Total_Cost_excl_GST__c,
                                        Cancellation_Reason__c = stQuote.Cancellation_Reason__c,
                                        Customer_Job_Address__c = stQuote.Customer_Job_Address__c,
                                        ShippingCountry = stQuote.Shipping_Country__c,
                                        ShippingCity = stQuote.Shipping_City__c,
                                        Total_Cost_incl_GST__c = stQuote.Total_Cost_incl_GST__c,
                                        Updated_by_TM_Number__c = stQuote.Updated_by_TM_Number__c,
                                        COS_Token__c = stQuote.COS_Token__c
                                        ));

            }
        }

        if(!lstQuotes.isEmpty()) {
            System.debug('syncWithQuote: updating quotes');
            system.debug(JSON.serializePretty(lstQuotes));
            Database.UpsertResult[] urList = Database.upsert(lstQuotes, Quote.COS_ID__c, false);
                Set<Id> completedQuoteId = new Set<Id>();

                Map<String, Database.Error> resultsWithErrorMap = new Map<String, Database.Error>();
                for(Integer i=0; i<urList.size(); i++) {
                    System.debug(urList.get(i).isSuccess());
                    if (urList.get(i).isSuccess()) {
                        completedQuoteId.add(urList.get(i).getId());
                    } else {
                        String cosId = lstQuotes.get(i).COS_ID__c;
                        Database.Error error = urList.get(i).getErrors().get(0);
                        resultsWithErrorMap.put(cosId, error);
                    }   
                }
        
                Set<String> completedCOSQuoteIds = new Set<String>();
                for(Quote quo : [SELECT OpportunityId, COS_ID__c FROM Quote WHERE Id IN :completedQuoteId]) {
                    completedCOSQuoteIds.add(quo.COS_ID__c);
                }
                        
            

            List<Staging_Object__c> lstCompletedStgRecs = new List<Staging_Object__c>();
            //Iterate through each staging object record and update status and date processed
            //If an operation is unsuccessful, log details into staging object error detail fields
            for(Staging_Object__c stQuote : lstStagingQuotes) {
                if(completedCOSQuoteIds.contains(stQuote.COS_ID__c)) {
                    stQuote.Status__c = 'Completed';
                    stQuote.Date_Processed__c = Datetime.now();

                    //Clear error log details
                    if(String.isNotBlank(stQuote.Error_Message__c)) {
                        stQuote.Error_Message__c = '';    
                        stQuote.Log_Type__c = ''; 
                        stQuote.Log_Object_Name__c = '';
                        stQuote.Source_Type__c = '';
                        stQuote.Function_Name__c = '';
                    }
                }else{
                    stQuote.Status__c = 'With Error';
                    stQuote.Date_Processed__c = Datetime.now();
                    stQuote.Log_Type__c = 'Exception';
                    stQuote.Source_Type__c = 'Batch';
                    stQuote.Log_Object_Name__c = 'Quote';
                    stQuote.Function_Name__c = 'TEMP_SM_QuoteBatch';
                    stQuote.Error_Message__c = resultsWithErrorMap.get(stQuote.COS_ID__c).getStatusCode() + ' : ' +
                                                resultsWithErrorMap.get(stQuote.COS_ID__c).getMessage() + ' : ' +
                                                resultsWithErrorMap.get(stQuote.COS_ID__c).getFields();

                }
                lstCompletedStgRecs.add(stQuote);
            }

            if(lstCompletedStgRecs.size() > 0) {
                try {
                    Update lstCompletedStgRecs;
                } catch(Exception e) {
                    ApplicationLogger.log('TEMP_SM_QuoteBatch', 'Quote', 'Batch', e);
                }
            }
        }
    }
}