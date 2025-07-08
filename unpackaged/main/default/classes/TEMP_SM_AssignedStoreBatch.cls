/*******************************************************************************************************
* Class Name      	: TEMP_SM_AssignedStoreBatch
* Description		: Temporary batch class to update legacy accounts where the assigned store is not the same as the location code on the Account owner (CCRM15-109 AC2)
* Author          	: Simplus MS
* Created On      	: 24/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus.MS / RLugpatan    24/08/2021		1000				Initial version
******************************************************************************************************/
public class TEMP_SM_AssignedStoreBatch implements Database.Batchable<sObject> {
    
    String query;
    
    public TEMP_SM_AssignedStoreBatch() {
        query = 'Select Id, Assigned_Store__c, Assigned_Store__r.Location_Code__c, Owner.Location_Code__c ' +
                'From Account ' +
                'Where Owner.Profile.Name IN (\'' + Constants.AU_TRADE_SPECIALIST_PROFILEENAME + '\', \'' + Constants.NZ_TRADE_SPECIALIST_PROFILEENAME + '\') ';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // execute code
        system.debug('Scope :: ' +scope);
        
        List<Account> lAccountToUpdate = new List<Account>();
        List<Account> lAccountsWithAssignedStore =  new List<Account>();
        Map<ID, ID> acctID_ownerIDMap = new Map<ID, ID>();
        Map<ID, ID> acctID_storeIDMap = new Map<ID, ID>();
        
        try {
            for(Account acct : scope) {
                if(acct.Assigned_Store__r.Location_Code__c != acct.Owner.Location_Code__c){
                    lAccountsWithAssignedStore.add(acct);
                    acctID_ownerIDMap.put(acct.ID, acct.OwnerID);
                }
            }   
            
            if(!lAccountsWithAssignedStore.isEmpty()){
                acctID_storeIDMap = SM_Account.mapAssignedStore(lAccountsWithAssignedStore, acctID_ownerIDMap);
            }
            
            for(Account acct : lAccountsWithAssignedStore) {
                if(!acctID_storeIDMap.isEmpty() && acctID_storeIDMap.containsKey(acct.ID)) {
                    acct.Assigned_Store__c = acctID_storeIDMap.get(acct.ID);
                    lAccountToUpdate.add(acct);
                }
            }
            
            if (lAccountToUpdate.size() > 0){
                update lAccountToUpdate;
            }

        } catch(Exception e) {
            ApplicationLogger.log('TEMP_SM_AssignedStoreBatch', 'Account', 'Batch', e);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code
    }
    
}