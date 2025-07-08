/*******************************************************************************************************
* Class Name      	: SM_BatchAccountDetailsUpdate
* Description		: Batch class for bulk update account number and identification number
* Author          	: Bunnings dev
* Created On      	: 22/10/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          22/10/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/

public class SM_BatchAccountDetailsUpdate implements Database.Batchable<sObject>{
    String query;
    String personRecordType = DM_RecordType.rtId_Account_PersonAccount;
    public SM_BatchAccountDetailsUpdate() {
            query = 'SELECT Id, Name, Power_Pass_Account_Number__c, Country__c '
                    + ' FROM  Account'
                    + ' WHERE (Account_Number__c = null OR Account_Identification__c = null)'
            		+ ' AND Power_Pass_Account_Number__c != null AND RecordTypeId != :personRecordType' ;
            System.debug('Query-->' +query);
                   
        }
    public Database.QueryLocator start(Database.BatchableContext BC) {
            return Database.getQueryLocator(query);
        }
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // execute code
       
               System.debug('scope:'+scope);
            List<Account> lstAccUpd = new List<Account>();
            for(Account a : scope){
             	AccountTriggerHandler.updateAccountNumberandAccountIdentificaton(scope);
                lstAccUpd.add(a);
                
            }


            if(lstAccUpd!=null && !lstAccUpd.isEmpty()){
                try {
					List<Database.SaveResult> accountResults = Database.update(lstAccUpd, false);
                        
                        for (Database.SaveResult result : accountResults) {
                     
                            if (!result.isSuccess()){
                                for (Database.Error err : result.getErrors()){
                          		 ApplicationLogger.log('SM_BatchAccountDetailsUpdate.updateAccounts', 'Account', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                               	 System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                                }
                            }
                        }

                }
         catch(Exception e) {
            ApplicationLogger.log('SM_BatchAccountDetailsUpdate.execute', 'Account', 'Batch Apex', e);
            
        }
    }
    }
    
    public void finish(Database.BatchableContext BC) {
        
        // finish code
 
    }
}