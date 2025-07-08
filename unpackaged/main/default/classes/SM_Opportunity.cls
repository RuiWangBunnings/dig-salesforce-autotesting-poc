/*******************************************************************************************************
* Class Name      	: SM_Opportunity
* Description		: Domain / Service layer for Opportunity
* Author          	: Simplus - Yi Zhang
* Created On      	: 13/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              13/08/2020		1000				Initial version
* Simplus MS            04/12/2020      1001                New changes for CCRM-6890 & CCRM-6892 enhancement
* Simplus MS 			24/02/2022		1002				SFSUP-53 - SF putting 'Error' in Loss Comments when cancelling COS Enquiry/Quote
* Bunnings Dev 			07/10/2024		1003				New changes for sending Bell Notification for AU Standard Closed lost Opportunity
* Bunnings Dev           2024-10-30     1300                CRMS-200 Update Follow Up Date for AU Opportunity
* Bunnings Dev          2024-11-01      1010                CRMS202 - Update Follow Up Date for NZ Opportunity
* Bunnings Dev          2024-11-21      1011                CRMS204 - Update Supplier Quote for Closed Won  
* Bunnings Dev          2024-12-06      1012                CRMS201 - PB Opportunity Create Action Conversation - New Opp Notification
******************************************************************************************************/
public with sharing class SM_Opportunity {

    private static final String CLOSED_LOST_UPDATE_FAILURE_NOTIFI_TITLE = 'Opportunity Update Unsuccessful';
    private static final String CLOSED_LOST_UPDATE_FAILURE_NOTIFI_BODY  = 'The update to opportunity <opportunity name> could not be completed. Please update the relevant quote/s directly in COS. ';
    public static final String CALLOUT_SUCCESS_KEY = 'calloutSuccess';

    // CCRM-6890,6892 - New Notification title & body added 
    private static final String CLOSED_WON_API_CALLOUT_FAILURE_REASON_TITLE = 'Failure in submission of Quote to COS Order';
    private static final String CLOSED_WON_API_CALLOUT_FAILURE_REASON_BODY  = 'There was a failure in submitting quote related to opportunity <opportunity name> to the COS order system. Please contact the System Administrator';
    // CCRM-6890,6892 End

    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param opptyId 
    **/
    // disabled/commented for CCRM-13488 //Aldrin
    /*
    @future(callout=true)
    public static void sendClosedWonOpptyToCOSAsync(Map<String, String> params) {
        sendClosedWonOpptyToCOS(params, true);
    } */
    
    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 , Simplus MS | 08/12/2020
    * @param StringMap
    * @param createLog 
    * @return Map<String, Object> 
    **/
    
    // disabled/commented for CCRM-13488 //Aldrin
    /*
    public static Map<String, Object> sendClosedWonOpptyToCOS(Map<String, String> params, Boolean createLog) {
        Map<String, Object> returnMap = new Map<String, Object>{CALLOUT_SUCCESS_KEY=>false};
        List<Opportunity> opptList = new List<Opportunity>();

        // CCRM-6892 - Below Map to create Http request from URL stored in Custom Metadata
        Map<String,String> wsParams = new Map<String, String>();
        wsParams.put('orderToken', params.get('orderToken'));
        wsParams.put('onHoldFlg', 'N');
        wsParams.put('username', params.get('username'));
        
        String method = 'POST';
        
        RequestWrapper wrapper = new RequestWrapper();
        wrapper.orderToken = params.get('orderToken');
        wrapper.onHoldFlg = 'N';
        wrapper.username = params.get('username'); 
        String body = JSON.serialize(wrapper, true);
        
        // Build Http request from Webservice Helper class
        HttpRequest request = SM_WSHelper.buildHttpRequestFromWSDef('OPP2COS_Won', wsParams);
        request.setBody(body);
        HttpResponse response;
        try {
            response = (new http()).send(request);
        
                // All good scenarios, e.g. statusCode = 200
                // Update Oppt with Sent To Integration checbox true
                if(response.getStatusCode() == 200) {
                    if(createLog == true){
                        Opportunity opp = new Opportunity();
                        opp.Sent_to_Integration__c = true;
                        opp.Id = params.get('opptyId');

                        OpportunityTriggerHandler.isFirstTime = false;
                        update opp;
                    }else{
                        returnMap.put('closedWonOpptyStage', new Opportunity(Id = params.get('opptyId')));
                    }
                    returnMap.put(CALLOUT_SUCCESS_KEY, true);
                }

                // Callout exception scenarios, e.g. statusCode = 400
                // Log Error/Exception return from API in Application_Log__c object
                if(response.getStatusCode() == 400 || response.getStatusCode() == 404 || response.getStatusCode() == 500) {
                    if(createLog == true ) {
                        ApplicationLogger.logCalloutException(
                            'SM_Opportunity.sendClosedWonOpptyToCOS', 
                            request, 
                            response, 
                            JSON.serialize(new Map<String, String>{'opptyId'=>params.get('opptyId'), 'previousStageName'=>params.get('previousStageName'), 'orderToken'=>params.get('orderToken'),
                                            'onHoldFlg'=>'N','username'=>params.get('username'),
                                             'userId'=>params.get('userId')}), 
                            'Opportunity',
                            'Trigger',
                            null);
                    }else{
                        
                            returnMap.put('closedWonOpptyStage', new Opportunity(Id = params.get('opptyId')));
                            returnMap.put(CALLOUT_SUCCESS_KEY, false);
                    }
                }
           //return returnMap;
        } catch(Exception e) {
            // log callout exception occurred while invoking Webservice
            if(createLog){
                ApplicationLogger.logCalloutException(
                            'SM_Opportunity.sendClosedWonOpptyToCOS', 
                            request, 
                            response, 
                            JSON.serialize(new Map<String, String>{'opptyId'=>params.get('opptyId'), 'previousStageName'=>params.get('previousStageName'), 'orderToken'=>params.get('orderToken'),
                                            'onHoldFlg'=>'N','username'=>params.get('username'),
                                             'userId'=>params.get('userId')}), 
                            'Opportunity',
                            'Trigger',
                            e); 

                
            }else{
                returnMap.put(CALLOUT_SUCCESS_KEY, false);
            }
        } 
        return returnMap;
    } */
    
    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param opptyId 
    **/
    @future(callout=true)
    public static void sendClosedLostOpptyToCOSAsync(Map<String, String> params) {
        sendClosedLostOpptyToCOS(params, true);
    }

    /**
    * @description - Updated method for CCRM-6890,6892 enhancements
    * @author Yi Zhang | 13/08/2020 
    * @author Simplus MS | 15/12/2020
    * @param opptyId 
    * @param previousStageName 
    * @param createLog 
    * @return Map<String, Object> 
    **/
    public static Map<String, Object> sendClosedLostOpptyToCOS(Map<String, String> params, Boolean createLog) {
        Map<String, Object> returnMap = new Map<String, Object>{CALLOUT_SUCCESS_KEY=>false};
        List<Opportunity> opptList = new List<Opportunity>();
        
        // Query Custom Metadata to keep cancellation reason configurable
        List<COS_Order_Cancellation_Reason__mdt> cancellationReasonList = [SELECT SF_Value__c, COS_Value__c 
                                                                           FROM COS_Order_Cancellation_Reason__mdt];
        
        // CCRM-6890 - Below Map to create Http request from URL stored in Custom Metadata
        Map<String,String> wsParams = new Map<String, String>();
        wsParams.put('orderToken', params.get('orderToken'));
        //wsParams.put('cancelComments', 'Error'); //Removed by Simplus MS 24.02.2022 for SFSUP-53
        wsParams.put('cancelComments', params.get('lossComments')); //Added by Simplus MS 24.02.2022 for SFSUP-53
        wsParams.put('username', params.get('username'));
        String method = 'POST';
        
        RequestWrapper wrapper = new RequestWrapper();
        for(COS_Order_Cancellation_Reason__mdt obj : cancellationReasonList){
            if(obj.SF_Value__c == params.get('lossReason')){
                wrapper.cancelReason = obj.COS_Value__c;
                wsParams.put('cancelReason', obj.COS_Value__c);
            }
        }
        wrapper.orderToken = params.get('orderToken'); 
        //wrapper.cancelComments = 'Error'; //Removed by Simplus MS 24.02.2022 for SFSUP-53
        wrapper.cancelComments = params.get('lossComments'); //Added by Simplus MS 24.02.2022 for SFSUP-53
        wrapper.username = params.get('username'); 
        
        String body = JSON.serialize(wrapper, true);
        system.debug('HTTPS BODY ::: '+body);
        
        // Build Http request from Webservice Helper class
        HttpRequest request = SM_WSHelper.buildHttpRequestFromWSDef('OPP2COS_Lost', wsParams);
        request.setBody(body);
        HttpResponse response;
        try {
            response = (new http()).send(request);
            System.debug(response.getBody());
            System.debug(response.getStatusCode());
        
            // if all good, do nothing
            // if wraning returned, custom notification to user (whom? the user who changed the status)
            // if failed & retry failed after x times, the admin should receive the failure message and resolve it?
            
            // Successful scenarios, e.g. statusCode = 200 & returnCode = 'Success' / 'Warning'
            
            // If response is 200, then update Sent_to_Integration__c on Opportunity
            if(response.getStatusCode() == 200) {
                System.debug(response.getBody());
                Map<String, String> result = (Map<String, String>)JSON.deserialize(response.getBody(), Map<String, String>.class);
                if(!createLog) {
                    returnMap.put('opportunityToRevertStage', new Opportunity(Id = params.get('opptyId'), StageName = params.get('previousStageName')));
                } else { 
                    Opportunity oppty = DM_Opportunity.getOpportunity(params.get('opptyId'));
                    oppty.Sent_to_Integration__c = true;

                    OpportunityTriggerHandler.isFirstTime = false;
                    update oppty;
                }
               
                returnMap.put(CALLOUT_SUCCESS_KEY, true);
            }
            

            // Callout exception scenarios, e.g. statusCode = 400
            // Log Error/Exception return from API in Application_Log__c object
            if(response.getStatusCode() == 400 || response.getStatusCode() == 404 || response.getStatusCode() == 500 ) {
                // Log 
                // create exception log
                if(createLog == true) {
                    ApplicationLogger.logCalloutException(
                        'SM_Opportunity.sendClosedLostOpptyToCOS', 
                        request, 
                        response, 
                        JSON.serialize(new Map<String, String>{'opptyId'=>params.get('opptyId'), 'previousStageName'=>params.get('previousStageName'), 
                                        'username'=>params.get('username'), 'orderToken'=>params.get('orderToken'), 'lossReason'=>params.get('lossReason'),
                                        'lossComments'=>params.get('lossComments'), 'userId'=>params.get('userId')}), 
                        'Opportunity',
                        'Trigger',
                        null);

                    // Below code commented to avoid updating oppt after initial API callout
                    /*Opportunity oppty = DM_Opportunity.getOpportunity(params.get('opptyId'));
                    oppty.StageName = params.get('previousStageName');
                    sendNotificationForClosedLostWarning(oppty, params.get('userId'));  // Warning Bell Notification incase of Closed Lost 

                    OpportunityTriggerHandler.isFirstTime = false;
                    update oppty;*/
                }
                else{
                    returnMap.put('opportunityToRevertStage', new Opportunity(Id = params.get('opptyId'), StageName = params.get('previousStageName')));
                    returnMap.put(CALLOUT_SUCCESS_KEY, false);
                }
            
            }
            //return returnMap;
        } catch(Exception e) {
            // log callout exception occurred while invoking Webservice
            if(createLog){
                ApplicationLogger.logCalloutException(
                            'SM_Opportunity.sendClosedLostOpptyToCOS', 
                            request, 
                            response, 
                            JSON.serialize(new Map<String, String>{'opptyId'=>params.get('opptyId'), 'previousStageName'=>params.get('previousStageName'), 'orderToken'=>params.get('orderToken'),
                                            'onHoldFlg'=>'N','username'=>params.get('username'),
                                             'userId'=>params.get('userId')}), 
                            'Opportunity',
                            'Trigger',
                            e); 
            }else{
                returnMap.put(CALLOUT_SUCCESS_KEY, false);
            }
            
        }
        return returnMap;
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param oppty 
    * @param runningUserId 
    **/
    public static void sendNotificationForClosedLostWarning(Opportunity oppty, String runningUserId) {
        Map<String, Object> flowInput = new Map<String, Object>();
        flowInput.put('customNotificationTypeName', 'Opportunity Notification');
        flowInput.put('targetId', oppty.Id);
        flowInput.put('recipientIds', new List<String>{runningUserId});
        flowInput.put('notificationTitle', System.Label.BN_COS_Closed_Lost_Notification_Title);
        flowInput.put('notificationBody', System.Label.BN_COS_Closed_Lost_Notification_Body.replace('<opportunity name>', oppty.Name));
        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
        sendCustomNotifiFlow.start();
    }

     /**
    * @description - CRMS203 - sendAUStndClosedLostBellNotification 
    * @author Bunnings Dev | 07/10/2024
    * @param oppty 
    * @param runningUserId 
    **/
    public static void sendAUStndClosedLostBellNotification(Opportunity oppty) {
        //Bell Receipient ids Set
        Set<String> bellRecipientIds = new Set<String>();
        bellRecipientIds.add(oppty.Ownerid);

        //Bell Notification Title in Custom label
        String bellNotificationTitle = System.Label.AU_Stnd_Oppty_Close_Lost_Bell_Notification_Title.replace('<opportunity name>', oppty.Name);

        //Bell Notification Body in Custom label
        String bellNotificationBody = System.Label.AU_Stnd_Oppty_Close_Lost_Bell_Notification_Body;
        bellNotificationBody = bellNotificationBody.replace('<opportunity synched quote name>',oppty.SyncedQuote.Name);
        bellNotificationBody = bellNotificationBody.replace('<opportunity account name>',oppty.Account.Name);
        bellNotificationBody = bellNotificationBody.replace('<opportunity lastmodifiedby firstname>',oppty.LastModifiedBy.FirstName);
        bellNotificationBody = bellNotificationBody.replace('<opportunity lastmodifiedby lastname>',oppty.LastModifiedBy.LastName);

        //Call to send Bell Notification
        SM_Utility.sendBellNotification('Opportunity_Notification', bellRecipientIds, bellNotificationTitle, bellNotificationBody);
    }
    /**
    * @description - CCRM-6890,6892 - Invokes Flow for sending Bell notification to user in case of Closed Won
    * @author Simplus MS | 16/12/2020 
    * @param oppty 
    * @param runningUserId 
    **/
    public static void sendNotificationForClosedWonWarning(Opportunity oppty, String runningUserId) {
        Map<String, Object> flowInput = new Map<String, Object>();
        flowInput.put('customNotificationTypeName', 'Opportunity Notification');
        flowInput.put('targetId', oppty.Id);
        flowInput.put('recipientIds', new List<String>{runningUserId});
        flowInput.put('notificationTitle', System.Label.BN_COS_Closed_Won_Notification_Title);
        flowInput.put('notificationBody', System.Label.BN_COS_Closed_Won_Notification_Body.replace('<opportunity name>', oppty.Name));
        Flow.Interview.Send_Custom_Notification flowNotification = new Flow.Interview.Send_Custom_Notification(flowInput);
        flowNotification.start();
    }



 /**
    * @description - CRMS202 - sendNZProposalReadyBellNotificationOpp 
    * @author Bunnings Dev | 01/11/2024
    * @param oppty 
    * @param runningUserId 
    **/
    public static void sendNZProposalReadyBellNotificationOpp(String ownerId, String name, String accname) {
        //Bell Receipient ids Set
        Set<String> bellRecipientIds = new Set<String>();
        bellRecipientIds.add(ownerId);

        //Bell Notification Title in Custom label
        String bellNotificationTitle = 'Price Submission Ready';

        //Bell Notification Body in Custom label
        String bellNotificationBody =  'Opportunity ' + name + ' is ready to be presented to '+ accname +'.';

        //Call to send Bell Notification
        SM_Utility.sendBellNotification('Opportunity_Proposal_Ready_Notification', bellRecipientIds, bellNotificationTitle, bellNotificationBody);
    }


    /**
    * @description - CRMS-200 Update Follow Up Date for AU Opportunity
    * @author Bunnings Dev | 30/10/2024 
    * @param oppty 
    * @param runningUserId 
    **/
    public static void updateAUOpptyFollowUpDate(Opportunity oppty) {
        Date today = System.today();
        Datetime todayDT = (DateTime)today;
        String dayOfWeek = todayDT.format('EEEE');
        System.debug(dayOfWeek);
        Integer noOfDays = SM_utility.getOpptyFollowUpDatePresentingStage();
        switch on dayOfWeek {
            when 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'  {
                oppty.Follow_Up_Date__c = today + noOfDays;
            }
            when 'Friday' {
                oppty.Follow_Up_Date__c = today + noOfDays + 2;
            }
            when 'Saturday'  {
                oppty.Follow_Up_Date__c = today + noOfDays + 3;
            }
            when else {
                System.debug(dayOfWeek);
            }
        }
    }

/**
    * @description - CRMS204 - Update Supplier Quote for Closed Won
    * @author Bunnings Dev | 21/11/2024 
    * @param opptyMap 
    **/
    public static void updateSupplierQuoteStatus(Map<id,Opportunity> opptyMap, String Status) {

        

        Set <Id> opptyIdSet = new Set<Id>();
        opptyIdSet = opptyMap.keySet();
        List<Supplier_Quote__c> lstSuppQuotes =  DM_SupplierQuote.getSupplierQuotesbyOpportunities(opptyIdSet);
        System.enqueueJob(new SM_OpptyUpdateSupplierQuotesQueueable(lstSuppQuotes,status));
        
    }


    /**
    * @description - CRMS201 - PB Opportunity Create Action Conversation - New Opp Notification 
    * @author Bunnings Dev | 07/12/2024
    * @param oppty 
    * @param runningUserId 
    **/
    public static void sendNewOpportunityBellNotification(Opportunity oppty) {
        //Bell Receipient ids Set
        Set<String> bellRecipientIds = new Set<String>();
        bellRecipientIds.add(oppty.Account.Ownerid);

        //Bell Notification Title in Custom label
        String bellNotificationTitle = 'New Opportunity';

        //Bell Notification Body in Custom label
        String bellNotificationBody = 'A new opportunity has been created for '+ oppty.Account.Name;
 
        //Call to send Bell Notification
        SM_Utility.sendBellNotification('New_Opportunity_Notification', bellRecipientIds, bellNotificationTitle, bellNotificationBody);
    }

    /**
     *  @description - Wrapper class for API Callout body 
    **/
    public class RequestWrapper{
        public String orderToken;
        public String onHoldFlg;
        public String cancelReason;
        public String cancelComments;
        public String username;
    }
}