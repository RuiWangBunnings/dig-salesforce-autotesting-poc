/*******************************************************************************************************
* Class Name      	: DM_OperationsRegionTSRole
* Description		: Data Layer - Selector for custom metadata Operations_Region_TS_Role__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 03/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              03/09/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_OperationsRegionTSRole {
    /**
    * @description 
    * @author Yi Zhang | 03/09/2020 
    * @param opRegCodes 
    * @return List<Operations_Region_TS_Role__mdt> 
    **/
    public static List<Operations_Region_TS_Role__mdt> getRecordsByOpRegCode(List<String> opRegCodes) {
        return new List<Operations_Region_TS_Role__mdt>([
            SELECT Id, Operations_Region__c, Trade_Specialist_Role__c 
            FROM Operations_Region_TS_Role__mdt 
            WHERE Operations_Region__c IN :opRegCodes
            ]);
    }
}