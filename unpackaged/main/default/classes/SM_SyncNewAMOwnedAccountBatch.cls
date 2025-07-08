/*******************************************************************************************************
* Class Name        : SM_SyncNewAMOwnedAccountBatch
* Description       : Batch class to trigger platform event for new accounts with AM as owner
* Author            : Bunnings Salesforce Team
* Created On        : 19/08/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings SFDC Team    19/08/2022      1000                Initial version
******************************************************************************************************/
public class SM_SyncNewAMOwnedAccountBatch implements Database.Batchable<sObject>, Schedulable {
    
    String query;

    public SM_SyncNewAMOwnedAccountBatch() {
        String joinedString = '';
        String dateRange = '';
        
        try {
            List <User> excludedUserList = [SELECT Id from User WHERE Name in ('Default User','Default UserNZ','Integration User')];
            if(!excludedUserList.IsEmpty()){
                for(User u : excludedUserList){
                   joinedString += '\'' + u.Id + '\', '; 
                }
                
				if (joinedString.endsWith(', ')) {
                    joinedString = joinedString.removeEnd(', ');
                }
            }
               
			System.debug('+++joinedString: '+joinedString);
            
            Initialisation__mdt config = DM_Initialisation.ccrmInitialisation;
			dateRange = config.SyncAccount_Date_Range__c;
            System.debug('+++dateRange: '+ dateRange);
            
			query = 'SELECT Id FROM Account ' + 
					'WHERE Owner.Is_TS__c = false ' +
					'AND Power_Pass_Account_Number__c != null ' +
					'AND Owner.Sales_Rep_Id__c != null ';
            if(joinedString != null && joinedString != '')
            	query += 'AND OwnerId NOT IN (' + joinedString + ') '; 
            
            if(dateRange != '' && dateRange != null){
                query += 'AND CreatedDate = ' + dateRange;
            }else{
                query += ' AND CreatedDate = TODAY';
            }
                
		} catch(Exception e) {
			ApplicationLogger.log('SM_SyncNewAMOwnedAccountBatch', 'Account', 'Batch', e);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query: '+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('+++scope: '+scope);
        try {
			List<Object_Event_Bridge__c> newListOEB = new List <Object_Event_Bridge__c>();
			
            for(Account acc : scope) {
                System.debug('+++acc: ' + acc);
				newListOEB.add(new Object_Event_Bridge__c(Record_Id__c = acc.Id, Operation__c = 'Edit', Object_Name__c = 'Account'));
            }    
			
			if(!newListOEB.IsEmpty()){
				insert newListOEB;
			}
        } catch(Exception e) {
            ApplicationLogger.log('SM_SyncNewAMOwnedAccountBatch', 'Account', 'Batch', e);
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
        mail.setSubject('SM_SyncNewAMOwnedAccountBatch ' + asyncJob.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + asyncJob.TotalJobItems +
        ' batches with '+ asyncJob.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_SyncNewAMOwnedAccountBatch(), 10);
    }
}