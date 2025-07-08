/*******************************************************************************************************
* Trigger Name      : LeadTrigger
* Description       : Trigger for Lead object
* Author            : Simplus - Yi Zhang
* Created On        : 15/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020      1000                Initial version
******************************************************************************************************/
trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            LeadTriggerHandler.beforeInsert(Trigger.New);
        }

        if(Trigger.isUpdate) {
            LeadTriggerHandler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }

        
    }

    if(Trigger.isAfter){
        if(Trigger.isDelete){
            LeadTriggerHandler.afterDelete(Trigger.oldMap);
        }
    }
}