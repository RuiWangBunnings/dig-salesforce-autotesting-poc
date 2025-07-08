/*******************************************************************************************************
* Trigger Name     	: QuoteTrigger
* Description		: Quote trigger
* Created On      	: 18/02/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          18/02/2022		1000				Initial version
* Simplus MS            30/05/2022		2000				SFSUP-738 - Opportunity has not updated the syncing quote, 
                                                            therefore the opp value is incorrect
******************************************************************************************************/
trigger QuoteTrigger on Quote (before insert, before update, before delete, after insert, after update, after delete) {
    
        if (Trigger.isBefore) {
            if (Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Quote_Trigger_Insert__c) {
                QuoteTriggerHandler.beforeInsert(Trigger.New);
            }        
        }
        if (Trigger.isAfter) {
            if (Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Quote_Trigger_Update__c) {
                QuoteTriggerHandler.afterInsert(Trigger.New);
            }

            if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Quote_Trigger_Update__c) {
                QuoteTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            }
        }

}