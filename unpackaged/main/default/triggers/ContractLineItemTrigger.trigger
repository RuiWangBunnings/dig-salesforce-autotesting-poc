/*******************************************************************************************************
* Trigger Name      : ContractLineItemTrigger
* Description       : Contract_Line_Item__c trigger
* Author            : Bunnings Dev
* Created On        : 15/05/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R Galapon      15/05/2023      1000                Initial version - BUNDIG-18514
* Jasper R Galapon      08/08/2023      1001                BUNDIG-23679 - Contract Amendments - A2 Approval Required for New Line Items
* Jasper R Galapon      09/08/2024      1002                BUNDIG-34608 - Contract Amendment - Set Auto Approval Eligibility
******************************************************************************************************/
trigger ContractLineItemTrigger on Contract_Line_Item__c (before insert, before update, before delete, after insert, after update, after delete) {   

    if (Trigger.isBefore) {
        if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Contract_Line_Item_Trigger_Update__c) {
            ContractLineItemTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Contract_Line_Item_Trigger_Insert__c) {
            ContractLineItemTriggerHandler.beforeInsert(Trigger.new);
        }
    }
    // BUNDIG-23679
    if (Trigger.isAfter) {
        if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Contract_Line_Item_Trigger_Update__c) {
            ContractLineItemTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}