/*******************************************************************************************************
* Trigger Name      : CaseTrigger
* Description		: Trigger for Case object
* Author          	: Simplus - Levi Davision
* Created On      	: 24/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Levi Davision         24/06/2020		1000				Initial version
* SIMPLUS MS            07/06/2020                          Created beforeInsert method - CCRM-13791
******************************************************************************************************/
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isBefore && Trigger.isInsert) {
        CaseTriggerHandler.checkContractGroupField(Trigger.new);
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            CaseTriggerHandler.afterInsert(Trigger.new);
        }
    }
}