/*******************************************************************************************************
* Class Name      	: TEMP_SM_ContractGroupBatch
* Description		: Temporary batch class to Update legacy accounts for CCRM15-103
* Author          	: Simplus MS
* Created On      	: 25/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus.MS                25/08/2021		1000				Initial version
******************************************************************************************************/
public class TEMP_SM_ContractGroupBatch implements Database.Batchable<sObject> {
    
    String query;
    
    public TEMP_SM_ContractGroupBatch() {
        query = 'SELECT Id, Name, Contract_Group__c, ' +
                '(SELECT Customer__c, Contract__c FROM Customer_Contracts__r), ' +
                '(SELECT Account__c, Price_List__c FROM Customer_Price_Lists__r)' +
                'From Account ' +
                'Where Contract_Group__c != null AND Batch_Update__c = True';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // execute code
        system.debug('Scope :: ' +scope);

        Set<Id> childAccounts = new Set<Id>();
        Set<Id> parentAccounts = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Customer_Price_List__c> toInsertCloneCPLList = new List<Customer_Price_List__c>();
        List<Customer_Contract__c> toInsertCloneCustContractList  = new List<Customer_Contract__c>();

        try {
            for(Account childAcc : scope) {
                childAccounts.add(childAcc.Id);
                parentAccounts.add(childAcc.Contract_Group__c );
            }

            Map<Id, Account> parentAccWithCustContractsAndCPLMap = DM_Account.getParentAccWithCustContractsAndCPL(parentAccounts);
            system.debug('parentAccWithCustContractsAndCPLMap :: ' +parentAccWithCustContractsAndCPLMap);
            Map<Id, Account> childAccWithCustContractsAndCPLMap = DM_Account.getChildAccWithCustContractsAndCPL(childAccounts);
            system.debug('childAccWithCustContractsAndCPLMap :: ' +childAccWithCustContractsAndCPLMap);

            Map<Id, Map<Id, Id>> childAccContractsMap = new Map<Id, Map<Id, Id>>();
            Map<Id, Map<Id, Id>> childAccCPLMap = new Map<Id, Map<Id, Id>>();
            
            for(Account newAcc : childAccWithCustContractsAndCPLMap.values()) {
                
                Map<Id, Id> contractsMap = new Map<Id, Id>();
                Map<Id, Id> cplMap = new Map<Id, Id>();

                for(Customer_Contract__c custContract : newAcc.Customer_Contracts__r){
                    contractsMap.put(custContract.Contract__c, newAcc.Contract_Group__c);
                    childAccContractsMap.put(newAcc.Id, contractsMap);
                }

                for(Customer_Price_List__c cpl : newAcc.Customer_Price_Lists__r){
                    cplMap.put(cpl.Price_List__c, newAcc.Contract_Group__c);
                    childAccCPLMap.put(newAcc.Id, cplMap);
                }
            }
        
            for(Account newAcc : scope) {
                Account parentAccWithCustContractsAndCPL = parentAccWithCustContractsAndCPLMap.get(newAcc.Contract_Group__c);

                Map<Id, Id> childAccCustContracts = childAccContractsMap.get(newAcc.Id);
                Map<Id, Id> childAccCPLs = childAccCPLMap.get(newAcc.Id);

                if(parentAccWithCustContractsAndCPL != null){
                    if(parentAccWithCustContractsAndCPL.Customer_Contracts__r.size() > 0){
                        for(Customer_Contract__c custContract : parentAccWithCustContractsAndCPL.Customer_Contracts__r){

                            if (childAccCustContracts != null){
                                if(!childAccCustContracts.isEmpty() && !childAccCustContracts.containsKey(custContract.Contract__c))
                                {
                                Customer_Contract__c custContractClone = custContract.clone(false, false, false, false);
                                custContractClone.Customer__c = newAcc.Id;
                                toInsertCloneCustContractList.add(custContractClone);
                                system.debug('toInsertCloneCustContractList :: ' +toInsertCloneCustContractList);
                                }
                            }else{
                                Customer_Contract__c custContractClone = custContract.clone(false, false, false, false);
                                custContractClone.Customer__c = newAcc.Id;
                                toInsertCloneCustContractList.add(custContractClone);
                                system.debug('custContract :: ' +custContract);
                            }
                        }
                        //accountsToUpdate.add(new Account(Id = newAcc.Id, On_Contract__c = 'Yes'));
                    }
    
                    if(parentAccWithCustContractsAndCPL.Customer_Price_Lists__r.size() > 0){
                        for(Customer_Price_List__c cpl : parentAccWithCustContractsAndCPL.Customer_Price_Lists__r){

                            if (childAccCPLs != null){
                                if(!childAccCPLs.isEmpty() && !childAccCPLs.containsKey(cpl.Price_List__c))
                                {
                                Customer_Price_List__c cplClone = cpl.clone(false, false, false, false);
                                cplClone.Account__c = newAcc.Id;
                                toInsertCloneCPLList.add(cplClone);
                                system.debug('toInsertCloneCPLList :: ' +toInsertCloneCPLList);
                                }
                            }else{
                                Customer_Price_List__c cplClone = cpl.clone(false, false, false, false);
                                cplClone.Account__c = newAcc.Id;
                                toInsertCloneCPLList.add(cplClone);
                                system.debug('cpl :: ' +cpl);
                            }
                        }
                        //accountsToUpdate.add(new Account(Id = newAcc.Id, On_Contract__c = 'Yes'));
                    }
                    
                    if(parentAccWithCustContractsAndCPL.Customer_Contracts__r.size() > 0 
                        || parentAccWithCustContractsAndCPL.Customer_Price_Lists__r.size() > 0){
                            accountsToUpdate.add(new Account(Id = newAcc.Id, On_Contract__c = 'Yes', Batch_Update__c = False));
                    }
                }
            }

            system.debug('accountsToUpdate :: ' +accountsToUpdate);
            system.debug('toInsertCloneCPLList :: ' +toInsertCloneCPLList);
            system.debug('toInsertCloneCustContractList :: ' +toInsertCloneCustContractList);
            
            if(accountsToUpdate.size() > 0) {
                try {
                    Update accountsToUpdate;
                } catch(Exception e) {
                    ApplicationLogger.log('TEMP_SM_ContractGroupBatch', 'Account', 'Batch', e);
                }
            }
    
            if(toInsertCloneCPLList.size() > 0) {
                try {
                    Insert toInsertCloneCPLList;
                } catch(Exception e) {
                    ApplicationLogger.log('TEMP_SM_ContractGroupBatch', 'Account', 'Batch', e);
                }
            }
            
            if(toInsertCloneCustContractList.size() > 0) {
                try {
                    Insert toInsertCloneCustContractList;
                } catch(Exception e) {
                    ApplicationLogger.log('TEMP_SM_ContractGroupBatch', 'Account', 'Batch', e);
                }
            }

        } catch(Exception e) {
            ApplicationLogger.log('TEMP_SM_ContractGroupBatch', 'Account', 'Batch', e);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code
    }
    
}