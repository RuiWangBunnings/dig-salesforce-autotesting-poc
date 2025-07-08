/*******************************************************************************************************
* Class Name      	: SM_SyncCallVolumesBatch
* Description		: Batch class to update Call Volumes of store members when needed 
* Author          	: Simplus - MS
* Created On      	: 15/12/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            15/12/2021		1000				Initial version [CCRM15-487]
******************************************************************************************************/
public class SM_SyncCallVolumesBatch implements Database.Batchable<sObject> {
    
    String query;
    
    public SM_SyncCallVolumesBatch() {
        
        query = 'SELECT Id, Batch_Update__c ' +
            ' FROM Store_Member__c ' + 
            ' WHERE Status__c = \'' + Constants.STOREMEMBER_ACTIVE_STATUS + '\' ' + 
            ' AND Role__c = \'' + Constants.STOREMEMBER_TS_ROLENAME + '\' ' + 
            ' AND Team_Member__r.IsActive = true ' + 
            ' AND Team_Member__r.Is_TS__c = true ' + 
            ' AND Store__r.Engagement_Model__c != null ' +
            ' ORDER BY Id ASC';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query: '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Store_Member__c> scope) {
        // execute code
        System.debug('scope: '+scope);

        List<Store_Member__c> lStoreMembersToUpdate = new List<Store_Member__c>();
        Boolean isToggle = FALSE;

        for(Store_Member__c member : scope) {
            System.debug('member: '+member);
            //just toggling the Batch_Update__c for the sake of running 
            //the isUpdate context of trigger for SM_StoreMember.calculateCallVolume logic
            member.Batch_Update__c = member.Batch_Update__c == isToggle ? TRUE : FALSE;
            lStoreMembersToUpdate.add(member);
        }
        
        try {
            if (!lStoreMembersToUpdate.isEmpty()){
                update lStoreMembersToUpdate;
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_SyncCallVolumesBatch', 'Store Member', 'Batch', e);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code
    }
}