/*******************************************************************************************************
* Class Name      	: CustomerContractTrigger_Test
* Description		: Test class for CustomerContractTrigger
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 22/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    22/08/2020		1000				Initial version
* Simplus MS 			07/07/2021		1001				Increased test coverage for CCRM-13792
* Bunnings Dev			11/03/2022		1002				Increased test coverage for SFSUP-373
******************************************************************************************************/
@IsTest
public class CustomerContractTrigger_Test {
    /**
    * @description 
    * @author John Paul Peñaflor | 08-22-2020 
    **/
    @isTest
    public static void testGetContacts() {

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

        Test.startTest();

        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});
		// Initiate Customer Contract initiation
		// Expected: 1 Project participant to be created.
        insert customerContracts;
        
        List<Project_Participant__c> projectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{contracts[0].Id});
        
        System.assertEquals(contracts[0].Id, projectParticipants[0].Contract__c, 'Project Participant not linked to Contract');
        System.assertEquals(1, projectParticipants.size(), 'Created Project Participant should only be 1');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT, projectParticipants[0].Status__c, 'Project Participant Status not updated');
        
        // Delete Initiated Customer Contract 
		// Expected: 1 Project participant to be deassociate to Contract. Contract = null.
        delete customerContracts;
        
        List<Project_Participant__c> oldProjectParticipants = DM_ProjectParticipant.getNoContractProjectParticipants(new Set<String>{projects[0].Id}, new Set<String>{accounts[0].Id});
        
        System.assertEquals(null, oldProjectParticipants[0].Contract__c, 'Contract not deassociated to Project Participant');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_NOT_ON_CONTRACT, oldProjectParticipants[0].Status__c, 'Project Participant Status not updated');
        
        List<Customer_Contract__c> newCustomerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});
        // Reinsert 1 Customer Contract with same values
		// Expected: 1 Project participant to be reassociated to Contract.
        insert newCustomerContracts;
        
        List<Project_Participant__c> updatedProjectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{contracts[0].Id});
        
        System.assertEquals(contracts[0].Id, updatedProjectParticipants[0].Contract__c, 'Project Participant not linked to Contract');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT, updatedProjectParticipants[0].Status__c, 'Project Participant Status not updated');
        System.assertEquals(projectParticipants[0].Id, updatedProjectParticipants[0].Id, 'A new Project Participant should not be created');
        System.assertEquals(1, updatedProjectParticipants.size(), 'Related Project Participant should only be 1 as Customer Contract is recreated with same values.');
        
        List<Customer_Contract__c> duplicateCustomerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});
        // Create 1 Customer Contract with same values
		// Expected: No creation of new Project Participant as there is an existing one. Preventing Duplicates
        insert duplicateCustomerContracts;
        
        updatedProjectParticipants = DM_ProjectParticipant.getProjectParticipants(new Set<String>{contracts[0].Id});
        
        System.assertEquals(1, updatedProjectParticipants.size(), 'Related Project Participant should only be 1 as Customer Contract is new Customer Contract is a duplicate');
        System.assertEquals(SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT, updatedProjectParticipants[0].Status__c, 'Project Participant Status should be active');
        System.assertEquals(projectParticipants[0].Id, updatedProjectParticipants[0].Id, 'A new Project Participant should not be created ');

        Test.stopTest();
    }

    /**
    * @description CCRM-13792: Test Any updates to the master account customer contract are 
    *                           also updated on the child account customer contract.
    * @author Simplus MS | 07/07/2021 
    **/
    @isTest
    public static void updateChildAccCustomerContractTest() {

        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        //contracts[0].Project__c = projects[0].Id;

        insert contracts;

        List<Account> parentAccounts = TestDataFactory.createAccounts(5);
        insert parentAccounts;
        List<Id> accountIds = new List<Id>();
        for(Account acc:parentAccounts){
            accountIds.add(acc.Id);
        }

        List<Account> childAccounts = TestDataFactory.createAccounts(5);
        Integer i = 0;
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccounts[i].Id;
            i++;
        }
        insert childAccounts;

        Test.startTest();
        List<Customer_Contract__c> accCustomerContracts = TestDataFactory.createAccCustomerContracts(accountIds, new List<Id>{contracts[0].Id});
        insert accCustomerContracts;
        List<Account> accList = [SELECT Id, (SELECT Id FROM Customer_Contracts__r) 
                                FROM Account
                                WHERE Name Like 'TestContract%' AND Contract_Group__c != null];
        for(Account acc:accList){
            System.assertEquals(1, acc.Customer_Contracts__r.size(), 'Child Account Customer Contracts not updated successfully');
        }
        Test.stopTest();
    }

    @isTest
    public static void checkAccountContracts_Test() {
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;

        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        contracts[0].Status__c = Label.Active;
        insert contracts;

        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>{contracts[0].Id});		
        insert customerContracts;

        Test.startTest();
            List<Customer_Contract__c> lstCC = [SELECT Id, Customer__c, Contract__c, Start_Date__c, Contract__r.Status__c
				FROM Customer_Contract__c WHERE Id =:customerContracts[0].Id];
            Map<Id, Customer_Contract__c> newMap = new Map<Id, Customer_Contract__c>(lstCC);

            for (Customer_Contract__c cc : newMap.values())
                cc.Start_Date__c = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());

        	CustomerContractTriggerHandler.checkAccountContracts(newMap.values());
            List<Account> acc = [SELECT On_Contract__c FROM Account WHERE Id =: accounts[0].Id LIMIT 1];
            System.assertEquals(acc[0].On_Contract__c, 'Yes');
        Test.stopTest();

    }


    


}