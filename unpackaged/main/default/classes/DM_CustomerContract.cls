/*******************************************************************************************************
* Class Name      	: DM_CustomerContract
* Description		: Data Layer - Selector for Sobject Customer Contract
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-05-14
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-14		1000				Initial version
* Simplus MS            2021-01-04      1001                CCRM-170 - New method added to fetch non-expired contracts based on AcctIds,OwnerIds & where Contract Group is null
* Simplus MS            2021-02-04      1002                CCRM-170 - Account_Under_Approval__c field replace with Account_Transferrable__c
******************************************************************************************************/
public with sharing class DM_CustomerContract {

    /**
    * @description   
    * @author       Yi Zhang | 14/07/2020 
    * @param        accountId 
    * @return       List<Customer_Contract__c> 
    **/
    public static List<Customer_Contract__c> getCustomerContracts(String accountId) {
        return new List<Customer_Contract__c>([
            SELECT Id, Contract__c, Customer__c, 
            Contract__r.Id,
            Contract__r.Status__c,
            Contract__r.Original_Reviewer__c,
            Contract__r.OwnerId
            FROM Customer_Contract__c
            WHERE Customer__c = :accountId
        ]);
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 08-18-2020 
    * @param Set<String> contractIds 
    * @return List<Customer_Contract__c> 
    **/
    public static List<Customer_Contract__c> getCustomerContracts(Set<String> contractIds) {
        return new List<Customer_Contract__c>([
            SELECT Id, Contract__c, Customer__c, 
            Contract__r.Project__c
            FROM Customer_Contract__c
            WHERE Contract__c IN: contractIds
        ]);
        
    }

    /**
    * @description   
    * @author       Yi Zhang | 15/05/2020 
    * @param        accountId 
    * @return       List<Customer_Contract__c> 
    **/
    public static List<Customer_Contract__c> getNonExpiredCustomerContracts(String accountId) {
        List<Customer_Contract__c> ccs = [
            SELECT Id, Contract__c, Customer__c, 
            Contract__r.Id,
            Contract__r.OwnerId
            FROM Customer_Contract__c
            WHERE Customer__c = :accountId
            AND Contract__r.Status__c != 'Expired'
        ];
        return ccs;
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param ownerIds 
    * @return List<Customer_Contract__c> 
    **/
    public static List<Customer_Contract__c> getNonExpiredCustomerContracts(Set<Id> accountIds, Set<Id> ownerIds) {
        return new List<Customer_Contract__c>([
            SELECT Id, Contract__c, Customer__c, 
            Contract__r.Id,
            Contract__r.OwnerId
            FROM Customer_Contract__c
            WHERE Customer__c IN :accountIds
            AND Contract__r.OwnerId IN :ownerIds
            AND Contract__r.Status__c != 'Expired'
        ]);
    }

    /**
    * @description  Get list of customer contracts based on Set of Account Ids, OwnerId & where Contract Group is null
    * @author       Simplus MS | 04/01/2021 
    * @param        AccountIds, OwnerIds
    * @return       List<Customer_Contract__c> 
    **/
    public static List<Customer_Contract__c> getNonExpiredCustContracts(Set<Id> accountIds, Set<Id> ownerIds) {
        return new List<Customer_Contract__c>([
            SELECT Id, Contract__c, Customer__c, 
            Contract__r.Id,
            Contract__r.Status__c,
            Contract__r.Original_Reviewer__c,
            Contract__r.OwnerId,
            Customer__r.Contract_Group__c,
            Customer__r.Account_Transferrable__c
            FROM Customer_Contract__c
            WHERE Customer__c IN :accountIds
            AND Contract__r.Status__c != 'Expired'
            AND Contract__r.OwnerId IN :ownerIds
            AND Customer__r.Contract_Group__c = null
        ]);
    }
}