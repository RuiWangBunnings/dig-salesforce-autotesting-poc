/*******************************************************************************************************
* Class Name      	: DM_SupplierQuote
* Description		: Data Layer - Selector for Sobject Supplier_Quote__c
* Author          	: Simplus - Philip Clark
* Created On      	: 13/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          13/07/2020		1000				Initial version
* Bunnings Dev          21/11/2024		2000				
* Bunnings Dev          2024-11-21      1011                CRMS204 - Update Supplier Quote for Closed Won
******************************************************************************************************/
public with sharing class DM_SupplierQuote {
    
    /**
    * @description  
    * @author       Philip Clark | 13/07/2020 
    * @param        Id
    * @return       list<Supplier_Quote__c> 
    **/
    public static list<Supplier_Quote__c> getSupplierQuotesbyOpportunity(Id oppId) {
        return new List<Supplier_Quote__c> ([
            SELECT Id, Name, Category__c, Opportunity__c, Supplier__c, Supplier__r.Name, Status__c   
			FROM Supplier_Quote__c 
            WHERE Opportunity__c =: oppId
        ]);
	}


       /**
    * @description  
    * @author       Bunnings Dev | 21/11/2024
    * @param        Set<Id>
    * @return       list<Supplier_Quote__c> 
    **/
    public static list<Supplier_Quote__c> getSupplierQuotesbyOpportunities(Set<Id> opptyId) {
        return new List<Supplier_Quote__c> ([
            SELECT Id, Name, Category__c, Opportunity__c, Supplier__c, Supplier__r.Name, Status__c   
			FROM Supplier_Quote__c 
            WHERE Opportunity__c IN : opptyId
        ]);
	}
}