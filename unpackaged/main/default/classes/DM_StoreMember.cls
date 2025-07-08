/*******************************************************************************************************
* Class Name      	: DM_StoreMember
* Description		: Data Layer - Selector for Sobject Store_Member__c
* Author          	: Simplus - Philip Clark
* Created On      	: 23/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          23/06/2020		1000				Initial version
* Simplus MS 			01/06/2021 		2000 				Added logic for CCRM-13832 prevent multiple active Team Member of per role to Store
* Simplus MS            14/06/2021		6000				CCRM-13881 - Default Trade Specialist Editable by Trade Specialists      
******************************************************************************************************/
public with sharing class DM_StoreMember {

    /**
    * @description  
    * @author       Philip Clark | 23/06/2020 
    * @param        set<Id> 
    * @return       list<Store_Member__c> 
    **/
    public static list<Store_Member__c> getStoreMemberbyUId(set<Id> uIdSet) {
        return new List<Store_Member__c> ([
            SELECT Id, Team_Member__c, Location_Code__c, End_Date__c, Role__c, Default_Trade_Specialist__c, Status__c, Store__c, Store__r.Name 
			FROM Store_Member__c 
            WHERE Team_Member__c IN: uIdSet
        ]);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param opRegCodes 
    * @param roles 
    * @param status 
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getStoreMembers(Set<String> opRegCodes, Set<String> roles, String status) {
        return new List<Store_Member__c>([
            SELECT Id, Role__c, Store__r.Operations_Region_Code__c
            FROM Store_Member__c 
            WHERE Store__r.Operations_Region_Code__c IN :opRegCodes
            AND Role__c IN :roles
            AND Status__c = :status
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param userIds 
    * @param status 
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getStoreMembers(List<Id> userIds, String status) {
        return new List<Store_Member__c>([
            SELECT Id, Role__c, Store__c, Default_Trade_Specialist__c,End_Date__c,Team_Member__c
            FROM Store_Member__c 
            WHERE Team_Member__c IN :userIds
            AND Status__c = :status
        ]);
    }
    
     /**
    * @description 
    * @param userIds 
    * @param status 
    * @param locationCode
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getInactiveStoreMembers(List<Id> userIds, String status, String locationCode) {
        List<Store_Member__c> inactiveSM = new List<Store_Member__c>();
        System.debug('locationCode>> '+locationCode+' userIds '+userIds+' status '+status);
        if(locationCode != null) {
            inactiveSM = [
                SELECT Id, Role__c, Store__c, Default_Trade_Specialist__c,End_Date__c,Status__c,Team_Member__c, Location_Code__c
                FROM Store_Member__c 
                WHERE Team_Member__c IN :userIds
                AND Status__c = :status
                AND Location_Code__c = :locationCode
            ];
        }
        System.debug('inactiveSM '+inactiveSM);
        return inactiveSM ;
    }

    /**
    * @description 
    * @author Yi Zhang | 25/08/2020 
    * @param storeIds 
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getActiveDefaultTradeSpecialistStoreMembers(List<Id> storeIds, List<Id> excludeStoreMemberIds) {
        return new List<Store_Member__c>([
            SELECT Id, Role__c, Store__c
            FROM Store_Member__c 
            WHERE Status__c = :Constants.STATUS_ACTIVE
            AND Default_Trade_Specialist__c = true
            AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
            AND Store__c IN :storeIds
            AND Id NOT IN :excludeStoreMemberIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 07/10/2020 
    * @param storeIds 
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getActiveTradeSpecialistStoreMembers(Set<Id> storeIds) {
        return new List<Store_Member__c>([
            SELECT Id, Store__c, Team_Member__c, Team_Member__r.ManagerId, Default_Trade_Specialist__c 
            FROM Store_Member__c 
            WHERE Store__c IN :storeIds
            AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
            AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
            ]);
    }

    /**
    * @description Added for CCRM-13881 
    * @author MS Simplus | 17/06/2021
    * @param storeIds 
    * @param storeMemberIds
    **/
    public static List<Store_Member__c> getOldActiveTradeSpecialistStoreMembers(Set<Id> storeIds, Set<Id> storeMemberIds) {
        return new List<Store_Member__c>([
            SELECT Id, Store__c, Team_Member__c, Team_Member__r.ManagerId, Default_Trade_Specialist__c 
            FROM Store_Member__c 
            WHERE Store__c IN :storeIds
            AND Id NOT IN : storeMemberIds
            AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
            AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
            ]);
    }

    /**
    * @description Added for CCRM-13832 
    * @author MS Simplus | 01/06/2021 
    * @param storeIds 
    * @return List<Store_Member__c> 
    **/
    public static List<Store_Member__c> getInactiveTradeSpecialistStoreMembers(Set<Id> storeIds) {
        return new List<Store_Member__c>([
            SELECT Id, Store__c, Team_Member__c, Status__c, Default_Trade_Specialist__c
            FROM Store_Member__c 
            WHERE Store__c IN :storeIds
            AND Status__c = :Constants.STOREMEMBER_INACTIVE_STATUS
            AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
            ]);
    }

}