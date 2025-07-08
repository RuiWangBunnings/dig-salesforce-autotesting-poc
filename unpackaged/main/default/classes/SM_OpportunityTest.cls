/*******************************************************************************************************
* Class Name      	: SM_OpportunityTest
* Description		: Domain / Service layer for Opportunity
* Author          	: Bunnigs Dev
* Created On      	: 17/10/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnigs Dev              17/10/2024		1000				Initial version
******************************************************************************************************/

@isTest
private class SM_OpportunityTest {
    
     /**
    * @description - test data setup
    * @author Bunnigs Dev  
    **/
    @testSetup 
    public static void testDataSetup() {
        Id userId = UserInfo.getUserId();
        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;
        
        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
            
    }
    
    
      /**
    * @description - test_sendClosedWonOpptyToCOS_Success
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedWonOpptyToCOS_Success(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"1","statusDescription":"Order value is zero"}', 200, false));

        // disabled/commented for CCRM-13488 //Aldrin
        //SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap, true);

        Test.stopTest();
    }

    
     /**
    * @description - test_sendClosedWonOpptyToCOS_Failure
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedWonOpptyToCOS_Failure(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"errors":[{"code":"orderToken0","path":"orderToken","error":"Invalid Order Token 6345656"}', 400, false));
		// disabled/commented for CCRM-13488 //Aldrin
        //SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap, true);

        Test.stopTest();
    }

    
    /**
    * @description - test_sendClosedLostOpptyToCOS_Success
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedLostOpptyToCOS_Success(){
        Id userId = UserInfo.getUserId();
		User u =[select id,name from user where id = :userid limit 1];
        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
		quotes[0].COS_ID__c = '78898';
        update quotes;
        Map<String, String> closedLostMap = new Map<String, String>();
     closedLostMap.put('opptyId',(String) oppList[0].Id);
        closedLostMap.put('previousStageName','New');
        closedLostMap.put('orderToken',quotes[0].COS_ID__c);
        closedLostMap.put('lossReason','Customer Cancelled');
        closedLostMap.put('cancelComments','Error');
        closedLostMap.put('lossComments','Error');
        closedLostMap.put('username',u.Name);

	
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"statusCode":"0","statusDescription":"Enquiry cancelled successfully"}', 200, false));

        SM_Opportunity.sendClosedLostOpptyToCOS(closedLostMap, true);

        Test.stopTest();
    }

    /**
    * @description - test_sendClosedLostOpptyToCOS_Failure
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedLostOpptyToCOS_Failure(){
        Id userId = UserInfo.getUserId();
		User u =[select id,name from user where id = :userid limit 1];
        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
		quotes[0].COS_ID__c = '78898';
        update quotes;
        Map<String, String> closedLostMap = new Map<String, String>();
        closedLostMap.put('opptyId',(String) oppList[0].Id);
        closedLostMap.put('previousStageName','New');
        closedLostMap.put('orderToken',quotes[0].COS_ID__c);
        closedLostMap.put('lossReason','Customer Cancelled');
        closedLostMap.put('cancelComments','Error');
        closedLostMap.put('lossComments','Error');
        closedLostMap.put('username',u.Name);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"errors":[{"code":"orderToken0","path":"orderToken","error":"Invalid Order Token 6345656"}', 400, false));

        SM_Opportunity.sendClosedLostOpptyToCOS(closedLostMap, true);

        Test.stopTest();
    }

     /**
    * @description - test_sendClosedLostOpptyToCOS_Exception
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedLostOpptyToCOS_Exception(){
        Id userId = UserInfo.getUserId();
		User u =[select id,name from user where id = :userid limit 1];
        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
		quotes[0].COS_ID__c = '78898';
        update quotes;
        Map<String, String> closedLostMap = new Map<String, String>();
        closedLostMap.put('opptyId',(String) oppList[0].Id);
        closedLostMap.put('previousStageName','New');
        closedLostMap.put('orderToken',quotes[0].COS_ID__c);
        closedLostMap.put('lossReason','Customer Cancelled');
        closedLostMap.put('cancelComments','Error');
        closedLostMap.put('lossComments','Error');
        closedLostMap.put('username',u.Name);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"errors":[{"code":"orderToken0","path":"orderToken","error":"Invalid Order Token 6345656"}', 400, true));

        SM_Opportunity.sendClosedLostOpptyToCOS(closedLostMap, true);

        Test.stopTest();
    }
   /**
    * @description - test_sendClosedWonOpptyToCOS_Exception
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendClosedWonOpptyToCOS_Exception(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"errors":[{"code":"orderToken0","path":"orderToken","error":"Invalid Order Token 6345656"}', 400, true));
		// disabled/commented for CCRM-13488 //Aldrin
        //SM_Opportunity.sendClosedWonOpptyToCOS(closedWonMap, true);

        Test.stopTest();
    }
    
    /**
    * @description - test_sendNotificationForClosedLostWarning
    * @author Bunnigs Dev  
    **/
     @isTest
    private static void test_sendNotificationForClosedLostWarning(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        
        SM_Opportunity.sendNotificationForClosedLostWarning(oppList[0], userId);

        Test.stopTest();
    }
    
