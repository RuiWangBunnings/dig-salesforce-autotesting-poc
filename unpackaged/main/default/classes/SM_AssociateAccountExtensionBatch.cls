/*******************************************************************************************************
* Class Name      	: SM_AssociateAccountExtensionBatch
* Description		: Batch class to associate Account Extension Record to Account record per PowerPass Number
* Author          	: Bunnings Salesforce Team
* Created On      	: 25/05/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings SFDC Team 	25/05/2022		1000				Initial version for SFSUP-725
******************************************************************************************************/
public class SM_AssociateAccountExtensionBatch implements Database.Batchable<sObject>, Schedulable{
	
    String accountQuery;
	
	public SM_AssociateAccountExtensionBatch(){
        accountQuery = 'Select Id,Account_Extension__c, Account_Status__c,Home_Store__c,Country__c,Power_Pass_Account_Number__c,Do_Not_Call__c,';
        accountQuery += 'Onboarding_Status__c,ParentId,OwnerId,';
        accountQuery += 'Call_Cycle_Ranking__c,Call_Priority__c,Call_Reason__c,PowerPass_Account_Created_Date__c From Account ';
        accountQuery += 'Where Account_Status__c != \'' + 'Inactive' +'\' ';
        accountQuery += 'AND Account_Status__c != \'' + 'Terminated' +'\' ';
        accountQuery += 'AND RecordType.Name != \'' + 'Person Account' +'\' ';
        accountQuery += 'AND Country__c != null AND Power_Pass_Account_Number__c != null AND Account_Extension__c = null';
	}
    
    public Database.QueryLocator start(Database.BatchableContext BC) {                     
        System.debug('accountQuery>> '+accountQuery);
        return Database.getQueryLocator(accountQuery);
    }

    public void execute(Database.BatchableContext BC, List<Account> accList) {
        
        if(accList.isEmpty()){
            return;
        }
        
        Set<String> accIdSet = New Set<String>(); 
        List<Account_Extension__c> accntExtList = New List<Account_Extension__c>();
        List<Account> accntToUpdateList = New List<Account>();
        Map<String, Id> accntExtMap = New Map<String, Id>();
        
        for(Account accnt : accList){
            accIdSet.add(accnt.Power_Pass_Account_Number__c);
        }
        
        accntExtList = [SELECT Id, Account_Number__c FROM Account_Extension__c WHERE Account_Number__c IN:accIdSet];
        
        if(accntExtList.isEmpty()){
            return;
        }
        
        for(Account_Extension__c accExtRecord : accntExtList){
            accntExtMap.put(accExtRecord.Account_Number__c, accExtRecord.Id); 
        }
        
        for(Account accnt : accList){
            if(accntExtMap.containsKey (accnt.Power_Pass_Account_Number__c) ){
                accnt.Account_Extension__c = accntExtMap.get(accnt.Power_Pass_Account_Number__c);
                accntToUpdateList.add(accnt);
            }
        }
        
        if(accntToUpdateList.size() != 0){
            /*try{
            	update accntToUpdateList;                
            } catch(Exception e) {
            	ApplicationLogger.log('SM_AssociateAccountExtensionBatch', 'Account', 'Batch', e);
        	}*/
            List<Database.SaveResult> results = Database.update(accntToUpdateList, false);
            for (Database.SaveResult result : results) {
              if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                  System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                }
              }
            }
        } 
    }

    public void finish(Database.BatchableContext BC) {
		AsyncApexJob asyncJob = [SELECT 
									Id, 
									Status, 
									NumberOfErrors, 
									JobItemsProcessed,
									TotalJobItems, CreatedBy.Email
								FROM AsyncApexJob WHERE Id =:BC.getJobId()];
						
	    // Send an email to the Apex job's submitter notifying of job completion.
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    String[] toAddresses = new String[] {asyncJob.CreatedBy.Email};
	    mail.setToAddresses(toAddresses);
	    mail.setSubject('SM_AssociateAccountExtensionBatch ' + asyncJob.Status);
	    mail.setPlainTextBody
	    ('The batch Apex job processed ' + asyncJob.TotalJobItems +
	    ' batches with '+ asyncJob.NumberOfErrors + ' failures.');
	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_AssociateAccountExtensionBatch(), 10);
    }    
}