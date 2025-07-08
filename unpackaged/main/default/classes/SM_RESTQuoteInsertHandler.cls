/***************************************************************************************************
* Class Name      	: SM_RESTQuoteInsertHandler
* Description		: REST Resource for Creating Quotes from COS 
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 05-Feb-2021
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         05-Feb-2021		1000				Initial version
* Jasper R. Galapon		19-Nov-2024		1001				CRMS-231 - Process-Enquiry - Add new integration User to createQuotes API
* Jasper R. Galapon     13/02/2025      1002                CRMS-449 - Random error - where the cos id not found
* Jasper R. Galapon     14/02/2025      1003                CRMS-452 - Opportunity Id Issue
* Jasper R. Galapon     07/05/2025      1004                BUNDIG-44073 - Update logic to include COS order token with Status = 'PricingOnlyQuote'
*****************************************************************************************************/
@RestResource(urlMapping='/Quote/createQuotes')
global class SM_RESTQuoteInsertHandler {
    public static string COS_OPP_ID_PREFIX = Label.BN_OPP_ID_Prefix;
    public virtual class ResultItem {
        String referenceId;
        Id id;
        Boolean success = false;
        Boolean created = false;
        ErrorItem[] errors = new List<ErrorItem>();
    }
    
    public class TopLevelError {
        string errorCode;
        string message;
    }    
    
    public class ErrorItem {
        string statusCode;
        string message;
        string[] fields = new list<String>();
    }
    
    @HttpPatch
    global static void createQuotes_Patch() {
        createQuotes();
    }
    
    @HttpPost
    global static void createQuotes() {
       	boolean isIntegUser = String.isBlank(config.Integration_User__c)==false && System.UserInfo.getUserName().equalsIgnoreCase(config.Integration_User__c);
        boolean isIntegUser2 = String.isBlank(config.Integration_User_2__c)==false && System.UserInfo.getUserName().equalsIgnoreCase(config.Integration_User_2__c); // CRMS-231
        //boolean isIntegUser = true;        
        RestResponse resp = restContext.response;
        RestRequest req = RestContext.request;
        String[] refIds = new List<String>();
        String result = ''; 
        resp.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Map<String, Object> o = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
        List<Object> records = (List<Object>)JSON.deserializeUntyped(JSON.serialize(o.get('records')));
        
        System.debug(LoggingLevel.DEBUG, 'PAYLOAD:\n\n' + req.requestBody.toString());
        System.debug(LoggingLevel.DEBUG, 'RECORD COUNT: ' + String.valueOf(records.size()));        
        
        if (!isIntegUser && !isIntegUser2) { // CRMS-231
            TopLevelError tle = new TopLevelError();
            tle.errorCode = 'INVALID_INPUT';
            tle.message = 'User is not allowed to execute this resource.';
            resp.responseBody = blob.valueOf(JSON.serialize(new List<TopLevelError>{tle}));
            resp.statusCode = 403;
            return;            
        }
        
        for(Object rec: records) {
            Map<String, Object> record = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rec));
            Map<String, Object> attributes = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record.get('attributes')));
            if (attributes.get('referenceId')==null || String.valueOf(attributes.get('referenceId')).trim()=='') {
                TopLevelError tle = new TopLevelError();
                tle.errorCode = 'INVALID_INPUT';
                tle.message = 'Include a reference ID for each record in the request.';
                resp.responseBody = blob.valueOf(JSON.serialize(new List<TopLevelError>{tle}));
                resp.statusCode = 403;
                return;
            } else {
                refIds.add(attributes.get('referenceId').toString());
            }
        }
        
        // CRMS-449 Commented out due to random error after sorting
        // new integration has confirmed that there is no duplicate reference id in a single payload
        // refIds.sort();
        // integer refCount = refIds.size();
        // for (integer i=0; i< refCount; i++) {
        //     if (i<(refCount-1)) {
        //         if (refIds[i]==refIds[i+1]) {
        //             TopLevelError tle = new TopLevelError();
        //             tle.errorCode = 'INVALID_INPUT';
        //             tle.message = 'Duplicate ReferenceId provided in the request: ' + refIds[i];
        //             resp.responseBody = blob.valueOf(JSON.serialize(new List<TopLevelError>{tle}));
        //             resp.statusCode = 403;
        //             return;  
        //         }
        //     }
        // }

        
        Quote[] quoteRecords = (List<Quote>) JSON.deserialize(JSON.serialize(records), List<Quote>.class);
        Map<String, Quote> refQuoteMap = new Map<String, Quote>();
        
        for (integer i=0; i<refIds.size(); i++) {
            refQuoteMap.put(refIds[i], quoteRecords[i]);
        }
        if ((resp.statusCode==null) || resp.statusCode==200) {
            result = processQuotesForNewOpps(refQuoteMap);
        }
        
        resp.responseBody = blob.valueOf(result);        
    }
    
    private static SM_Configs__c config {
        get {
            if (config==null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    }    
    
    private static String processQuotesForNewOpps(Map<String, Quote> refQuoteMap) {
        String status = '';
        Map<String, object> refResultMap = new Map<String, object>();
        Map<String, opportunity> quoteToOppMap = new Map<String, Opportunity>();
        Map<String, Id> oppRTMap = new Map<String, Id>(); 
        Map<String, String> oppStageNameMap = new Map<String, String>();
        Map<String, Opportunity> existingOppsMap = new Map<String, Opportunity>();
        Set<String> cosIds = new Set<String>();        
        
        oppRTMap.put('AUSTRALIA', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AU_Store_Initiated_Opportunity').getRecordTypeId());
        oppRTMap.put('NEW ZEALAND', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NZ_Store_Initiated_Opportunity').getRecordTypeId());
        
        oppStageNameMap.put('AUSTRALIA', 'Proposal');
        oppStageNameMap.put('NEW ZEALAND', 'Pending');
        
        for (String key : refQuoteMap.keySet()) {
            Quote quotation = refQuoteMap.get(key);
            cosIds.add(COS_OPP_ID_PREFIX + quotation.COS_ID__c);
        }
		
        
        for (Opportunity opp : [SELECT Id, COS_Opportunity_ID__c FROM Opportunity WHERE COS_Opportunity_ID__c IN :cosIds ]) {
            existingOppsMap.put(opp.COS_Opportunity_ID__c, opp);
        }        
        
        for (String key : refQuoteMap.keySet()) {
            Quote quotation = refQuoteMap.get(key);
            String OppCOSId = COS_OPP_ID_PREFIX + quotation.COS_ID__c;
            // if ((String.isblank(quotation.OpportunityId)) && !existingOppsMap.containsKey(OppCOSId)) {
            if ((String.isblank(quotation.OpportunityId) || quotation.OpportunityId == null) && !existingOppsMap.containsKey(OppCOSId)) { // CRMS-452
                Opportunity opp = new Opportunity();
                opp.COS_Opportunity_ID__c = OppCOSId;
                opp.Country__c = quotation.Country__c;
                opp.Name = quotation.Name;
                opp.Originating_Store__r = quotation.Assigned_Store__r;
                opp.Account = quotation.Account;
                
                switch on quotation.Status.toLowerCase() {
                    when 'submitted' {
                        opp.StageName = 'Closed Won';
                    }
                    
                    when 'pricing_only_quote','cancelled', 'pricingonlyquote' { // BUNDIG-44073
                        opp.StageName = 'Closed Lost';
                    }
                    
                    when 'enquiry', 'quote' {
                        opp.StageName = oppStageNameMap.get(quotation.Country__c.toUpperCase());
                    }
                }	
                
                opp.CloseDate = quotation.ExpirationDate;
                opp.Amount = quotation.Total_Value_Excl_Gst__c;
                opp.Loss_Reason__c = quotation.Cancellation_Reason__c;
                opp.Loss_Reason_Comments__c = quotation.Cancellation_Comments__c;
                opp.RecordTypeId = oppRTMap.get(quotation.Country__c.toUpperCase());
                quotation.Opportunity = new Opportunity(COS_Opportunity_ID__c=OppCOSId);
                quoteToOppMap.put(key,opp);
            }
        }               
        
        if (quoteToOppMap.size()>0) {            
            Database.SaveResult[] srs = Database.insert(quoteToOppMap.values(), false);
            integer index = 0;
            for (String key : quoteToOppMap.keySet()) {
                Database.SaveResult rs = srs[index];
                Database.error err;
                if (!rs.isSuccess()) {
                    err = rs.getErrors()[0];
                    ErrorItem ei = new ErrorItem();
                    ei.statusCode = string.valueOf(err.getStatusCode());
                    ei.message = err.getMessage();
                    ei.fields = err.getFields();
                    
                    ResultItem ri = new ResultItem();
                    ri.referenceId = key;                    
                    ri.errors = new List<ErrorItem>{ei};
                        refResultMap.put(key, ri);
                }
                index++;
            }             
        }
        
        Opportunity[] oppsToUpdate = new List<Opportunity>();    
        
        //remove items that had errors
        for (String key : refResultMap.keySet()) {
            quoteToOppMap.remove(key);
            refQuoteMap.remove(key);
        }
        
        for (String key : quoteToOppMap.keySet()) {
            Quote quotation = refQuoteMap.get(key);
            Opportunity opp = new Opportunity(COS_Opportunity_ID__c=COS_OPP_ID_PREFIX + quotation.COS_ID__c);
            opp.SyncedQuote = new Quote(COS_ID__c=quotation.COS_ID__c);
            oppsToUpdate.add(opp);
        }          
        
        if (refQuoteMap.size()>0) {
            Database.UpsertResult[] urs = Database.upsert(refQuoteMap.values(), Quote.Fields.COS_ID__c,false);
            integer index = 0;
            for (String key : refQuoteMap.keySet()) {
                Database.UpsertResult ur = urs[index];
                ResultItem ri = new ResultItem();
                ri.referenceId = key;
                ri.id = refQuoteMap.get(key).Id; 
                ri.created = ur.created;
                ri.success = ur.success;
                if (!ur.isSuccess()) {
                    Database.Error err = ur.getErrors()[0];
                    ErrorItem ei = new ErrorItem();
                    ei.statusCode = string.valueof(err.getStatusCode());
                    ei.message = err.getMessage();
                    ei.fields = err.getFields();
                    
                    ri.referenceId = key;       
                    ri.errors = new List<ErrorItem>{ei};
                }
                refResultMap.put(key, ri);   
                index++;
            }
            
            // CRMS-449 - Commented out to handle try catch
            //urs = Database.upsert(oppsToUpdate,Opportunity.Fields.COS_Opportunity_ID__c,true);                                        
            Database.UpsertResult[] results = Database.upsert(oppsToUpdate, Opportunity.Fields.COS_Opportunity_ID__c, false);

            List<ApplicationLog__c> errorLogs = new List<ApplicationLog__c>();


            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                Opportunity oppty = oppsToUpdate[i];

                if (result.isSuccess()) {
                    /* Do Nothing */
                } else {
                    for (Database.Error err : result.getErrors()) {
                        ApplicationLog__c log = new ApplicationLog__c(
                            Error_Message__c = err.getMessage(),
                            Function_Name__c = 'SM_RESTQuoteInsertHandler - Create Oppty',
                            Method__c = 'processQuotesForNewOpps',
                            Object_Name__c = 'Opportunity',
                            Object_Id__c = oppty.COS_Opportunity_ID__c
                        );
                        errorLogs.add(log);
                    }
                }
            }

            if (!errorLogs.isEmpty()) {
                try {
                    insert errorLogs;
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Failed to insert error logs: ' + e.getMessage());
                }
            }
        }        		
        
        status = JSON.serialize(refResultMap.values());         
        System.debug(LoggingLevel.DEBUG, 'STATUS:\n\n' + status);  
        
        return status;
    }
}