/*******************************************************************************************************
* Class Name      	: QuoteTriggerHandler
* Description		: Trigger Handler for Quote Object
* Author          	: Bunnings Dev
* Created On      	: 22/02/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          22/02/2022		1000				SFSUP-51 - Conversion of Process Builder (Quote Create/Update Actions)
*															and Flow (COS Quote Initialisations, COS Quote and Opportunity Sync, 
*															COS Quote and Opportunity Sync, COS Quote to Opportunity Totals Sync)
* Simplus MS            30/05/2022		2000				SFSUP-738 - Opportunity has not updated the syncing quote, 
*                                                            therefore the opp value is incorrect
* Jasper R. Galapon     17/08/2023      3000                BUNDIG-24085 - Fix future call error when loading COS data
* Jasper R. Galapon     19/03/2025      3001                CRMS-470 - AU Store Initiated Opportunities created in Salesforce without any Quotes
* Jasper R. Galapon     07/05/2025      3002                BUNDIG-44073 - Update logic to include COS order token with Status = 'PricingOnlyQuote'
******************************************************************************************************/
public class QuoteTriggerHandler {
    
    public static final Id qtRtId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('COS_Quote').getRecordTypeId();
    
    public static void beforeInsert(List<Quote> lstNewQuote) {
        System.debug('beforeInsert: '+lstNewQuote);
    }

    public static void afterInsert(List<Quote> lstNewQuote) {
        // Quote Create Action: COS Quote Initialisations Flow
        newCOSQuoteInitialisations(lstNewQuote);
    }
    
    public static void afterUpdate(Map<Id, Quote> oldMap, Map<Id, Quote> newMap) {
        // Quote Update Action: COS Quote and Opportunity Sync
        System.debug('***updateCOSQuoteAndOppSync');
        updateCOSQuoteAndOppSync(oldMap, newMap.values());
    }

    /**
    * @description SFSUP-738: Quote Create Action: COS Quote Initialisations Flow
    * @author Simplus MS | 31/05/2022
    * @param lstNewQuote
    **/
    @testVisible 
    private static void newCOSQuoteInitialisations(List<Quote> lstNewQuote) {

        Set<Id> oppIds = new Set<Id>();		                    // use to get all oppty information
        Set<Id> opptyIds = new Set<Id>();	                    // use to filter oppty related to quotes
        Map<Id, ID> opptyToUpdateMap = new Map<Id, ID>();       // used for cos Quote And Opportunity Sync

        for (Quote qt : lstNewQuote) {            
            if (qt.OpportunityId != null)
                oppIds.add(qt.OpportunityId);                        
        }
        
        if (!oppIds.isEmpty()) {
            // Get all opportunity information associated to the quote
            Map<Id, Opportunity> mapOppty = new Map<Id, Opportunity>([SELECT Id, StageName, RecordType.DeveloperName FROM Opportunity WHERE Id IN :oppIds]);
            
            for (Quote qt : lstNewQuote) {
                if (qt.COS_ID__c != null && mapOppty.get(qt.OpportunityId).RecordType.DeveloperName != 'Organisation_Tender_Opportunity' && mapOppty.get(qt.OpportunityId).StageName != 'Closed Won') {                
                    //qt.RecordTypeId = qtRtId;
                    opptyIds.add(qt.OpportunityId);
                    opptyToUpdateMap.put(qt.Id, qt.OpportunityId);
                }
                System.debug(LoggingLevel.FINEST, '***AFTER INSERT opptyIds: ' + opptyIds);
                //SFSUP-792 - Sync S&I Opportunities
              /*  if (qt.Name != null && mapOppty.get(qt.OpportunityId).RecordType.DeveloperName == 'Supply_Install_Opportunity' && mapOppty.get(qt.OpportunityId).StageName != 'Closed Won') {
                    //qt.RecordTypeId = qtRtId;
                     opptyIds.add(qt.OpportunityId);
                     opptyToUpdateMap.put(qt.Id, qt.OpportunityId);
               }   */         
            }
           

            // Quote Create Action: COS Quote Initialisations Flow
            // BUNDIG-24085 - Commented out to fix future method issue
            // cosQuoteAndOppSync(opptyToUpdateMap);

            System.debug('***opptyToUpdateMap: ' + opptyToUpdateMap);

            Initialisation__mdt init = DM_Initialisation.getCCRMInitialisation();
            List<String> exemptionProfile = init.Staging_Object_Exemption_Profile__c.split(', ');
            System.debug(LoggingLevel.FINEST, '***exemptionProfile: ' + exemptionProfile);
    
            // Get Running User Details
            User runningUser = DM_User.getUser(UserInfo.getUserId());
            System.debug(LoggingLevel.FINEST, '***runningsUser: ' + runningUser);
    
            if (runningUser != null && !exemptionProfile.contains(runningUser.Profile.Name)) {
                System.debug(LoggingLevel.FINEST, '***Non-admin user');
                cosQuoteAndOppSync(opptyToUpdateMap);
            
                // Quote Create Action: COS Quote and Opportunity Sync Flow
                cosQuoteAndOppSync(cosQuoteAndOpportunitySync(opptyIds, lstNewQuote, null));
            } else {
                System.debug(LoggingLevel.FINEST, '***Admin user');
                System.enqueueJob(new SM_CosQuoteAndOppSyncQueueable(opptyToUpdateMap));
            }
        }
    }
    
