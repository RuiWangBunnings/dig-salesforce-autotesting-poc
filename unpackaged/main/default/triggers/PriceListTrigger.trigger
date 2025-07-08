/*******************************************************************************************************
* Trigger Name      : PriceListTrigger
* Description       : Determine the number of occurrences of duplicated Price List Definitions within a Price List.
* Author            : Jasper R. Galapon
* Created On        : 19/12/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     19/12/2023      1000                BUNDIG-28056 - Initial Version
******************************************************************************************************/

trigger PriceListTrigger on Price_List__c (before insert, before update, before delete, after update, after insert, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Price_List_Trigger_Insert__c) {
            PriceListTriggerHandler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Price_List_Trigger_Update__c) {
            PriceListTriggerHandler.afterUpdate(Trigger.new);
        }
        if (Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Price_List_Trigger_Delete__c) {
            PriceListTriggerHandler.afterDelete(Trigger.old);
        }
    }

}