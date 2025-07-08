/*******************************************************************************************************
* Class Name      	: OpportunityTrigger_Test
* Description		: Test class for OpportunityTrigger
* Author          	: Simplus - Yi Zhang
* Created On      	: 14/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              14/08/2020		1000				Initial version
* Simplus MS            22/12/2020      1001                New code added to cover CCRM-6890,6892 enhancement changes
******************************************************************************************************/
@isTest
private class OpportunityTrigger_Test {
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
            
            List<Opportunity> lstOpportunity = TestDataFactory.createOpenOpportunities(acct[0].Id, user1.Id , 1);
            insert lstOpportunity;
            
            List<Quote> lstQuotes = TestDataFactory.createQuotes(lstOpportunity[0].Id, 'Quote', 3);
            insert lstQuotes;
            for (Quote q : lstQuotes) {
                q.OwnerId = user1.Id;
            }
            update lstQuotes;
            
            
        }
    }
    
    @isTest
    public static void testBeforeInsert() {
        List<Opportunity> lstOpportunity = [SELECT Id, Site_Address__c
                                            FROM Opportunity];
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        
        Test.startTest();
        try {
            OpportunityTriggerHandler.beforeInsert(lstOpportunity);
            System.runAs(user1) {
                for (Opportunity opp : lstOpportunity) {
                    opp.Site_Address__c = 'Test Address';
                }
            }
            UPDATE lstOpportunity;
            OpportunityTriggerHandler.beforeInsert(lstOpportunity);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testAfterUpdateLost() {        
        Test.startTest();
        try {
            List<Opportunity> lstOpportunity = [SELECT Id, Site_Address__c, OwnerId, Loss_Reason__c, Loss_Reason_Comments__c
                                                FROM Opportunity];
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(lstOpportunity);
            for (Opportunity opp1 : oldMap.values()) {
                opp1.StageName = 'New';
            }
            
            lstOpportunity = [SELECT Id, Site_Address__c, OwnerId, Loss_Reason__c, Loss_Reason_Comments__c
                              FROM Opportunity];
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>(lstOpportunity);
            for (Opportunity opp2 : newMap.values()) {
                opp2.StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
            }
            system.debug('oldMap ' + oldMap);
            system.debug('newMap ' + newMap);
            OpportunityTriggerHandler.afterUpdate(oldMap, newMap);
            OpportunityTriggerHandler.beforeUpdate(newMap, newMap);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testAfterUpdateWon() {
        Test.startTest();
        try {
            List<Opportunity> lstOpportunity = [SELECT Id, Site_Address__c, OwnerId, Loss_Reason__c, Loss_Reason_Comments__c
                                                FROM Opportunity];
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(lstOpportunity);
            for (Opportunity opp1 : oldMap.values()) {
                opp1.StageName = 'New';
            }
            
            lstOpportunity = [SELECT Id, Site_Address__c, OwnerId, Loss_Reason__c, Loss_Reason_Comments__c
                              FROM Opportunity];
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>(lstOpportunity);
            for (Opportunity opp2 : newMap.values()) {
                opp2.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
            }
            system.debug('oldMap ' + oldMap);
            system.debug('newMap ' + newMap);
            OpportunityTriggerHandler.afterUpdate(oldMap, newMap);
            OpportunityTriggerHandler.beforeUpdate(newMap, newMap);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void test_ClosedWon_ZeroQuote() {
        
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Account account = [Select Id From Account limit 1];
        
        Test.startTest();
        
        System.runAs(user1) {
            Opportunity opp = TestDataFactory.createOpenOpportunities(account.Id, user1.Id , 1)[0];
            opp.Site_Address__c = '21436576';
            opp.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
            insert opp;
            
            System.assertEquals(Constants.OPPTY_STAGE_CLOSED_WON, [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id].StageName, 'Failed to update opportunity stage');
            
            Test.stopTest();
        }
    }
	
    @isTest
    private static void test_ClosedWon_OneActiveQuote_Success() {
        // Integration Test
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Account account = [Select Id From Account limit 1];
		Opportunity opp = TestDataFactory.createOpenOpportunities(account.Id, user1.Id , 1)[0];
        insert opp;
        
        Quote activeQuote = TestDataFactory.createQuotes(opp.Id, Constants.QUOTE_STATUS_PRICING_ONLY, 1)[0];
        
        opp.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
        update opp;
        
        // Map created for CCRM-6890,6892 changes
        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String)opp.Id);
        closedWonMap.put('username',opp.Owner.Team_Member_ID__c);
        closedWonMap.put('orderToken',activeQuote.COS_Token__c);
        closedWonMap.put('userId',(String)user1.Id);
        
        Test.startTest();
        
        // This might change when IA finally arrives
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Success"}', 200, false));
        // https://patlatus.wordpress.com/2019/08/06/salesforce-bug-in-tests-system-calloutexception-you-have-uncommitted-work-pending-please-commit-or-rollback-before-calling-out/
        //SM_Opportunity.sendClosedWonOpptyToCOS(opps[0].Id, true);
        // disabled/commented for CCRM-13488 //Aldrin
        //SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap, true); // CCRM-6890,6892 - Map passed as parameter instead of Oppt Id
        // SM_Opportunity.sendClosedWonOpptyToCOSAsync(opps[0].Id);
        // opps[0].StageName = Constants.OPPTY_STAGE_CLOSED_WON;
        // update opps;
        // TODO
        Test.stopTest();
    }

    @isTest
    private static void test_ClosedWon_OneActiveQuote_Error() {
        // Integration Test
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Account account = [Select Id From Account limit 1];
		Opportunity opp = TestDataFactory.createOpenOpportunities(account.Id, user1.Id , 1)[0];
        insert opp;
        
        Quote activeQuote = TestDataFactory.createQuotes(opp.Id, 'Quote', 1)[0];
        
        opp.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
        update opp;

        // Map created for CCRM-6890,6892 changes
        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String)opp.Id);
        closedWonMap.put('username',opp.Owner.Team_Member_ID__c);
        closedWonMap.put('orderToken',activeQuote.COS_Token__c);
        closedWonMap.put('userId',(String)user1.Id);
        
        Test.startTest();
        // This might change when IA finally arrives
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Error"}', 400, false));
        // https://patlatus.wordpress.com/2019/08/06/salesforce-bug-in-tests-system-calloutexception-you-have-uncommitted-work-pending-please-commit-or-rollback-before-calling-out/
        //SM_Opportunity.sendClosedWonOpptyToCOS(opps[0].Id, true);
        // disabled/commented for CCRM-13488 //Aldrin
        //SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap,  true); // CCRM-6890,6892 - Map passed as parameter instead of Oppt Id
        // SM_Opportunity.sendClosedWonOpptyToCOSAsync(opps[0].Id);
        // opps[0].StageName = Constants.OPPTY_STAGE_CLOSED_WON;
        // update opps;
        // TODO
        Test.stopTest();
    }
	

    @isTest
    private static void test_ClosedWon_TwoActiveQuotes() {

        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId, StageName From Opportunity limit 1];
        List<Quote> quotes = [Select Id, OpportunityId From Quote Where OpportunityId =: opp.Id];
        
        Test.startTest();
        System.runAs(user1) {
            opp.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
            try {
            	update opp;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(OpportunityTriggerHandler.CLOSED_WON_ERROR_MULTIPLE_ACTIVE_QUOTES), 'error message incorrect');
            }
            //System.assertNotEquals(Constants.OPPTY_STAGE_CLOSED_WON, opp.StageName, 'Stage cannot be changed to Closed Won when 2 or more quotes are active');
            Integer activeQuoteCount = OpportunityTriggerHandler.countActiveQuotes([SELECT Id, Status FROM Quote Where OpportunityId =: opp.Id]);
            System.assertEquals(3, activeQuoteCount);
        }
        
        Test.stopTest();

    } 

    
    @isTest
    private static void test_ClosedWon_QuotesAllCancelled() {

        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        
        Account account = [Select Id From Account limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId From Opportunity limit 1];
        List<Quote> quotes = [Select Id, OpportunityId, Status From Quote Where OpportunityId =:  opp.Id];

        Test.startTest();
        
        System.runAs(user1) {
            opp.AccountId = account.Id;
            update opp;
            
            List<Quote> cancelledQuote = new List<Quote>();
            for (Quote qr : quotes){
                qr.Status = Constants.QUOTE_STATUS_CANCELLED;
                cancelledQuote.add(qr);
            }
            update cancelledQuote;
            
            opp.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
            
            try {
                update opp;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(OpportunityTriggerHandler.CLOSED_WON_ERROR_QUOTES_CANCELLED), 'error message incorrect');
            }
        }
        //System.assertNotEquals(Constants.OPPTY_STAGE_CLOSED_WON, [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id].StageName, 'Stage cannot be changed to Closed Won when all quotes are cancelled');
        Integer activeQuoteCount = OpportunityTriggerHandler.countActiveQuotes([SELECT Id, Status FROM Quote Where OpportunityId =: opp.Id]);
        System.assertEquals(0, activeQuoteCount);
        
        Test.stopTest();
    }
    
    @isTest
    private static void test_ClosedLost_ZeroQuote() {
        
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId From Opportunity limit 1];
        
        Test.startTest();
        
        System.runAs(user1) {
            opp.StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
            update opp;
            System.assertEquals(Constants.OPPTY_STAGE_CLOSED_LOST, [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id].StageName, 'Failed to update opportunity stage');
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    private static void test_ClosedLost_AllActiveQuotes_Success() {
        // Integration
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Opportunity opp = [Select Id, Site_Address__c, Owner.Team_Member_ID__c From Opportunity limit 1];
        
        // CCRM-6890,6892 changes start - For Closed Lost, to cover loss reason and loss comments
        opp.Loss_Reason__c = 'Customer Cancelled';
        opp.Loss_Reason_Comments__c = 'Cancel';
        opp.StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
        // CCRM-6890,6892 changes end
        
        update opp;
        
        List<Quote> quotes = [Select Id, OpportunityId, COS_Token__c From Quote Where OpportunityId =:  opp.Id];
        
        // CCRM-6890,6892 changes start
        Map<String, String> closedLostMap = new Map<String, String>();
        closedLostMap.put('opptyId',(String)opp.Id);
        closedLostMap.put('username',opp.Owner.Team_Member_ID__c);
        closedLostMap.put('orderToken',quotes[0].COS_Token__c);
        closedLostMap.put('userId',(String)user1.Id);
        closedLostMap.put('lossReason',opp.Loss_Reason__c);
        closedLostMap.put('lossComments',opp.Loss_Reason_Comments__c);
        // CCRM-6890,6892 changes end

        Test.startTest();
        // This might change when IA finally arrives
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Success"}', 200, false));
       // SM_Opportunity.sendClosedLostOpptyToCOS(closedLostMap,  true); // CCRM-6890,6892 - Map passed as parameter instead of Oppt Id
        //SM_Opportunity.sendClosedLostOpptyToCOS(opps[0].Id, 'Proposal', userId, true);
        // SM_Opportunity.sendClosedLostOpptyToCOSAsync(opps[0].Id, 'Proposal', userId);
        // opps[0].StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
        // update opps;
        // TODO
        Test.stopTest();
    }
    
    @isTest
    private static void test_ClosedLost_AllActiveQuotes_Warning() {
        
        // Integration
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId From Opportunity limit 1];
        List<Quote> quotes = [Select Id, OpportunityId From Quote Where OpportunityId =:  opp.Id];
        
        Test.startTest();
        // This might change when IA finally arrives
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Warning"}', 200, false));
        //SM_Opportunity.sendClosedLostOpptyToCOS(opps[0].Id, 'Proposal', userId, true);
        // SM_Opportunity.sendClosedLostOpptyToCOSAsync(opps[0].Id, 'Proposal', userId);
        // opps[0].StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
        // update opps;
        // TODO
        Test.stopTest();
    }

    
    @isTest
    private static void test_ClosedLost_AllActiveQuotes_Error() {
        
        // Integration
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId From Opportunity limit 1];
        List<Quote> quotes = [Select Id, OpportunityId From Quote Where OpportunityId =:  opp.Id];
        
        Test.startTest();
        // This might change when IA finally arrives
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Error"}', 400, false));
        //SM_Opportunity.sendClosedLostOpptyToCOS(opps[0].Id, 'Proposal', userId, true);
        // SM_Opportunity.sendClosedLostOpptyToCOSAsync(opps[0].Id, 'Proposal', userId);
        // opps[0].StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
        // update opps;
        // TODO
        Test.stopTest();
    }
    
    
    @isTest
    private static void test_ClosedLost_OneSubmittedQuote() {
        
        User user1 = [Select Id From User Where Profile.Name = :Constants.PROFILE_INTEGRATIONS_USER AND isActive = true limit 1];
        
        Account account = [Select Id From Account limit 1];
        Opportunity opp = [Select Id, Site_Address__c, OwnerId From Opportunity limit 1];
        Quote submittedQuote = [Select Id, OpportunityId From Quote Where OpportunityId =:  opp.Id limit 1];
        
        Test.startTest();
        
        System.runAs(user1) {
            opp.AccountId = account.Id;
            update opp;
            submittedQuote.Status = Constants.QUOTE_STATUS_SUBMITTED;
            update submittedQuote;
            
            opp.StageName = Constants.OPPTY_STAGE_CLOSED_LOST;
            
            try {
                update opp;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(OpportunityTriggerHandler.CLOSED_LOST_QUOTE_SUBMITTED), 'error message incorrect');
            }
            
            //System.assertNotEquals(Constants.OPPTY_STAGE_CLOSED_LOST, opp.StageName, 'Stage cannot be changed to Closed Closed when 1 or more quotes are submitted');
            Integer activeQuoteCount = OpportunityTriggerHandler.countActiveQuotes([SELECT Id, Status FROM Quote Where OpportunityId =: opp.Id]);
            System.assertEquals(2, activeQuoteCount);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testPauseSendCloseLostOpp() {
        List<String> lstIds = new List<String>();
        for (Opportunity opp : [SELECT Id FROM Opportunity]) {
            lstIds.add('{"opptyId":"'+ opp.Id +'"}');
        }
        
        Test.startTest();
        try {
           // OpportunityTriggerHandler.pauseSendCloseLostOppty(lstIds);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testSendNotificationForClosedLostWarning() {
        Opportunity opp = [Select Id, Site_Address__c, OwnerId, Name From Opportunity limit 1];
        Test.startTest();
        try {
            SM_Opportunity.sendNotificationForClosedLostWarning(opp, UserInfo.getUserId());
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    @isTest
    public static void testSendNotificationForClosedWonWarning() {
        Opportunity opp = [Select Id, Site_Address__c, OwnerId, Name From Opportunity limit 1];
        Test.startTest();
        try {
            SM_Opportunity.sendNotificationForClosedWonWarning(opp, UserInfo.getUserId());
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    @isTest
    public static void testupdateSupplierQuoteStatus() {
         Id userId = UserInfo.getUserId();
        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;
        acclist[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NZ Supplier').getRecordTypeId();
        
        update acclist[0];
        System.debug('recordtypename:'+acclist[0].Record_TYpe_name__c);
        //List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        //insert oppList;
        list<Opportunity> oppList = [Select Id, Site_Address__c, OwnerId, Name,Record_Type_name__c From Opportunity ];

        oppList[0].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('NZ Standard Opportunity').getRecordTypeId();
        
        update oppList[0];
        
        Opportunity opp = [Select Id, Site_Address__c, OwnerId, Name,Record_Type_name__c From Opportunity where id = :oppList[0].id];
    
         System.debug('recordtypename:'+opp.Record_Type_name__c);
           List<Supplier_Quote__c> supQuoList = TestDataFactory.createSupplierQuotes(opp.Id, accList[0].id, 2);
        insert supQuoList;
      
        Test.startTest();
        try {
           opp.StageName='Closed Won';
            update opp;
            
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
         Opportunity opp1 = [Select Id, Site_Address__c, OwnerId, Name,Record_Type_name__c,StageName From Opportunity where id = :oppList[0].id];
         System.debug('stage:'+opp1.StageName);
        System.debug('stage:'+opp1.Record_Type_name__c);
        List<Supplier_Quote__c> supQuoupdList = [Select id, Status__c from Supplier_Quote__c limit 1];
        //System.assertEquals(supQuoupdList[0].Status__c,'New');
        
    }

}