/*******************************************************************************************************
* Class Name        : CallPlanLeaveTrigger
* Description       : Trigger for Call_Plan_Leave__c object
* Author            : Simplus - Yi Zhang
* Created On        : 09/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              09/07/2020      1000                Initial version
******************************************************************************************************/
trigger CallPlanLeaveTrigger on Call_Plan_Leave__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            CallPlanLeaveTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CallPlanLeaveTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            CallPlanLeaveTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CallPlanLeaveTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isDelete) {
            CallPlanLeaveTriggerHandler.afterDelete(Trigger.old);
        }
    }
}