    /**
    * @description SFSUP-738: Based on received map this method sync quote with oppoortunity
    * @author Simplus MS | 31/05/2022
    * @param map of oppToUpdateMap
    **/
    @future
    public static void cosQuoteAndOppSync(Map<Id, Id> oppToUpdateMap) {
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        if (!oppToUpdateMap.isEmpty()) {
            for (Id key : oppToUpdateMap.keySet()) {
                oppUpdateList.add(new Opportunity(Id = oppToUpdateMap.get(key), SyncedQuoteId = key));
            }
        }
        if (!oppUpdateList.isEmpty()) {
            try {
                UPDATE oppUpdateList;
            } catch (Exception e) {
                ApplicationLogger.log('QuoteTriggerHandler.cosQuoteAndOppSync', 'Quote', 'Trigger', e);
            }            
        }
    }
    
    /**
    * @description SFSUP-738: Quote Update Action: COS Quote and Opportunity Sync
    * @author Simplus MS | 31/05/2022
    * @param lstNewQuote
    **/
    @testVisible
    private static Map<Id, Opportunity> updateCOSQuoteAndOppSync(Map<Id, Quote> mapOldQuote, List<Quote> lstNewQuote) {
                
        Set<Id> opptyIds = new Set<Id>();	// use to filter oppty related to quotes
        Map<Id, Opportunity> opptyUpdate = new Map<Id, Opportunity>();
                        
        for (Quote qt : lstNewQuote) {                
            if (qt.COS_ID__c != null && qt.Opportunity.RecordType.DeveloperName != 'Organisation_Tender_Opportunity' && qt.Opportunity.StageName != 'Closed Won') {
                opptyIds.add(qt.OpportunityId);
            }            
        }
        System.debug(LoggingLevel.FINEST, '***opptyIds: ' + opptyIds);
        if (!opptyIds.isEmpty()) {
            for (Quote qt : lstNewQuote) {               

                Quote oldQuote = mapOldQuote?.get(qt.Id);

                // BUNDIG-44073 - Start
                String lossReason = '';
                //String lossReason = qt.Status == 'Pricing Only Quote' ? 'Pricing Only Quote' : qt.Cancellation_Reason__c;
                System.debug(LoggingLevel.FINEST, '***qt.Cancellation_Reason: ' + qt.Cancellation_Reason__c);

                if (qt.Cancellation_Reason__c != null) {
                    lossReason = qt.Cancellation_Reason__c;
                } else if (qt.Status == 'Pricing Only Quote' || qt.Status == 'PricingOnlyQuote') {
                    lossReason = 'Closed Lost - Pricing';
                }
                System.debug(LoggingLevel.FINEST, '***lossReason : ' + lossReason);
                // BUNDIG-44073 - End

                Date qtCancelDt = qt.ExpirationDate != null ? qt.ExpirationDate : null;			
    
                if (qt.COS_ID__c != null && qt.Opportunity.RecordType.DeveloperName != 'Organisation_Tender_Opportunity' &&
                    (qt.Opportunity.StageName != 'Closed Won' || (qt.Opportunity.StageName == 'Closed Won' && qt.IsSyncing)) &&
                    (qt.Total_GP__c != oldQuote?.Total_GP__c || qt.Cancellation_Reason__c != oldQuote?.Cancellation_Reason__c || 
                    qt.Total_Value_excl_GST__c != oldQuote?.Total_Value_excl_GST__c || qt.Cancellation_Comments__c != oldQuote?.Cancellation_Comments__c ||
                    qt.ExpirationDate != oldQuote?.ExpirationDate)) {
                        //if(opptyUpdate.containsKey(qt.OpportunityId)) {
                            opptyUpdate.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                                                                Amount = qt.Total_Value_excl_GST__c,
                                                                                //StageName = opptyUpdate.get(qt.OpportunityId).StageName,
                                                                                Loss_Reason__c = lossReason, 
                                                                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c,
                                                                                SyncedQuoteId = qt.Id,
                                                                                Primary_Quote_Expiry_Date__c = qtCancelDt));
                        //}
                }
                                
            }
            
