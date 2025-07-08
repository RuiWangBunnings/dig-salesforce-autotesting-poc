/*******************************************************************************************************
* Class Name      	: AccountOnContractUpdate
* Description		: Update On Contract field to Yes on Account if there are Active Contracts for the acct
* Author          	: Simplus - Francis Benzon
* Created On      	: 03/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        03/06/2020		1000				Initial version
* Bunnings Dev          07/03/2022      2000                SFSUP-373 Commented out checkAccountContracts, functionality moved to
*                                                           CustomerContractTrigger/CustomerContractTriggerHandler
******************************************************************************************************/
public without sharing class AccountOnContractUpdate {
    
    
    public class pbInputs {
        @InvocableVariable
        public Account accountSObj;
        
        @InvocableVariable
        public Contract__c contractSObj;
        
        @InvocableVariable
        public String objectName;
    }
    
    /**
    * @description 
    * @author Francis Benzon | 03/06/2020
    * @param requests 
    **/
    @InvocableMethod
    public static void checkInvokeSourceObject(List<pbInputs> requests) {
        // SFSUP-373 - Commented out
        //if(requests[0].objectName == Label.CustomerContract)
        //    checkAccountContracts(requests[0].accountSObj.ID);        
        
        if(requests[0].objectName == Label.Contract)
            checkContractAccounts(requests[0].contractSObj.ID);
            
    }
    
    /**
    * @description 
    * @author Francis Benzon | 03/06/2020
    * @param acctID 
    **/
    // SFSUP-373 - Commented out
    /*public static void checkAccountContracts(ID acctID) {
        //system.assertEquals('IN ACCT', ' ' + acctID);
        Set<ID> contractIDSet = new Set<ID>();
        Account acct = [SELECT ID, On_Contract__c FROM Account WHERE ID =:acctID];
        
        for(Customer_Contract__c cc : [SELECT ID, Contract__c, Contract__r.Status__c, Customer__c FROM Customer_Contract__c
                                        WHERE Customer__c = :acctID]) {
            if(cc.Contract__c != null && cc.Contract__r.Status__c == Label.Active) 
                contractIDSet.add(cc.Contract__c);
        }
        
        if(!contractIDSet.isEmpty() && contractIDSet.size() > 0) {
            acct.On_Contract__c = Label.Yes;
            
            try {
                update acct;
            }catch(Exception e) {
                //add logger here 
            }
        }
    }*/
        
    /**
    * @description 
    * @author Francis Benzon | 03/06/2020 
    * @param contractID 
    **/
    public static void checkContractAccounts(ID contractID) {
        //system.assertEquals('IN CONTRACT', ' ' + contractID);
        List<Account> acctsToUpdateList = new List<Account>();
        Map<ID, Set<String>> acctID_cotractStatStrSetMap = new Map<ID, Set<String>>();
        Set<ID> acctIDSet = new Set<ID>();
        
        
        for(Customer_Contract__c cc : [SELECT Customer__c FROM Customer_Contract__c WHERE Contract__c = :contractID]) {
            if(cc.Customer__c != null)
                acctIDSet.add(cc.Customer__c);
        }
        //query ALL customer Contracts related to ALL accounts related to the updated Contract
        for(Customer_Contract__c cc : [SELECT ID, Contract__c, Contract__r.Status__c, Customer__c FROM Customer_Contract__c
                                        WHERE Customer__c IN :acctIDSet]) 
        {
            //map acct ID and contract IDs that are Active
            if(cc.Contract__c != null && cc.Contract__r.Status__c != ''){
                if(acctID_cotractStatStrSetMap.containsKey(cc.Customer__c)) {
                    acctID_cotractStatStrSetMap.get(cc.Customer__c).add(cc.Contract__r.Status__c);
                }else {
                    acctID_cotractStatStrSetMap.put(cc.Customer__c, new Set<String> {cc.Contract__r.Status__c});
                }
            }               
        }
        
        Boolean hasActiveContract;
        
        //updated Accounts that have active Contracts
        if(!acctID_cotractStatStrSetMap.isEmpty()) {
            for(Account acct : [SELECT ID, On_Contract__c FROM Account WHERE ID IN :acctID_cotractStatStrSetMap.keySet()]) {
                
                hasActiveContract = false;
                
                for(String stat : acctID_cotractStatStrSetMap.get(acct.ID)) {
                    if(stat == Label.Active) {
                        hasActiveContract = true;
                        break;
                    }
                }
                
                if(hasActiveContract)
                    acct.On_Contract__c = Label.Yes;
                else 
                    acct.On_Contract__c = Label.No; 
                
                acctsToUpdateList.add(acct);
            }
            
            if(!acctsToUpdateList.isEmpty()) {
                try {
                    update acctsToUpdateList;
                }catch(Exception e) {
                    //add logger here 
                }
            }
        }
    }
}