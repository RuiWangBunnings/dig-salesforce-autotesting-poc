/*******************************************************************************************************
* Class Name      	: SM_BulkAccountAndRelatedTransferBatch
* Description		: Batch class for transfer bulk accounts
* Author          	: Bunnigs Dev
* Created On      	: 20/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          20/07/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/
public class SM_BulkAccountAndRelatedTransferBatch implements Database.Batchable<sObject>,Database.Stateful{
    String query;
    String transferFromId;
    String transferToId;
    String newContractOwnerId;
    String comments;
    
  
    List<Account> lSelectedAccounts = new List<Account>();
    List<Account_Request__c> lUpdateAccountRequests = new List<Account_Request__c>();
    Map<id,id> acctoAccReqMap = new Map<id,id>();

    public SM_BulkAccountAndRelatedTransferBatch(List<Account_Request__c> lUpdateAccountReqs, List<Account> lSelectedAccounts, Id transferFromUserId, Id transferToUserId, String newContractOwner, String comments,Map<id,id> acctoAccRequestMap) {
        
        
        transferFromId = transferFromUserId;
        transferToId = transferToUserId;
        newContractOwnerId = newContractOwner;
        comments = comments;
        lSelectedAccounts = lSelectedAccounts;
        lUpdateAccountRequests = lUpdateAccountReqs;
        acctoAccReqMap = acctoAccRequestMap;

        System.debug('transferFromId-->' +transferFromId);
        System.debug('transferToUserId-->' +transferToUserId);
        System.debug('this.newContractOwner-->' +newContractOwnerId);
        System.debug('lUpdateAccountRequests-->' +lUpdateAccountRequests);
        System.debug('acctoAccReqMap-->' +acctoAccReqMap);

            List<Id> sAccountIds = new List<Id>();
            for (Account acc : lSelectedAccounts){
                sAccountIds.add(acc.Id);
            }
            String idString= '\''+String.join(sAccountIds,'\',\'')+'\'';
            system.debug('sAccountIds ' +sAccountIds);
            query = 'SELECT Id, Name, Power_Pass_Account_Number__c, PowerPass_Account_Created_Date__c, On_Contract__c, '
                + ' Account_State__c, BillingAddress, Assigned_Store__r.Name, Primary_Segment__c, '
                + ' Secondary_Segment__r.Name, Account_Transferrable__c '
                + ' FROM Account'
                + ' WHERE Id IN (' +idString+ ')';
        
        
        System.debug('Query-->' +query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);

        
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // execute code
        System.debug('Scope ::' +scope);
        
        try {
            List<Account> updateAcctList = new List<Account>();
            List<Account> acctList = new List<Account>();
            List<Contract__c> contractList = new List<Contract__c>();
            
            
            for(Account a : scope){
                if(a.Account_Transferrable__c == 'Yes'){
                    Account acc = new Account();
                    acc.Id = a.Id;
                    acc.OwnerId = transferToId;
                    acc.Bulk_Account_Transfer__c = true;
                    acc.Transfer_comments__c = comments;
                    updateAcctList.add(acc);
                      
                }
                
            }
            Set<Id> ownerIds = new Set<Id>();
            ownerIds.add(transferFromId);
            List<id> resultSet = new List<id>();
            List<id> resultSetError = new List<id>();
            
            if(updateAcctList!=null && !updateAcctList.isEmpty()){
                try {

                   
                        List<Database.SaveResult> accountResults = Database.update(updateAcctList, false);
                        
                        for (Database.SaveResult result : accountResults) {
                            if (result.isSuccess()){
                                resultSet.add(result.getId());
                            }
                        if (!result.isSuccess()){
                            for (Database.Error err : result.getErrors()){
                            resultSetError.add(result.getId());

                             ApplicationLogger.log('SM_BulkAccountAndRelatedTransferBatch.updateAccounts', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                            System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                            }
                        }
                        }
                 
                    system.debug('resultSet here :: '+resultSet);
                    List<Account> accListToUpdate = DM_Account.getAccounts(resultSet);
                   Map<id,id> accReqMap =new Map<id,id>();
                  
                   if( !resultSet.isEmpty() || resultSet != null){
                        for(id key : resultSet ){
                            accReqMap.put(acctoAccReqMap.get(key),key);

                        }
                    }

                        system.debug('accReqMap here :: '+accReqMap);
                    system.debug('lUpdateAccountRequests here :: '+lUpdateAccountRequests);
                    SM_AccountRequestTransfer.transferAccountRelatedRecords(accListToUpdate, transferFromId, transferToId,lUpdateAccountRequests,accReqMap);
                    
                    Set<Id> acctIds = new Set<Id>(resultSet);
                    if(acctIds!=null){
                        List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
                        System.debug('newContractOwnerId::' +newContractOwnerId);
                        User managerIdUser = DM_User.getUser(newContractOwnerId);
                        System.debug('managerIdUser-->' +managerIdUser);
                        if(contracts!=null && !contracts.isEmpty()){
                            for(Customer_Contract__c cusContract : contracts){
                                if(cusContract.Customer__r.Account_Transferrable__c == 'Yes'){
                                    Contract__c contract = new Contract__c();
                                    contract.Id = cusContract.Contract__r.Id;
                                    contract.OwnerId = newContractOwnerId;
                                    contract.New_Reviewer__c = newContractOwnerId;
                                    contract.New_Approver__c = managerIdUser.ManagerId;
                                    contractList.add(contract);
                                }
                            }
                        }
                    }
                   
                    if(contractList!=null && !contractList.isEmpty()){
                        system.debug('contractList here :: '+contractList);
                        List<Database.SaveResult> contractResults = Database.update(contractList, false);
                        for (Database.SaveResult result : contractResults) {
                        if (!result.isSuccess()){
                            for (Database.Error err : result.getErrors()){
                            ApplicationLogger.log('SM_BulkAccountAndRelatedTransferBatch.updateContracts', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                            System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                            }
                        }
                        }
                        
                    } 
                    
                    
                } catch (Exception ex) {
                    System.debug(ex.getStackTraceString());
                    SM_AccountRequestTransfer.sendBulkAccountTransferErrorNotification(transferFromId);
                }
            }
            
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code
        SM_AccountRequestTransfer.sendBulkAccountTransferNotification(transferToId);
    }
    

    
    
}