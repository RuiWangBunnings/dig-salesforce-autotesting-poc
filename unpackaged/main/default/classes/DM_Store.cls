/*******************************************************************************************************
* Class Name        : DM_Store
* Description       : Data Layer - Selector for Sobject Store__c
* Author            : Simplus - Philip Clark
* Created On        : 23/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          23/06/2020      1000                Initial version
* Simplus MS            17/06/2021		3000				CCRM-13881 - Default Trade Specialist Editable by Trade Specialists
* Simplus MS            19/10/2021      4000                Added logic for CCRM15-79: Return a map of store records
* Simplus MS            02/12/2021      5000                Added logic for CCRM15-417: Planned Leave - Account Assignment and Transfers
* Simplus MS 			18/01/2022		6000				Added field getStoresWithAddressByLocationCode for CCRM15-566
******************************************************************************************************/
public with sharing class DM_Store {
    
    /**
    * @description  
    * @author       Philip Clark | 23/06/2020 
    * @param        set<String> 
    * @param        String 
    * @param        set<String> 
    * @return       list<Store__c> 
    **/
    public static list<Store__c> getStoreByLocCode(set<String> locSet, String activeStatus, set<String> roleSet) {
        List<Store__c> retList = new List<Store__c>();
        if (roleSet!=null) {
            retList = [
                SELECT Id, Location_Code__c, Operations_Region_Code__c, Sales_Rep_ID__c,
                    (SELECT Id, Team_Member__c, Default_Trade_Specialist__c, Role__c FROM User_Stores__r 
                    WHERE Status__c =: activeStatus AND Role__c IN: roleSet 
                    ORDER BY CREATEDDATE ASC) 
                FROM Store__c WHERE Location_Code__c IN: locSet];
        } else
        {
            retList = [
                SELECT Id, Location_Code__c, Operations_Region_Code__c, Sales_Rep_ID__c,
                    (SELECT Id, Team_Member__c, Default_Trade_Specialist__c, Role__c FROM User_Stores__r 
                    WHERE Status__c =: activeStatus 
                    ORDER BY CREATEDDATE ASC) 
                FROM Store__c WHERE Location_Code__c IN: locSet];
        }
        return retList;
    }
    
    /**
    * @description  
    * @author       Philip Clark | 23/06/2020 
    * @param        set<String> 
    * @param        String 
    * @param        set<String> 
    * @return       list<Store__c> 
    **/
    public static list<Store__c> getStoreByOpRegCode(set<String> regCodeSet, String activeStatus, set<String> roleSet) {
        List<Store__c> retList = new List<Store__c>();
        if (roleSet!=null) {
            retList = [
                SELECT Id, Location_Code__c, Operations_Region_Code__c, Sales_Rep_ID__c,
                    (SELECT Id, Team_Member__c, Default_Trade_Specialist__c, Role__c FROM User_Stores__r 
                    WHERE Status__c =: activeStatus AND Role__c IN: roleSet 
                    ORDER BY CREATEDDATE ASC) 
                FROM Store__c WHERE Operations_Region_Code__c IN: regCodeSet];
        } else
        {
            retList = [
                SELECT Id, Location_Code__c, Operations_Region_Code__c, Sales_Rep_ID__c,
                    (SELECT Id, Team_Member__c, Default_Trade_Specialist__c, Role__c FROM User_Stores__r 
                    WHERE Status__c =: activeStatus 
                    ORDER BY CREATEDDATE ASC) 
                FROM Store__c WHERE Operations_Region_Code__c IN: regCodeSet];
        }
        return retList;
    }

    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param opRegCodes 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoreByOpRegCodes(Set<String> opRegCodes) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c
            FROM Store__c
            WHERE Operations_Region_Code__c IN :opRegCodes
            AND Status__c = :Constants.STATUS_ACTIVE
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param storeIds 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithActiveTSs(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c,
            (
                SELECT Id, Default_Trade_Specialist__c 
                FROM User_Stores__r 
                WHERE Default_Trade_Specialist__c = false
                AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME 
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description Added for CCRM-13881 
    * @author MS Simplus | 17/06/2021
    * @param storeIds 
    * @param storeMemberIds
    **/
    public static List<Store__c> getStoresWithActiveTSList(List<Id> storeIds, Set<Id> storeMemberIds) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c,
            (
                SELECT Id, Default_Trade_Specialist__c 
                FROM User_Stores__r 
                WHERE Default_Trade_Specialist__c = false
                AND Id NOT IN : storeMemberIds 
                AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
                AND Team_Member__c NOT IN (SELECT OwnerId FROM Planned_Leave__c WHERE Status__c = 'Approved' 
                AND (Start_Date__c = TODAY OR End_Date__c = TODAY))
                ORDER BY Call_Volume__c DESC, CreatedDate ASC
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description Added for CCRM15-394
    * @author MS Simplus | 31/01/2022
    * @param storeIds 
    * @param storeMemberIds
    **/
    /*public static List<Store__c> getStoresWithAllTSList(List<Id> storeIds, Set<Id> storeMemberIds) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c,
            (
                SELECT Id, Default_Trade_Specialist__c 
                FROM User_Stores__r 
                WHERE Default_Trade_Specialist__c = true
                //AND Id NOT IN : storeMemberIds 
                //AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
                AND Team_Member__c NOT IN (SELECT OwnerId FROM Planned_Leave__c WHERE Status__c = 'Approved' 
                AND (Start_Date__c = TODAY OR End_Date__c = TODAY))
                //ORDER BY Call_Volume__c DESC, CreatedDate ASC
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }*/

    /**
    * @description Added for CCRM15-394
    * @author MS Simplus | 20/12/2021
    * @param storeIds
    **/
    public static List<Store__c> getStoresWithActiveDTSList(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c,
            (
                SELECT Id, Default_Trade_Specialist__c 
                FROM User_Stores__r 
                WHERE Default_Trade_Specialist__c = true
                AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
                AND Team_Member__c NOT IN (SELECT OwnerId FROM Planned_Leave__c WHERE Status__c = 'Approved' 
                AND (Start_Date__c = TODAY OR End_Date__c = TODAY))
                ORDER BY Call_Volume__c DESC, CreatedDate ASC
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description Added for CCRM-13881 
    * @author MS Simplus | 14/06/2021 
    * @param storeIds 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithDefaultActiveTSs(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Operations_Region_Code__c,
            (
                SELECT Id, Default_Trade_Specialist__c, Team_Member__c  
                FROM User_Stores__r 
                WHERE Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME 
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param storeIds 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithOneActiveRCM(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Name, Operations_Region_Code__c,
            (
                SELECT Id, Team_Member__c 
                FROM User_Stores__r 
                WHERE Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                AND Role__c = :Constants.STOREMEMBER_RCM_ROLENAME 
                LIMIT 1
            )
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 28/10/2020 
    * @param storeIds 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithActiveSMs(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Engagement_Model__c,
            (
                SELECT Id, Team_Member__c, Team_Member__r.Name, Role__c, Default_Trade_Specialist__c 
                FROM User_Stores__r 
                WHERE Status__c = :Constants.STATUS_ACTIVE
            )
            FROM Store__c
            WHERE Id In :storeIds
        ]);
    }

    
    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param storeIds 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStores(List<Id> storeIds) {
        return new List<Store__c>([
            SELECT Id, Name, Operations_Region_Code__c, Location_Code__c, Sales_Rep_ID__c
            FROM Store__c
            WHERE Id IN :storeIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 03/09/2020 
    * @param locationCodes 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithValidOpRegCodeByLocationCode(List<String> locationCodes) {
        return new List<Store__c>([
            SELECT Id, Location_Code__c, Operations_Region_Code__c 
            FROM Store__c 
            WHERE  Location_Code__c IN : locationCodes 
            AND Operations_Region_Code__c != null
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 21/10/2020 
    * @param locationCodes 
    * @return List<Store__c> 
    **/
    public static List<Store__c> getStoresWithAddressByLocationCode(List<String> locationCodes) {
        return new List<Store__c>([
            SELECT Id, Location_Code__c, Location_Type__c, 
            Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,
            City__c, State__c, Postcode__c, Country__c, Trade_Specialist_Email__c
            FROM Store__c 
            WHERE  Location_Code__c IN : locationCodes 
        ]);
    }
    
    /**
    * @description 
    * @author Simplus MS | 20/10/2021 
    * @param storeMembers 
    * @return Map<Id, Store__c> 
    **/
    public static Map<Id, Store__c> getStoreMap(List<Store_Member__c> storeMembers) {
        Set<Id> storeIdSet = new Set<Id>();
        for(Store_Member__c sm : storeMembers) {
            storeIdSet.add(sm.Store__c);
        }
        return new Map<Id, Store__c>([
            SELECT Id, Engagement_Model__c, Location_Type__c, Country__c, Store_Call__c
            FROM Store__c WHERE Id IN: storeIdSet
        ]);
    }
}