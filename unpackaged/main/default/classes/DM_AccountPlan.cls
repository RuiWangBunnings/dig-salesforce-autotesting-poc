/*******************************************************************************************************
* Class Name        : DM_AccountPlan
* Description       : Data Layer - Selector for Sobject Account Plan
* Author            : Bunnings Dev - Jasper R Galapon
* Created On        : 04/08/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R Galapon      04/08/2022      1000                SFSUP-898 - Initial version
******************************************************************************************************/

public with sharing class DM_AccountPlan {

    public static List<Account_Plan__c> getAccountPlans(Set<Id> accountIds, Set<Id> ownerIds, Id recTypeId) {
        return [
            SELECT Id, Status__c, Account__c, OwnerId 
            FROM Account_Plan__c 
            WHERE Account__c IN :accountIds
            AND OwnerId IN : ownerIds
            AND RecordTypeId = :recTypeId
        ];
    }
    
}