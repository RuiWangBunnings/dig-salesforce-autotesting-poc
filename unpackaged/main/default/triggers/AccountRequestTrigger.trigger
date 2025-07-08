/*******************************************************************************************************
* Trigger Name     	: AccountRequestTrigger
* Description		: Account Request trigger
* Author          	: Bunnings Dev
* Created On      	: 24/07/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev           24/07/2024		   1000				Initial version
******************************************************************************************************/
trigger AccountRequestTrigger on Account_Request__c (before insert, before update,after update) {

    if(Trigger.isBefore) {
       system.debug('DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Insert__c--'+DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Insert__c);
        system.debug('DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Update__c--'+DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Update__c);
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Insert__c) {
            system.debug('beforeInsert');
            AccountRequestTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Account_Request_Trigger_Update__c) {
            system.debug('beforeUpdate');
            AccountRequestTriggerHandler.beforeUpdate(Trigger.new,Trigger.newMap,Trigger.oldMap);
            
        }
        
    }
  
}