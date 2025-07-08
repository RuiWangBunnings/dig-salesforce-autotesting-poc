/*******************************************************************************************************
* Trigger Name      : StoreMemberTrigger
* Description		: Trigger for Store_Member__c object
* Author          	: Simplus - Yi Zhang
* Created On      	: 25/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              25/08/2020		1000				Initial version
* Yi Zhang              07/10/2020		2000				Added isAfter
******************************************************************************************************/
trigger StoreMemberTrigger on Store_Member__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            SM_StoreMember.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            SM_StoreMember.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            SM_StoreMember.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            SM_StoreMember.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}