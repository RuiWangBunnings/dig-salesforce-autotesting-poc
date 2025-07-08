/*******************************************************************************************************
* Trigger Name      : TaskTrigger
* Description       : Trigger for Task object
* Author            : Simplus - John Paul Penaflor
* Created On        : 21/02/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* John Paul Penaflor    21/02/2020      1000                Initial version
* Yi Zhang              21/10/2020      2000                Removed inactive contact check
* Simplus MS			06/08/2021		3000				Added logic for turning on/off trigger using custom metadata
******************************************************************************************************/
trigger TaskTrigger on Task (before insert, before update, after insert, after update) {    
    
    if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Insert__c) {
            TaskTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Update__c) {
            TaskTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap, Trigger.new);
        }
        /**
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Delete__c) {
            
        }
		**/
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Insert__c){
            TaskTriggerHandler.afterInsert(Trigger.newMap);
        }
        /**
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Update__c) {
        
        }
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Task_Trigger_Delete__c) {
            
        }
		**/
    }
}