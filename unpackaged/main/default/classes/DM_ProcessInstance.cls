/*******************************************************************************************************
* Class Name      	: DM_ProcessInstance
* Description		: Data Layer - Selector for Sobject ProcessInstance
* Author          	: Simplus - Yi Zhang
* Created On      	: 18/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              18/05/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_ProcessInstance {
    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param targetObjectIds 
    * @return List<ProcessInstance> 
    **/
    public static List<ProcessInstance> getPendingProcessInstances(Set<Id> targetObjectIds) {
        return [
            SELECT Id, TargetObjectId
            FROM ProcessInstance
            WHERE TargetObjectId IN :targetObjectIds
            AND Status = 'Pending'
        ];
    }
}