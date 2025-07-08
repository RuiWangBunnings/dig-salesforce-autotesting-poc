/*******************************************************************************************************
* Class Name      	: AccountController
* Description		: Controller for components / pages referencing it
* Author          	: Simplus - Purba Ghosh
* Created On      	: 01/03/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Purba Ghosh           01/03/2020		1000				Initial version
******************************************************************************************************/
public with sharing class AccountController {  
    /**
    * @description  Get account record
    * @author Purba Ghosh | 01/03/2020 
    * @param accountId 
    * @return Account 
    **/
    @AuraEnabled
    public static Account getAccountDetails(String accountId) {         
        return DM_Account.getAccountDetails(accountId);
    }
    /**
    * @description 
    * @author Purba Ghosh | 01/03/2020 
    * @param accountId 
    * @param recordStatus 
    * @return List<Customer_Price_List__c> 
    **/
    @AuraEnabled
    public static List<Customer_Price_List__c> getCustomerPriceLists(String accountId, String recordStatus){
        return CustomerPriceListHelper.getCustomerPriceLists(accountId, recordStatus);
    }
    /**
    * @description 
    * @author Purba Ghosh | 01/03/2020 
    * @param accountId 
    * @param recordStatus 
    * @return List<Customer_Family_Tree_Discount__c> 
    **/
    @AuraEnabled
    public static List<Customer_Family_Tree_Discount__c> getPendingCustomerPriceFiles(String accountId, String recordStatus){
        return CustomerFamilyTreeDiscountsHelper.getPendingCustomerPriceFiles(accountId, recordStatus);
    }
}