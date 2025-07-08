/*******************************************************************************************************
* Class Name      	: SM_Store
* Description		: Domain / Service layer for Store
* Author          	: Simplus - Philip Clark
* Created On      	: 19/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          19/06/2020		1000				Initial version
* Yi Zhang              19/08/2020		2000				Revamp all resulted from requirement change
* Simplus MS            18/10/2021      3000                Added logic for CCRM15-79: Update related store member records 
* Simplus MS 			18/01/2022		4000				Updated methods: updateUserAddress, storeAddressUpdated for CCRM15-566:  TS onboarding email - Update fields for user's email address
******************************************************************************************************/
public without sharing class SM_Store { 
    
    public static final List<String> STORE_LOCATION_TYPES_WITH_SALES_REP = new List<String>{
        'Small Format Store', 'Frame and Truss Plant', 'Trade Distribution Centre', 'Warehouse'
    };
    public static final List<String> STORE_LOCATION_TYPES_FOR_ADDRESS_UPDATE = new List<String>{
        'Small Format Store', 'Trade Distribution Centre', 'Warehouse'
    };
	
    /**
    * @description 
    * @author Philip Clark | 19/06/2020 
    * @param newMap
    **/
    public static void afterInsert(Map<Id,Store__c> newMap) {

        createStoreMembers(newMap);

        createSalesReps(newMap);

    }

    /**
    * @description 
    * @author Yi Zhang | 27/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Store__c> oldMap, Map<Id, Store__c> newMap) {

        updateSalesRepIds(oldMap, newMap);

        updateUserAddress(oldMap, newMap);
        
        updateStoreMembers(oldMap, newMap); //CCRM15-79: Update store member records to recalculate team member call % if store call % is changed
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param newMap 
    **/
    public static void createSalesReps(Map<Id, Store__c> newMap) {
        // get sales rep record type & country based on store's country
        Map<Id, Sales_Rep__c> salesReps = new Map<Id, Sales_Rep__c>();  // key is store Id
        for(Store__c store : newMap.values()) {
            if(String.isNotBlank(store.Location_Type__c) && STORE_LOCATION_TYPES_WITH_SALES_REP.contains(store.Location_Type__c)) {
                Sales_Rep__c sr = new Sales_Rep__c();
                sr.RecordTypeId = (store.Country__c == Constants.COUNTRY_NZ) ? DM_RecordType.rtId_SalesRep_Nz : DM_RecordType.rtId_SalesRep_Au;
                sr.Country__c = (store.Country__c == Constants.COUNTRY_NZ) ? Constants.COUNTRY_NZ : Constants.COUNTRY_AU;
                sr.Status__c = Constants.STATUS_ACTIVE;
                sr.Assigned_to_Store__c = store.Id;
                sr.Sales_Rep_Legacy_ID__c = store.Sales_Rep_ID__c;

                salesReps.put(store.Id, sr);    
            }
        }

        System.debug(LoggingLevel.DEBUG, 'salesReps: ' + JSON.serialize(salesReps));

        if(salesReps.size() > 0) {
            try {
                insert salesReps.values();
            } catch(Exception e) {
                ApplicationLogger.log('SM_Store.createSalesReps', 'Store__c', 'Trigger', e);
            }
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param newMap 
    **/
    public static void createStoreMembers(Map<Id,Store__c> newMap) {
        // collect all operations region codes, and stores with codes
        List<String> opRegCodes = new List<String>();
        List<Store__c> storesWithOpRegCode = new List<Store__c>();
        for(Store__c store : newMap.values()) {
            if(String.isNotBlank(store.Operations_Region_Code__c)) {
                storesWithOpRegCode.add(store);
                opRegCodes.add(store.Operations_Region_Code__c);
            }
        }
        if(opRegCodes.isEmpty()) {
            return;
        }

         
        List<String> roles = new List<String>{Constants.STOREMEMBER_SSM_ROLENAME, Constants.STOREMEMBER_RCM_ROLENAME, Constants.STOREMEMBER_AREA_BDM_ROLENAME, Constants.STOREMEMBER_CCS_MANAGER_ROLENAME};
        // get related operations regions
        List<Operations_Region__c> opRegs = DM_OperationsRegion.getOpRegs(opRegCodes, roles);
        if(opRegs.isEmpty()) {
            return;
        }
        

        // group opRegs into Map
        Map<String, List<Operations_Region__c>> opRegCodeUsersMap = new Map<String, List<Operations_Region__c>>();
        for(Operations_Region__c opReg : opRegs) {
            if(opRegCodeUsersMap.containsKey(opReg.Name) == false) {
                opRegCodeUsersMap.put(opReg.Name, new List<Operations_Region__c>());
            }
            opRegCodeUsersMap.get(opReg.Name).add(opReg);
        }

        List<Store_Member__c> members = new List<Store_Member__c>();
        List<Task> tasks = new List<Task>();
        for(Store__c store : storesWithOpRegCode) {
            if(opRegCodeUsersMap.containsKey(store.Operations_Region_Code__c)) {
                for(Operations_Region__c opReg : opRegCodeUsersMap.get(store.Operations_Region_Code__c)) {
                    members.add(new Store_Member__c(
                        Store__c = store.Id,
                        Role__c = opReg.Role__c,
                        Status__c = Constants.STOREMEMBER_ACTIVE_STATUS,
                        Start_Date__c = Date.today(),
                        Team_Member__c = opReg.Team_Member__c
                    ));
                    if(opReg.Role__c == Constants.STOREMEMBER_SSM_ROLENAME) {
                        tasks.add(SM_Task.createTask(
                            store.Id, 
                            opReg.Team_Member__c,
                            'Assign ASM', 
                            'Please assign an ASM for store '+ store.Name, 
                            Date.today()));
                    }
                }
            }
        }

        try {
            if(members.size() > 0) {
                insert members;
            }
            if(tasks.size() > 0) {
                insert tasks;
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_Store.afterInsert', 'Store__c', 'Trigger', e);
        }
    }
    
    /**
    * @description      Update corresponding Sales Rep records' Sales Rep Legacy Id when Sales Rep ID on Store changes
    * @author Yi Zhang | 27/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateSalesRepIds(Map<Id, Store__c> oldMap, Map<Id, Store__c> newMap) {
        List<Id> storeIds = new List<Id>();
        for(Store__c oldStore : oldMap.values()) {
            Store__c newStore = newMap.get(oldStore.Id);
            if(oldStore.Sales_Rep_ID__c != newStore.Sales_Rep_ID__c) {
                storeIds.add(newStore.Id);
            }
        }
        if(storeIds.isEmpty()) {
            return;
        }

        // System.debug(LoggingLevel.DEBUG, 'storeIds: ' + storeIds);

        // System.debug(LoggingLevel.DEBUG, 'salesReps: ' + DM_SalesRep.getActiveSalesRepsWithStoreIds(storeIds));

        // find all active sales reps associated
        List<Sales_Rep__c> salesReps = new List<Sales_Rep__c>();
        for(Sales_Rep__c salesRep : DM_SalesRep.getActiveSalesRepsWithStoreIds(storeIds)) {
            // only when the Current Sales Rep ID not the same as Store's, do the update on Legacy Id
            // this is to avoid looping
            if(salesRep.Category__c == SM_SalesRep.CATEGORY_DEFAULT && salesRep.Current_Sales_Rep_ID__c != salesRep.Assigned_to_Store__r.Sales_Rep_ID__c) {
                salesRep.Sales_Rep_Legacy_ID__c = salesRep.Assigned_to_Store__r.Sales_Rep_ID__c;
                salesReps.add(salesRep);
            }
        }

        System.debug(LoggingLevel.DEBUG, 'salesReps: ' + salesReps);

        if(salesReps.size() > 0) {
            try {
                update salesReps;
            } catch(Exception e) {
                ApplicationLogger.log('SM_Store.updateSalesRepIds', 'Store__c', 'Trigger', e);
            }
        }
    }
    

    /**
    * @description 
    * @author Yi Zhang | 22/10/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateUserAddress(Map<Id, Store__c> oldMap, Map<Id, Store__c> newMap) {
        // key = location code
        Map<String, Store__c> storesAddressUpdatedMap = new Map<String, Store__c>();
        for(Store__c newStore : newMap.values()) {
            Store__c oldStore = oldMap.get(newStore.Id);
            if(storeAddressUpdated(oldStore, newStore)) {
                storesAddressUpdatedMap.put(newStore.Location_Code__c, newStore);
            }
        }
        if(storesAddressUpdatedMap.isEmpty()) {
            return;
        }

        // query all active users based on location code
        List<User> usersToUpdate = new List<User>();
        for(User user : [SELECT Id, Location_Code__c, Store_Email__c FROM User WHERE Location_Code__c IN :storesAddressUpdatedMap.keySet() AND isActive = true]) {
            usersToUpdate.add(SM_User.mapStoreAddressToUserAddress(user, storesAddressUpdatedMap.get(user.Location_Code__c)));
        }
        if(usersToUpdate.isEmpty() == false) {
            SM_User.updateUsersAsync(JSON.serialize(usersToUpdate), 'SM_Store.updateUserAddress', 'Store__c');
        }
    }

    private static Boolean storeAddressUpdated(Store__c oldStore, Store__c newStore) {
        // store's address changed
        // store is active
        // store location type is one of 3
        // store's location code is not empty
        // store's TS email changed
        return 
            (oldStore.Address_Line_1__c != newStore.Address_Line_1__c || 
            oldStore.Address_Line_2__c != newStore.Address_Line_2__c || 
            oldStore.Address_Line_3__c != newStore.Address_Line_3__c || 
            oldStore.City__c != newStore.City__c || 
            oldStore.State__c != newStore.State__c || 
            oldStore.Postcode__c != newStore.Postcode__c || 
            oldStore.Country__c != newStore.Country__c ||
			oldStore.Trade_Specialist_Email__c != newStore.Trade_Specialist_Email__c) //Added by Simplus MS 18.Jan.2022 for CCRM15-566
            && STORE_LOCATION_TYPES_FOR_ADDRESS_UPDATE.contains(newStore.Location_Type__c)
            && newStore.Status__c == Constants.STATUS_ACTIVE
            && String.isNotBlank(newStore.Location_Code__c)
            ;
    }
    
    /**
    * @description Update related store member records
    * @author Simplus MS | 20/10/2021 
    * @param oldMap, newMap
    **/
	public static void updateStoreMembers(Map<Id, Store__c> oldMap, Map<Id, Store__c> newMap) {
		Set<Id> storeIdSet = new Set<Id>();
        for(Store__c oldStMem : oldMap.values()) {
            Store__c newStMem = newMap.get(oldStMem.Id);
            if(oldStMem.Store_Call__c != newStMem.Store_Call__c ||
               oldStMem.Country__c != newStMem.Country__c ||
               oldStMem.Location_Type__c != newStMem.Location_Type__c ||
               oldStMem.Engagement_Model__c != newStMem.Engagement_Model__c) 
            {
            	storeIdSet.add(newStMem.Id);
            }
        }      
        
        List<Store_Member__c> members = [SELECT Id, Store__c, Team_Member_Call__c, Call_Volume__c 
                                           FROM Store_Member__c 
                                          WHERE Store__c IN: storeIdSet AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME ];
		System.debug('members*'+members);
        try {
            if(members.size() > 0) {
                update members;
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_Store.afterUpdate', 'Store_Member__c', 'Trigger', e);
        }  
    }
}