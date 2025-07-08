/*******************************************************************************************************
* Class Name      	: DM_Opportunity
* Description		: Data Layer - Selector for Sobject Opportunity
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/05/2020		1000				Initial version
* Simplus MS            18/12/2020      1001                CCRM-6890,6892 - COS_Token__c added
* Bunnings Dev 			07/10/2024		1003				New changes for sending Bell Notification for AU Standard Closed lost Opportunity
******************************************************************************************************/
public with sharing class DM_Opportunity {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param accountId 
    * @param ownerId 
    * @return Map<Id, Opportunity> 
    **/
    public static Map<Id, Opportunity> getOpenOpportunities(String accountId, String ownerId) {
        return new Map<Id, Opportunity>([
            SELECT Id
            FROM Opportunity
            WHERE AccountId = :accountId
            AND OwnerId = :ownerId
            AND IsClosed = FALSE 
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param ownerIds 
    * @return Map<Id, Opportunity> 
    **/
    public static Map<Id, Opportunity> getOpenOpportunities(Set<Id> accountIds, Set<Id> ownerIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, AccountId, OwnerId
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND OwnerId IN :ownerIds
            AND IsClosed = FALSE 
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 14/08/2020 
    * @param opptyIds 
    * @return Map<Id, Opportunity> 
    **/
    public static Map<Id, Opportunity> getOpportunitiesWithQuotes(List<Id> opptyIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, RecordTypeId, // CCRM-6890,6892 - Query RecordTypeId from Oppt
            (SELECT Id, Status, COS_Token__c FROM Quotes) // CCRM-6890,6892 - Added COS_Token__c to query from Quote
            FROM Opportunity
            WHERE Id IN :opptyIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param opptyId 
    * @return Opportunity 
    **/
    public static Opportunity getOpportunity(Id opptyId) {
        return [
            SELECT Id, Name
            FROM Opportunity
            WHERE Id = :opptyId
            LIMIT 1
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 17/08/2020 
    * @param opptyIds 
    * @return Map<Id, Opportunity> 
    **/
    public static Map<Id, Opportunity> getOpportunities(Set<String> opptyIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, Name
            FROM Opportunity
            WHERE Id IN :opptyIds
        ]);
    }
    /**
    * @description CRMS 203 - Get Oppportunities with Details
    * @author Bunnnigs Dev | 08/10/2024
    * @param opptyIds 
    * @return Map<Id, Opportunity> 
    **/
    public static Map<Id, Opportunity> getOpportunitiesDetails(Set<Id> opptyIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, Name,SyncedQuote.Name,Account.Name,LastModifiedBy.FirstName,LastModifiedBy.LastName,Record_Type_Name__c,StageName,Owner.Profile.Name,SyncedQuoteId,Owner.isActive,Ownerid,Follow_Up_Date__c,Price_Submission_Expiry__c,
            AccountId,Account.Owner.Id,CreatedById,Account.Owner.Is_TS__c,SyncedQuote.Status
            FROM Opportunity
            WHERE Id IN :opptyIds
        ]);
    }
}