/*******************************************************************************************************
* Class Name      	: SalesRepTrigger
* Description		: Trigger for Sales_Rep__c object
* Author          	: Simplus - Yi Zhang
* Created On      	: 24/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              24/08/2020		1000				Initial version
******************************************************************************************************/
trigger SalesRepTrigger on Sales_Rep__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            SM_SalesRep.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            SM_SalesRep.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            SM_SalesRep.afterInsert(Trigger.newMap);
        }
        if(Trigger.isUpdate) {
            SM_SalesRep.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}