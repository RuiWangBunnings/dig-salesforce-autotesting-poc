/*******************************************************************************************************
* Trigger Name      : CustomerContractTrigger
* Description       : Customer Contract Trigger
* Author            : Simplus - John Paul Peñaflor
* Created On        : 17/08/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    17/08/2020      1000                Initial version
* Bunnings Dev          07/03/2022      2000                SFSUP-373 - Added after update to replace process builder Customer Contract Update Actions
******************************************************************************************************/
trigger CustomerContractTrigger on Customer_Contract__c (before insert, before update, before delete, after insert, after update, after delete) {
        
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CustomerContractTriggerHandler.afterInsert(Trigger.newMap);
        }
        if (Trigger.isUpdate) {
            CustomerContractTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }

    if (Trigger.isBefore) {
        if (Trigger.isDelete){
            CustomerContractTriggerHandler.beforeDelete(Trigger.oldMap);
        }
    }
}