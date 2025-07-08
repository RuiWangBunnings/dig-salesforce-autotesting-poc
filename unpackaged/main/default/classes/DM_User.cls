/*******************************************************************************************************
* Class Name      	: DM_User
* Description		: Data Layer - Selector for Sobject User
* Author          	: Simplus - Yi Zhang
* Created On      	: 14/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              14/05/2020		1000				Initial version
* Philip Clark			01/07/2020		1001				getActiveUsers
* Simplus MS            11/06/2021      1002                added isActive field query on getUsers
* Bunnnings Dev         28/08/2024      1003                added getUserStatus
******************************************************************************************************/
public with sharing class DM_User {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param userId 
    * @return User 
    **/
    public static User getUser(String userId) {
        if(userId == null) {
            return null;
        }
        List<User> users = [
            SELECT Id, Name, Profile.Name, Is_TS__c, ManagerId, Country__c, LocaleSidKey
            FROM User
            WHERE Id = :userId];
        return (users.isEmpty()) ? null : users[0];
    }

    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param userIds 
    * @return Map<Id, User> 
    **/
    public static Map<Id, User> getUsers(List<String> userIds) {
        return new Map<Id, User>([
            SELECT Id, Profile.Name, Is_TS__c, ManagerId, isActive,Sales_Rep_ID__c
            FROM User
            WHERE Id IN :userIds
        ]);
    }

    /**
    * @description 
    * @author Philip Clark | 01/07/2020 
    * @param userIds 
    * @return Map<Id, User> 
    **/
    public static Map<Id, User> getActiveUsers() {
        return new Map<Id, User>([
            SELECT Id, Profile.Name, Is_TS__c, ManagerId, DelegatedApproverId
            FROM User
            WHERE isActive = TRUE
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 23/06/2020 
    * @param managerId 
    * @param profileNames 
    * @return List<User> 
    **/
    public static List<User> getActiveUsersManagedBy(String managerId, List<String> profileNames) {
        return new List<User>([
            SELECT Id, Name
            FROM User
            WHERE ManagerId = :managerId
            AND Profile.Name IN :profileNames
            AND IsActive = true
            ORDER BY Name ASC
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 23/06/2020 
    * @param profileNames 
    * @return List<User> 
    **/
    public static List<User> getActiveUsersOfProfiles(List<String> profileNames) {
        return new List<User>([
            SELECT Id, Name
            FROM User
            WHERE Profile.Name IN :profileNames
            AND IsActive = true
            ORDER BY Name ASC
        ]);
    }

    /**
    * @description  Only Trade Specialists
    * @author Yi Zhang | 24/08/2020 
    * @param locationCodes 
    * @return List<User> 
    **/
    public static List<User> getTSUsersByLocationCode(List<String> locationCodes) {
        return new List<User>([
            SELECT Id, Location_Code__c, Bunnings_Job_Role__c
            FROM User
            WHERE Location_Code__c IN :locationCodes
            AND Is_TS__c = true
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 28/10/2020 
    * @param names 
    * @return List<User> 
    **/
    public static List<User> getUsersByName(List<String> names) {
        return new List<User>([
            SELECT Id, Name 
            FROM User 
            WHERE Name IN :names
        ]);
    }


     /**
    * @description : getUserStatus
    * @author Sowjanya 
    * @param userId 
    * @return Boolean 
    **/
    public static Boolean getUserStatus(String userId) {
        if(userId == null) {
            return null;
        }
        List<User> users = [
            SELECT id, isActive 
            FROM User 
            WHERE Id = :userId];
        return (users.isEmpty()) ? null : users[0].isActive;
    }
}