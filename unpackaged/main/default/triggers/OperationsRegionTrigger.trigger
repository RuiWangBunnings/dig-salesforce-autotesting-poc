/*******************************************************************************************************
* Trigger Name     	: OperationsRegionTrigger
* Description		: Trigger for Operations_Region__c object
* Author          	: Simplus - Philip Clark
* Created On      	: 22/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          22/06/2020		1000				Initial version
******************************************************************************************************/
trigger OperationsRegionTrigger on Operations_Region__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            SM_OperationsRegion.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            SM_OperationsRegion.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            SM_OperationsRegion.afterInsert(Trigger.newMap);
        }
        if(Trigger.isUpdate) {
            SM_OperationsRegion.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isDelete) {
            SM_OperationsRegion.afterDelete(Trigger.old);
        }
    }
}