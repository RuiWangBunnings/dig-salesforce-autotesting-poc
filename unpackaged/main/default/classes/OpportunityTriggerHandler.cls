/*******************************************************************************************************
* Class Name      	: OpportunityTriggerHandler
* Description		: Trigger Handler for Opportunity Object
* Author          	: Simplus - Yi Zhang
* Created On      	: 12/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              12/08/2020		1000				Initial version
* Simplus MS            01/12/2020      1001                New changes for CCRM-6890 & CCRM-6892 enhancement
* Simplus MS            22/12/2020      1002                Changes in beforeInsert and beforeUpdate for CCRM-8582
* Simplus MS			23/04/2021		1003				Changes in sendCloseOpptiesToCOS for CCRM-13532
* Simplus MS 			03/05/2021		1004				Changes in sendCloseOpptiesToCOS
* Simplus MS 			27/05/2021		1005				Changes in getOrderToken for adding Cancelled Quote Status for CCRM 13809
* Simplus MS 			04/06/2021		1006				Changes in afterUpdate for CCRM-13848 Fix SOQL 101 issue
* Simplus MS 			17/02/2022		1007				Exclude Integration Users SFSUP-352 in validation errors
* Bunnings Dev			24/10/2024      1008                CRMS-232 Exclude New Integration User 2 from Triggering Quote/Opp Outbound Integration from Salesforce
* Bunnings Dev          2024-10-30      1009                CRMS-200 Update Follow Up Date for AU Opportunity
* Bunnings Dev          2024-11-01      1010                CRMS202 - Update Follow Up Date for NZ Opportunity
* Bunnings Dev          2024-11-21      1011                CRMS204 - Update Supplier Quote for Closed Won
* Bunnings Dev          2024-12-06      1012                CRMS201 - PB Opportunity Create Action Conversation - New Opp Notification
******************************************************************************************************/
public with sharing class OpportunityTriggerHandler {
    
    public static final String CLOSED_WON_ERROR_MULTIPLE_ACTIVE_QUOTES = 'There are multiple active quotes associated to this opportunity. Please submit or cancel the quotes in COS directly.';
    public static final String CLOSED_WON_ERROR_QUOTES_CANCELLED = 'The quotes/enquiries associated to this opportunity have already been cancelled. Create a new quote on this opportunity to proceed, or create a new opportunity.';
    public static final String CLOSED_LOST_QUOTE_SUBMITTED = 'This opportunity has already been submitted to order. Please cancel the order/s as required.';
    
    /* @description - Static boolean variable added to avoid recursion */
    public static Boolean isFirstTime = true;

    /**
    * @description base 64 encode site address
    * @author Ramtej Juloori | 30/10/2020 
    * @param newList 
    **/
    public static void beforeInsert(List<Opportunity> newList) {
		encodeSiteAddress(newList); // CCRM - 8582 Encode Site address

        // CRMS-200 Update Follow Up Date for AU Opportunity
        System.debug('DM_FeatureToggle.getFeatureToggleEnabled(Update_AU_Opportunity_Follow_Up_Date):'+DM_FeatureToggle.getFeatureToggleEnabled('Update_AU_Opportunity_Follow_Up_Date'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('Update_AU_Opportunity_Follow_Up_Date')){
            System.debug('beforeinsertFollow up date ');
            updateAUOpptyFollowUpDate('before insert',null, null,newList);
        }
        // END - CRMS-200 Update Follow Up Date for AU Opportunity


        // CRMS202 - Update Follow Up Date for NZ Opportunity
        System.debug('DM_FeatureToggle.getUpdateNZOpptyFollowUpDate():'+DM_FeatureToggle.getFeatureToggleEnabled('Update_NZ_Opportunity_Follow_Up_Date'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('Update_NZ_Opportunity_Follow_Up_Date')){
            System.debug('beforeinsertFollow up date ');
            updateNZOpptyFollowUpDate('before insert',null, null,newList);
        }
        // END - CRMS202 - Update Follow Up Date for NZ Opportunity


    }
    /**
    * @description after insert
    * @author Bunnings dev | 30/11/2024 
    * @param newList 
    **/
    public static void afterInsert(Map<Id, Opportunity> newMap) {

        
        // CRMS201 - PB Opportunity Create Action Conversation - New Opp Notification
        System.debug('DM_FeatureToggle.New_Pricing_Oppty_Bell_Notification():'+DM_FeatureToggle.getFeatureToggleEnabled('New_Pricing_Oppty_Bell_Notification'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('New_Pricing_Oppty_Bell_Notification')){
            System.debug('beforeinsert New_Pricing_Oppty_Bell_Notification');
            sendNewOpportunityBellNotification(newMap);
        }
        // END - PB Opportunity Create Action Conversation - New Opp Notification
    }
    /**
    * @description base 64 encode site address
    * @author Ramtej Juloori | 30/10/2020 
    * @param newMap, oldMap
    * New Update below
    * @author Simpus MS | 08/12/2020
    * @description - Conditional validations added for CCRM-6890 & CCRM-6892
    **/
    public static void beforeUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        encodeSiteAddress(newMap.values()); // CCRM - 8582 Encode Site address
        
        // Below code added as part of CCRM-6890 & CCRM-6892

        /* Below code commented for CCRM-8582 Deployment */
        Map<Id, Opportunity> closedWonOppties = new Map<Id, Opportunity>();
        Map<Id, Opportunity> closedLostOppties = new Map<Id, Opportunity>();
        List<String> integrationUsers = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');//CCRM15-412
        User user = DM_User.getUser(UserInfo.getUserId());
        System.debug('integrationUsers.contains(user.Profile.Name)'+integrationUsers.contains(user.Profile.Name));
            for(Id opptyId : oldMap.keySet()) {
                Opportunity oldOppty = oldMap.get(opptyId);
                Opportunity newOppty = newMap.get(opptyId);
                if(oldOppty.StageName != Constants.OPPTY_STAGE_CLOSED_WON && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON) {
                    closedWonOppties.put(opptyId, newOppty);
                }else if(oldOppty.StageName != Constants.OPPTY_STAGE_CLOSED_LOST && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST) {
                    closedLostOppties.put(opptyId, newOppty);
                }else if(oldOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON ){
                    closedWonOppties.put(opptyId, newOppty);
                }else if(oldOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST ){
                    closedLostOppties.put(opptyId, newOppty);
                }
            }
            
            if(closedWonOppties.size() > 0 || closedLostOppties.size() > 0){
                List<Id> opptyIds = new List<Id>(closedWonOppties.keySet());
                opptyIds.addAll(closedLostOppties.keySet());
                Map<Id, Opportunity> opptiesWithQuotes = DM_Opportunity.getOpportunitiesWithQuotes(opptyIds);

                for(Id opptyId : closedWonOppties.keySet()){
                    Opportunity opptyWithQuotes = opptiesWithQuotes.get(opptyId);
                    if(opptyWithQuotes.Quotes.size() > 0){
                        Integer activeQuotesCount = countActiveQuotes(opptyWithQuotes.Quotes);
                        if(allQuotesCancelled(opptyWithQuotes.Quotes) == true && !integrationUsers.contains(user.Profile.Name)) {//Exclude Integration Users SFSUP-352
                            newMap.get(opptyId).addError(CLOSED_WON_ERROR_QUOTES_CANCELLED);
                        }else if(activeQuotesCount > 1 && allQuotesActive(opptyWithQuotes.Quotes) == true && !integrationUsers.contains(user.Profile.Name)) {//Exclude Integration Users CCRM15-412
                            newMap.get(opptyId).addError(CLOSED_WON_ERROR_MULTIPLE_ACTIVE_QUOTES);
                        } 
                    }
                }

                for(Id opptyId : closedLostOppties.keySet()){
                    Opportunity opptyWithQuotes = opptiesWithQuotes.get(opptyId);
                    if(opptyWithQuotes.Quotes.size() > 0){
                        if(anyQuoteSubmitted(opptyWithQuotes.Quotes) == true && !integrationUsers.contains(user.Profile.Name)) { //Exclude Integration Users SFSUP-352
                            newMap.get(opptyId).addError(CLOSED_LOST_QUOTE_SUBMITTED);
                        }
                    }
                }
            }
            
            // End of code changes as part of CCRM-6890,6892
            // CRMS-200 Update Follow Up Date for AU Opportunity
            System.debug('DM_FeatureToggle.getFeatureToggleEnabled(Update_AU_Opportunity_Follow_Up_Date):'+DM_FeatureToggle.getFeatureToggleEnabled('Update_AU_Opportunity_Follow_Up_Date'));
            if(DM_FeatureToggle.getFeatureToggleEnabled('Update_AU_Opportunity_Follow_Up_Date')){
              System.debug('beforeupdateFollow up date ');
                updateAUOpptyFollowUpDate('before update',oldMap, newMap,null);
            }
            // END - CRMS-200 Update Follow Up Date for AU Opportunity

            // CRMS202 - Update Follow Up Date for NZ Opportunity
            System.debug('DM_FeatureToggle.getUpdateNZOpptyFollowUpDate():'+DM_FeatureToggle.getFeatureToggleEnabled('Update_NZ_Opportunity_Follow_Up_Date'));
            if(DM_FeatureToggle.getFeatureToggleEnabled('Update_NZ_Opportunity_Follow_Up_Date')){
                System.debug('beforeinsertFollow up date ');
            updateNZOpptyFollowUpDate('before update',oldMap, newMap,null);
        }
        // END - CRMS202 - Update Follow Up Date for NZ Opportunity
    }
    
    /**
    * @description 
    * @author Yi Zhang | 12/08/2020 
    * @author Simplus MS | 04/12/2020
    * @param oldMap 
    * @param newMap 
    **/
    /* Below code commented for CCRM-8582 deployment */
    public static void afterUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        
        //CRMS-232 Exclude New Integration User 2 from Triggering Quote/Opp Outbound Integration from Salesforce
        String integrationUserId = Config.Integration_User_2__c;
        System.debug('integrationUserId;'+integrationUserId);
        System.debug('Userinfo.getUserName();'+Userinfo.getUserName());
        if(!(Userinfo.getUserName() == integrationUserId)){
            System.debug('sendCloseOpptiesToCOS: Not an integration 2 user');   
            sendCloseOpptiesToCOS(oldMap, newMap);
        }
       

        //CRMS - 203 Send Bell notification to the Owner when Au Std Opportunity with Closed Lost Stage
        System.debug('DM_FeatureToggle.AU_Stnd_Oppty_Close_LostBellNotification():'+DM_FeatureToggle.getFeatureToggleEnabled('AU_Stnd_Oppty_Close_LostBellNotification'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('AU_Stnd_Oppty_Close_LostBellNotification')){
        sendStdAUCloseLostOpptiesBellNotification(oldMap, newMap);
        }
        /** Removed by Simplus MS - 04.Jun.2021 - CCRM-13848 Fix SOQL 101 issue
        for(Id oppId : newMap.keySet()){
            sendCloseOpptiesToCOS(oldMap, newMap);
        } 
		**/


        //CRMS - 204 PB Opportunity Update Action Conversation - Update Supplier Quote for Closed Won
        System.debug('DM_FeatureToggle.Update Supplier Quote for Closed Won:'+DM_FeatureToggle.getFeatureToggleEnabled('Update_Supplier_Quote_for_Closed_Won'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('Update_Supplier_Quote_for_Closed_Won')){
        updateSupplierQuotesStatus(oldMap, newMap,'Accepted');
        }
        
        //CRMS - 205 PB Opportunity Update Action Conversation - Update Supplier Quote for Closed Lost
        System.debug('DM_FeatureToggle.Update Supplier Quote for Closed Lost:'+DM_FeatureToggle.getFeatureToggleEnabled('Update_Supplier_Quote_for_Closed_Lost'));
        if(DM_FeatureToggle.getFeatureToggleEnabled('Update_Supplier_Quote_for_Closed_Lost')){
        updateSupplierQuotesStatus(oldMap, newMap,'Lost');
        }

    }
    


    /**
    * @description - Changes added as part of CCRM-6890 & CCRM-6892
    * @author Yi Zhang | 13/08/2020 
    * @author Simplus MS | 07/12/2020
    * @param oldMap 
    * @param newMap 
    **/
    public static void sendCloseOpptiesToCOS(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        /* Below map created to keep Opportunity Record Type configurable by querying from Customer Metadata */
        Map<String, String> recordTypeMap = new Map<String, String>();
        for(Opportunity_Record_Type__mdt opp : [SELECT Record_Type__c, Record_Type_Name__c FROM Opportunity_Record_Type__mdt]){
            recordTypeMap.put(opp.Record_Type__c, opp.Record_Type_Name__c);
        }

        // only non-integration user will send
        Id userId = UserInfo.getUserId();
        User user = DM_User.getUser(userId);
        // Commented below If condition for testing using Administrator Profile
        
        //if(user.Profile.Name != Constants.PROFILE_INTEGRATIONS_USER && user.Profile.Name != Constants.PROFILE_SYSTEM_ADMIN) { // Commented for testing purpose

            Map<Id, Opportunity> closedWonOppties = new Map<Id, Opportunity>();
            Map<Id, Opportunity> closedLostOppties = new Map<Id, Opportunity>();

            for(Id opptyId : oldMap.keySet()) {
                Opportunity oldOppty = oldMap.get(opptyId);
                Opportunity newOppty = newMap.get(opptyId);
                if(oldOppty.StageName != Constants.OPPTY_STAGE_CLOSED_LOST && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST) {
                    closedLostOppties.put(opptyId, newOppty);
                } else if(oldOppty.StageName != Constants.OPPTY_STAGE_CLOSED_WON && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON) {
                    closedWonOppties.put(opptyId, newOppty);
                }
                /**Commented by Simplus MS - 03/05/2021
                 * This is initially added in case there is an API callout failure, user can update the Opp which will trigger the callout again.
                 * But this needs to be removed, as later we implemented the retry logic and after 3 retries, we reverted the stage to old one
                 * so this line will cause issues
                //Below else if added as part of CCRM-6890 & CCRM 6892 to allow user to update data incase of Integration failure
                else if(oldOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_WON ){
                    closedWonOppties.put(opptyId, newOppty);
                }
                else if(oldOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST ){
                    closedLostOppties.put(opptyId, newOppty);
                }
                **/
            }

            if(closedLostOppties.size() > 0 || closedWonOppties.size() > 0) {
                // query oppties with quotes
                List<Id> opptyIds = new List<Id>(closedLostOppties.keySet());
                opptyIds.addAll(closedWonOppties.keySet());
                Map<Id, Opportunity> opptiesWithQuotes = DM_Opportunity.getOpportunitiesWithQuotes(opptyIds);
                
                /* CCRM-6890,6892 - Added to fetch Team Member Id to pass to Integration */

                List<User> userList = [SELECT Team_Member_ID__c from User 
                                       WHERE Id IN (SELECT OwnerId FROM Opportunity WHERE Id IN : opptyIds)];
                // Closed Won
                // 1) if related quote count = 0, do nothing
                // 2) if related active quote count = 1, do callout (integration) to COS
                // 3) if related active quote count > 1, show alert
                // 4) if related quote count > 0 and all cancelled, show alert
                // 5) the rest of the scenario, go ahead (which might not exist)
                for(Id opptyId : closedWonOppties.keySet()) {
                    Opportunity opptyWithQuotes = opptiesWithQuotes.get(opptyId);
                    if(opptyWithQuotes.Quotes.size() > 0) {
                        Integer activeQuotesCount = countActiveQuotes(opptyWithQuotes.Quotes);
                        /* CCRM-6890,6892 - Conditional checks based on Record Types */
                        String recordTypeName = getRecordTypeNameById('Opportunity', opptyWithQuotes.RecordTypeId);
                        Boolean isRecordTypeCheck = true;
                        for(String recTypeName : recordTypeMap.keySet()){
                            if(recordTypeMap.get(recTypeName).contains(recordTypeName) && activeQuotesCount == 1){
                                isRecordTypeCheck = false;
                            }
                        }
                        
                        if(isRecordTypeCheck){
                            /* CCRM-6890,6892 - Fetch COS_Token__c to pass as Order Token To COS API */
                            String orderToken = getOrderToken(opptyWithQuotes.Quotes);
                            /* CCRM-6890,6892 - Created map to pass to SM_Opportunity class instead of existing logic of sending Oppt Id */
                            Map<String,String> closedWonMap = new Map<String, String>();
                            closedWonMap.put('opptyId',(String) opptyId);
                            for(User userObj : userList){
                                if(userObj.Id == closedWonOppties.get(opptyId).OwnerId){
                                    closedWonMap.put('username', userObj.Team_Member_ID__c);
                                }
                            }
                            closedWonMap.put('orderToken',orderToken);
                            closedWonMap.put('userId',userId);
                            closedWonMap.put('previousStageName',oldMap.get(opptyId).StageName);
                            // TODO callout
                            // disabled/commented for CCRM-13488 //Aldrin
                            //SM_Opportunity.sendClosedWonOpptyToCOSAsync(closedWonMap);
                        }
                    }
                }
                // Closed Lost
                // 1) if related quote count = 0, do nothing
                // 2) if related quote count > 0 and all Active, do callout (integration) to COS
                // 3) if related quote count > 0 and 1 quote status is Submitted, show error
                for(Id opptyId : closedLostOppties.keySet()) {
                    Opportunity opptyWithQuotes = opptiesWithQuotes.get(opptyId);
                    if(opptyWithQuotes.Quotes.size() > 0) {
                        /* CCRM-6890,6892 - Conditional checks based on Record Types */
                        Boolean isAllQuotesActive = allQuotesActive(opptyWithQuotes.Quotes);
                        String recordTypeName = getRecordTypeNameById('Opportunity', opptyWithQuotes.RecordTypeId);
                        Boolean isRecordTypeCheck = true;
                        for(String recTypeName : recordTypeMap.keySet()){
                            if(recordTypeMap.get(recTypeName).contains(recordTypeName) && isAllQuotesActive){
                                isRecordTypeCheck = false;
                            }
                        }
                        
                        if(isRecordTypeCheck){
                            /* CCRM-6890,6892 - Fetch COS_Token__c to pass as Order Token To COS API */
                            String orderToken = getOrderToken(opptyWithQuotes.Quotes);
                            /* CCRM-6890,6892 - Created map to pass to SM_Opportunity class instead of existing logic of sending Oppt Id */
                            Map<String,String> closedLostMap = new Map<String, String>();
                            closedLostMap.put('opptyId',(String) opptyId);
                            for(User userObj : userList){
                                if(userObj.Id == closedLostOppties.get(opptyId).OwnerId){
                                    closedLostMap.put('username', userObj.Team_Member_ID__c);
                                }
                            }


                            // TODO callout                           
                            //SM_Opportunity.sendClosedLostOpptyToCOSAsync(closedLostMap); =>commented/disabled for pause
                            //Added by Simplus MS - Changes for CCRM-13532 ENHANCEMENT-SUBMITTING CLOSED LOST COMMENTS
                            Map<String, String> flowInput = new Map<String, String>();
                            flowInput.put('opptyId',(String) opptyId);
                            flowInput.put('opptyParams', 
                                          JSON.serialize(new Map<String, String>{'opptyId'=>(String) opptyId,'previousStageName'=>oldMap.get(opptyId).StageName, 
                                              'username'=>closedLostMap.get('username'), 'orderToken'=> orderToken, 'lossReason'=>newMap.get(opptyId).Loss_Reason__c,
                                              'lossComments'=>newMap.get(opptyId).Loss_Reason_Comments__c, 'userId'=>userId}));
                            system.debug('flowInput'+flowInput);
                            Flow.Interview.Pause_Send_Close_Lost_to_COS pauseSendingCloseLostFlow = new Flow.Interview.Pause_Send_Close_Lost_to_COS(flowInput);
                            pauseSendingCloseLostFlow.start();
                        }
                    }
                }
            }
        //}
    }
    
    /**
	* @description - Logic for CCRM-13532 ENHANCEMENT-SUBMITTING CLOSED LOST COMMENTS
	*              - Invoke by Flow: Pause Send Close Lost to COS
	* @author Simplus MS | 23/04/2021 
	* @param List<String> opptyParams
	* @return 
	**/
    @InvocableMethod (Label='Send Close Lost to COS')
    public static void pauseSendCloseLostOppty(List<String> opptyParams) {
        system.debug('pauseSendCloseLostOppty'+opptyParams);
        Map<String,String> closedLostMap = new Map<String, String>();
        Map<String, String> closedLostParams = new Map<String, String>();
        closedLostParams = (Map<String, String>)JSON.deserialize(opptyParams[0], Map<String, String>.class);
        
        Opportunity oppty = [Select Id, Loss_Reason_Comments__c, Loss_Reason__c From Opportunity Where Id =: closedLostParams.get('opptyId') LIMIT 1];
        
        String lossCommentMapping;
        system.debug('lossComments'+oppty.Loss_Reason_Comments__c);
        if (oppty.Loss_Reason_Comments__c == null){
            lossCommentMapping = oppty.Loss_Reason__c;
        } else {
            lossCommentMapping =oppty.Loss_Reason_Comments__c;
        }
        
        closedLostMap.put('opptyId',closedLostParams.get('opptyId'));
        closedLostMap.put('previousStageName',closedLostParams.get('previousStageName'));
        closedLostMap.put('username',closedLostParams.get('username'));
        closedLostMap.put('orderToken',closedLostParams.get('orderToken'));
        closedLostMap.put('lossReason',closedLostParams.get('lossReason'));
        closedLostMap.put('lossComments',lossCommentMapping);
        closedLostMap.put('userId',closedLostParams.get('userId'));
        
        system.debug('closedLostMap'+closedLostMap);
        SM_Opportunity.sendClosedLostOpptyToCOSAsync(closedLostMap);
    }
    /**
    * @description 
    * @author Yi Zhang | 14/08/2020 
    * @param quotes 
    * @return Boolean 
    **/
    private static Boolean anyQuoteSubmitted(List<Quote> quotes) {
        for(Quote q :quotes) {
            if(q.Status == Constants.QUOTE_STATUS_SUBMITTED) {
                return true;
            }
        }
        return false;
    }

    /**
    * @description 
    * @author Yi Zhang | 14/08/2020 
    * @param quotes 
    * @return Boolean 
    **/
    private static Boolean allQuotesActive(List<Quote> quotes) {
        for(Quote q :quotes) {
            if(q.Status != Constants.QUOTE_STATUS_ENQUIRY && q.Status != Constants.QUOTE_STATUS_QUOTE && q.Status != Constants.QUOTE_STATUS_PRICING_ONLY) {
                return false;
            }
        }
        return true;
    }

    /**
    * @description 
    * @author Yi Zhang | 14/08/2020 
    * @param quotes 
    * @return Boolean 
    **/
    private static Boolean allQuotesCancelled(List<Quote> quotes) {
        for(Quote q : quotes) {
            if(q.Status != Constants.QUOTE_STATUS_CANCELLED) {
                return false;
            }
        }
        return true;
    }
    /**
    * @description 
    * @author Yi Zhang | 14/08/2020 
    * @param quotes 
    * @return Integer 
    **/
    @TestVisible
    private static Integer countActiveQuotes(List<Quote> quotes) {
        Integer count = 0;
        for(Quote q : quotes) {
            if(q.Status == Constants.QUOTE_STATUS_ENQUIRY || q.Status == Constants.QUOTE_STATUS_QUOTE || q.Status == Constants.QUOTE_STATUS_PRICING_ONLY) {
                count ++;
            }
        }
        return count;
    }
    
    /**
    * @description base 64 encode site address helper method
    * @author Ramtej Juloori | 30/10/2020 
    * @param quotes 
    * @return Integer 
    **/
    private static void encodeSiteAddress(List<Opportunity> newOpportunityList) {
        for(Opportunity opp :newOpportunityList){
            if(!String.isBlank(opp.Site_Address__c)){
                opp.Base_64_Site_Address__c = EncodingUtil.base64Encode(Blob.valueof(opp.Site_Address__c));
            }
            else{
                opp.Base_64_Site_Address__c = '';
            }            
        }
    }

    /**
    * @description Fetch the COS_Token__c for a given quote - CCRM-6890,6892
    * @author Simplus MS | 08/12/2020 
    * @param quotes 
    * @return String 
    **/
    private static String getOrderToken(List<Quote> quotes){
        String orderToken='';
        for(Quote q : quotes){
            //Simplus MS - 27/05/2021 - CCRM 13809 - Added Status QUOTE_STATUS_CANCELLED
            if(q.Status == Constants.QUOTE_STATUS_ENQUIRY || q.Status == Constants.QUOTE_STATUS_QUOTE 
               || q.Status == Constants.QUOTE_STATUS_PRICING_ONLY || q.Status == Constants.QUOTE_STATUS_CANCELLED) {
                orderToken = q.COS_Token__c ;
            }
        }
        return orderToken;
    }

    /**
    * @description Get RecordTypeName for given RecordTypeId - CCRM-6890,6892
    * @author Simplus MS | 18/01/2021 
    * @param objectName,recordTypeId 
    * @return String 
    **/
    private static String getRecordTypeNameById(String objectName, Id strRecordTypeId)
    {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getDeveloperName();
    }   

     /**
    * @description -   CRMS203 - Send notification for AU Std Closed Lost opportunities
    * @author Bunninngs dev
    * @param oldMap 
    * @param newMap 
    **/
    public static void sendStdAUCloseLostOpptiesBellNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        /* Below map to get related object details from Oppotunity id */
        
        Map<Id, Opportunity> mapOppty = DM_Opportunity.getOpportunitiesDetails(oldMap.keySet());
       
            for(Id opptyId : oldMap.keySet()) {
                Opportunity oldOppty = oldMap.get(opptyId);
                Opportunity newOppty = newMap.get(opptyId);
            
                Opportunity oppty = mapOppty.get(opptyId);
                System.debug('oldOppty.StageName:'+oldOppty.StageName);
                System.debug('newOppty.StageName:'+newOppty.StageName);
                System.debug('newOppty.SyncedQuoteId:'+newOppty.SyncedQuoteId);
                System.debug('newOppty.Record_Type_Name__c:'+newOppty.Record_Type_Name__c);
                System.debug('oppty.Owner.Profile.Name:'+oppty.Owner.Profile.Name);
                System.debug('oppty.Owner.isActive:'+oppty.Owner.isActive);
               
                //Verify the conditions to send bell notification for Closed Lost Oppty  - CRMS203
                if(oldOppty.StageName !=  newOppty.StageName && newOppty.StageName == Constants.OPPTY_STAGE_CLOSED_LOST &&  newOppty.SyncedQuoteId!=null && newOppty.Record_Type_Name__c == 'AU_Standard_Opportunity' && oppty.Owner.Profile.Name != 'Trade Specialist' && oppty.Owner.Profile.Name != 'NZ Trade Specialist' && oppty.Owner.isActive) {                    
                   SM_Opportunity.sendAUStndClosedLostBellNotification(oppty);
                }
     
      
            }
    
    }

/**
    * @description -   CRMS200 - Update AU Follow Up date
    * @author Bunninngs dev
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateAUOpptyFollowUpDate(String operation,Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap,List<Opportunity> newListOppty) {

        /* Below map to get related object details from Oppotunity id */
       System.debug('Operation:'+Operation);
        if(operation == 'before update'){
            for(Id opptyId : newMap.keySet()) {
                Opportunity oldOppty = oldMap.get(opptyId);
                System.debug('oldOppty.StageName:'+oldOppty.StageName);
                Opportunity newOppty = newMap.get(opptyId);
                                    
                    System.debug('newOppty.StageName:'+newOppty.StageName);
            
                    System.debug('newOppty.Record_Type_Name__c:'+newOppty.Record_Type_Name__c);
                    if(oldOppty.StageName !=  newOppty.StageName && newOppty.StageName == 'Presenting' && !newOppty.Record_Type_Name__c.contains('NZ')) {                    
                        SM_Opportunity.updateAUOpptyFollowUpDate(newOppty);
                    }
            }

        }else if(operation == 'before insert') {
            for(Opportunity opp : newListOppty){
                System.debug('opp.StageName:'+opp.StageName);
                System.debug('opp.Record_Type_Name__c:'+opp.Record_Type_Name__c);
                if(opp.StageName == 'Presenting' && !opp.Record_Type_Name__c.contains('NZ')) {                    
                    SM_Opportunity.updateAUOpptyFollowUpDate(opp);
                }


            }
        }


    }

/**
    * @description -   CRMS202 - Update Follow Up Date for NZ Opportunity
    * @author Bunninngs dev
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateNZOpptyFollowUpDate(String operation,Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap,List<Opportunity> newListOppty) {

        /* Below map to get related object details from Oppotunity id */
       System.debug('Operation:'+Operation);
        if(operation == 'before update'){
             Map<Id, Opportunity> mapOppty = DM_Opportunity.getOpportunitiesDetails(oldMap.keySet());
            for(Id opptyId : newMap.keySet()) {

               
                Opportunity oldOppty = oldMap.get(opptyId);
                System.debug('oldOppty.StageName:'+oldOppty.StageName);
                Opportunity newOppty = newMap.get(opptyId);
                Opportunity oppty = mapOppty.get(opptyId);                 
                    System.debug('newOppty.StageName:'+newOppty.StageName);
            
                    System.debug('newOppty.Record_Type_Name__c:'+newOppty.Record_Type_Name__c);
                    if(oldOppty.StageName !=  newOppty.StageName && newOppty.StageName == 'Proposal Ready' && newOppty.Record_Type_Name__c.contains('NZ')) {                    
                        System.debug(System.today());
                            Date today = System.today();
                            newOppty.Follow_Up_Date__c = today + 7;
                            newOppty.Price_Submission_Expiry__c = today + 30;
                            SM_Opportunity.sendNZProposalReadyBellNotificationOpp(oppty.Ownerid,oppty.Name,oppty.Account.Name);
                    }
            }

        }else if(operation == 'before insert') {
            Set<id> accSet = new Set<id>();
            System.debug('newListOppty:'+newListOppty);
            for(Opportunity opp : newListOppty){
                accSet.add(opp.AccountId);

            }
            System.debug('accSet:'+accSet);
            Map<id,Account> accMap = DM_Account.getAccountMap(accSet);
            System.debug('accMap:'+accMap);
            for(Opportunity opp : newListOppty){
                System.debug('opp.StageName:'+opp.StageName);
                System.debug('opp.Record_Type_Name__c:'+opp.Record_Type_Name__c);
                Account acc = accMap.get(opp.AccountId); 
                System.debug('accDetails:'+acc);
                if(opp.StageName == 'Proposal Ready' && opp.Record_Type_Name__c.contains('NZ')) {                    
                    System.debug(System.today());
                    Date today = System.today();
                    opp.Follow_Up_Date__c = today + 7;
                    opp.Price_Submission_Expiry__c = today + 30;
                   SM_Opportunity.sendNZProposalReadyBellNotificationOpp(opp.OwnerID,opp.name,acc.Name);
                }


            }
        }


    }

/**
    * @description -  CRMS204 - Update Supplier Quote for Closed Won
    * @author Bunninngs dev
    * @param newMap 
    **/
    public static void updateSupplierQuotesStatus(Map<Id, Opportunity> oldMap,Map<Id, Opportunity> newMap,String Status) {

        /* Below map to get related object details from Oppotunity id */
   
             Map<Id, Opportunity> mapOppty = DM_Opportunity.getOpportunitiesDetails(newMap.keySet());
            for(Id opptyId : newMap.keySet()) {

               
                Opportunity oldOppty = oldMap.get(opptyId);
                System.debug('oldOppty.StageName:'+oldOppty.StageName);
                Opportunity newOppty = newMap.get(opptyId);
                Opportunity oppty = mapOppty.get(opptyId);                 
                    System.debug('newOppty.StageName:'+newOppty.StageName);
            
                    System.debug('newOppty.Record_Type_Name__c:'+newOppty.Record_Type_Name__c);
                
                    if(oldOppty.StageName !=  newOppty.StageName && newOppty.StageName == 'Closed Won') {                    
                            SM_Opportunity.updateSupplierQuoteStatus(newMap,status);
                    }else if(oldOppty.StageName !=  newOppty.StageName && newOppty.StageName == 'Closed Lost'){
                        SM_Opportunity.updateSupplierQuoteStatus(newMap,status);
                    }
            }

        


    }


     /**
    * @description - CRMS204 - Update Supplier Quote for Closed Won 
    * @author Bunninngs dev
    * @param oldMap 
    * @param newMap 
    **/
    public static void sendNewOpportunityBellNotification(Map<Id, Opportunity> newMap) {

        /* Below map to get related object details from Oppotunity id */
        
        Map<Id, Opportunity> mapOppty = DM_Opportunity.getOpportunitiesDetails(newMap.keySet());
       
            for(Id opptyId : newMap.keySet()) {
                
                Opportunity newOppty = newMap.get(opptyId);
            
                System.debug('newOppty.Accountid:'+newOppty.Accountid);
                System.debug('newOppty.Account.Owner.Id:'+newOppty.Account.Owner.Id);
                System.debug('newOppty.CreatedById:'+newOppty.CreatedById);
                System.debug('newOppty.Account.Owner.Is_TS__c:'+newOppty.Account.Owner.Is_TS__c);
                System.debug('newOppty.SyncedQuoteId:'+newOppty.SyncedQuoteId);
                System.debug('newOppty.SyncedQuote.Status:'+newOppty.SyncedQuote.Status);
               
                //Verify the conditions to send bell notification for New Oppty  - CRMS201                        
                if(!String.isBlank(newOppty.Accountid) &&  newOppty.Account.Owner.Id !=  newOppty.CreatedById && newOppty.Account.Owner.Is_TS__c == false && ! String.isBlank(newOppty.SyncedQuoteId) && newOppty.SyncedQuote.Status == 'Pricing_Only_Quote') {                    
                   SM_Opportunity.sendNewOpportunityBellNotification(newOppty);
                }
     
      
                }
    
    }
      /**
    * @description -   CRMS-232
    * @author Bunninngs dev
    * @param oldMap 
    * @param newMap 
    **/
    private static SM_Configs__c config {
        get {
            if (config==null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    }   
}