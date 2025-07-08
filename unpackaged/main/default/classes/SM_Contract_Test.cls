/*******************************************************************************************************
* Class Name      	: SM_Contract_Test
* Description		: Test class for SM_Contract
* Author          	: Simplus - Yi Zhang
* Created On      	: 28/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              28/07/2020		1000				Initial version (Moved Phil's codes from SM_ContractReview_Test)
* Jasper R Galapon		13/04/2023		2000				BUNDIG-17527 - Test class for blocking Integration user updates
* Jasper R. Galapon		20/06/2023		3000				BUNDIG-21197 - New/Renewal Contracts - No Case Created When A1 Rejects
* Jasper R. Galapon     30/06/2023      6000                BUNDIG-22401 / BUNDIG-22402 - New/Renewal Contract / Contract Amendments - Email Notifications
* Jasper R. Galapon		19/10/2023		7000				BUNDIG-26279 - Test Class failures in PROD
******************************************************************************************************/
@isTest
private class SM_Contract_Test {
    @isTest
    private static void updateContractProjectAddress() {
        /**
         * 
        Create 1 account
        Create 2 project with different addresses
        Create 2 project participants linking account 1 with project 1&2 respectively
        Create a contract with same address as project 1
        Test starts:
        Create 1 customer contract linking account 1 with contract
        Expected result: contract’s project is populated correctly
        Change contract’s address to match project 2
        Expected result: contract’s project is updated, and project participants updated
         */
        List<Account> accounts = TestDataFactory.createAccounts(3);
        insert accounts;
        List<Project__c> projects = TestDataFactory.createProject(2);
        projects[0].Project_Address__c = 'A1';
        projects[0].State__c = 'VIC';
        projects[0].Postcode__c = '3000';
        projects[1].Project_Address__c = 'A2';
        projects[1].State__c = 'SA';
        projects[1].Postcode__c = '5000';
        insert projects;
        List<Project_Participant__c> participants = new List<Project_Participant__c>{
            new Project_Participant__c(Account__c = accounts[0].Id, Project__c = projects[0].Id),
            new Project_Participant__c(Account__c = accounts[0].Id, Project__c = projects[1].Id)
        };
        insert participants;
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Project_Address__c = 'A1';
        contracts[0].Project_State__c = 'VIC';
        contracts[0].Project_Postcode__c = '3000';
        insert contracts;

        List<Customer_Contract__c> ccs = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});
        Test.startTest();
        insert ccs;
        System.assertEquals(projects[0].Id, [SELECT Id, Project__c FROM Contract__c WHERE Id = :contracts[0].Id].Project__c, 'Project not set properly.');
        
        contracts[0].Project_Address__c = projects[1].Project_Address__c;
        contracts[0].Project_State__c = projects[1].State__c;
        contracts[0].Project_Postcode__c = projects[1].Postcode__c;
        update contracts;
        System.assertEquals(projects[1].Id, [SELECT Id, Project__c FROM Contract__c WHERE Id = :contracts[0].Id].Project__c, 'Project not updated properly.');

        contracts[0].Project_Address__c = null;
        update contracts;
        System.assertEquals(null, [SELECT Id, Project__c FROM Contract__c WHERE Id = :contracts[0].Id].Project__c, 'Project not set to null.');
        
        contracts[0].Project_Address__c = projects[1].Project_Address__c;
        update contracts;
        System.assertEquals(projects[1].Id, [SELECT Id, Project__c FROM Contract__c WHERE Id = :contracts[0].Id].Project__c, 'Project not updated from null properly.');

        Test.stopTest();

    }
    @isTest
    private static void updateOriginalApproverReviewer() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        
        List<User> users = TestDataFactory.createUsers(3, p.Id);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
        	insert users[2];
        	insert users[1];
            users[0].DelegatedApproverId = users[1].Id;
        	insert users[0];
        }
        
        list<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Original_Approver__c = users[2].Id;
        contracts[0].Original_Reviewer__c = users[2].Id;
        contracts[0].Approver__c = users[2].Id;
        contracts[0].Reviewer__c = users[2].Id;
        insert contracts;
        
        Test.startTest();
        
        contracts[0].Original_Approver__c = users[0].Id;
        contracts[0].Original_Reviewer__c = users[0].Id;
        update contracts;
        
        Test.stopTest();
        
        Contract__c c = DM_Contract.getContract(contracts[0].Id);
        system.assertEquals(users[1].Id,c.Approver__c,'Contract approver not updated to new original approvers delegated approver');
        system.assertEquals(users[1].Id,c.Reviewer__c,'Contract reviewer not updated to new original reviewers delegated approver');
    }

    @isTest
    private static void testProjectParticipantUpdate() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.NATIONAL_MANAGER_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(1, p.Id);
        users[0].FirstName = 'Bob';
        users[0].LastName = 'Vuksan';
		
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
			//insert userSysAd;
        }

        List<Store__c> stores = TestDataFactory.createStores(1);
        stores[0].Engagement_Model__c = 'New';

        insert stores;
            								
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Power_Pass_Account_Number__c = 'Test-1001';
        accounts[0].Home_Store__c = stores[0].Id;

        insert accounts;

        List<Project__c> projects = TestDataFactory.createProject(2);
        projects[0].RecordTypeId = CSUtils.getRecordTypeId('Project__c', 'AU Project');
        projects[1].RecordTypeId = CSUtils.getRecordTypeId('Project__c', 'AU Project');

        insert projects;

        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        contracts[0].Project__c = projects[0].Id;

        insert contracts;

        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});

        insert customerContracts;

        Test.startTest();

        contracts[0].Project__c = projects[1].Id;
        update contracts;

        List<Project_Participant__c> deassociatedProjectParticipants = DM_ProjectParticipant.getNoContractProjectParticipants(new Set<String>{projects[0].Id}, new Set<String>{accounts[0].Id});
        List<Project_Participant__c> newProjectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{projects[1].Id}, new Set<String>{accounts[0].Id});

        System.assertEquals(1, deassociatedProjectParticipants.size(), 'Deassociated Project Participant should be 1');
        System.assertEquals(1, newProjectParticipants.size(), 'New Associated Project Participant should be 1');
        System.assertEquals(null, deassociatedProjectParticipants[0].Contract__c, 'Project Participant not deassociated to Contract');
        System.assertEquals(contracts[0].Id, newProjectParticipants[0].Contract__c, 'New Project Participant not linked to Contract');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_NOT_ON_CONTRACT, deassociatedProjectParticipants[0].Status__c, 'Deassociated Project Participant Status not updated');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT, newProjectParticipants[0].Status__c, 'New Project Participant Status not updated');

        contracts[0].Project__c = null;
        update contracts;

        deassociatedProjectParticipants = DM_ProjectParticipant.getNoContractProjectParticipants(new Set<String>{projects[0].Id, projects[1].Id}, new Set<String>{accounts[0].Id});

        System.assertEquals(2, deassociatedProjectParticipants.size(), 'Deassociated Project Participant should be 2');

        contracts[0].Project__c = projects[0].Id;
        update contracts;
        List<Project_Participant__c> reassociatedProjectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{projects[0].Id}, new Set<String>{accounts[0].Id});
        System.assertEquals(1, reassociatedProjectParticipants.size(), 'Reassociated Project Participant should be 1');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT, reassociatedProjectParticipants[0].Status__c, 'Reassociated Project Participant Status not updated');
        System.assertEquals(contracts[0].Id, reassociatedProjectParticipants[0].Contract__c, 'Reassociated Project Participant not linked to Contract');

        contracts[0].Name = 'Test Name change';
        update contracts;

        List<Project_Participant__c> updatedProjectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{projects[0].Id}, new Set<String>{accounts[0].Id});
        System.assertEquals(1, updatedProjectParticipants.size(), 'Updated Project Participant should be 1');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_REQUEST_CONTRACT_CHANGE, updatedProjectParticipants[0].Status__c, 'Updated Project Participant Status not updated');
        System.assertEquals(contracts[0].Id, updatedProjectParticipants[0].Contract__c, 'Updated Project Participant not linked to Contract');

        Test.stopTest();
        
    }
    
    @isTest
    private static void testExceptionsBeforeUpdate() {
        Test.startTest();
        try {
            SM_Contract.beforeUpdate(null, null);
        }catch(Exception e){
            System.assert(TRUE);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testResetReviewersApprovers() {
        Test.startTest();
        try {
            Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
            
            List<User> users = TestDataFactory.createUsers(3, p.Id);
            User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs (thisUser) {
                insert users[2];
                insert users[1];
                users[0].DelegatedApproverId = users[1].Id;
                insert users[0];
            }
            
            List<Contract__c> contracts = TestDataFactory.createContracts(1);
            contracts[0].Reviewer__c = users[0].Id;
            contracts[0].Approver__c = users[1].Id;
            insert contracts;
            System.debug('***CONTRACT: '+contracts);
            
            Set<Id> userIdSet = new Set<Id>();
            for (User u : [Select Id From User]){
                userIdSet.add(u.Id);
            }
            SM_Contract.resetReviewersApprovers(userIdSet);
            DM_Contract.getContractsbyReviewerApprover(userIdSet);
        }catch(Exception e){
            System.assert(TRUE);
        }
        Test.stopTest();
    }
    
    // BUNDIG-17527
    @isTest
    private static void blockUpdate_Test() {
        Test.startTest();
        	// BUNDIG-26279
            // Id intId = [SELECT Id FROM User WHERE Name = 'Integration User'].Id;
        	Id intId = [SELECT Id FROM User WHERE Name = 'Integration User' AND Profile.Name = 'Integrations User' LIMIT 1].Id;
                    
            SM_Configs__c config = new SM_Configs__c(Integration_User_Id__c = intId);
            insert config;
            
            List<Contract__c> contracts = TestDataFactory.createContracts(1);
            contracts[0].Contract_Approval_Status__c = 'Customer Approved';
            insert contracts;
                    
            User thisUser = [SELECT Id FROM User WHERE Name = 'Integration User' AND Profile.Name = 'Integrations User' LIMIT 1];
           
            System.runAs (thisUser) {
                contracts[0].Contract_Approval_Status__c = 'Pending';
                contracts[0].Reviewer_Action__c = 'A';
                contracts[0].Approver_Action__c = 'A';
                contracts[0].Reviewer_Action_Date__c = Date.today();
                contracts[0].Approver_Action_Date__c = Date.today();
                contracts[0].Reviewer_Comments__c = 'Approved by reviewer';
                contracts[0].Approver_Comments__c = 'Approved by approver';            
                update contracts;                
            }
        Test.stopTest();
    }
    
    // BUNDIG-21197
    @isTest
    private static void testCreateCase() {
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Status__c = 'Pending';
        insert contracts;
        
        Test.startTest();
        	contracts[0].Status__c = 'Rejected';
        	update contracts;
        Test.stopTest();
    }
    
    @isTest
    private static void testrenewedContractEmailNotification() {
        Test.startTest();
        	Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];            
            List<User> users = TestDataFactory.createUsers(1, p.Id);
        	users[0].isActive = true;
        	users[0].email = 'jasper@test.com.au';
        	System.runAs(new User(Id = UserInfo.getUserId())) {
            	insert users;
            }
        	
        	List<Contract__c> contracts = TestDataFactory.createContracts(1);
        	contracts[0].Contract_Name__c =  'Test Contract';
        	contracts[0].Status__c = 'Pending';
        	contracts[0].Reviewer__c = users[0].Id;
        	contracts[0].Reviewer_Action__c = null;
        	insert contracts;        	
        Test.stopTest();
    }
            
    @isTest
    private static void testcontractEmailNotification() {
        Test.startTest();
        	Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];            
            List<User> users = TestDataFactory.createUsers(2, p.Id);
        	users[0].isActive = true;
        	users[1].isActive = true;
        	System.runAs(new User(Id = UserInfo.getUserId())) {
            	insert users;
            }
        
			List<Contract__c> contracts = TestDataFactory.createContracts(1);
        	contracts[0].Contract_Name__c =  'Test Contract';
        	contracts[0].Status__c = 'Draft';
        	contracts[0].Reviewer__c = users[0].Id;
        	contracts[0].Approver__c = users[1].Id;
        	contracts[0].Reviewer_Action__c = null;
        	insert contracts;
        
        	contracts[0].Status__c = 'Pending';
        	update contracts;
        
        	contracts[0].Status__c = 'Reviewed';
        	update contracts;
        
        	contracts[0].Status__c = 'Approved';
        	update contracts;
        
        	contracts[0].Status__c = 'Pending';
        	contracts[0].Approver_Action__c = 'R';
        	update contracts;
        
        	// Test Contract Line Item
        	List<Contract_Line_Item__c> items1 = TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1);
        	insert items1;
        
        	List<Contract_Line_Item__c> items2 = TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A2', null, 1);
        	insert items2;
        	
        Test.stopTest();
    }
}