/*******************************************************************************************************
* Class Name      	: DM_ProjectContractMatchingField
* Description		: Data Layer - Selector for Custom Metadata Type Project_Contract_Matching_Field__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 01/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              01/10/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_ProjectContractMatchingField {
    /**
    * @description 
    * @author Yi Zhang | 01/10/2020 
    * @return List<Project_Contract_Matching_Field__mdt> 
    **/
    public static List<Project_Contract_Matching_Field__mdt> matchingFields {
        get {
            if(matchingFields == null) {
                matchingFields = new List<Project_Contract_Matching_Field__mdt>([
                    SELECT Id, 
                    Source_Field__r.QualifiedApiName, 
                    Destination_Field__r.QualifiedApiName 
                    FROM Project_Contract_Matching_Field__mdt
                    ]);
            }
            return matchingFields;
        } set;
    }
}