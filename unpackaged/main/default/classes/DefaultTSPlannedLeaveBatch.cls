/*******************************************************************************************************
* Class Name      	: DefaultTSPlannedLeaveBatch
* Description		: Batch class to Update Default Trade Specialist of Store as per Planned Leave for CCRM15-417
* Author          	: Simplus MS
* Created On      	: 29/11/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus.MS                29/11/2021		1000				Initial version
******************************************************************************************************/
global class DefaultTSPlannedLeaveBatch implements Database.Batchable<sObject> {
    
    String query;
    
    public DefaultTSPlannedLeaveBatch() {
        query = 'SELECT Start_Date__c, End_Date__c, OwnerId ' +
            'FROM Planned_Leave__c ' +
            'WHERE Status__c = \'Approved\' AND (Start_Date__c = TODAY OR End_Date__c = TODAY)';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Planned_Leave__c> scope) {
        try {
            updateDefaultTSOfStore(scope);  
        } catch(Exception e) {
            ApplicationLogger.log('DefaultTSPlannedLeaveBatch', 'Planned_Leave__c', 'Batch', e);
        }
    }
    
    
    public void finish(Database.BatchableContext BC) {
        // Actions to be carried out on finish of batch job
    }
    
    /**
* @description : Update Default Trade Specialist of Store as per Planned Leave for CCRM15-417
* @author Simplus MS | 29/11/2021
* @param Scope 
**/
    public void updateDefaultTSOfStore(List<Planned_Leave__c> lstPlannedLeave) {

            Set<Id> OwnerIds = new Set<Id>();
            if(lstPlannedLeave.size() > 0) {
                for(Planned_Leave__c plObj:lstPlannedLeave){
                    OwnerIds.add(plObj.OwnerId);
                }
            }
            
            List<Initialisation__mdt> filterRCMProfileList = [SELECT Id, Default_TS_Auto_Selection_Exemption__c FROM Initialisation__mdt];
            
            //String strProfilesOFTSAndRCM = filterRCMProfileList[0].RCM_Profiles__c + ',' + filterRCMProfileList[0].Trade_Specialist_Profiles__c;
            List<String> profilesOFRCMList = new List<String> {filterRCMProfileList[0].Default_TS_Auto_Selection_Exemption__c.replaceAll(',(\\s+)', ',')};
                
                List<Store_Member__c> storeMemList = [SELECT Id, Default_Trade_Specialist__c, Team_Member__r.Name, Store__c, LastModifiedBy.Profile.Name 
                                                      FROM Store_Member__c 
                                                      WHERE Team_Member__c IN  :OwnerIds
                                                      AND Default_Trade_Specialist__c = TRUE
                                                      AND LastModifiedBy.Profile.Name NOT IN :profilesOFRCMList];
            Set<Id> storeIds = new Set<Id>();
            if(storeMemList.size() > 0) {
                for(Store_Member__c storeMem:storeMemList){
                    storeIds.add(storeMem.Store__c);
                }
            }
            
            Map<Id, Integer> storePLTSCount = new Map<Id, Integer>();
            for(Store__c store : DM_Store.getStoresWithActiveTSList(new List<Id>(storeIds), null)) {
                storePLTSCount.put(store.Id, store.User_Stores__r.size());
            }
            
            List<Store_Member__c> lstOfStoreMembersToUpdate = new List<Store_Member__c>();
            if(storeMemList.size() > 0) {
                for(Store_Member__c smObj : storeMemList) {
                    if(storePLTSCount.get(smObj.Store__c) > 0 
                        && !filterRCMProfileList[0].Default_TS_Auto_Selection_Exemption__c.contains(smObj.LastModifiedBy.Profile.Name)){
                        lstOfStoreMembersToUpdate.add(new Store_Member__c(Id = smObj.Id, Default_Trade_Specialist__c = FALSE));
                    }
                }
            }
            
            if(lstOfStoreMembersToUpdate.size() > 0) {
                try {
                    Update lstOfStoreMembersToUpdate;
                } catch(Exception e) {
                    ApplicationLogger.log('DefaultTSPlannedLeaveBatch', 'Planned_Leave__c', 'Batch', e);
                }
            }    
    }
}