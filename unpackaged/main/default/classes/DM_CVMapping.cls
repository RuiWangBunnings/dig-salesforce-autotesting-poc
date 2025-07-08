/*******************************************************************************************************
* Class Name      	: DM_CVMapping
* Description		: Data Layer - Selector for custom metadata CV_Mapping__mdt
* Author          	: Simplus - Philip Clark
* Created On      	: 29/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark			29/06/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_CVMapping {
    /**
    * @description 
    * @author Philip Clark | 29/06/2020 
    * @return List<CV_Mapping__mdt> 
    **/
    public static List<CV_Mapping__mdt> getCVMappings() {
        return [
            SELECT Id, Object__c, MasterLabel, Field_for_Start__c, List_View__c, Display_Field__c, Colour__c, Fill_Pattern__c, User_Profiles__c
            FROM CV_Mapping__mdt
            WHERE Active__c = TRUE
        ];
    }
}