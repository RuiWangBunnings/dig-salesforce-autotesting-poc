/*******************************************************************************************************
* Class Name      	: DM_Case
* Description		: Data Layer - Selector for Sobject Case
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-05-15
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-15		1000				Initial version
******************************************************************************************************/
public with sharing class DM_Case {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param accountId 
    * @param ownerId 
    * @return Map<Id, Case> 
    **/
    public static Map<Id, Case> getCases(String accountId, String ownerId) {
        return new Map<Id, Case>([
            SELECT Id
            FROM Case
            WHERE AccountId = :accountId
            AND OwnerId = :ownerId
        ]);
    }

    
    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param ownerIds 
    * @return Map<Id, Case> 
    **/
    public static Map<Id, Case> getCases(Set<Id> accountIds, Set<Id> ownerIds) {
        return new Map<Id, Case>([
            SELECT Id, AccountId, OwnerId
            FROM Case
            WHERE AccountId IN :accountIds
            AND OwnerId IN :ownerIds
        ]);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param ownerIds 
    * @return Map<Id, Case> 
    **/
    public static Map<Id, Case> getOpenCases(Set<Id> accountIds, Set<Id> ownerIds) {
        return new Map<Id, Case>([
            SELECT Id, AccountId, OwnerId
            FROM Case
            WHERE AccountId IN :accountIds
            AND OwnerId IN :ownerIds
            AND IsClosed = FALSE
        ]);
    }
}