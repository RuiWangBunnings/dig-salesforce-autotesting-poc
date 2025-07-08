/*******************************************************************************************************
* Trigger Name      : OrderTrigger
* Description       : Trigger for Order object
* Author            : Simplus - Yi Zhang
* Created On        : 09/10/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              09/10/2020      1000                Initial version
* Bunnings dev            03/10/2024		1001				Adding Before Insert Trigger logic
******************************************************************************************************/
trigger OrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete) {
    System.debug('DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Insert__c:'+DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Insert__c);
    System.debug('DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Update__c:'+DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Update__c);
    if(Trigger.isBefore) {
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Insert__c) {
            SM_Order.beforeInsert(Trigger.new);
        }        
    }

    if(Trigger.isAfter) {
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Insert__c) {
            SM_Order.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Order_Trigger_Update__c) {
            SM_Order.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}