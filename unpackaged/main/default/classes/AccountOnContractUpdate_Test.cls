/*******************************************************************************************************
* Class Name      	: AccountOnContractUpdate_Test
* Description		: Test class for AccountOnContractUpdate
* Author          	: Simplus - Francis Benzon
* Created On      	: 04/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        04/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public with sharing class AccountOnContractUpdate_Test {
    @isTest
    public static void testContractActivation() {
        
        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].On_Contract__c = Label.No;
        insert accounts;
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Status__c = Label.Active;
        insert contracts;
        
        List<Customer_Contract__c> customerConList = TestDataFactory.createCustomerContracts(accounts[0].ID, new List<ID> {contracts[0].ID});
        insert customerConList; 

        Test.startTest();
        
        AccountOnContractUpdate.pbInputs argument;
        argument = new AccountOnContractUpdate.pbInputs();
        argument.accountSObj = accounts[0];
        argument.objectName = Label.CustomerContract;

        AccountOnContractUpdate.checkInvokeSourceObject(
            new List<AccountOnContractUpdate.pbInputs>{ argument }
        );
        
        //System.AssertEquals('Yes', accounts[0].On_Contract__c);
        
        
        contracts[0].Status__c = 'Expired';
        update contracts;
        
        AccountOnContractUpdate.pbInputs argument1;
        argument1 = new AccountOnContractUpdate.pbInputs();
        argument1.contractSObj = contracts[0];
        argument1.objectName = Label.Contract;

        AccountOnContractUpdate.checkInvokeSourceObject(
            new List<AccountOnContractUpdate.pbInputs>{ argument1 }
        );
        
        
        //System.AssertEquals('No', accounts[0].On_Contract__c);
        
        
        contracts[0].Status__c = 'Active';
        update contracts;
        
        AccountOnContractUpdate.pbInputs argument2;
        argument2 = new AccountOnContractUpdate.pbInputs();
        argument2.contractSObj = contracts[0];
        argument2.objectName = Label.Contract;

        AccountOnContractUpdate.checkInvokeSourceObject(
            new List<AccountOnContractUpdate.pbInputs>{ argument2 }
        );
        
        
        //System.AssertEquals('Yes', accounts[0].On_Contract__c);
        
        Test.stopTest();
    }
}