/*******************************************************************************************************
* Class Name      	: SM_SupplierQuoteSelection
* Description		: Service layer supplierQuoteSelection LWC
* Author          	: Simplus - Philip Clark
* Created On      	: 10/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          10/07/2020		1000				Initial version
******************************************************************************************************/
public without sharing class SM_SupplierQuoteSelection {
    /**
    * @description 
    * @author Philip Clark | 10/07/2020 
    * @param region    
    * @return list<Account> 
    **/
    @AuraEnabled
    public static list<Account> getSuppliersByRegion(String region) {
        return DM_Account.getSupplierAccountsByRegion(region);
    }

    /**
    * @description 
    * @author Philip Clark | 13/07/2020 
    * @param oppId    
    * @return list<Supplier_Quote__c> 
    **/
    @AuraEnabled
    public static list<Supplier_Quote__c> getSupplierQuotesByOpportunity(String oppId) {
        return DM_SupplierQuote.getSupplierQuotesbyOpportunity(Id.valueOf(oppId));
    }

    /**
    * @description 
    * @author Philip Clark | 13/07/2020 
    * @param sqList
    **/
    @AuraEnabled
    public static void createSupplierQuotes(list<Supplier_Quote__c> sqList){
        insert sqList;
    }

    /**
    * @description 
    * @author Philip Clark | 13/07/2020 
    * @param sqList   
    **/
    @AuraEnabled
    public static void deleteSupplierQuotes(list<Id> sqIdList){
        Database.delete(sqIdList, true);
    }
}