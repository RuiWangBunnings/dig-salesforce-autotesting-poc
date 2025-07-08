/*******************************************************************************************************
* Class Name      	: DM_ProcessInstanceWorkitem
* Description		: Data Layer - Selector for Sobject ProcessInstanceWorkitem
* Author          	: Simplus - Yi Zhang
* Created On      	: 19/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              19/05/2020		1000				Initial version
******************************************************************************************************/
public without sharing class DM_ProcessInstanceWorkitem {
    /**
    * @description 
    * @author Yi Zhang | 19/05/2020 
    * @param targetObjectIds 
    * @return List<ProcessInstanceWorkitem> 
    **/
    public static List<ProcessInstanceWorkitem> getProcessInstanceWorkItems(Set<Id> targetObjectIds) {
        return [
            SELECT Id, ProcessInstance.TargetObjectId, ActorId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :targetObjectIds
        ];
    }
}