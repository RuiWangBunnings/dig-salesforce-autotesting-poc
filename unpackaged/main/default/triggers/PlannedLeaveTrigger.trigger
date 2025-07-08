/**
 * @author            : Simplus MS
 * @last modified on  : 03/12/2021
 * @last modified by  : Simplus MS
**/
trigger PlannedLeaveTrigger on Planned_Leave__c (before insert, before update, after update) {

    if(Trigger.isBefore && Trigger.isInsert)
        PlannedLeaveTriggerHandler.beforeInsert(Trigger.new);
    if(Trigger.isBefore && Trigger.isUpdate)
        PlannedLeaveTriggerHandler.beforeUpdate(Trigger.newMap);
    if(Trigger.isAfter && Trigger.isUpdate)
        PlannedLeaveTriggerHandler.afterUpdate(Trigger.new);

}