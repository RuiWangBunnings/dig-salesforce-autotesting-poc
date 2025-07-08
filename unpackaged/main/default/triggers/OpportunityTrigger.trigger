/*******************************************************************************************************
* Class Name        : OpportunityTrigger
* Description       : Trigger for Opportunity object
* Author            : Simplus - Yi Zhang
* Created On        : 12/08/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              12/08/2020      1000                Initial version
* Simplus MS            14/12/2020      1001                CCRM-6890,6892 Enhancement Changes
* Simplus MS			03/06/2021		3000				Added logic for turning on/off trigger using custom metadata
* Bunnings Dev          2024-11-21      1011                CRMS204 - Update Supplier Quote for Closed Won 
* Bunnings Dev          2024-12-06      1012                CRMS201 - PB Opportunity Create Action Conversation - New Opp Notification
******************************************************************************************************/
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete) {
    
    if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Opportunity_Trigger_Entry_1__c){
            OpportunityTriggerHandler.beforeInsert(Trigger.New);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Opportunity_Trigger_Entry_2__c){
            OpportunityTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.NewMap);
        }
    }

    if(Trigger.isAfter) {
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Opportunity_Trigger_Entry_2__c) {
            OpportunityTriggerHandler.afterInsert(Trigger.newMap);
        }
        if(Trigger.isUpdate && OpportunityTriggerHandler.isFirstTime && DM_ProcessAutomation.ccrmProcessAutomation.Opportunity_Trigger_Entry_2__c) {
            OpportunityTriggerHandler.isFirstTime = false;
            OpportunityTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
    
}