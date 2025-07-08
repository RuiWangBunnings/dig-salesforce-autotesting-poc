/*******************************************************************************************************
* Trigger Name      : CustomerPriceListTrigger
* Description       : CustomerPriceList trigger
* Author            : Simplus MS
* Created On        : 15/12/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            15/12/2020       1000                Initial version - CCRM-297
* Simplus MS            29/06/2021       2000    		 	 modifications CCRM-13792
* Simplus MS            09/08/2021       3000                Added logic for turning on/off trigger using custom metadata
******************************************************************************************************/

trigger CustomerPriceListTrigger on Customer_Price_List__c (before insert, before update, before delete, after update, after insert, after delete) {
	 /**
     if(Trigger.isBefore){
        if(Trigger.isInsert && DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Insert__c) {
            
        }
        if(Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Update__c) {
            
        }
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Delete__c) {
            
        }
    }
    **/
    
    if(Trigger.isAfter){     
        //&& DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Insert__c
        if(Trigger.isInsert ) { //CCRM-13792
            CustomerPriceListTriggerHandler.afterInsert(Trigger.new);
        }
        //&& DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Update__c
        if(Trigger.isUpdate ){
            //CustomerPriceListTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            CustomerPriceListTriggerHandler.handleCPSPricingAssignment(Trigger.oldMap, Trigger.newMap);
        }
        /**
        if(Trigger.isDelete && DM_ProcessAutomation.ccrmProcessAutomation.Customer_Price_List_Trigger_Delete__c) {
            
        }
		**/
    }
}