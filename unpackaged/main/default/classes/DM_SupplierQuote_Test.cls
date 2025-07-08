/*******************************************************************************************************
* Class Name      	: DM_SupplierQuote_Test
* Description		: Data Layer - test calss for  DM_SupplierQuote
* Author          	: Bunnings Dev  
* Created On      	: 2024-11-21
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          2024-11-21		1000				Initial version
* Bunnings Dev          21/11/2024		2000				
******************************************************************************************************/
@isTest
public class DM_SupplierQuote_Test {
 @testSetup 
    static void testDataSetup() {
        List<Account> accList = TestDataFactory.createAccounts(1);
        accList[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Supplier');
        accList[0].Supplier_Region__c = 'Area 4';
        accList[0].Country__c='New Zealand';
        insert accList;
        list<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, UserInfo.getUserId(), 1);
        oppList[0].RecordTypeId = CSUtils.getRecordTypeId('Opportunity', 'NZ Standard Opportunity');
        insert oppList;
         List<Supplier_Quote__c> supQuoList = TestDataFactory.createSupplierQuotes(oppList[0].Id, accList[0].id, 2);
        insert supQuoList;
    }
    
    
    static testmethod void testgetSupplierQuotesbyOpportunity() {
        Opportunity opp = [Select id,name from Opportunity limit 1];
        
        Test.startTest();
        DM_SupplierQuote.getSupplierQuotesbyOpportunity(opp.id);
        Test.stopTest();
    }
    
    static testmethod void testgetSupplierQuotesbyOpportunities() {
        List<Opportunity> oppList = [Select id,name from Opportunity];
        Set<id> oppset = new Set<id>();
        for(Opportunity op : oppList){
            oppset.add(op.id);
        }
        Test.startTest();
        DM_SupplierQuote.getSupplierQuotesbyOpportunities(oppset);
        Test.stopTest();
    }
}