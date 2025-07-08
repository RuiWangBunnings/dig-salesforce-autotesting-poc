/*******************************************************************************************************
* Class Name      	: SM_SupplierQuoteSelection_Test
* Description		: Test class for SM_SupplierQuoteSelection
* Author          	: Simplus - Philip Clark
* Created On      	: 15/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          15/07/2020		1000				Initial version
******************************************************************************************************/
@IsTest
private class SM_SupplierQuoteSelection_Test {
    
    /**
    *  Method name  :  testDataSetup
    *  Description  :  
    *  Author       :  Philip Clark
    **/
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
    }
    
    /**
    *  Method name  :  testGetSuppliersByRegion
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testGetSuppliersByRegion() {
        
        Test.startTest();
        
        list<Account> accList = SM_SupplierQuoteSelection.getSuppliersByRegion('Area 4');
        
        Test.stopTest();
        
        system.assertEquals(1,accList.size(),'incorrect number of suppliers returned');
    }
    
    /**
    *  Method name  :  testGetSupplierQuotesByOpportunity
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testGetSupplierQuotesByOpportunity() {
        
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        List<Supplier_Quote__c> sqList = TestDataFactory.createSupplierQuotes(oppId, accId, 1);
        insert sqList;


        Test.startTest();
        
        sqList = SM_SupplierQuoteSelection.getSupplierQuotesByOpportunity(oppId);
        
        Test.stopTest();
        
        system.assertEquals(1,sqList.size(),'incorrect number of supplier quotes returned');
    }
    
    /**
    *  Method name  :  testCreateSupplierQuotes
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testCreateSupplierQuotes() {
        
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        Test.startTest();
        
        List<Supplier_Quote__c> sqList = TestDataFactory.createSupplierQuotes(oppId, accId, 1);
        SM_SupplierQuoteSelection.createSupplierQuotes(sqList);
        
        Test.stopTest();
        
        sqList = SM_SupplierQuoteSelection.getSupplierQuotesByOpportunity(oppId);
        system.assertEquals(1,sqList.size(),'incorrect number of supplier quotes inserted');
    }
    
    /**
    *  Method name  :  testDeleteSupplierQuotes
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testDeleteSupplierQuotes() {
        
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        List<Supplier_Quote__c> sqList = TestDataFactory.createSupplierQuotes(oppId, accId, 1);
        insert sqList;

        Test.startTest();
        
        SM_SupplierQuoteSelection.deleteSupplierQuotes(new Id[] {sqList[0].Id});
        
        Test.stopTest();
        
        sqList = SM_SupplierQuoteSelection.getSupplierQuotesByOpportunity(oppId);
        system.assertEquals(0,sqList.size(),'supplier quote not deleted');
    }

}