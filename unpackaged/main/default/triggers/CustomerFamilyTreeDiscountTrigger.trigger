/*******************************************************************************************************
* Trigger Name     	: CustomerFamilyTreeDiscountTrigger
* Description		: Customer Family Tree Discount Trigger
* Created On      	: 20/02/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     20/02/2023		1000				Initial version - BUNDIG-14164
******************************************************************************************************/

trigger CustomerFamilyTreeDiscountTrigger on Customer_Family_Tree_Discount__c (before insert, before update, before delete, after insert, after update, after delete) {

    if (Trigger.isAfter) {
        if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Customer_Family_Tree_Discount_Update__c) {
            CustomerFTDTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }

}