/*******************************************************************************************************
* Trigger Name      : ContactTrigger
* Description       : Contact trigger
* Author            : Simplus - Haider Raza
* Created On        : 15/04/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           15/04/2020      1000                Initial version
* Francis Benzon        15/06/2020      2000                Update with beforeInsert and beforeUpdate
* Yi Zhang              08/09/2020      3000                Add afterDelete
* Simplus MS			06/08/2021		3000				Added logic for turning on/off trigger using custom metadata
******************************************************************************************************/
trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Insert__c) {
             ContactTriggerHandler.beforeInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Update__c) {
             ContactTriggerHandler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Delete__c){
            ContactTriggerHandler.beforeDelete(Trigger.new, Trigger.oldMap, Trigger.old);
        }
    }

    if(Trigger.isAfter){   
        /**
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Insert__c) {
            
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Update__c) {
            
        }
		**/
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Contact_Trigger_Delete__c){
            ContactTriggerHandler.afterDelete(Trigger.oldMap);
        }
    }
}