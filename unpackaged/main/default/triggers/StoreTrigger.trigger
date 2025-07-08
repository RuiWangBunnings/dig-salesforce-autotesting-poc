/*******************************************************************************************************
* Trigger Name     	: StoreTrigger
* Description		: Store trigger
* Author          	: Simplus - Philip Clark
* Created On      	: 19/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          19/06/2020		1000				Initial version
******************************************************************************************************/
trigger StoreTrigger on Store__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            SM_Store.afterInsert(Trigger.newMap);
        }
        if(Trigger.isUpdate) {
            SM_Store.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}