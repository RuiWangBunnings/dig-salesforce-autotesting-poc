/*******************************************************************************************************
* Class Name      	: SM_BulkAccountRequestTransferBatch
* Description		: Batch class for transfer bulk accounts requests
* Author          	: Sowjanya
* Created On      	: 20/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          20/07/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/
public class SM_BulkAccountRequestTransferBatch implements Database.Batchable<sObject>,Database.Stateful{
	String query;
    String transferFromId;
    String transferToId;
    String newContractOwnerId;
    String selectedOption;
    Map<id,List<Account>> accOldIdAccListMap = new Map<id,List<Account>>();
    Map<id,id> accOldNewOwnerMap = new Map<id,id>();
    List<Account_Request__c> updateAcctReqList = new List<Account_Request__c>(); 
    Map<id,id> acctoAccReqMap = new Map<id,id>();
    String status= 'Pending Transfer';
    String type= 'Bulk Account Transfer';
    public SM_BulkAccountRequestTransferBatch() {
        query = 'SELECT Id, Name, PowerPass_Account_Number__c, New_Owner__c, Account__c,Previous_Owner__c'
                + ' FROM  Account_Request__c '
                + ' WHERE Status__c = :status '
                 + ' AND Type__c =:type '
                + ' Order by CreatedDate';
        System.debug('Query-->' +query);
               
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Account_Request__c> scope) {
        // execute code
        
        try {
               
            
            Set<Id> acctIds = new Set<Id>();
            Map<id,String> accNewOwnerMap=new Map<id,String>();
            system.debug('scope in main batch:'+scope);
            for(Account_Request__c a : scope){
                if(a.Account__c != null){
                    acctIds.add(a.Account__c);   
                    accNewOwnerMap.put(a.Account__c,a.New_Owner__c);
                    updateAcctReqList.add(a);
                    acctoAccReqMap.put(a.Account__c,a.id);

                }
                
            }
        
                
            if(acctIds!=null){
                List<Account> accList =[Select Ownerid, id from Account Where id IN :acctIds];
                system.debug('accList'+ accList);
                for(Account ac: accList){
                    if(accOldIdAccListMap.get(ac.Ownerid) == NULL)
                    {
                         accOldIdAccListMap.put(ac.Ownerid,new List<Account>());
                    }
                    accOldIdAccListMap.get(ac.Ownerid).add(ac);

                    if(accOldNewOwnerMap.get(ac.Ownerid) == NULL)
                    {
                        accOldNewOwnerMap.put(ac.Ownerid,accNewOwnerMap.get(ac.id));

                        
                    }
                }
            }
                        
            
        } catch(Exception e) {
            ApplicationLogger.log('SM_BulkAccountRequestTransferBatch.execute', 'AccountRequest', 'Batch Apex', e);
            
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code

        try {

            for(id ownid : accOldIdAccListMap.keySet()){
                List<Account> acList = accOldIdAccListMap.get(ownid);
                set<id> idList = new Set<id>();
                for(Account ac : acList){
                    	idList.add(ac.id);
                    
                }
                List<Account_Request__c> updateARList = DM_AccountRequest.getAccountTransferRequestsByAccid(idList);
                 Map<id,id> aToARMap = new Map<id,id>();
                for(Account_Request__c ar : updateARList){
                    aToARMap.put(ar.Account__c,ar.id);
                }
                System.debug('ownid-->'+ownid); 
                 System.debug('acList-->'+acList);
                  System.debug('idList-->'+idList); 
                System.debug('updateARList-->'+updateARList); 
                System.debug('aToARMap-->'+aToARMap); 
                SM_BulkAccountAndRelatedTransferBatch batchJob = new SM_BulkAccountAndRelatedTransferBatch(updateARList,acList,ownid,accOldNewOwnerMap.get(ownid),accOldNewOwnerMap.get(ownid),'Account Transfer',aToARMap);
                Id batchJobId = Database.executeBatch(batchJob,10000);
                System.debug('this.batchJobId-->' +batchJobId);
                
                
            }
        } catch (Exception e) {
            
            ApplicationLogger.log('SM_BulkAccountRequestTransferBatch.finish', 'AccountRequest', 'Batch Apex', e);
        }

        
    
    }
    
}