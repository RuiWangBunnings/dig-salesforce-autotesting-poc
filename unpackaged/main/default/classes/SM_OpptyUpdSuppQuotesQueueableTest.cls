/*******************************************************************************************************
* Class Name        : SM_OpptyUpdSuppQuotesQueueableTest
* Description       : Test class of SM_OpptyUpdSuppQuotesQueueableTest
* Author            : Bunnings Dev
* Created On        : 28/11/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev         28/11/2024      1000                Initial version
******************************************************************************************************/
@isTest
public class SM_OpptyUpdSuppQuotesQueueableTest {
    
   @testSetup
    public static void dataSetup() {  
        
        Id userId = UserInfo.getUserId();
        
        // Use Integrations User to create opportunity & quote
        Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_INTEGRATIONS_USER LIMIT 1];
        Profile profileSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, p.Id);
        users[1].ProfileId = profileSM.Id;
        insert users;
        
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        System.runAs(user1) {
            
            List<Account> acct = TestDataFactory.createAccounts(1);
            insert acct;
             acct[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NZ Supplier').getRecordTypeId();
        
        update acct[0];
            List<Opportunity> lstOpportunity = TestDataFactory.createOpenOpportunities(acct[0].Id, user1.Id , 1);
            insert lstOpportunity;
            lstOpportunity[0].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('NZ Standard Opportunity').getRecordTypeId();
        
        update lstOpportunity[0];
            List<Quote> lstQuotes = TestDataFactory.createQuotes(lstOpportunity[0].Id, 'Quote', 3);
            insert lstQuotes;
            for (Quote q : lstQuotes) {
                q.OwnerId = user1.Id;
            }
            update lstQuotes;
            List<Supplier_Quote__c> supQuoList = TestDataFactory.createSupplierQuotes(lstOpportunity[0].Id, acct[0].id, 2);
        insert supQuoList;
            
        }
    }

    static testmethod void testQueueableAccepted() {
        // query for test data to pass to queueable class
        List<Supplier_Quote__c> suppQuoList = [select id, name,Status__c from Supplier_Quote__c];
        // Create our Queueable instance
        SM_OpptyUpdateSupplierQuotesQueueable suppQuoteQueueable = new SM_OpptyUpdateSupplierQuotesQueueable(suppQuoList,'Accepted');
        
        Test.startTest();
        System.enqueueJob(suppQuoteQueueable);
        Test.stopTest();
    }
    static testmethod void testQueueableLost() {
        // query for test data to pass to queueable class
        List<Supplier_Quote__c> suppQuoList = [select id, name,Status__c from Supplier_Quote__c];
        // Create our Queueable instance
        SM_OpptyUpdateSupplierQuotesQueueable suppQuoteQueueable = new SM_OpptyUpdateSupplierQuotesQueueable(suppQuoList,'Lost');
        
        Test.startTest();
        System.enqueueJob(suppQuoteQueueable);
        Test.stopTest();
    }
}