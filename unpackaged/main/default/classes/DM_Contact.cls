/*******************************************************************************************************
* Class Name        : DM_Contact
* Description       : Data Layer - Selector for Sobject Contact
* Author            : Simplus - Yi Zhang
* Created On        : 2020-05-15
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-15      1000                Initial version
* Jasper R. Galapon     2024-04-04      1001                BUNDIG-23006 - Inactive Contact Is Listed in Call Planner
******************************************************************************************************/
public with sharing class DM_Contact {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param accountId 
    * @param ownerId 
    * @return Map<Id, Contact> 
    **/
    public static Map<Id, Contact> getContacts(String accountId, String ownerId) {
        return new Map<Id, Contact>([
            SELECT Id
            FROM Contact
            WHERE AccountId = :accountId
            AND OwnerId = :ownerId
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param ownerIds 
    * @return Map<Id, Contact> 
    **/
    public static Map<Id, Contact> getContacts(Set<Id> accountIds, Set<Id> ownerIds) {
        return new Map<Id, Contact>([
            SELECT Id, AccountId, OwnerId
            FROM Contact
            WHERE AccountId IN :accountIds
            AND OwnerId IN :ownerIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 22/06/2020 
    * @param accountOwnerId 
    * @return Map<Id, Contact> 
    **/
    public static Map<Id, Contact> getContactsBasedOnAcctOwner(Id accountOwnerId) {
        return new Map<Id, Contact>([
            SELECT Id, AccountId, 
            Account.Id, 
            Account.Power_Pass_Account_Number__c,
            Account.Name,
            Account.R12_Sales__c, 
            Account.Last_3_Month_Sales__c, 
            Account.Share_of_Wallet__c, 
            Account.Reason_for_Share__c, 
            Tactic__c, //Modified for CCRM-8162 // Aldrin Rasdas 13.Nov.2020
            Name, Target_Call_Frequency__c, First_Day__c, Recurrence__c, Call_Days__c
            FROM Contact
            WHERE Account.OwnerId = :accountOwnerId
            AND Account.RecordType.DeveloperName IN ('AU_Customer', 'NZ_Customer', 'AU_Prospect', 'NZ_Prospect')
            AND Account.Account_Status__c IN ('Active', 'Referred')
            AND Status__c = 'Active' //BUNDIG-23006
            ORDER BY Account.Name ASC, Name ASC
        ]);
    }
}