/*******************************************************************************************************
* Trigger Name      : CallTargetsTrigger
* Description		: Trigger for Call_Targets__c object
* Author          	: Simplus - Yi Zhang
* Created On      	: 18/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              18/06/2020		1000				Initial version
******************************************************************************************************/
trigger CallTargetsTrigger on Call_Targets__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            CallTargetsTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CallTargetsTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}