            System.debug('***opptyUpdate: '+opptyUpdate.values());

            // Quote Update Action: COS Quote and Opportunity Sync Flow
            // Future method cannot be called from a future or batch method
            if(System.IsBatch() == false && System.isFuture() == false){ 
                // make your future call here
                cosQuoteAndOppSync(cosQuoteAndOpportunitySync(opptyIds, lstNewQuote, mapOldQuote));

                //COS Quote To Opportunity TotalsSync action
                if (!opptyUpdate.isEmpty()) {
                    //Using JSON.Serialize method we can convert the Opportunity list to Json
                    // Pass the JSON String to the Future method
                    cosQuoteToOpportunityTotalsSync(json.serialize(opptyUpdate.values()));
                }
            }
            
            
            /*if (!opptyUpdate.isEmpty()) {
                try {
                    UPDATE opptyUpdate.values();
                } catch (Exception e) {
                    ApplicationLogger.log('QuoteTriggerHandler.updateCOSQuoteAndOppSync', 'Quote', 'Trigger', e);
                }            
            }*/
            
            return opptyUpdate;
        } else {
            return null;
        }
    }

    /**
    * @description SFSUP-738: Based on received JSON this method sync quote with 
    * oppoortunity for: COS Quote To Opportunity TotalsSync flow
    * @author Simplus MS | 15/06/2022
    * @param map of oppToUpdateMap
    **/
    @future
    public static void cosQuoteToOpportunityTotalsSync(String jsonString) {
        //deserialize the JSON to the Account List
        List<Opportunity> oppUpdateList = (List<Opportunity>)Json.deserialize(jsonString, List<Opportunity>.class);
        if (!oppUpdateList.isEmpty()) {
            try {
                UPDATE oppUpdateList;
            } catch (Exception e) {
                ApplicationLogger.log('QuoteTriggerHandler.cosQuoteToOpportunityTotalsSync', 'Quote', 'Trigger', e);
            }            
        }
    }
    
    /**
    * @description SFSUP-738: Quote Create/Update Action: COS Quote and Opportunity Sync
    * @author Simplus MS | 31/05/2022
    * @param Set<Id> oppIds, List<Quote> newQuote, Map<Id, Quote> oldQuot
    **/
    private static Map<Id, Id> cosQuoteAndOpportunitySync(Set<Id> oppIds, List<Quote> newQuote, Map<Id, Quote> oldQuote) {
        
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        Map<Id, Id> cosQuoteAndOppSync = new Map<Id, Id>();
                        
        Map<Id, Opportunity> mapOppty = new Map<Id, Opportunity>([SELECT Id, StageName, RecordType.DeveloperName, Loss_Reason__c,
			Loss_Reason_Comments__c, Primary_Quote_Expiry_Date__c
			FROM Opportunity WHERE Id IN :oppIds]);

        Map<Id, Opportunity> mapOpenQtsWithOpp = new Map<Id, Opportunity>([SELECT Id, (SELECT Id, Status 
        FROM Quotes WHERE Status NOT IN ('Cancelled','Pricing_Only_Quote', 'PricingOnlyQuote') ORDER BY LastModifiedDate DESC LIMIT 1) // BUNDIG-44073
        FROM Opportunity WHERE Id IN :oppIds]);       
        for (Quote qt : newQuote) {
            Quote oldQt = oldQuote != null ? oldQuote?.get(qt.Id) : null;
			
            String opptyRt = mapOppty.get(qt.OpportunityId) != null ? mapOppty.get(qt.OpportunityId).RecordType.DeveloperName : null;
            String opptyStage = mapOppty.get(qt.OpportunityId) != null ? mapOppty.get(qt.OpportunityId).StageName : null;

            // BUNDIG-44073 - Start
            String lossReason = '';
            //String lossReason = qt.Status == 'Pricing_Only_Quote' ? 'Pricing_Only_Quote' : qt.Cancellation_Reason__c;
            System.debug(LoggingLevel.FINEST, '***qt.Cancellation_Reason: ' + qt.Cancellation_Reason__c);

            if (qt.Cancellation_Reason__c != null) {
                lossReason = qt.Cancellation_Reason__c;
            } else if (qt.Status == 'Pricing Only Quote' || qt.Status == 'PricingOnlyQuote') {
                lossReason = 'Closed Lost - Pricing';
            }
            System.debug(LoggingLevel.FINEST, '***lossReason: ' + lossReason);
            // BUNDIG-44073 - End

            Date qtCancelDt = qt.ExpirationDate != null ? qt.ExpirationDate : null;                        
            System.debug('qt.Status: '+qt.Status+' oldQt: '+oldQt+' opptyRt: '+opptyRt+' opptyStage: '+opptyStage);

            if(oldQuote == null){
                // When Insert: Sync Opportunity - COS Quote and Opportunity Sync
                // CRMS-347 - Added Oppty BDM Contract Record Type
                if (opptyRt != 'Organisation_Tender_Opportunity' && opptyStage != 'Closed Won') {
                                                                                    
                    if (qt.Status == 'Cancelled' || qt.Status == 'Pricing_Only_Quote' || qt.Status == 'PricingOnlyQuote') { // BUNDIG-44073
                        
                        // CRMS-470 - Added null checking
                        if (mapOpenQtsWithOpp.get(qt.OpportunityId) == null || mapOpenQtsWithOpp.get(qt.OpportunityId).Quotes.size() == 0) {
                            if (qt.Status == 'Cancelled') {
                                mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                    StageName = 'Closed Lost', 
                                    Loss_Reason__c = lossReason, 
                                    Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                    Amount = qt.Total_Value_excl_GST__c,
                                    Primary_Quote_Expiry_Date__c = qtCancelDt));
                            }
                            if (qt.Status == 'Pricing_Only_Quote' || qt.Status == 'PricingOnlyQuote') { // BUNDIG-44073
                                mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, StageName = 'Closed Lost', Loss_Reason__c = 'Closed Lost - Pricing'));
                            }
                        } else {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, Loss_Reason__c = null, Loss_Reason_Comments__c = qt.Cancellation_Comments__c));
                            cosQuoteAndOppSync.put(mapOpenQtsWithOpp.get(qt.OpportunityId).Quotes[0].Id, qt.OpportunityId);
                        }
                    }
                    if (qt.Status == 'Submitted') {
                        mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                            StageName = 'Closed Won', 
                            Loss_Reason__c = lossReason, 
                            Loss_Reason_Comments__c = qt.Cancellation_Comments__c,
                            Amount = qt.Total_Value_excl_GST__c,
                            Primary_Quote_Expiry_Date__c = qtCancelDt));                    
                    }
                    if (qt.Status == 'Enquiry' || qt.Status == 'Quote') {
                        if (opptyRt == 'NZ_Standard_Opportunity' || opptyRt == 'NZ_Store_Initiated_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Pending', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));                        
                        }
                        if (opptyRt == 'NZ_Schedule_Opportunity' || opptyRt == 'NZ_Farm_Shed_Opportunity' || opptyRt == 'NZ_Estimate_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));                        
                        }
                        if (opptyRt == 'AU_Standard_Opportunity' || opptyRt == 'AU_Store_Initiated_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));
                        }
                        if (opptyRt == 'Supply_Install_Opportunity') {
                            // SFSUP-792 - Sync S&I Opportunities 
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal in Progress', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));
                        }
                        
                    }                
                }
            }else{
                // When Update: Sync Opportunity - COS Quote and Opportunity Sync
                if ((qt.Status != oldQt?.Status && oldQuote != null) && qt.RecordTypeId == qtRtId && opptyRt != 'Organisation_Tender_Opportunity' && opptyStage != 'Closed Won') {                                                                       
                    if (qt.Status == 'Cancelled' || qt.Status == 'Pricing_Only_Quote' || qt.Status == 'PricingOnlyQuote') {  // BUNDIG-44073  
                        
                        // CRMS-470 - Added null checking
                        if (mapOpenQtsWithOpp.get(qt.OpportunityId) == null || mapOpenQtsWithOpp.get(qt.OpportunityId).Quotes.size() == 0) {
                            if (qt.Status == 'Cancelled') {
                                mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                    StageName = 'Closed Lost', 
                                    Loss_Reason__c = lossReason, 
                                    Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                    Amount = qt.Total_Value_excl_GST__c,
                                    Primary_Quote_Expiry_Date__c = qtCancelDt));                            
                            }
                        
                            if (qt.Status == 'Pricing_Only_Quote' || qt.Status == 'PricingOnlyQuote') {  // BUNDIG-44073                        
                                mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, StageName = 'Closed Lost', Loss_Reason__c = 'Closed Lost - Pricing'));
                            }
                        } else {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, Loss_Reason__c = null, Loss_Reason_Comments__c = qt.Cancellation_Comments__c));
                            cosQuoteAndOppSync.put(mapOpenQtsWithOpp.get(qt.OpportunityId).Quotes[0].Id, qt.OpportunityId);
                        }
                    }
                    if (qt.Status == 'Submitted') {
                        mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                            StageName = 'Closed Won', 
                            Loss_Reason__c = lossReason, 
                            Loss_Reason_Comments__c = qt.Cancellation_Comments__c,
                            Amount = qt.Total_Value_excl_GST__c,
                            Primary_Quote_Expiry_Date__c = qtCancelDt));                    
                    }
                    if (qt.Status == 'Enquiry' || qt.Status == 'Quote') {
                        if (opptyRt == 'NZ_Standard_Opportunity' || opptyRt == 'NZ_Store_Initiated_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Pending', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));                        
                        }
                        if (opptyRt == 'NZ_Schedule_Opportunity' || opptyRt == 'NZ_Farm_Shed_Opportunity' || opptyRt == 'NZ_Estimate_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));                        
                        }
                        if (opptyRt == 'AU_Standard_Opportunity' || opptyRt == 'AU_Store_Initiated_Opportunity') {
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));
                        }
                        if (opptyRt == 'Supply_Install_Opportunity') {
                            // SFSUP-792 - Sync S&I Opportunities 
                            mapOpp.put(qt.OpportunityId, new Opportunity(Id = qt.OpportunityId, 
                                StageName = 'Proposal in Progress ', 
                                Amount = qt.Total_Value_excl_GST__c,
                                Loss_Reason__c = lossReason,
                                Loss_Reason_Comments__c = qt.Cancellation_Comments__c, 
                                Primary_Quote_Expiry_Date__c = qtCancelDt));
                        }
                    }
                }
            }
        }
            
        if (!mapOpp.isEmpty()) {
            try {
                UPDATE mapOpp.values();
            } catch (Exception e) {
                ApplicationLogger.log('QuoteTriggerHandler.cosQuoteAndOpportunitySync', 'Quote', 'Trigger', e);
            }            
        }
        return cosQuoteAndOppSync;
    }
}