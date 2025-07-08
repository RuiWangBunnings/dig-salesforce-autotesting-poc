/*******************************************************************************************************
* Class Name      	: SM_RESTCalloutRetryBatch
* Description		: Service layer for REST Callout Retry Batch
* Author          	: Simplus - Yi Zhang
* Created On      	: 17/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              17/08/2020		1000				Initial version
* Simplus MS            21/12/2020      1001                CCRM-6890,6892 Enhancement changes
* Simplus MS            14/05/2021		2000				modifications CCRM-13728
* Bunnings Dev          06/09/2022      3000                SFSUP-890 - Customisable batch size
******************************************************************************************************/
global class SM_RESTCalloutRetryBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    
    String query;

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    **/
    global SM_RESTCalloutRetryBatch() {
        // Source__c: determines the Apex method
        // Retry_Count__c: the number of retry left
        // Retry_Params__c: serialized Map<String, String> which contains all the params required for the retry method
        query = 'SELECT Id, Source__c, Retry_Count__c, Retry_Params__c, Response_Body__c FROM ApplicationLog__c WHERE Retry_Count__c > 0';
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param BC 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description - Updated retry logic for CCRM-6890,6892 & CCRM-297
    * @author Yi Zhang | 17/08/2020 , Simplus MS | 17/12/2020
    * @param BC 
    * @param scope 
    **/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<ApplicationLog__c> logs = (List<ApplicationLog__c>) scope;
        List<Opportunity> oppties = new List<Opportunity>();
        Map<String, String> opptyUserIdMapClosedLost = new Map<String, String>();
        Map<String, String> opptyUserIdMapClosedWon = new Map<String, String>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();

        List<Account> accts = new List<Account>();
        // execute
        for(ApplicationLog__c log : logs) {

            Map<String, Object> retryResult = new Map<String, Object>{SM_Opportunity.CALLOUT_SUCCESS_KEY=>false};
            /* Map for CCRM-6890,6892 Changes */
            Map<String, String> closedWonMap = new Map<String, String>();
            Map<String, String> closedLostMap = new Map<String, String>();
            Map<String, String> closedLostParams = new Map<String, String>();
            Map<String, String> closedWonParams = new Map<String, String>();
            
            /* Map CCRM-297 Changes */
            Map<Id, Map<String, String>> cplAssignmentMap = new Map<Id, Map<String, String>>();
            Map<Id, Map<String, String>> cplAssignmentParams = new Map<Id, Map<String, String>>();
            Map<String, String> cplDeletionParams = new Map<String, String>();
            Map<String, String> cplDeletionMap = new Map<String, String>();
            Map<Id, Map<String, String>> cplDelMap = new Map<Id, Map<String, String>>();
            
            
            String accountId = '';

            /* CCRM-6890 - Check if source is ClosedWon Oppt */
            if(log.Source__c == 'SM_Opportunity.sendClosedWonOpptyToCOS') {
                closedWonParams = (Map<String, String>)JSON.deserialize(log.Retry_Params__c, Map<String, String>.class);
                closedWonMap.put('opptyId',closedWonParams.get('opptyId'));
                closedWonMap.put('orderToken',closedWonParams.get('orderToken'));
                closedWonMap.put('onHoldFlg','N');
                closedWonMap.put('username',closedWonParams.get('username'));
                closedWonMap.put('userId',closedWonParams.get('userId'));
                closedWonMap.put('previousStageName',closedWonParams.get('previousStageName'));
                // disabled/commented for CCRM-13488 //Aldrin
                //retryResult = SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap, false);
            } 
            /* CCRM-6892 - Check if source is ClosedLost Oppt */
            else if(log.Source__c == 'SM_Opportunity.sendClosedLostOpptyToCOS') {
                closedLostParams = (Map<String, String>)JSON.deserialize(log.Retry_Params__c, Map<String, String>.class);
                closedLostMap.put('opptyId',closedLostParams.get('opptyId'));
                closedLostMap.put('previousStageName',closedLostParams.get('previousStageName'));
                closedLostMap.put('username',closedLostParams.get('username'));
                closedLostMap.put('orderToken',closedLostParams.get('orderToken'));
                closedLostMap.put('lossReason',closedLostParams.get('lossReason'));
                closedLostMap.put('lossComments',closedLostParams.get('lossComments'));
                closedLostMap.put('userId',closedLostParams.get('userId'));
                retryResult = SM_Opportunity.sendClosedLostOpptyToCOS(closedLostMap, false);
            } 
            /* CCRM-297 - Check if source is Customer Price List Assignment */
            else if(log.Source__c == 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment'){
                cplAssignmentParams = (Map<Id, Map<String, String>>)JSON.deserialize(log.Retry_Params__c, Map<Id, Map<String, String>>.class);
               
                for(Id cplId : cplAssignmentParams.keySet()){
                    Map<String, String> tempMap = cplAssignmentParams.get(cplId);
                    cplAssignmentMap.put(cplId, new Map<String, String> {'PriceListId' => tempMap.get('PriceListId'), 'AccountId' => tempMap.get('AccountId'),
                                                    'CustomerId' => tempMap.get('CustomerId'), 'TMNumber' => tempMap.get('TMNumber'),
                                                    'CountryCode' => tempMap.get('CountryCode')});
                    accountId = tempMap.get('AccountId');
                }
                retryResult = SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(cplAssignmentMap, false);  
            } 
            /* CCRM-297 - Check if source is Customer Price List Deletion */
            else if(log.Source__c == 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion'){
                cplDelMap = (Map<Id, Map<String, String>>)JSON.deserialize(log.Retry_Params__c, Map<Id, Map<String, String>>.class);

                /*
                cplDeletionMap.put('PriceListId', cplDeletionParams.get('PriceListId'));
                cplDeletionMap.put('AccountId', cplDeletionParams.get('AccountId'));
                cplDeletionMap.put('CustomerId', cplDeletionParams.get('CustomerId'));
                cplDeletionMap.put('TMNumber', cplDeletionParams.get('TMNumber'));
                cplDeletionMap.put('CountryCode', cplDeletionParams.get('CountryCode'));
         		*/
                
                accountId = cplDelMap.values()[0].get('AccountId');
                retryResult = SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(cplDelMap, false);
            }
            // If new callout method requires retry, add it here


            // either reduce retry count to null or by 1
            if(retryResult.get(SM_Opportunity.CALLOUT_SUCCESS_KEY) == true) {
                log.Retry_Count__c = null;
            } // Below else if added for CCRM-297 
            else if(retryResult.get(SM_CustomerPriceList.CALLOUT_SUCCESS_KEY) == true) {
                log.Retry_Count__c = null;
            }else {
                log.Retry_Count__c = log.Retry_Count__c - 1;
            }

            // CCRM-6890,6892 - collect opportunities if any for ClosedWon or ClosedLost
            if(log.Source__c == 'SM_Opportunity.sendClosedLostOpptyToCOS' && Integer.valueOf(log.Retry_Count__c) == 0) {
                if(oppties.size() > 0){
                    for(Opportunity op : oppties){
                        oppIds.add(op.Id);
                    }
                }
                if(oppIds.contains(closedLostParams.get('opptyId'))){
                    System.debug('Do nothing');
                }else{
                    oppties.add(new Opportunity(Id = closedLostParams.get('opptyId'), StageName = closedLostParams.get('previousStageName'), 
                                            API_Callout_Retry_Maxed_Out__c = true, COS_API_Failure_Reason__c = log.Response_Body__c));
                    opptyUserIdMapClosedLost.put(closedLostParams.get('opptyId'), closedLostParams.get('userId'));
                    OpportunityTriggerHandler.isFirstTime = false;
                }
            }else if(log.Source__c == 'SM_Opportunity.sendClosedWonOpptyToCOS' && Integer.valueOf(log.Retry_Count__c) == 0) {
                if(oppties.size() > 0){
                    for(Opportunity op : oppties){
                        oppIds.add(op.Id);
                    }
                }
                
                if(oppIds.contains(closedWonParams.get('opptyId'))){
                    System.debug('Do nothing');
                }else{
                    oppties.add(new Opportunity(Id = closedWonParams.get('opptyId'), StageName = closedWonParams.get('previousStageName'), API_Callout_Retry_Maxed_Out__c = true, 
                    COS_API_Failure_Reason__c = log.Response_Body__c));
                    opptyUserIdMapClosedWon.put(closedWonParams.get('opptyId'), closedWonParams.get('userId'));
                    OpportunityTriggerHandler.isFirstTime = false;
                }
                
            }
            // Added for CCRM-297 
            else if(log.Source__c == 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment' && Integer.valueOf(log.Retry_Count__c) == 0) {
                if(accts.size() > 0){
                    for(Account acc : accts){
                        accIds.add(acc.Id);
                    }
                }
                if(accIds.contains(accountId)){
                    System.debug('Do nothing');
                }else{
                    accts.add(new Account(Id = accountId, API_Callout_Retry_Maxed_Out__c = true, 
                                            Integration_Failure_Reason__c = log.Response_Body__c));
                }
                
            }else if(log.Source__c == 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion' && Integer.valueOf(log.Retry_Count__c) == 0) {
                if(accts.size() > 0){
                    for(Account acc : accts){
                        accIds.add(acc.Id);
                    }
                }
                if(accIds.contains(accountId)){
                    System.debug('Do nothing');
                }else{
                    accts.add(new Account(Id = accountId, API_Callout_Retry_Maxed_Out__c = true, 
                                            Integration_Failure_Reason__c = log.Response_Body__c));
                }
            }
        }

        update logs;

        System.debug(LoggingLevel.DEBUG, 'oppties Map: ' + JSON.serialize(oppties));

        /* CCRM-6890,6892 - If Oppts, send Bell Notification to user for Closed Won or Closed Lost
        *  Update Opportunities
        */
        if(oppties.size() > 0) {

            // custom notifications via flow
            Map<Id, Opportunity> opptyLostMap = DM_Opportunity.getOpportunities(opptyUserIdMapClosedLost.keySet());  // to get Name
            for(String opptyId : opptyUserIdMapClosedLost.keySet()) {
                SM_Opportunity.sendNotificationForClosedLostWarning(opptyLostMap.get(opptyId), opptyUserIdMapClosedLost.get(opptyId));
            }

            Map<Id, Opportunity> opptyWonMap = DM_Opportunity.getOpportunities(opptyUserIdMapClosedWon.keySet());  // to get Name
            for(String opptyId : opptyUserIdMapClosedWon.keySet()) {
                SM_Opportunity.sendNotificationForClosedWonWarning(opptyWonMap.get(opptyId), opptyUserIdMapClosedWon.get(opptyId));
            }

            update oppties;
        }

        /* CCRM-297 - Update Accounts if API Callout Retry maxed out*/
        if(accts.size() > 0){
            update accts;
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param BC 
    **/
    global void finish(Database.BatchableContext BC) {
        // finish code
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param SC 
    **/
    global void execute(SchedulableContext SC) {
        //SFSUP-890
        //Database.executeBatch(new SM_RESTCalloutRetryBatch(), 50);  // 100 callouts per batch max        
        Decimal batchSize = getBatchSize();
        System.debug('***batchSize: '+batchSize);

        if (batchSize != 0) {
            Database.executeBatch(new SM_RESTCalloutRetryBatch(), Integer.valueOf(batchSize));
        } else {
            Database.executeBatch(new SM_RESTCalloutRetryBatch(), 50);
        }
    }

    /**
    * @description - Static method for scheduling REST Retry Callout
    * @author Simplus MS | 14/01/2021 
    **/
    global static void schedule() {
		String name1 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 1' : 'REST Callout Retry Batch 1';
		String cron1 = '0 5 * * * ?'; 
		SM_RESTCalloutRetryBatch job1 = new SM_RESTCalloutRetryBatch();
        System.schedule(name1, cron1, job1);
        
        String name2 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 2' : 'REST Callout Retry Batch 2';
		String cron2 = '0 10 * * * ?'; 
		SM_RESTCalloutRetryBatch job2 = new SM_RESTCalloutRetryBatch();
        System.schedule(name2, cron2, job2);
        
        String name3 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 3' : 'REST Callout Retry Batch 3';
		String cron3 = '0 15 * * * ?'; 
		SM_RESTCalloutRetryBatch job3 = new SM_RESTCalloutRetryBatch();
        System.schedule(name3, cron3, job3);
        
        String name4 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 4' : 'REST Callout Retry Batch 4';
		String cron4 = '0 20 * * * ?'; 
		SM_RESTCalloutRetryBatch job4 = new SM_RESTCalloutRetryBatch();
        System.schedule(name4, cron4, job4);
        
        String name5 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 5' : 'REST Callout Retry Batch 5';
		String cron5 = '0 25 * * * ?'; 
		SM_RESTCalloutRetryBatch job5 = new SM_RESTCalloutRetryBatch();
        System.schedule(name5, cron5, job5);
        
        String name6 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 6' : 'REST Callout Retry Batch 6';
		String cron6 = '0 30 * * * ?'; 
		SM_RESTCalloutRetryBatch job6 = new SM_RESTCalloutRetryBatch();
        System.schedule(name6, cron6, job6);
        
        String name7 = Test.isRunningTest() ? 'Test REST Callout Retry Batch7' : 'REST Callout Retry Batch 7';
		String cron7 = '0 35 * * * ?'; 
		SM_RESTCalloutRetryBatch job7 = new SM_RESTCalloutRetryBatch();
        System.schedule(name7, cron7, job7);
        
        String name8 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 8' : 'REST Callout Retry Batch 8';
		String cron8 = '0 40 * * * ?'; 
		SM_RESTCalloutRetryBatch job8 = new SM_RESTCalloutRetryBatch();
        System.schedule(name8, cron8, job8);
        
        String name9 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 9' : 'REST Callout Retry Batch 9';
		String cron9 = '0 45 * * * ?'; 
		SM_RESTCalloutRetryBatch job9 = new SM_RESTCalloutRetryBatch();
        System.schedule(name9, cron9, job9);
        
        String name10 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 10' : 'REST Callout Retry Batch 10';
		String cron10 = '0 50 * * * ?'; 
		SM_RESTCalloutRetryBatch job10 = new SM_RESTCalloutRetryBatch();
        System.schedule(name10, cron10, job10);
        
        String name11 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 11' : 'REST Callout Retry Batch 11';
		String cron11 = '0 55 * * * ?'; 
		SM_RESTCalloutRetryBatch job11 = new SM_RESTCalloutRetryBatch();
        System.schedule(name11, cron11, job11);
        
        String name12 = Test.isRunningTest() ? 'Test REST Callout Retry Batch 12' : 'REST Callout Retry Batch 12';
		String cron12 = '0 0 * * * ?'; 
		SM_RESTCalloutRetryBatch job12 = new SM_RESTCalloutRetryBatch();
		System.schedule(name12, cron12, job12);
	}

    private static Decimal getBatchSize() {
        Decimal intBatchSize;
        
        intBatchSize = [SELECT Callout_Retry_Batch_Size__c FROM Initialisation__mdt].Callout_Retry_Batch_Size__c;
        if (intBatchSize != null) {
            return intBatchSize;
        } else {
            return 0;
        }                        
    }
}