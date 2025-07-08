/*******************************************************************************************************
* Class Name      	: TEMP_SM_ContractGroupBatch_Test
* Description		: Temporary batch class to Update legacy accounts for CCRM15-103
* Author          	: Simplus MS
* Created On      	: 27/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus.MS                27/08/2021		1000				Initial version
******************************************************************************************************/
@isTest
public with sharing class TEMP_SM_ContractGroupBatch_Test {
   
    @testSetup static void setup() {

        List<Contract__c> contracts = TestDataFactory.createContracts(2);
        contracts[0].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        contracts[1].RecordTypeId = CSUtils.getRecordTypeId('Contract__c', 'AU Contract');
        insert contracts;

        List<Account> parentAccountsList = TestDataFactory.createAccounts(5);
        insert parentAccountsList;

        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;

        Price_List__c pb1 = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb1;
        Price_List__c pb2 = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb2;
        Customer_Price_List__c cpl1 = new Customer_Price_List__c(Price_List__c = pb1.Id, Account__c = parentAccountsList[0].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '45426');
        insert cpl1;
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(Price_List__c = pb2.Id, Account__c = parentAccountsList[0].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '77655');
        insert cpl2;

        Customer_Price_List__c cplFuture = new Customer_Price_List__c(Price_List__c = pb1.Id, Account__c = parentAccountsList[0].Id, Start_Date__c = System.today().addDays(1),
                                                               Status__c = 'Inactive', Customer_Price_List_ID__c = '45456');
        insert cplFuture;

        List<Id> accountIdsList = new List<Id>();
        for(Account acc:parentAccountsList){
            accountIdsList.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContractsList = TestDataFactory.createAccCustomerContracts(accountIdsList, new List<Id>{contracts[0].Id});
        insert accCustomerContractsList;

        List<Account> childAccounts = TestDataFactory.createAccounts(2);
        Integer i = 0;
        
        for(Account acc:childAccounts){
            acc.Contract_Group__c = parentAccountsList[i].Id;
            acc.Batch_Update__c = True;
            i++;
        }
        insert childAccounts;

        List<Account> childAccounts1 = TestDataFactory.createAccounts(2);
        Integer j = 0;
        
        for(Account acc:childAccounts1){
            acc.Contract_Group__c = parentAccountsList[j].Id;
            acc.Batch_Update__c = True;
            j++;
        }
        insert childAccounts1;

        Price_List__c pbChild = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pbChild;
        Customer_Price_List__c cplChild = new Customer_Price_List__c(Price_List__c = pbChild.Id, Account__c = childAccounts[0].Id,
                                                               Status__c = 'Active', Customer_Price_List_ID__c = '87654');
        insert cplChild;

        List<Id> childAccountIdsList = new List<Id>();
        for(Account acc:childAccounts){
            childAccountIdsList.add(acc.Id);
        }
        List<Customer_Contract__c> accCustomerContractsChildList = TestDataFactory.createAccCustomerContracts(childAccountIdsList, new List<Id>{contracts[1].Id});
        insert accCustomerContractsChildList;
    }

    @isTest
    static void testCustContractAndCPLPopulatedOnChild() {
        
        Test.startTest();
            Database.executeBatch(new TEMP_SM_ContractGroupBatch());
        Test.stopTest();
    }
}