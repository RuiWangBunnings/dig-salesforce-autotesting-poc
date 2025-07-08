/*******************************************************************************************************
* Class Name      	: ContractLineItemTriggerHandlerTest
* Description		: Test class for ContractLineItemTriggerHandler
* Author          	: Bunnings Dev
* Created On      	: 18/05/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R Galapon		18/05/2023		1000				Initial Version
* Jasper R Galapon		19/10/2032		1001				BUNDIG-26279 - Test Class failures in PROD 
* Jasper R Galapon		06/08/2024		1002				BUNDIG-34608 - New Test class method for setAutoApprovalEligibility
******************************************************************************************************/

@isTest
private class ContractLineItemTriggerHandlerTest {
    
    @isTest
    private static void blockUpdate_Test() {
        Test.startTest();
        	// BUNDIG-26279
			// Id intId = [SELECT Id FROM User WHERE Name = 'Integration User'].Id;
        	Id intId = [SELECT Id FROM User WHERE Profile.Name = 'Integrations User' LIMIT 1].Id;
                    
            SM_Configs__c config = new SM_Configs__c(Integration_User_Id__c = intId);
            insert config;
            
            List<Contract__c> contracts = TestDataFactory.createContracts(1);
            contracts[0].Contract_Approval_Status__c = 'Customer Approved';
            insert contracts;
                    
            User thisUser = [SELECT Id FROM User WHERE Profile.Name = 'Integrations User' LIMIT 1];
                        
            List<Contract_Line_Item__c> items = TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, 'A1', null, 1);
        	items[0].Amendment_Type__c = 'U';
            insert items;
           
            System.runAs (thisUser) {                
                items[0].Reviewer_Action__c = 'A';
                items[0].Approver_Action__c = 'A';
                items[0].Reviewer_Action_Date__c = Date.today();
                items[0].Approver_Action_Date__c = Date.today();
                items[0].Reviewer_Comments__c = 'Approved by reviewer';
                items[0].Approver_Comments__c = 'Approved by approver';            
                update items;
                
                System.assertNotEquals('A', [SELECT Reviewer_Action__c FROM Contract_Line_Item__c WHERE Id = :items[0].Id].Reviewer_Action__c, 'not equals');
            }
        Test.stopTest();
    }
    
    @isTest
    private static void sendNotificationToReviewer_Test() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: 'Account Manager' LIMIT 1];
        Profile pSM = [SELECT Id FROM Profile WHERE Name =: 'Sales Manager' LIMIT 1];
                
        list<User> userAM = TestDataFactory.createUsers(1, pAM.Id);
        insert userAM;
        list<User> userSM = TestDataFactory.createUsers(1, pSM.Id);
        insert userSM;
        
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Contract_Name__c = 'C1', Status__c = 'Pending', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL',
                           Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id)
        };
		System.runAs (thisUser) {
        	insert contracts;
        }
        
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1));
        //items[0].Line_Status__c = 'A1';
        items[0].Amendment_Type__c = 'U';
        System.runAs (thisUser) {
        	insert items;
        }
        
        Test.startTest();
        	items[0].Reviewer_Action__c = 'A';
        	items[0].Line_Status__c = 'A2';
        	System.runAs (thisUser) {
        		update items;
            }
        	items[0].Approver_Action__c = 'R';
        	items[0].Line_Status__c = 'R';
        	System.runAs (thisUser) {
        		update items;
            }
        Test.stopTest();
        
    }
    
    @isTest
    private static void setAutoApprovalEligibility_Eligible_Test() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Power_Pass_Account_Number__c = 'JRG001';
        insert accounts;
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Status__c = Label.Active;
        contracts[0].Country__c = 'Australia';
        insert contracts;
        
        List<Customer_Contract__c> customerConList = TestDataFactory.createCustomerContracts(accounts[0].ID, new List<ID> {contracts[0].ID});
        insert customerConList; 
        
        Test.startTest();
            List<Contract_Line_Item__c> cli = TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1);
            cli[0].Amendment_Type__c = 'U';
            insert cli;
		Test.stopTest();

        System.assertEquals(TRUE, [SELECT Auto_Approval_Eligibility__c FROM Contract_Line_Item__c WHERE Id = :cli[0].Id].Auto_Approval_Eligibility__c, 'Contract Line Item is eligible for auto approval');              
    }
    
    @isTest
    private static void setAutoApprovalEligibility_Ineligible_Test() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].Power_Pass_Account_Number__c = 'JRG001';
        insert accounts;
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Status__c = Label.Active;
        contracts[0].Country__c = 'Australia';
        insert contracts;
        
        List<Customer_Contract__c> customerConList = TestDataFactory.createCustomerContracts(accounts[0].ID, new List<ID> {contracts[0].ID});
        insert customerConList;
        
        Account_Exclusion_List__c ael = new Account_Exclusion_List__c(Account_Reference__c = 'JRG001');
        insert ael;
        
        Supplier_Exclusion_List__c sel = new Supplier_Exclusion_List__c(Supplier_Reference__c = 'JRG002');
        insert sel;
        
        Test.startTest();
            List<Contract_Line_Item__c> cli = TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1);
            cli[0].Amendment_Type__c = 'U';
            insert cli;
		Test.stopTest();        
    }
    
}