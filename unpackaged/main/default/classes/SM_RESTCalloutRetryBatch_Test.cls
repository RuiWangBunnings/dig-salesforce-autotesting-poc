/*******************************************************************************************************
* Class Name      	: SM_RESTCalloutRetryBatch_Test
* Description		: Test class for SM_RESTCalloutRetryBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 17/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              17/08/2020		1000				Initial version
* Simplus MS            18/12/2020      1001                New code to cover CCRM-6890,6892 changes
* Simplus MS            22/12/2020      1002                CCRM-297 code coverage addition
* Simplus MS           14/05/2021		2000				modifications CCRM-13728
******************************************************************************************************/
@isTest
private class SM_RESTCalloutRetryBatch_Test {

    @testSetup static void setup() {

        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        List<Opportunity> oppties = TestDataFactory.createOpenOpportunities(accounts[0].Id, UserInfo.getUserId(), 1);
        insert oppties;
		List<Quote> quotes = TestDataFactory.createQuotes(oppties[0].Id,'Enquiry',1);
        insert quotes;
    }


    @isTest
    private static void testRESTCalloutRetryBatch_ClosedLost() {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_Opportunity.sendClosedLostOpptyToCOS',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(new Map<String, String>{'opptyId'=>[SELECT Id FROM Opportunity LIMIT 1].Id, 'previousStageName'=>'Qualifying', 'userId'=>UserInfo.getUserId(),
                	'lossComments'=>'Error','lossReason'=>'Customer Cancelled','orderToken'=>'6345656','username'=>'335205'})
        );
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Success"}', 200, false));

        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();

        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }
    
    @isTest
    private static void testRESTCalloutRetryBatch_ClosedLost_RetryCntZero() {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_Opportunity.sendClosedLostOpptyToCOS',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(new Map<String, String>{'opptyId'=>[SELECT Id FROM Opportunity LIMIT 1].Id, 'previousStageName'=>'Qualifying', 'userId'=>UserInfo.getUserId(),
                	'lossComments'=>'Error','lossReason'=>'Customer Cancelled','orderToken'=>'6345656','username'=>'335205'})
        );
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{calloutSuccess=false, opportunityToRevertStage=Opportunity:{Id=0061m000003VFmrAAG, StageName=Qualifying}}', 400, false));
        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();
		
        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }
   
    
    @isTest
    private static void testRESTCalloutRetryBatch_ClosedWon() {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_Opportunity.sendClosedWonOpptyToCOS',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(new Map<String, String>{'opptyId'=>[SELECT Id FROM Opportunity LIMIT 1].Id, 'previousStageName'=>'Qualifying',
                					'username'=>[SELECT Owner.Team_Member_ID__c FROM Opportunity LIMIT 1].Owner.Team_Member_ID__c,
                					'orderToken'=>'B58B6D636C40328AE053051B17AC519B','userId'=>UserInfo.getUserId()})
        );
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"returnCode":"Success"}', 200, false));

        // schedulable (not immediate)
        Id jobId = System.schedule('Callout Retry Batch Test', '0 0 * * * ?', new SM_RESTCalloutRetryBatch());
        
        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();

        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }
    
    @isTest
    private static void testRESTCalloutRetryBatch_ClosedWon_RetryCntZero() {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_Opportunity.sendClosedWonOpptyToCOS',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(new Map<String, String>{'opptyId'=>[SELECT Id FROM Opportunity LIMIT 1].Id, 'previousStageName'=>'Qualifying',
                					'username'=>[SELECT Owner.Team_Member_ID__c FROM Opportunity LIMIT 1].Owner.Team_Member_ID__c,
                					'orderToken'=>'B58B6D636C40328AE053051B17AC519B','userId'=>UserInfo.getUserId()})
        );
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{calloutSuccess=false, opportunityToRevertStage=Opportunity:{Id=0061m000003VFmrAAG, StageName=Qualifying}}', 400, false));

        // schedulable (not immediate)
        Id jobId = System.schedule('Callout Retry Batch Test', '0 0 * * * ?', new SM_RESTCalloutRetryBatch());
        
        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();

        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }
    
    @isTest
    private static void testRESTCalloutRetryBatch_CPLAssignment() {
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        maptoSerialize.put([SELECT Price_List__c from Customer_Price_List__c LIMIT 1].Price_List__c, new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 'TMNumber' => '67674',
                                                                            'CountryCode' => 'AU'});
        
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(maptoSerialize));
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{calloutSuccess=false, opportunityToRevertStage=Opportunity:{Id=0061m000003VFmrAAG, StageName=Qualifying}}', 400, false));

        // schedulable (not immediate)
        Id jobId = System.schedule('Callout Retry Batch Test', '0 0 * * * ?', new SM_RESTCalloutRetryBatch());
        
        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();

        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }
    
    @isTest
    private static void testRESTCalloutRetryBatch_CPLDeletion() {
        
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        Customer_Price_List__c cpl = new Customer_Price_List__c(Price_List__c = pb.Id, Account__c = [SELECT Id from Account LIMIT 1].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl;
        
        Map<String,String> params = new Map<String, String>{'CustomerId' => '3467367', 'PriceListId' => [SELECT Customer_Price_List_ID__c from Customer_Price_List__c LIMIT 1].Customer_Price_List_ID__c,
                                                                            'AccountId' => [SELECT Account__c from Customer_Price_List__c LIMIT 1].Account__c, 
                                                                            'CountryCode' => 'AU'};
        
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c           = 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion',
            Type__c             = 'Outbound message',
            Retry_Count__c      = 1,
            Retry_Params__c     = JSON.serialize(new Map<Id, Map<String, String>>{cpl.id=> params}));
        insert log;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{calloutSuccess=false, opportunityToRevertStage=Opportunity:{Id=0061m000003VFmrAAG, StageName=Qualifying}}', 400, false));

        // schedulable (not immediate)
        Id jobId = System.schedule('Callout Retry Batch Test', '0 0 * * * ?', new SM_RESTCalloutRetryBatch());
        
        // batchable
        Database.executebatch(new SM_RESTCalloutRetryBatch(), 50);

        Test.stopTest();

        ApplicationLog__c updatedLog = [SELECT Id, Retry_Count__c FROM ApplicationLog__c LIMIT 1];
        System.assert(updatedLog.Retry_Count__c == null || updatedLog.Retry_Count__c < log.Retry_Count__c, 'Batch not run');

    }

    @isTest
    private static void test_schedule(){
        Test.startTest();
        SM_RESTCalloutRetryBatch.schedule(); 
        Test.stopTest(); 
    }
}