    /**
    * @description - test_sendNotificationForClosedWonWarning
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendNotificationForClosedWonWarning(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;

        List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        
        SM_Opportunity.sendNotificationForClosedWonWarning(oppList[0], userId);

        Test.stopTest();
    }
    
     /**
    * @description - test_sendAUStndClosedLostBellNotification
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendAUStndClosedLostBellNotification(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;
        
         List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
        
        oppList[0].Name='77777777778';
         oppList[0].SyncedQuoteId=quotes[0].id;
        oppList[0].AccountId=accList[0].id;
       // oppList[0].SyncedQuote.Name='67868';
       // oppList[0].Account.Name='67868';
		//oppList[0].LastModifiedBy.FirstName='Test';
       // oppList[0].LastModifiedBy.LastName='Test';
        update oppList[0];
       

        Map<String, String> closedWonMap = new Map<String, String>();
        closedWonMap.put('opptyId',(String) oppList[0].Id);
        closedWonMap.put('orderToken',quotes[0].COS_ID__c);
        closedWonMap.put('userId',userId);

        Test.startTest();
        try{
           SM_Opportunity.sendAUStndClosedLostBellNotification(oppList[0]); 
        }catch(Exception e){
            System.debug('true');
        }
        

        Test.stopTest();
    }
    /**
    * @description - test_updateSupplierQuotes
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_updateSupplierQuotes(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;
	acclist[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NZ Supplier').getRecordTypeId();
        update acclist[0];
        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;
        List<Supplier_Quote__c> supQuoList = TestDataFactory.createSupplierQuotes(oppList[0].Id, accList[0].id, 2);
        insert supQuoList;
      
        
        oppList[0].Name='77777777778';

        oppList[0].AccountId=accList[0].id;
      
        update oppList[0];
       Map<id,Opportunity> opptyMap = new Map<id,Opportunity>();
		opptyMap.put(oppList[0].id,oppList[0]);

        Test.startTest();
        try{
           SM_Opportunity.updateSupplierQuoteStatus(opptyMap,'Accepted'); 
        }catch(Exception e){
            System.debug('true');
        }
        

        Test.stopTest();
    }
    /**
    * @description - test_updateSupplierQuotesLost
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_updateSupplierQuotesLost(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;
	acclist[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NZ Supplier').getRecordTypeId();
        update acclist[0];
        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;
        List<Supplier_Quote__c> supQuoList = TestDataFactory.createSupplierQuotes(oppList[0].Id, accList[0].id, 2);
        insert supQuoList;
      
        
        oppList[0].Name='77777777778';

        oppList[0].AccountId=accList[0].id;
      
        update oppList[0];
       Map<id,Opportunity> opptyMap = new Map<id,Opportunity>();
		opptyMap.put(oppList[0].id,oppList[0]);

        Test.startTest();
        try{
           SM_Opportunity.updateSupplierQuoteStatus(opptyMap,'Lost'); 
        }catch(Exception e){
            System.debug('true');
        }
        

        Test.stopTest();
    }
     /**
    * @description - test_sendNZProposalReadyBellNotificationOpp
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_sendNZProposalReadyBellNotificationOpp(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;
        
         List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
        
        oppList[0].Name='77777777778';
         oppList[0].SyncedQuoteId=quotes[0].id;
        oppList[0].AccountId=accList[0].id;
       // oppList[0].SyncedQuote.Name='67868';
       // oppList[0].Account.Name='67868';
		//oppList[0].LastModifiedBy.FirstName='Test';
       // oppList[0].LastModifiedBy.LastName='Test';
        update oppList[0];
       

        Test.startTest();
        try{
           SM_Opportunity.sendNZProposalReadyBellNotificationOpp(userId,'Test Oppty','Test Account'); 
        }catch(Exception e){
            System.debug('true');
        }
        

        Test.stopTest();
    }
    
     /**
    * @description - test_updateAUOpptyFollowUpDate
    * @author Bunnigs Dev  
    **/
    @isTest
    private static void test_updateAUOpptyFollowUpDate(){
        Id userId = UserInfo.getUserId();

        List<Account> accList = TestDataFactory.createAccounts(1);
        insert accList;

        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accList[0].Id, userId, 1);
        insert oppList;
        
         List<Quote> quotes = TestDataFactory.createQuotes(oppList[0].Id, Constants.QUOTE_STATUS_ENQUIRY, 1);
        insert quotes;
        
        oppList[0].Name='77777777778';
         oppList[0].SyncedQuoteId=quotes[0].id;
        oppList[0].AccountId=accList[0].id;
       // oppList[0].SyncedQuote.Name='67868';
       // oppList[0].Account.Name='67868';
		//oppList[0].LastModifiedBy.FirstName='Test';
       // oppList[0].LastModifiedBy.LastName='Test';
        update oppList[0];
       

  

        Test.startTest();
        try{
           SM_Opportunity.updateAUOpptyFollowUpDate(oppList[0]); 
        }catch(Exception e){
            System.debug('true');
        }
        

        Test.stopTest();
    }
}