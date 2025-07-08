/*******************************************************************************************************
* Class Name      	: DM_SalesRep
* Description		: Data Layer - Selector for Sobject Sales_Rep__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 24/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              24/08/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_SalesRep {
    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param storeUserIds 
    * @param excludedSalesRepIds 
    * @return List<Sales_Rep__c> 
    **/
    public static List<Sales_Rep__c> getActiveSalesReps(List<Id> storeUserIds, List<Id> excludedSalesRepIds) {
        return new List<Sales_Rep__c>([
            SELECT Id, Assigned_to_Store__c, Assigned_to_Team_Member__c, Category__c
            FROM Sales_Rep__c
            WHERE Status__c = :Constants.STATUS_ACTIVE
            AND (Assigned_to_Store__c IN :storeUserIds OR Assigned_to_Team_Member__c IN :storeUserIds)
            AND Id NOT IN :excludedSalesRepIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param storeLocationCodes 
    * @return List<Sales_Rep__c> 
    **/
    public static List<Sales_Rep__c> getActiveSalesRepsWith(List<String> storeLocationCodes) {
        // System.debug('In getActiveSalesRepsWith');
        return new List<Sales_Rep__c>([
            SELECT Id, Assigned_to_Store__c, Current_Sales_Rep_ID__c, Category__c, 
            Assigned_to_Store__r.Location_Code__c
            FROM Sales_Rep__c
            WHERE Assigned_to_Store__r.Location_Code__c IN :storeLocationCodes
            AND Status__c = :Constants.STATUS_ACTIVE
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 27/08/2020 
    * @param storeIds 
    * @return List<Sales_Rep__c> 
    **/
    public static List<Sales_Rep__c> getActiveSalesRepsWithStoreIds(List<Id> storeIds) {
        return new List<Sales_Rep__c>([
            SELECt Id, Assigned_to_Store__c, Current_Sales_Rep_ID__c, Category__c, 
            Assigned_to_Store__r.Id, Assigned_to_Store__r.Sales_Rep_ID__c, Assigned_to_Store__r.Location_Code__c
            FROM Sales_Rep__c
            WHERE Assigned_to_Store__c IN :storeIds
            AND Status__c = :Constants.STATUS_ACTIVE
        ]);
    }
}