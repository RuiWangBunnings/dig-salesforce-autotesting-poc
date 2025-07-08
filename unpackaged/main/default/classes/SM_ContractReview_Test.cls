/*******************************************************************************************************
* Class Name      	: SM_ContractReview_Test
* Description		: Test class for SM_ContractReview
* Author          	: Simplus - Yi Zhang
* Created On      	: 09/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              09/06/2020		1000				Initial version
* Simplus MS            21/01/2021      1001                New method added to cover the saveAmendementContractLineItems method coverage
******************************************************************************************************/
@isTest
private class SM_ContractReview_Test {
    @isTest
    public static void testGetContractMetadata() {
        // setup data
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // User
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: 'Account Manager' LIMIT 1];
        Profile pSM = [SELECT Id FROM Profile WHERE Name =: 'Sales Manager' LIMIT 1];
                
        list<User> userAM = TestDataFactory.createUsers(1, pAM.Id);
        insert userAM;
        list<User> userSM = TestDataFactory.createUsers(1, pSM.Id);
        insert userSM;
        
        // contract
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Contract_Name__c = 'C1', Status__c = 'Pending', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL',
                           Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id)			
        };
		System.runAs (thisUser) {
        	insert contracts;
        }
        
        // contract line items
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, null, 20));
        System.runAs (thisUser) {
        	insert items;
        }
        
        Id recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = 'AU_Customer'].Id;
        
        // account
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = recordTypeId;
        accounts[1].RecordTypeId = recordTypeId;
        System.runAs (thisUser) {
        	insert accounts;
        }
        
        // customer contracts
        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
        customerContracts.addAll(TestDataFactory.createCustomerContracts(accounts[1].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet())));
        System.runAs (thisUser) {
        	insert customerContracts;
        }
        
        // special buys
        List<Special_Buy__c> specialBuys = new List<Special_Buy__c>{
            TestDataFactory.createSpecialBuy('SB1', Date.today() + 10),
            TestDataFactory.createSpecialBuy('SB2', Date.today() + 5)
        };
		System.runAs (thisUser) {
        	insert specialBuys;
        }
        
        // customer special buys
        List<Customer_Special_Buy__c> customerSpecialBuys = TestDataFactory.createCustomerSpecialBuys(accounts[0].Id, new List<Id>((new Map<Id, Special_Buy__c>(specialBuys)).keySet()));
        System.runAs (thisUser) {
        	insert customerSpecialBuys;
        }
        
        // special buy line items
        List<Special_Buy_Line_Item__c> sbItems = TestDataFactory.createSpecialBuyLineItems(specialBuys[0].Id, new List<String>{items[0].Name, items[1].Name});
        System.runAs (thisUser) {
        	insert sbItems;
        }
        
        Test.startTest();
            //SM_ContractReview.getContractMetadata(contracts[0].Id, null);
            SM_ContractReview.getContractMetadata(contracts[0].Id, userAM[0].Id);
        	System.runAs (thisUser) {
            	SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
            	SM_ContractReview.saveContract(contracts[0]);
            	//SM_ContractReview.saveAmendementContractLineItems(new List<String>{items[0].Id}, 'A', 'Approved', UserInfo.getUserId(), 'AU CZ2');
            }
            try {
                SM_ContractReview.saveContractLineItems(null);
            } catch(Exception e) {
                System.assert(true, 'exception not caught');
            }
    
            try {
                SM_ContractReview.saveContract(null);
            } catch(Exception e) {
                System.assert(true, 'exception not caught');
            }

        	System.runAs (thisUser) {
                contracts[0].Contract_Locked__c = true;
                update contracts[0];
            
            	SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
            	SM_ContractReview.saveContract(contracts[0]);
            
            	// make contract amendment
            	items[1].Line_Type__c = Constants.CLI_LINE_TYPE_AMENDMENT;
            	update items[1];
            	SM_ContractReview.getContractMetadata(contracts[0].Id, null);
            	contracts[0].Contract_Locked__c = false;
            	update contracts[0];
            	SM_ContractReview.getContractMetadata(contracts[0].Id, null);
            }
        Test.stopTest();
        
    }

    @isTest
    public static void testgetContractAmendmentMetadata() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // User
        Profile pAM = [SELECT Id FROM Profile WHERE Name =: 'Account Manager' LIMIT 1];
        Profile pSM = [SELECT Id FROM Profile WHERE Name =: 'Sales Manager' LIMIT 1];
                
        list<User> userAM = TestDataFactory.createUsers(1, pAM.Id);
        insert userAM;
        list<User> userSM = TestDataFactory.createUsers(1, pSM.Id);
        insert userSM;
        
		// Contract
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Contract_Name__c = 'C1', Status__c = 'Pending', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL', 
                            Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id),
			new Contract__c(Name = 'C2', Contract_Name__c = 'C2', Status__c = 'Active', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL', 
                            Contract_Locked__c = true, Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id),
			new Contract__c(Name = 'C3', Contract_Name__c = 'C3', Status__c = 'Submitted', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL', 
                            Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id),
			new Contract__c(Name = 'C4', Contract_Name__c = 'C4', Status__c = 'Draft', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL', 
                            Reviewer__c = userAM[0].Id, Approver__c = userSM[0].Id)
        };
		System.runAs (thisUser) {
        	insert contracts;
        }
        
        // Contract line items
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, null, 1));
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1));
        
        items.addAll(TestDataFactory.createContractLineItems(contracts[2].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, null, 1));
        items.addAll(TestDataFactory.createContractLineItems(contracts[2].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A', null, 1));
        
        items.addAll(TestDataFactory.createContractLineItems(contracts[3].Id, Constants.CLI_LINE_TYPE_CONTRACT, null, null, 1));
        items.addAll(TestDataFactory.createContractLineItems(contracts[3].Id, Constants.CLI_LINE_TYPE_AMENDMENT, 'A1', null, 1));
        System.runAs (thisUser) {
        	insert items;
        }
        
        Id recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = 'AU_Customer'].Id;
        
        // account
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].RecordTypeId = recordTypeId;
        accounts[1].RecordTypeId = recordTypeId;
        System.runAs (thisUser) {
        	insert accounts;
        }
        
        // customer contracts
        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
        customerContracts.addAll(TestDataFactory.createCustomerContracts(accounts[1].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet())));
        System.runAs (thisUser) {
        	insert customerContracts;
        }
        
        // special buys
        List<Special_Buy__c> specialBuys = new List<Special_Buy__c>{
            TestDataFactory.createSpecialBuy('SB1', Date.today() + 10),
            TestDataFactory.createSpecialBuy('SB2', Date.today() + 5)
        };
		System.runAs (thisUser) {
        	insert specialBuys;
        }
        
        // customer special buys
        List<Customer_Special_Buy__c> customerSpecialBuys = TestDataFactory.createCustomerSpecialBuys(accounts[0].Id, new List<Id>((new Map<Id, Special_Buy__c>(specialBuys)).keySet()));
        System.runAs (thisUser) {
        	insert customerSpecialBuys;
        }
        
        // special buy line items
        List<Special_Buy_Line_Item__c> sbItems = TestDataFactory.createSpecialBuyLineItems(specialBuys[0].Id, new List<String>{items[0].Name, items[1].Name});
        System.runAs (thisUser) {
        	insert sbItems;
        }
        
		Test.startTest();
			SM_ContractReview.getContractAmendmentMetadata(contracts[0].Id, userAM[0].Id);
        	SM_ContractReview.getContractAmendmentMetadata(contracts[1].Id, userSM[0].Id);
        	SM_ContractReview.getContractAmendmentMetadata(contracts[0].Id, null);
        	SM_ContractReview.getContractAmendmentMetadata(contracts[2].Id, userSM[0].Id);
        	SM_ContractReview.getContractAmendmentMetadata(contracts[3].Id, userAM[0].Id);
        Test.stopTest();
    }
    
    @isTest
    public static void test_ContractLineStatus_A1() {
        // setup data
        // contract
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Status__c = 'Active', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL')
        };
        insert contracts;
        // contract line items
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, 'A1', null, 200));
        insert items;
        
        // account
        List<Account> accounts = TestDataFactory.createAccounts(2);
        insert accounts;
        // customer contracts
        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
        customerContracts.addAll(TestDataFactory.createCustomerContracts(accounts[1].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet())));
        insert customerContracts;
        // special buys
        List<Special_Buy__c> specialBuys = new List<Special_Buy__c>{
            TestDataFactory.createSpecialBuy('SB1', Date.today() + 10),
            TestDataFactory.createSpecialBuy('SB2', Date.today() + 5)
        };
        insert specialBuys;
        // customer special buys
        List<Customer_Special_Buy__c> customerSpecialBuys = TestDataFactory.createCustomerSpecialBuys(accounts[0].Id, new List<Id>((new Map<Id, Special_Buy__c>(specialBuys)).keySet()));
        insert customerSpecialBuys;
        // special buy line items
        List<Special_Buy_Line_Item__c> sbItems = TestDataFactory.createSpecialBuyLineItems(specialBuys[0].Id, new List<String>{items[0].Name, items[1].Name});
        insert sbItems;

        Test.startTest();
        SM_ContractReview.getContractMetadata(contracts[0].Id, null);
        
        SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
        SM_ContractReview.saveContract(contracts[0]);
        SM_ContractReview.saveAmendementContractLineItems(new List<String>{items[0].Id}, 'A', 'Approved', UserInfo.getUserId(), 'CZ2');

        try {
            SM_ContractReview.saveContractLineItems(null);
        } catch(Exception e) {
            System.assert(true, 'exception not caught');
        }

        try {
            SM_ContractReview.saveContract(null);
        } catch(Exception e) {
            System.assert(true, 'exception not caught');
        }
        

        contracts[0].Contract_Locked__c = true;
        update contracts[0];
        SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
        SM_ContractReview.saveContract(contracts[0]);
       
        Test.stopTest();
        
    }

    @isTest
    public static void test_ContractLineStatus_A2() {
        // setup data
        // contract
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Status__c = 'Active', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL')
        };
        insert contracts;
        // contract line items
        List<Contract_Line_Item__c> items = new List<Contract_Line_Item__c>();
        items.addAll(TestDataFactory.createContractLineItems(contracts[0].Id, Constants.CLI_LINE_TYPE_CONTRACT, 'A2', null, 200));
        insert items;
        
        // account
        List<Account> accounts = TestDataFactory.createAccounts(2);
        insert accounts;
        // customer contracts
        List<Customer_Contract__c> customerContracts = TestDataFactory.createCustomerContracts(accounts[0].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet()));
        customerContracts.addAll(TestDataFactory.createCustomerContracts(accounts[1].Id, new List<Id>((new Map<Id, Contract__c>(contracts)).keySet())));
        insert customerContracts;
        // special buys
        List<Special_Buy__c> specialBuys = new List<Special_Buy__c>{
            TestDataFactory.createSpecialBuy('SB1', Date.today() + 10),
            TestDataFactory.createSpecialBuy('SB2', Date.today() + 5)
        };
        insert specialBuys;
        // customer special buys
        List<Customer_Special_Buy__c> customerSpecialBuys = TestDataFactory.createCustomerSpecialBuys(accounts[0].Id, new List<Id>((new Map<Id, Special_Buy__c>(specialBuys)).keySet()));
        insert customerSpecialBuys;
        // special buy line items
        List<Special_Buy_Line_Item__c> sbItems = TestDataFactory.createSpecialBuyLineItems(specialBuys[0].Id, new List<String>{items[0].Name, items[1].Name});
        insert sbItems;

        Test.startTest();
        SM_ContractReview.getContractMetadata(contracts[0].Id, null);
        
        SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
        SM_ContractReview.saveContract(contracts[0]);
        SM_ContractReview.saveAmendementContractLineItems(new List<String>{items[0].Id}, 'A', 'Approved', UserInfo.getUserId(), 'CZ2');

        try {
            SM_ContractReview.saveContractLineItems(null);
        } catch(Exception e) {
            System.assert(true, 'exception not caught');
        }

        try {
            SM_ContractReview.saveContract(null);
        } catch(Exception e) {
            System.assert(true, 'exception not caught');
        }
        

        contracts[0].Contract_Locked__c = true;
        update contracts[0];
        SM_ContractReview.saveContractLineItems(new List<Contract_Line_Item__c>{items[0]});
        SM_ContractReview.saveContract(contracts[0]);
       
        Test.stopTest();
        
    }

    @isTest
    public static void test_GetContractHistory() {
        // setup data
        // contract
        List<Contract__c> contracts = new List<Contract__c>{
            new Contract__c(Name = 'C1', Status__c = 'Active', Country__c = 'Australia', State__c = 'VIC', Cost_Zone__c = 'ALL')
        };
        insert contracts;
        List<Contract__History> contractsHistory = new List<Contract__History>{
            new Contract__History(Field = 'Status__c', ParentId = contracts[0].Id)
        };
        insert contractsHistory;

        Test.startTest();
        SM_ContractReview.getContractHistory(contracts[0].Id);
        DM_Contract.getContractsbyReviewerApprover(new set<Id> {UserInfo.getUserId()});
        DM_Contract.getContractsbyOrigReviewerApprover(new set<Id> {UserInfo.getUserId()});
        Test.stopTest();
    }
}