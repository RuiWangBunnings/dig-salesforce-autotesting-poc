/*******************************************************************************************************
* Trigger Name      : UmbrellaBeneficiaryTrigger
* Description       : Trigger for Umbrella_Beneficiary__c object
* Author            : Simplus MS
* Created On        : 17/01/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            17/01/2022      1000                Initial version
******************************************************************************************************/
trigger UmbrellaBeneficiaryTrigger on Umbrella_Beneficiary__c (before insert, before update, before delete, after insert, after update, after delete) {
    
    if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Insert__c) {
            UmbrellaBeneficiaryTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Update__c) {
            UmbrellaBeneficiaryTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        /**
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Delete__c) {
            
        }
		**/
    }
    /**if(Trigger.isAfter) {
         
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Insert__c) {
            
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Update__c) {
            
        }
        
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Umbrella_Beneficiary_Trigger_Delete__c) {
            
        }
		
    }**/
}