/*******************************************************************************************************
* Class Name      	: DM_SalesRepCategoryMapping
* Description		: Data Layer - Selector for Custom Metadata Type Sales_Rep_Category_Mapping__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 16/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              16/10/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_SalesRepCategoryMapping {
    /**
    * @description 
    * @author Yi Zhang | 16/10/2020 
    * @return Map<String, String> key is Bunnings Job Role on User, value is Category on Sales Rep
    **/
    public static Map<String, String> jobRoleSalesRepCategoryMap {
        get {
            if(jobRoleSalesRepCategoryMap == null) {
                jobRoleSalesRepCategoryMap = new Map<String, String>();
                for(Sales_Rep_Category_Mapping__mdt mapping: [SELECT Id, Job_Role__c, Sales_Rep_Category__c FROM Sales_Rep_Category_Mapping__mdt]) {
                    jobRoleSalesRepCategoryMap.put(mapping.Job_Role__c, mapping.Sales_Rep_Category__c);
                }
            }
            return jobRoleSalesRepCategoryMap;
        } set;
    }
}