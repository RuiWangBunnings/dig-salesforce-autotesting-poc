/*******************************************************************************************************
* Trigger Name     	: AccountTrigger
* Description		: Account trigger
* Author          	: Simplus - Haider Raza
* Created On      	: 15/04/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           15/04/2020		1000				Initial version
* Yi Zhang              20/05/2020      2000                Added beforeUpdate & afterUpdate
* Simplus MS			03/06/2021		3000				Added logic for turning on/off trigger using custom metadata
* Simplus MS            29/07/2021      4000                Added try catch on afterUpdate for INC1000914 / INC1000976 / INC1001024 
******************************************************************************************************/
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_1__c) {
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_2__c) {
            AccountTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap, Trigger.new);
        }
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_3__c){
            AccountTriggerHandler.beforeDelete(Trigger.new, Trigger.oldMap, Trigger.old);
        }
    }

    if(Trigger.isAfter) {
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_1__c) {
            AccountTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_2__c) {
            //AccountTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            
            try{
                AccountTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            } catch (Exception e){
                String msg = e.getMessage();
                AuraHandledException ex = new AuraHandledException(msg);
                ex.setMessage(msg);
                throw ex;
            }
        }
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Account_Trigger_Entry_3__c) {
            AccountTriggerHandler.afterDelete(Trigger.oldMap);
        }
    }
}