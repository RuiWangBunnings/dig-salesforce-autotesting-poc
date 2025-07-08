/*******************************************************************************************************
* Trigger Name      : ContractTrigger
* Description       : Contract__c trigger
* Author            : Simplus - Philip Clark
* Created On        : 01/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          01/07/2020      1000                Initial version
******************************************************************************************************/
trigger ContractTrigger on Contract__c (before insert, before update, after update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            SM_Contract.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            SM_Contract.beforeUpdate(Trigger.oldMap, Trigger.new);
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isUpdate) {
            SM_Contract.afterUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}