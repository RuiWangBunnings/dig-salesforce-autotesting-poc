/*******************************************************************************************************
* Trigger Name     	: QuoteTrigger
* Description		: Quote trigger
* Created On      	: 31/03/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          31/03/2022		1000				SFSUP-289 - Log COS API Callout details
******************************************************************************************************/
// Platforn event object only support after insert
trigger ApplicationLogETrigger on Application_Log__e (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Application_Log_Event_Trigger_Insert__c) {
            ApplicationLogETriggerHandler.afterInsert(Trigger.oldMap, Trigger.newMap);
        }
    }
}