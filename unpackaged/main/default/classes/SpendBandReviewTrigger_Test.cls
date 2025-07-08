/*******************************************************************************************************
* Class Name      	: SpendBandReviewTrigger_Test
* Description		: Test class for SpendBandReviewTrigger
* Author          	: Simplus - Haider Raza
* Created On      	: 05/03/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           05/03/2020		1000				Initial version
* Yi Zhang              15/06/2020		2000			    update how Spend_Band_Review__c is created
* Bunnings Dev			25/07/2022		3000				New method to test Level 2 Approver
******************************************************************************************************/
@isTest
public with sharing class SpendBandReviewTrigger_Test {
    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  Method for setting up test data
    **/

    @testSetup static void dataSetup() {
        Account account = TestDataFactory.createAccounts(1)[0];
        account.RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        insert account;
    }

    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  method for testing SpendBandReview Trigger
    **/
    @isTest static void test_SpendBandReviewTrigger() {
        Account account = [SELECT Id FROM Account LIMIT 1];        
        
        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;
        sbs[0].Status__c = 'Approver 1';
        update sbs;

        Spend_Band_Review__c spendBandReview = TestDataFactory.createSpendBandReview(account.Id, sbs[0].Id, sbs[1].Id, 'Australia');

        Test.startTest();
        	insert spendBandReview;
        Test.stopTest();

        System.assert(spendBandReview != null);
    }
           
    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  method for testing SpendBandReview Approved Trigger
    **/
    @isTest static void test_SpendBandReviewApprovedTrigger() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;
        sbs[0].Status__c = 'Approver 2';
        update sbs;

        Spend_Band_Review__c spendBandReview = TestDataFactory.createSpendBandReview(account.Id, sbs[0].Id, sbs[1].Id, 'Australia');        
        insert spendBandReview;
        
        List<Id> newWorkItemIds = new List<Id>();
        for (List<ProcessInstance> pis : [SELECT (SELECT Id FROM Workitems) FROM ProcessInstance p WHERE p.TargetObjectId = :spendBandReview.Id AND p.Status = 'Pending']) {
            for (ProcessInstance pi : pis) {
                for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                    for (ProcessInstanceWorkitem wi : wis ) {
                        newWorkItemIds.add(wi.id);
                    }
                }
            }
        }

        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');

        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

        // Use the ID FROM the newly created item to specify the item to be worked
        req2.setWorkitemId(newWorkItemIds.get(0));

        Test.startTest();
        // Submit the request for approval
        Approval.ProcessResult result2 =  Approval.process(req2);
        // Verify the results
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        System.assertEquals('Approved', result2.getInstanceStatus(), 'Instance Status'+result2.getInstanceStatus());
                        
        Test.stopTest();
    }
    
    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  method for testing SpendBandReview Rejected Trigger
    **/
    @isTest static void test_SpendBandReviewRejectedTrigger() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;

        Spend_Band_Review__c spendBandReview = TestDataFactory.createSpendBandReview(account.Id, sbs[0].Id, sbs[1].Id, 'Australia');
        insert spendBandReview;

        Test.startTest();
            rejectRecords(spendBandReview);        	
        Test.stopTest();
    }
    
    /**
    * @author       Jasper Galapon
    * @date         25/07/2022
    * @description  method for testing SpendBandReview Rejected with Manager Approval
    **/    
    @isTest static void test_SpendBandReviewRejectedDecreaseTrigger() {        
                
        Id tsProfileId = [SELECT Id FROM Profile WHERE Name = 'Trade Specialist'].Id;
        Id smProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'].Id;
        
        List<User> tsUser = TestDataFactory.createUsers(1, tsProfileId);
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert tsUser;
        }           
        List<User> smUser = TestDataFactory.createUsers(1, smProfileId);
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	insert smUser;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
        	tsUser[0].ManagerId = smUser[0].Id;
            update tsUser;
        }           
        
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.OwnerId = tsUser[0].Id;
        update account;
        
        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{5000, 3000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;
                        
        Spend_Band_Review__c sbr = new Spend_Band_Review__c(Account__c = account.Id, Current_Spend_Band__c = sbs[0].Id, Proposed_Spend_Band__c = sbs[1].Id,
			Level_1_Approver__c = tsUser[0].Id, Level_2_Approver__c = smUser[0].Id);
        insert sbr;
        
        Test.startTest();
        	List<Id> newWorkItemIds = new List<Id>();
        	for (List<ProcessInstance> pis : [SELECT (SELECT Id FROM Workitems) FROM ProcessInstance p WHERE p.TargetObjectId = :sbr.Id AND p.Status = 'Pending']) {
                for (ProcessInstance pi : pis) {
                    for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                        for (ProcessInstanceWorkitem wi : wis ) {
                            newWorkItemIds.add(wi.id);
                        }
                    }
                }
            }
        
        	Approval.ProcessWorkitemRequest req1 = new Approval.ProcessWorkitemRequest();
            req1.setComments('Rejecting request.');
            req1.setAction('Reject');    
            req1.setNextApproverIds(new Id[] {tsUser[0].Id});
    
            System.debug('newWorkItemIds =>'+newWorkItemIds);
            // Use the ID FROM the newly created item to specify the item to be worked
            req1.setWorkitemId(newWorkItemIds.get(0));
    
            // Submit the request for approval
            Approval.ProcessResult result1 =  Approval.process(req1);
            // Verify the results
            System.assert(result1.isSuccess(), 'Result Status:'+result1.isSuccess());
            System.assertEquals('Rejected', result1.getInstanceStatus(), 'Instance Status'+result1.getInstanceStatus());
        	
        	// Manager Approval
        	List<Id> nWorkItemIds = new List<Id>();
        	for (List<ProcessInstance> pis : [SELECT Status, (SELECT Id, ProcessInstanceId FROM Workitems) FROM ProcessInstance p WHERE p.TargetObjectId = :sbr.Id]) {
                for (ProcessInstance pi : pis) {
                    System.debug('ProcessInstance =>'+pis);
                    System.debug('***WIS: '+pi.WorkItems);
                    for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                        for (ProcessInstanceWorkitem wi : wis ) {
                            system.debug('ProcessInstanceWorkitem =>'+wis);
                            nWorkItemIds.add(wi.id);
                        }
                    }
                }
            }               
        	 
        	System.debug('***nWorkItemIds :'+nWorkItemIds);
        	Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        	req2.setComments('Approving request.');
            req2.setAction('Approve');    
            req2.setNextApproverIds(new Id[] {smUser[0].Id});
        	req2.setWorkitemId(nWorkItemIds.get(0));
        
        	Approval.ProcessResult result2 =  Approval.process(req2);
        
        	System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
            System.assertEquals('Approved', result2.getInstanceStatus(), 'Instance Status'+result2.getInstanceStatus());                        

        Test.stopTest();
    }       

    static void rejectRecords(Spend_Band_Review__c spendBandReview){
        List<Id> newWorkItemIds = new List<Id>();
        for (List<ProcessInstance> pis : [SELECT (SELECT Id FROM Workitems) FROM ProcessInstance p WHERE p.TargetObjectId = :spendBandReview.Id AND p.Status = 'Pending']) {
            for (ProcessInstance pi : pis) {
                system.debug('ProcessInstance =>'+pis);
                for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                    for (ProcessInstanceWorkitem wi : wis ) {
                        system.debug('ProcessInstanceWorkitem =>'+wis);
                        newWorkItemIds.add(wi.id);
                    }
                }
            }
        }

        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Rejecting request.');
        req2.setAction('Reject');

        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

        system.debug('newWorkItemIds =>'+newWorkItemIds);
        // Use the ID FROM the newly created item to specify the item to be worked
        req2.setWorkitemId(newWorkItemIds.get(0));

        // Submit the request for approval
        Approval.ProcessResult result2 =  Approval.process(req2);
        // Verify the results
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        System.assertEquals('Rejected', result2.getInstanceStatus(), 'Instance Status'+result2.getInstanceStatus());

    }
    
    @isTest static void test_SpendBandReviewComments() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        List<Spend_Band__c> sbs = TestDataFactory.createSpendBands(new List<Double>{4000, 5000}, new List<String>{'AT_TEST_01', 'AT_TEST_02'}, 'Australia');
        upsert sbs Spend_Band_ID__c;

        Spend_Band_Review__c spendBandReview = TestDataFactory.createSpendBandReview(account.Id, sbs[0].Id, sbs[1].Id, 'Australia');
        insert spendBandReview;
                
        List<Id> newWorkItemIds = new List<Id>();
        for (List<ProcessInstance> pis : [SELECT (SELECT Id FROM Workitems) FROM ProcessInstance p WHERE p.TargetObjectId = :spendBandReview.Id AND p.Status = 'Pending']) {
            for (ProcessInstance pi : pis) {
                for (List<ProcessInstanceWorkitem> wis : pi.Workitems) {
                    for (ProcessInstanceWorkitem wi : wis ) {
                        newWorkItemIds.add(wi.id);
                    }
                }
            }
        }

        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('With this utility you generate a 16 character output based on your input of numbers and upper and lower case letters.  Random strings can be unique. Used in computing, a random string generator can also be called a random character string generator. This is an important tool if you want to generate a unique set of strings. The utility generates a sequence that lacks a pattern and is random.');
        req2.setAction('Approve');

        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

        // Use the ID FROM the newly created item to specify the item to be worked
        req2.setWorkitemId(newWorkItemIds.get(0));

        Test.startTest();
            // Submit the request for approval
            Approval.ProcessResult result2 =  Approval.process(req2);
            // Verify the results
            System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
            System.assertEquals('Approved', result2.getInstanceStatus(), 'Instance Status'+result2.getInstanceStatus());                        
        Test.stopTest();
    }
    
}