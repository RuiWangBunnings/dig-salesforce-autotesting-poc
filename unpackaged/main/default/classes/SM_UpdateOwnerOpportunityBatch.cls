/*******************************************************************************************************
* Class Name      	: SM_UpdateOwnerOpportunityBatch
* Description		: Temporary Batch class for updating owner of Opportunity and Order
* Author          	: Simplus - MS
* Created On      	: 17/05/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            17/05/2021		1000				Initial version
******************************************************************************************************/
public class SM_UpdateOwnerOpportunityBatch implements Database.Batchable<sObject>{
    
    String query;
    List<String> includedUsers = new List<String> {'Integration User','Migration User'};
        
    public SM_UpdateOwnerOpportunityBatch(){
        query = 'SELECT Id, OwnerId, Account.OwnerId ' +
            'FROM Opportunity WHERE AccountId != null AND Owner.Name In :includedUsers';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        // execute code
        System.debug('Scope ::' +scope);
        List<Opportunity> updateList = new List<Opportunity>();
		
        try {
			for (Opportunity oppty : scope){
				if (oppty.OwnerId != oppty.Account.OwnerId){
				
					//update Opportunity Owner based on Account's Owner
                    oppty.OwnerId = oppty.Account.OwnerId;
                    updateList.add(oppty);
				}
			}
            system.debug('updateList size ::' +updateList.size());
            update updateList;
            
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    public void finish(Database.BatchableContext BC) {
        // finish code
    }
    
}