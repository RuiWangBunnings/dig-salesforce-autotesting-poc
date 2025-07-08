/*******************************************************************************************************
* Class Name      	: TEMP_SM_OrderBatch_Test
* Description		: Test class for TEMP_SM_OrderBatch
* Author          	: Simplus MS
* Created On      	: 11/10/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS                11/10/2021		1000				Initial version
******************************************************************************************************/
@isTest
private with sharing class TEMP_SM_OrderBatch_Test {
    @TestSetup
    static void makeData(){
        //Create Account
        List<Account> accts = TestDataFactory.createAccounts(1);
        insert accts;

        //Create Oppty
        List<Opportunity> opps = TestDataFactory.createOpenOpportunities(accts[0].Id, UserInfo.getUserId(), 1);
        insert opps;

        //Create Quote
        List<Quote> qtes = TestDataFactory.createQuotes(opps[0].Id, 'Submitted', 1);
        insert qtes;

        //Create Store
        List<Store__c> stres = TestDataFactory.createStores(1);
        insert stres;

        //Create Orders
        List<Order> orders = new List<Order> {
            new Order(AccountId=accts[0].Id, COS_ID__c='1', QuoteId=qtes[0].Id, Assigned_Store__c=stres[0].Id, Status='Submitted', EffectiveDate=Date.today()),
            new Order(AccountId=accts[0].Id, COS_ID__c='2', QuoteId=qtes[0].Id, Assigned_Store__c=stres[0].Id, Status='Submitted', EffectiveDate=Date.today())
        };
        insert orders;

        //Create Staging Orders
        List<Staging_Object__c> stOrders = new List<Staging_Object__c>();

        //Staging orders with matching COS ID to test UPDATE operation
        for(Integer i=1;i<3;i++) {
            Staging_Object__c so = new Staging_Object__c();
            so.Object_Name__c = 'Order';
            so.Status__c = 'Open';
            so.AccountID__c = accts[0].Id;
            so.QuoteId__c = qtes[0].Id;
            so.Assigned_Store__c = stres[0].Id;
            so.COS_ID__c = String.valueOf(i);
            so.Effective_Date__c = Date.today();
            so.Order_Status__c = 'Submitted';
            so.Comments__c = 'Sample comment';
            so.Contact_Number__c = '8877669944';

            stOrders.add(so);
        }
        
        //Staging orders without matching COS ID to test INSERT operation                                
        for(Integer i=3;i<5;i++) {
            Staging_Object__c so = new Staging_Object__c();
            so.Object_Name__c = 'Order';
            so.Status__c = 'Open';
            so.AccountID__c = accts[0].Id;
            so.QuoteId__c = qtes[0].Id;
            so.Assigned_Store__c = stres[0].Id;
            so.COS_ID__c = String.valueOf(i);
            so.Effective_Date__c = Date.today();
            so.Order_Status__c = 'Submitted';
            so.Contact_Number__c = '9988776655';

            stOrders.add(so);
        }

        //Staging order with missing fields to test ERROR operation
        stOrders.add(new Staging_Object__c(Object_Name__c = 'Order',
                                           Status__c = 'Open',
                                           AccountID__c = accts[0].Id,
                                           COS_ID__c = '5'));
        
        //Staging order from failed to successful operation
        stOrders.add(new Staging_Object__c(Object_Name__c = 'Order',
                                           Status__c = 'With Error',
                                           AccountID__c = accts[0].Id,
                                           COS_ID__c = '6',
                                           Order_Status__c = 'Submitted',
                                           Effective_Date__c = Date.today(),
                    					   Error_Message__c = 'Sample Error Message',
                                           Log_Type__c = 'Exception',
                                           Source_Type__c = 'Batch',
                                           Log_Object_Name__c = 'Order'));
        
        insert stOrders;
    }
    @isTest static void testSyncOrders() {
        Test.startTest();
            Database.executeBatch(new TEMP_SM_OrderBatch());
        Test.stopTest();
        
        Set<String> completedCOSIds = new Set<String>();
        Set<String> withErrorCOSIds = new Set<String>();
        List<Staging_Object__c> scope = [SELECT COS_ID__c, Status__c FROM Staging_Object__c WHERE Object_Name__c = 'Order' AND COS_ID__c != null];
        
        for(Staging_Object__c so : scope) {
            if(so.Status__c == 'Completed') {
                completedCOSIds.add(so.COS_ID__c);
            } else {
                withErrorCOSIds.add(so.COS_ID__c);
            }
        }
  
        Integer ordersProcessed = [SELECT COS_ID__c FROM Order WHERE COS_ID__c IN :completedCOSIds].size();
        Integer ordersFailed = scope.size() - ordersProcessed;
        
        //Asserts number of processed staging records and actual number of order records
        System.assertEquals(completedCOSIds.size(), ordersProcessed, 'Order records processed does not match number of completed staging records');
        System.assertEquals(withErrorCOSIds.size(), ordersFailed, 'Failed Order records does not match number of staging records with error');
    }   
}