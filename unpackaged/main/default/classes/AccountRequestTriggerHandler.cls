/*******************************************************************************************************
* Class Name        : AccountRequestTriggerHandler
* Description       : Account Request trigger handler
* Author            : Bunnings Dev
* Created On        : 24/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          24/07/2024      1000               Initial version
******************************************************************************************************/
public without sharing class AccountRequestTriggerHandler {

    public static boolean runOnce = true;
    public static boolean errorFlag = false;
    public static boolean accErrorFlag = false;
  	/**
    *  Method name  :  beforeInsert
    *  Description  :  Business logic after account request insert
    *  Author       :  Sowjanya   
    * @param        :  newAccReqList 
    **/
    public static void beforeInsert(List<Account_Request__c> newAccReqList) {

        Set<String> powerpassNumberSet = DM_AccountRequest.getPowerPassNumbers(newAccReqList);
        updateAccountRequest('beforeInsert',newAccReqList,powerpassNumberSet,null,null);
        
    }

    /**
    *  Method name  :  beforeUpdate
    *  Description  :  Business logic after account request update
    *  Author       :  Sowjanya   
    * @param        :  newAccReqList 
    **/
    public static void beforeUpdate(List<Account_Request__c> newAccReqList,Map<Id, Account_Request__c> mapNewAccReqs,Map<Id, Account_Request__c> mapOldAccReqs) {
        
        Set<String> powerpassNumberSet = DM_AccountRequest.getPowerPassNumbers(newAccReqList);
        system.debug('runonce:'+ runonce);
        if(runOnce) {
            
            runOnce = false;
            updateAccountRequest('beforeUpdate',newAccReqList,powerpassNumberSet,mapNewAccReqs,mapOldAccReqs);
            transferAccountAfterApproval(mapOldAccReqs, mapNewAccReqs);
        }
        
        
    }


	/**
    *  Method name  :  updateAccountRequest
    *  Description  :  Business logic to update details on Account Request
    *  Author       :  Sowjanya   
    * @param        :  operationType,newAccReqList, powerpassNumberSet ,mapNewAccReqs,mapOldAccReqs 
    **/
    public static void updateAccountRequest(String operationType,List<Account_Request__c> newAccReqList,Set<String> powerpassNumberSet,Map<Id, Account_Request__c> mapNewAccReqs, Map<Id, Account_Request__c> mapOldAccReqs ) {
       // List<Account_Request__c> arlistUpdate = new List<Account_Request__c>();
        try {
             
             Map<String,Boolean> mapUserStatus = DM_AccountRequest.getUserStatus(newAccReqList);
             Map<String,Account> powerpassAccMap = DM_Account.getAccountsByPowerPassNumbers(powerpassNumberSet);
           
            //Update Account Request with account id, Status, Failed reason fields
            for (Account_Request__c ar : newAccReqList) {
                try {
                
                    if((operationType == 'beforeInsert')|| (operationType == 'beforeUpdate' && (mapOldAccReqs.get(ar.Id).PowerPass_Account_Number__c != mapNewAccReqs.get(ar.Id).PowerPass_Account_Number__c) || mapOldAccReqs.get(ar.Id).New_Owner__c != mapNewAccReqs.get(ar.Id).New_Owner__c )){
                 
                       
                        if(operationType == 'beforeInsert' || (operationType == 'beforeUpdate' && (mapOldAccReqs.get(ar.Id).PowerPass_Account_Number__c != mapNewAccReqs.get(ar.Id).PowerPass_Account_Number__c))){
                            if(powerpassAccMap.get(ar.PowerPass_Account_Number__c)!=null){
                                ar.Previous_Owner__c=powerpassAccMap.get(ar.PowerPass_Account_Number__c).OwnerId;
                                ar.Previous_Owner_Sales_Id__c=powerpassAccMap.get(ar.PowerPass_Account_Number__c).Account_Owner_Sales_Id__c;
                            }

                        }

                        if(powerpassAccMap.get(ar.PowerPass_Account_Number__c)!=null){
                        
                            ar.Account__c=powerpassAccMap.get(ar.PowerPass_Account_Number__c).ID;
                           
                            if(ar.New_Owner__c!=null && mapUserStatus.get((Id)ar.New_Owner__c)){
                                ar.New_Owner__c=(ID)ar.New_Owner__c;
                                ar.New_Owner_Name__c=(ID)ar.New_Owner__c;
                                ar.Failed_Reason__c='';
                                ar.Status__c='Pending Transfer';
                                
                            }else if(ar.New_Owner__c!=null && !mapUserStatus.get((Id)ar.New_Owner__c)){
                                    ar.New_Owner__c=(ID)ar.New_Owner__c;
                                    ar.New_Owner_Name__c=(ID)ar.New_Owner__c;
                                    ar.Failed_Reason__c='New Owner is Inactive';
                                    ar.Status__c='Validation Failed';
                            }
                
                        }
                        else{
                        
                            ar.Status__c='Validation Failed';
                            if(powerpassAccMap.get(ar.PowerPass_Account_Number__c)==null && ar.New_Owner__c!=null && !mapUserStatus.get((Id)ar.New_Owner__c)){
                                ar.Failed_Reason__c='Power Pass Account not found and New Owner is Inactive';

                            }else if(powerpassAccMap.get(ar.PowerPass_Account_Number__c)==null){
                                ar.Failed_Reason__c='Power Pass Account not found';
                            
                            }else if(ar.New_Owner__c!=null && !mapUserStatus.get((Id)ar.New_Owner__c)){
                               ar.New_Owner__c=(ID)ar.New_Owner__c;
                                ar.Failed_Reason__c='New Owner is Inactive';
                                
                            }
                        
                    
                        }
                    }
                } catch(Exception e){
                    ar.Failed_Reason__c=e.getMessage();
                    ar.Status__c='Validation Failed';
                }
    
         }
        
        }catch(Exception e){
        
            //Log Error for Account Request
            ApplicationLogger.log('AccountRequestTriggerHandler.updateAccountRequest', 'AccountRequest', 'Trigger', e);
            
        }
    }

    /**
    *  Method name  :  transferAccountAfterApproval
    *  Description  :  Business logic to update details on Account Request
    *  Author       :  Sowjanya   
    * @param        :  oldAccReqList,  newAccReqList
    **/
    public static void transferAccountAfterApproval(Map<Id, Account_Request__c> oldAccReqList, Map<Id, Account_Request__c> newAccReqList) {
        
        //Declare variables
        Map<Id, Account_Request__c> oldMapBusinessAcc = new Map<Id, Account_Request__c>();
        Map<Id, Account_Request__c> newMapBusinessAcc = new Map<Id, Account_Request__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> newOwnerIds = new Set<Id>();
        Set<Id> oldOwnerIds = new Set<Id>();
        List<Account_Request__c> updAccReqList = new List<Account_Request__c>();
       
        if(!newAccReqList.isEmpty()){
            
            for (Account_Request__c newAccountReq : newAccReqList.values()) {
                Account_Request__c oldAccountReq = oldAccReqList.get(newAccountReq.Id);
                System.debug('oldAccountReq.Transfer_approval_status__c:' +oldAccountReq.Transfer_approval_status__c);
                System.debug('newAccountReq.Transfer_approval_status__c:' +newAccountReq.Transfer_approval_status__c);
                //check for the new account request is approved and then transfer account and related records
                if(oldAccountReq.Transfer_approval_status__c != newAccountReq.Transfer_approval_status__c && newAccountReq.Transfer_approval_status__c=='Approved') {
                   Boolean userStatus = DM_User.getUserStatus(newAccountReq.Transfer_to__c);
               
                    if(userStatus){
                        Account a = DM_Account.getAccount(newAccountReq.Account__c);
                        accountIds.add(a.id);
                        newOwnerIds.add(newAccountReq.Transfer_to__c);
                        oldOwnerIds.add(a.OwnerId);
                        updAccReqList.add(newAccountReq);
                        // transfer account
                      SM_AccountRequestTransfer.transferAccountAndRelatedRecords(accountIds, newOwnerIds,oldOwnerIds,updAccReqList);
                      //Update Account Request List based on error in account transfer
                      
                      if(accErrorFlag){
                        newAccountReq.Status__c = 'Failed';
                        newAccountReq.Failed_Reason__c ='Account Transfer Failed';
                      }
                      else if(errorFlag){

                        newAccountReq.Status__c = 'Partially Completed';
                        newAccountReq.Failed_Reason__c ='Related Objects on Account Transfer Failed';
                        }
                        else{
                            newAccountReq.Status__c = 'Completed';
                        }    
                       
      
                    }else{
                        try {
                            for(Account_Request__c ar : newAccReqList.values()) {
                                ar.Status__c = 'Validation Failed';
                                ar.Failed_Reason__c ='Transfer to User  is Inactive';
                              
                            }
                                     
                            
                            } catch(Exception e) {
                                // TODO log exception
                                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAfterApproval', 'Account_Request__c', 'Trigger', e, newAccountReq.id); //Added 04.Jun.2021

                                
                            }
                        
                    }
                    
                    
                } 
                
            }
            
            
        
        }
                
    }
    
}