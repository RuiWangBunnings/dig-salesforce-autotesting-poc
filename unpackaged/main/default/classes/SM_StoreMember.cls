/*******************************************************************************************************
* Class Name      	: SM_StoreMember
* Description		: Domain / Service layer for StoreMember
* Author          	: Simplus - Philip Clark
* Created On      	: 19/06/2020
* Modification Log	: 
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          19/06/2020		1000				Initial version
* Yi Zhang              25/08/2020		2000				Added single Active Default TS per Store 
* Simplus MS			22/04/2021      3000                Added logic for CCRM-13689 prevent multiple default TS assigned to Store
* Simplus MS 			21/05/2021 		4000 				Added logic for CCRM-13830 prevent multiple active Team Member per user to Store
* Simplus MS 			01/06/2021 		5000 				Added logic for CCRM-13832 able to uncheck the default TS and automatically checks the other active TS 
*															task is created when there is no default TS for the store
* Simplus MS            14/06/2021		6000				CCRM-13881 - Default Trade Specialist Editable by Trade Specialists
* Simplus MS            18/10/2021      7000                Added logic for CCRM15-79: Set default value of Team Member Call % and calculate call volume
* Simplus MS            02/12/2021      8000                Added logic for CCRM15-417: Planned Leave - Account Assignment and Transfers
* Simplus MS 			31/01/2022		9000				Added logic for CCRM15-394 to create task to RCM when there no DTS for Store
******************************************************************************************************/
public without sharing class SM_StoreMember {
    
    private static Boolean blnAlreadyRunOnce = false;
    //private static Boolean runForStoreTaskCreation = false;
    public static final String ERROR_ONE_ACTIVE_DEFAULT_TS_PER_STORE = System.Label.One_Default_TS_Per_Store;
    public static final String ERROR_ONE_ACTIVE_STORE_MEMBER_PER_TEAM_MEMBER = System.Label.One_Active_Team_Member_Per_User;
    public static final String ERROR_DEFAULT_TS_NOT_EDITABLE = System.Label.Error_Default_TS_Not_Editable;
    public static final String ERROR_WHEN_ONLY_ONE_DEFAULT_TS_NOT_EDITABLE = System.Label.Error_When_Only_One_Default_TS_Not_Editable;
    public static final String ERROR_WHEN_DEFAULT_TS_NOT_ACTIVE = System.label.Error_When_Default_TS_Not_Active;
    //public static final String ERROR_ONE_TEAM_MEMBER_PER_ROLE = System.Label.One_Team_Member_Per_Role;
    public static final String TEAM_MEMBER_CALL_DEFAULT_VALUE = System.label.Team_Member_Call_Default_Value;

    /**
    * @description 
    * @author Yi Zhang | 25/08/2020 
    * @param newList 
    **/
    public static void beforeInsert(List<Store_Member__c> newList) {
		System.debug('beforeInsert Store Member** ');
        List<Store_Member__c> defaultTSActiveMembers = new List<Store_Member__c>();
        Map<Id, Store__c> storeMap = DM_Store.getStoreMap(newList); //CCRM15-79: Retrieve store details to determine call baseline volume
        
        for(Store_Member__c newMember : newList) {
            //CCRM15-79: Set default value of 100% if Store Member Role is TS and Team Member Call % is empty
            if(newMember.Role__c == Constants.STOREMEMBER_TS_ROLENAME && String.isEmpty(newMember.Team_Member_Call__c)) {
            	newMember.Team_Member_Call__c = TEAM_MEMBER_CALL_DEFAULT_VALUE; 
            }
            
            //Calculate call volume
            newMember.Call_Volume__c = calculateCallVolume(storeMap.get(newMember.Store__c), newMember.Team_Member_Call__c);
            //End of CCRM15-79
            
            if(newMember.Default_Trade_Specialist__c == true && newMember.Status__c == Constants.STATUS_ACTIVE) {
                defaultTSActiveMembers.add(newMember);
            }
            
            if (newMember.Status__c != 'Active' && newMember.Default_Trade_Specialist__c) {
                newMember.addError(ERROR_WHEN_DEFAULT_TS_NOT_ACTIVE);
            }
        }
        
        singleActiveStoreMemberPerUser(newList);
        //validateRoleAndTeamMember(newList);

        system.debug('defaultTSActiveMembers'+defaultTSActiveMembers.size());
        singleActiveDefaultTradeSpecialistPerStore(defaultTSActiveMembers);
    }

    /**
    * @description 
    * @author Yi Zhang | 25/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void beforeUpdate(Map<Id, Store_Member__c> oldMap, Map<Id, Store_Member__c> newMap) {
        List<Store_Member__c> defaultTSActiveMembers = new List<Store_Member__c>();
        List<Store_Member__c> activeMembers = new List<Store_Member__c>();
        Map<Id, Store__c> storeMap = DM_Store.getStoreMap(newMap.values()); //CCRM15-79: Retrieve store details to determine call baseline volume
        
        // only examine store members which is Active Default TS after the update (either status chagned or Default TS ticked)
        for(Store_Member__c newMember : newMap.values()) {
            Store_Member__c oldMember = oldMap.get(newMember.Id);
            
            //CCRM15-79: Set default value of 100% if Store Member Role is TS and Team Member Call % is empty
            if(newMember.Role__c == Constants.STOREMEMBER_TS_ROLENAME && String.isEmpty(newMember.Team_Member_Call__c)) {
            	newMember.Team_Member_Call__c = TEAM_MEMBER_CALL_DEFAULT_VALUE; 
            }
            
            //Calculate call volume
            newMember.Call_Volume__c = calculateCallVolume(storeMap.get(newMember.Store__c), newMember.Team_Member_Call__c);
            // End of CCRM15-79           
            
            if(newMember.Default_Trade_Specialist__c == true && newMember.Status__c == Constants.STATUS_ACTIVE 
            && (oldMember.Default_Trade_Specialist__c == false || oldMember.Status__c == Constants.STATUS_INACTIVE)) {
                    defaultTSActiveMembers.add(newMember);
            }
            
            if (newMember.Status__c != 'Active' && !oldMember.Default_Trade_Specialist__c && newMember.Default_Trade_Specialist__c) {
                newMember.addError(ERROR_WHEN_DEFAULT_TS_NOT_ACTIVE);
            }
        }
        
        singleActiveStoreMemberPerUser(newMap.values());
        //validateRoleAndTeamMember(newMap.values());
        defaultTradeSpecialistEditableByTS(oldMap, newMap);
        singleActiveDefaultTradeSpecialistPerStore(defaultTSActiveMembers);
    }

    /**
    * @description 
    * @author Yi Zhang | 07/10/2020 
    * @param newList 
    **/
    public static void afterInsert(List<Store_Member__c> newList) {

        // assign TS User's Manager with RCM
        Map<Id, Store_Member__c> rcmMap = new Map<Id, Store_Member__c>();
        for(Store_Member__c sm : newList) {
            if(isActiveRCM(sm)) {
                rcmMap.put(sm.Store__c, sm);
            }
        }
        assignTSUserManagerBasedOnRCM(rcmMap);
    }

    /**
    * @description 
    * @author Yi Zhang | 07/10/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Store_Member__c> oldMap, Map<Id, Store_Member__c> newMap) {

        // assign TS User's Manager with RCM
        Map<Id, Store_Member__c> rcmMap = new Map<Id, Store_Member__c>();
        for(Store_Member__c newStoreMember : newMap.values()) {
            Store_Member__c oldStoreMember = oldMap.get(newStoreMember.Id);
            // when becomes an Active RCM or Team Member is updated
            if(isActiveRCM(newStoreMember) && (!isActiveRCM(oldStoreMember) || newStoreMember.Team_Member__c != oldStoreMember.Team_Member__c)) {
                rcmMap.put(newStoreMember.Store__c, newStoreMember);
            }
        }
        assignTSUserManagerBasedOnRCM(rcmMap);

        if(!blnAlreadyRunOnce) {
            blnAlreadyRunOnce = true;
            activateDefaultTradeSpecialistStoreMembers(oldMap, newMap); //commented out as automatic assignment of default TS is no longer needed
        }
        /** Commented since : Same logic covered in activateDefaultTradeSpecialistStoreMembers() method.
        else if(runForStoreTaskCreation) {//Added for CCRM 15-394
           checkForNoDefaultTradeSpecialist(newMap);
        }**/
    }

    /**
    * @description Added for CCRM-13832
    * @author MS Simplus | 01/06/2021 
    * @param newList 
    **/
    /** Commented since : Business wants to remove this validation. They are now allowing the multiple roles assigned to diff users.
    public static void validateRoleAndTeamMember(List<Store_Member__c> newList) {
        List<Id> stMemIds = new List<Id>();
        for(Store_Member__c stMem : newList) {
            if(String.isNotBlank(stMem.Id)) {
                stMemIds.add(stMem.Id);
            }
        }

        // Only one user can be active in the role against the Store Member at any one time
        List<Store_Member__c> allOtherStMems = DM_StoreMember.getStMemsExcluding(stMemIds);
        Map<String, Integer> stMemRoleUserMap = new Map<String, Integer>();   // key : stMem Store + Role, val : Team Member Count
        for(Store_Member__c stMem : allOtherStMems) {
            stMemRoleUserMap.put(stMem.Store__c + stMem.Role__c, 1);
        }
        for(Store_Member__c stMem : newList) {
            if(stMemRoleUserMap.containsKey(stMem.Store__c + stMem.Role__c) == true) {
                stMem.addError(ERROR_ONE_TEAM_MEMBER_PER_ROLE);
            }
        }
    }**/

    /**
    * @description Added for CCRM-13881 
    * @author MS Simplus | 14/06/2021
    * @param oldMap 
    * @param newMap 
    **/                 
    public static void defaultTradeSpecialistEditableByTS(Map<Id, Store_Member__c> oldMap, Map<Id, Store_Member__c> newMap) {
        
        Set<Id> storeIds = new Set<Id>();
        for(Store_Member__c oldStMem : oldMap.values()) {
            Store_Member__c newStMem = newMap.get(oldStMem.Id);
            if(((oldStMem.Default_Trade_Specialist__c == true && newStMem.Default_Trade_Specialist__c == false) ||
                (oldStMem.Default_Trade_Specialist__c == false && newStMem.Default_Trade_Specialist__c == true)) && 
                (newStMem.Role__c == Constants.STOREMEMBER_TS_ROLENAME && newStMem.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS)) 
            {
                storeIds.add(oldStMem.Store__c);
            }
        }
        if(storeIds.isEmpty()) {
            return;
        }

        Map<Id, Map<Id, Store_Member__c>> storeWithTSMembersMap = new Map<Id, Map<Id, Store_Member__c>>();
        Id currentUserId = UserInfo.getUserId();

        if(storeIds.size() > 0) {
            User currentUser = DM_User.getUser(currentUserId);
            if(currentUser.Profile.Name.contains(Constants.PROFILE_TRADE_SPECIALIST)){
                for(Store__c store : DM_Store.getStoresWithDefaultActiveTSs(new List<Id>(storeIds))) {
                    Map<Id, Store_Member__c> smTSMap = new Map<Id, Store_Member__c>();
                    if(store.User_Stores__r != null && store.User_Stores__r.size() > 0) {
                        for(Store_Member__c member : store.User_Stores__r) {
                            smTSMap.put(member.Team_Member__c, member);
                        }
                    }
                    if(!smTSMap.isEmpty()) {
                        storeWithTSMembersMap.put(store.Id, smTSMap);
                    }
                }
            } 
        }

        if(!storeWithTSMembersMap.isEmpty()){
            for (Id storeId : storeWithTSMembersMap.keySet()) {
                
                for (Store_Member__c storeMember : storeWithTSMembersMap.get(storeId).values()) {
                    if(storeWithTSMembersMap.get(storeId).values().size() == 1 && storeMember.Default_Trade_Specialist__c == true &&
                       storeWithTSMembersMap.get(storeId).keySet().contains(currentUserId) == true){
                            if(newMap.get(storeMember.Id) != null) {
                                    newMap.get(storeMember.Id).addError(ERROR_WHEN_ONLY_ONE_DEFAULT_TS_NOT_EDITABLE);
                                    break;
                                }
                            }

                    if(!storeWithTSMembersMap.get(storeId).values().isEmpty() && 
                        storeWithTSMembersMap.get(storeId).keySet().contains(currentUserId) == false) {
                            if(newMap.get(storeMember.Id) != null) {
                                    newMap.get(storeMember.Id).addError(ERROR_DEFAULT_TS_NOT_EDITABLE);
                                    break;
                                }
                            }
                }
            }
        }
    }
    
    /**
    * @description Added for CCRM 15-394 
    * 13/12/2021
    * @param newMap 
    **/                 
    /** Commented since : Same logic covered in activateDefaultTradeSpecialistStoreMembers() method.
    public static void checkForNoDefaultTradeSpecialist(Map<Id, Store_Member__c> newMap) {
        Set<Id> storeIds = new Set<Id>();
        Map<Id, Task> taskMap = new Map<Id, Task>();    // Key is store Id, one store should have max one task
        
        for(Store_Member__c newStMem : newMap.values()) {
            if(newStMem.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS && newStMem.Default_Trade_Specialist__c == false) 
            {
                storeIds.add(newStMem.Store__c);
            }
        }
        List<Store_Member__c> storeMembersList = [SELECT Id, Store__c, Team_Member__c, Team_Member__r.ManagerId, Default_Trade_Specialist__c 
                                                  FROM Store_Member__c 
                                                  WHERE Store__c IN :storeIds
                                                  AND Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS
                                                  AND Role__c = :Constants.STOREMEMBER_TS_ROLENAME
                                                  AND Default_Trade_Specialist__c = true];
        
        //if there is no SM with default trade specialist true then create task record
        if(storeMembersList.size() == 0 && storeIds.size() > 0) {
            if(storeIds.size() > 0) {
                for(Store__c store : DM_Store.getStoresWithOneActiveRCM(new List<Id>(storeIds))) {
                    if(store.User_Stores__r != null && store.User_Stores__r.size() == 1) {
                        taskMap.put(store.Id, SM_Task.createTask(
                            store.Id, 
                            store.User_Stores__r[0].Team_Member__c, 
                            'Assign Trade Specialist', 
                            'Please assign a Trade Specialist for store ' + store.Name, 
                            Date.today()));
                    }
                }
            }      
        }
        if(taskMap.size() > 0) {
            System.debug('taskMap>> '+taskMap);
            SM_StoreMember.upsertTaskList(JSON.serialize(taskMap.values()));
        }
    }**/


    /**
    * @description Added for CCRM-13832 
    * @author MS Simplus | 01/06/2021
    * @param oldMap 
    * @param newMap 
    **/   
    
    public static void activateDefaultTradeSpecialistStoreMembers(Map<Id, Store_Member__c> oldMap, Map<Id, Store_Member__c> newMap) {
        
        System.debug('Inside activateDefaultTradeSpecialistStoreMembers');

        Set<Id> autoStoreIds = new Set<Id>();
        Set<Id> autoStoreMemberIds = new Set<Id>();
        for(Store_Member__c oldStMem : oldMap.values()) {
            Store_Member__c newStMem = newMap.get(oldStMem.Id);
            if((oldStMem.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS && newStMem.Status__c == Constants.STOREMEMBER_INACTIVE_STATUS)
                || (oldStMem.Default_Trade_Specialist__c == true && newStMem.Default_Trade_Specialist__c == false)) 
            {
                autoStoreIds.add(oldStMem.Store__c);
                autoStoreMemberIds.add(oldStMem.Id);
            }
        }

        if(autoStoreIds.isEmpty() || autoStoreMemberIds.isEmpty()){
            return;
        }

        System.debug('Inside autoStoreIds'+autoStoreIds);

        
        Set<Id> manualStoreIds = new Set<Id>();
        Set<Id> manualStoreMemberIds = new Set<Id>();
        for(Store_Member__c oldStMem : oldMap.values()) {
            Store_Member__c newStMem = newMap.get(oldStMem.Id);
            if((newStMem.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS)
                || (oldStMem.Default_Trade_Specialist__c == false && newStMem.Default_Trade_Specialist__c == true)) 
            {
                manualStoreIds.add(oldStMem.Store__c);
                manualStoreMemberIds.add(oldStMem.Id);
            }
        }
        
        System.debug('Inside manualStoreIds'+manualStoreIds);
        /*if(manualStoreIds.isEmpty()) {
            return;
        }*/

        List<Store_Member__c> toUpdateTSMembersManualList = new List<Store_Member__c>();

        if(manualStoreIds.size() > 0) {
            for(Store_Member__c member : DM_StoreMember.getOldActiveTradeSpecialistStoreMembers(manualStoreIds, manualStoreMemberIds)) {
                if(member.Default_Trade_Specialist__c == true) {
                    member.Default_Trade_Specialist__c = false;
                    toUpdateTSMembersManualList.add(member);
                }
            }
        }
        if(toUpdateTSMembersManualList.size() > 0) {
            try {
                //runForStoreTaskCreation = true;
                update toUpdateTSMembersManualList;
            } catch(Exception e) {
                ApplicationLogger.log('SM_StoreMember.activateDefaultTradeSpecialistStoreMembers', 'Store_Member__c', 'Trigger', e);
            }
        }

        Set<Id> storesToAlertRCM = new Set<Id>();
        Map<Id, Task> taskMap = new Map<Id, Task>();    // Key is store Id, one store should have max one task
        List<Store_Member__c> toUpdateTSMembersList = new List<Store_Member__c>();

        if(autoStoreIds.size() > 0) {
            for(Store_Member__c member : DM_StoreMember.getInactiveTradeSpecialistStoreMembers(autoStoreIds)) {
                if(member.Status__c == Constants.STOREMEMBER_INACTIVE_STATUS) {
                    member.Default_Trade_Specialist__c = false;
                    toUpdateTSMembersList.add(member);
                }
            }
        }else{return;}
        
        
        User runningUser = DM_User.getUser(UserInfo.getUserId());
        List<Initialisation__mdt> filterRCMProfileList = [SELECT Id, Default_TS_Auto_Selection_Exemption__c FROM Initialisation__mdt];
        System.debug('filterRCMProfileList: '+filterRCMProfileList);

        // promote a remaining active TS to Default
        if(autoStoreIds.size() > 0) {
            for(Store__c store : DM_Store.getStoresWithActiveTSList(new List<Id>(autoStoreIds), autoStoreMemberIds)) {
                if(store.User_Stores__r != null && store.User_Stores__r.size() > 0) {
                    for(Store_Member__c member : store.User_Stores__r) {
                            if(!newMap.containsKey(member.Id)){
                                if(filterRCMProfileList!=null && !filterRCMProfileList.isEmpty() &&
                                    !filterRCMProfileList[0].Default_TS_Auto_Selection_Exemption__c.contains(runningUser.Profile.Name)){
                                        member.Default_Trade_Specialist__c = true;
                                        toUpdateTSMembersList.add(member);
                                        break;
                                }
                            }else if(store.User_Stores__r.size() == 1){
                                storesToAlertRCM.add(store.Id);
                            }
                    }                    
                }else{
                    storesToAlertRCM.add(store.Id);
                }
            }
        }else{return;}

        if(toUpdateTSMembersList.size() > 0) {
            try {
                System.debug('toUpdateTSMembersList '+toUpdateTSMembersList);
                    update toUpdateTSMembersList;
            } catch(Exception e) {
                    ApplicationLogger.log('SM_StoreMember.activateDefaultTradeSpecialistStoreMembers', 'Store_Member__c', 'Trigger', e);
            }
        }

        if(autoStoreIds.size() > 0) { //Added for CCRM 15-394
            for(Store__c store : DM_Store.getStoresWithActiveDTSList(new List<Id>(autoStoreIds))) {
                if(store.User_Stores__r.size() == 0) {
                    storesToAlertRCM.add(store.Id);
                }
            }
        }

        // in case no remaining active TS, alert store's RCM
        if(storesToAlertRCM.size() > 0) {
            for(Store__c store : DM_Store.getStoresWithOneActiveRCM(new List<Id>(storesToAlertRCM))) {
                if(store.User_Stores__r != null && store.User_Stores__r.size() == 1) {
                    taskMap.put(store.Id, SM_Task.createTask(
                        store.Id, 
                        store.User_Stores__r[0].Team_Member__c, 
                        'Assign Trade Specialist', 
                        'Please assign a Trade Specialist for store ' + store.Name, 
                        Date.today()));
                }
            }
        }

        if(taskMap.size() > 0) {
            System.debug('taskMap '+taskMap);
            SM_StoreMember.upsertTaskList(JSON.serialize(taskMap.values()));
        }
        
    }

	
    /**
    * @description 
    * @author Yi Zhang | 25/08/2020 
    * @param storeMembers 
    **/
    public static void singleActiveDefaultTradeSpecialistPerStore(List<Store_Member__c> storeMembers) {
        system.debug('singleActiveDefaultTradeSpecialistPerStore'+storeMembers);
        if(storeMembers.isEmpty()) {
            return;
        }

        List<Id> storeMemberIds = new List<Id>();
        List<Id> storeIds = new List<Id>();
        List<Id> storeIdsWithActiveDefaultTS = new List<Id>();
        Map<Id, List<String>> defaultTSMap = new Map<Id, List<String>>();
        for(Store_Member__c member : storeMembers) {
            storeIds.add(member.Store__c);
            system.debug('member.Store__c'+member.Store__c);
            if(String.isNotBlank(member.Id)) {
                storeMemberIds.add(member.Id);
            }
            
            //Added for CCRM-13689 Stores with multiple default TS assigned - Simplus MS
            system.debug('Default_Trade_Specialist__c value'+member.Default_Trade_Specialist__c);
            //find all default TS in the store members to insert/update
            if (member.Default_Trade_Specialist__c){
                system.debug('Default_Trade_Specialist__c'+member);
                if(defaultTSMap.containsKey(member.Store__c)){
                    defaultTSMap.get(member.Store__c).add(member.Id);
                }else{
                    defaultTSMap.put(member.Store__c, new List<String>{member.Id});
                }
            }
            system.debug('defaultTSMap.get(member.Store__c).size()'+defaultTSMap.get(member.Store__c).size());
            if (member.Store__c != null && defaultTSMap.get(member.Store__c) != null){
                if (defaultTSMap.get(member.Store__c).size() > 1){
                    member.Default_Trade_Specialist__c = FALSE;
                    //storeIdsWithActiveDefaultTS.add(member.Store__c);
                }
            }
        }
        system.debug('storeIds'+storeIds);
        system.debug('storeMemberIds'+storeMemberIds);
        // find all existing active records of the same store and get store Ids
        
        for(Store_Member__c member : DM_StoreMember.getActiveDefaultTradeSpecialistStoreMembers(storeIds, storeMemberIds)) {
            storeIdsWithActiveDefaultTS.add(member.Store__c);
        }
        if(storeIdsWithActiveDefaultTS.isEmpty()) {
            return;
        }

        
        for(Store_Member__c member : storeMembers) {
            if(storeIdsWithActiveDefaultTS.contains(member.Store__c)) {
                member.addError(ERROR_ONE_ACTIVE_DEFAULT_TS_PER_STORE);
            }
        }

    }

    
    /**
    * @description Added for CCRM-13830
    * @author MS Simplus | 21/05/2021 
    * @param storeMembers 
    **/
    public static void singleActiveStoreMemberPerUser(List<Store_Member__c> storeMembers) {
        system.debug('singleActiveStoreMemberPerUser'+storeMembers);
        
        if(storeMembers.isEmpty()) {
            return;
        }
        
        Set<Id> stores = new Set<Id>();
        for (Store_Member__c sm : storeMembers){
            stores.add(sm.Store__c);
        }
        
        Map<Id, Store_Member__c> mapOfStoreMember = new Map<Id, Store_Member__c>();
        for (Store_Member__c currentStoreMember : [Select Id, Store__c, Team_Member__c, Status__c From Store_Member__c WHERE Store__c In :stores ] ){
            if (currentStoreMember.Status__c == Constants.STATUS_ACTIVE){
                mapOfStoreMember.put(currentStoreMember.Team_Member__c, currentStoreMember);  
            }
        }

        for(Store_Member__c member : storeMembers) {
            if((member.Status__c == Constants.STATUS_ACTIVE)
               && (mapOfStoreMember.containsKey(member.Team_Member__c)) 
               && (mapOfStoreMember.get(member.Team_Member__c).Id != member.Id)
               && (mapOfStoreMember.get(member.Team_Member__c).Store__c == member.Store__c)) {
                   member.addError(ERROR_ONE_ACTIVE_STORE_MEMBER_PER_TEAM_MEMBER);
               }
        }        
    }
    /**
    * @description 
    * @author Yi Zhang | 07/10/2020 
    * @param rcmMap Key is the store Id, value is the RCM Store Member 
    **/
    public static void assignTSUserManagerBasedOnRCM(Map<Id, Store_Member__c> rcmMap) {
        if(rcmMap.isEmpty()) {
            return;
        }

        // find all active TS Store Member
        List<Store_Member__c> tsStoreMembers = DM_StoreMember.getActiveTradeSpecialistStoreMembers(rcmMap.KeySet());
        if(tsStoreMembers.isEmpty()) {
            return;
        }

        // build user map
        Map<Id, User> userMap = new Map<Id, User>();
        for(Store_Member__c sm : tsStoreMembers) {
            Store_Member__c rcm = rcmMap.get(sm.Store__c);
            if(sm.Team_Member__r.ManagerId != rcm.Team_Member__c) {
                userMap.put(sm.Team_Member__c, new User(Id = sm.Team_Member__c, ManagerId = rcm.Team_Member__c));
            }
        }
        if(userMap.size() > 0) {
            updateUsersAsync(JSON.serialize(userMap.values()));
        }

    }
    
    /**
    * @description
    * @author Yi Zhang | 07/10/2020 
    * @param usersJson 
    **/
    @future
    public static void updateUsersAsync(String usersJson) {
        List<User> users = (List<User>) JSON.deserialize(usersJson, List<User>.class);
        try {
            update users;
        } catch(Exception e) {
            ApplicationLogger.log('SM_StoreMember.updateUsersAsync', 'Store_Member__c', 'Trigger', e);
        }
    }

    private static Boolean isActiveRCM(Store_Member__c sm) {
        return (sm.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS && sm.Role__c == Constants.STOREMEMBER_RCM_ROLENAME);
    }
    
    /**
    * @description 
    * @author Philip Clark | 19/06/2020 
    * @param userList
    **/
    public static void createStoreMember(map<Id,set<String>> userLocMap, string roleName, boolean async) {
        system.debug('[SM_StoreMember.createStoreMember] entering method');
        set<String> locSet = new set<String>();
        for (set<String> userLocs : userLocMap.values()) {
            locSet.addAll(userLocs);
        }
        // find store 
        map<String,Id> locStoreIdMap = new map<String,Id>();
        map<Id,Integer> storeTScountMap = new map<Id,Integer>();
        set<String> roleSet = new set<String> {Constants.STOREMEMBER_TS_ROLENAME};
            for (Store__c s : DM_Store.getStoreByLocCode(locSet, Constants.STOREMEMBER_ACTIVE_STATUS, roleSet)) {
                locStoreIdMap.put(s.Location_Code__c,s.Id);
                storeTScountMap.put(s.Id,s.User_Stores__r.size());
            }
        
        // create store member
        list<Store_Member__c> smList = new list<Store_Member__c>();
        for (Id uid : userLocMap.keySet()) {
            if (uid!=null) {
                for (String loc : userLocMap.get(uid)) {
                    Id storeId = locStoreIdMap.get(loc);
                    if(String.isNotBlank(storeId)) {
                        boolean defaultTS = storeTScountMap.get(storeId)==0 ? true : false;
                        smList.add(new Store_Member__c(
                            Start_Date__c = date.Today(),
                            Role__c = roleName,
                            Status__c = Constants.STOREMEMBER_ACTIVE_STATUS,
                            Store__c = storeId,
                            Default_Trade_Specialist__c = (roleName==Constants.STOREMEMBER_TS_ROLENAME ? defaultTS : false),
                            Team_Member__c = uid
                        ));
                    }
                }
            }
        }
        if (!smList.isEmpty()) {
            if (!async) {
                upsert smList;
            } else {
                String smListJson = JSON.serialize(smList);
                upsertSMList(smListJson);
            }
        }
    }
    
    /**
    * @description 
    * @author 	Philip Clark | 19/06/2020 
    * @param 	map<Id,String> userLocMap
    **/
    /** Commented since it is no longer used in any apex classes 
    public static void endDateStoreMember(map<Id,set<String>> userLocMap, string roleName, boolean async) {
        system.debug('[SM_StoreMember.endDateStoreMember] entering method');
        set<String> locSet = new set<String>();
        for (set<String> userLocs : userLocMap.values()) {
            if (userLocs!=null)
            	locSet.addAll(userLocs);
        }
        // collect existing store members for reassignment of default TS
        map<String,Store_Member__c> locTSMap = new map<String,Store_Member__c>();
        map<String,Id> locRCMMap = new map<String,Id>();
        for (Store__c s : DM_Store.getStoreByLocCode(locSet, Constants.STOREMEMBER_ACTIVE_STATUS, null)) {
            for (Store_Member__c sm : s.User_Stores__r) {
                if (!locTSMap.containsKey(s.Location_Code__c) && sm.Role__c==Constants.STOREMEMBER_TS_ROLENAME 
                    && !userLocMap.keySet().contains(sm.Team_Member__c)) {
                        locTSMap.put(s.Location_Code__c,sm);
                    }
                if (sm.Role__c==Constants.STOREMEMBER_RCM_ROLENAME)
                    locRCMMap.put(s.Location_Code__c,sm.Team_Member__c);
            }
        }
        list<Store_Member__c> smList = new list<Store_Member__c>();
        list<Task> RCMtaskList = new list<Task>();
        for (Store_Member__c sm : DM_StoreMember.getStoreMemberbyUId(userLocMap.keySet())) {
            if (userLocMap.get(sm.Team_Member__c)!=null) {
                // deactivate specific to stores
                for (String loc : userLocMap.get(sm.Team_Member__c)) {
                    if (sm.Location_Code__c==loc && 
                        (roleName==null || sm.Role__c==roleName) &&
                        (sm.End_Date__c == null || sm.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS)) {
                            system.debug('[SM_StoreMember.endDateStoreMember] end dating store member: '+sm.Id);
                            sm.End_Date__c = date.Today();
                            sm.Status__c = Constants.STOREMEMBER_INACTIVE_STATUS;
                            sm.Default_Trade_Specialist__c = FALSE;
                            smList.add(sm);
                            // set existing store TS as default TS if present
                            if (sm.Role__c==Constants.STOREMEMBER_TS_ROLENAME) {
                                if (locTSMap.containsKey(sm.Location_Code__c)) {
                                    Store_Member__c newDefTS = locTSMap.get(sm.Location_Code__c);
                                    newDefTS.Default_Trade_Specialist__c = TRUE;
                                    smList.add(newDefTS);
                            		system.debug('[SM_StoreMember.endDateStoreMember] setting new default trade specialist '+newDefTS.Id+' for store: '+sm.Store__c);
                                }
                                else 
                                {
                                    // create task and assign to RCM for their operational area
                            		system.debug('[SM_StoreMember.endDateStoreMember] no remaining trade specialists for store: '+sm.Store__c+', raising task for RCM');
                                    if (locRCMMap.containsKey(sm.Location_Code__c)) 
                                        RCMtaskList.add(SM_Task.createTask(sm.Store__c, locRCMMap.get(sm.Location_Code__c), 
                                                                           'Assign Trade Specialist', 'Please assign a Trade Specialist for store '+sm.Store__r.Name, null));
                                }
                            }
                        }
                }
            } else {
                // deactivate all active non-TS store members - for deactivated users with no location code
                if ((sm.End_Date__c == null || sm.Status__c == Constants.STOREMEMBER_ACTIVE_STATUS) && sm.Role__c!=Constants.STOREMEMBER_TS_ROLENAME) {
                    system.debug('[SM_StoreMember.endDateStoreMember] end dating non-TS store member for deactivated user without loc code: '+sm.Id);
                    sm.End_Date__c = date.Today();
                    sm.Status__c = Constants.STOREMEMBER_INACTIVE_STATUS;
                    smList.add(sm);
                }
            }
        }
        if (!smList.isEmpty()) {
            if (!async) {
                upsert smList;
            } else {
                String smListJson = JSON.serialize(smList);
                upsertSMList(smListJson);
            }
        }
        if (!RCMtaskList.isEmpty()) {
            if (!async) {
                upsert RCMtaskList;
            } else {
                String taskListJson = JSON.serialize(RCMtaskList);
                upsertTaskList(taskListJson);
            }
        }
    }
    **/
    /**
    * @description 
    * @author 	Philip Clark | 25/06/2020 
    * @param 	String
    **/
    @future
    public static void upsertSMList (String smListJson) {
        system.debug('[SM_StoreMember.upsertSMList] entering method');
        List<Store_Member__c> smList = (List<Store_Member__c>) JSON.deserialize(smListJson, List<Store_Member__c>.class);
        try {
            upsert smList;
        } catch(Exception e) {
            ApplicationLogger.log('SM_StoreMember.upsertSMList', 'Store_Member__c', 'Trigger', e);
        }    
    }
    
    /**
    * @description      Modified to do insert only as DMLOptions is needed
    * @author 	Philip Clark | 25/06/2020 
    * @param 	String
    **/
    //@future
    public static void upsertTaskList (String taskListJson) {
        system.debug('[SM_StoreMember.upsertTaskList] entering method');
        List<Task> taskList = (List<Task>) JSON.deserialize(taskListJson, List<Task>.class);
        try {
            //Set EmailHeader.triggerUserEmail to true
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.EmailHeader.triggerUserEmail = true;

            Database.insert(taskList, dmlOptions);
        } catch(Exception e) {
            ApplicationLogger.log('SM_StoreMember.upsertTaskList', 'Task', 'Trigger', e);
        }
    }

    /**
    * @description  Used when updates must be in order
    * @author Yi Zhang | 26/08/2020 
    * @param storeMemberList1Json   First List to be updated
    * @param storeMemberList2Json   Second List to be updated
    **/
    @future
    public static void updateStoreMemberLists(String storeMemberList1Json, String storeMemberList2Json) {
        try {
            List<Store_Member__c> list1 = (List<Store_Member__c>) JSON.deserialize(storeMemberList1Json, List<Store_Member__c>.class);
            if(list1.size() > 0) {
                System.debug('list1 '+list1);
                update list1;
            }
            
            List<Store_Member__c> list2 = (List<Store_Member__c>) JSON.deserialize(storeMemberList2Json, List<Store_Member__c>.class);
            if(list2.size() > 0) {
                 System.debug('list2 '+list2);
                update list2;
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_StoreMember.updateStoreMemberLists', 'Store_Member__c', 'Trigger', e);
        }    
    }
        
    /**
    * @description Calculate call volume
    * @author 	Simplus MS | 19/10/2021 
    * @param 	store, teamMbrCall
    **/
    public static Integer calculateCallVolume(Store__c store, String teamMbrCall) {
        system.debug('inside calculateCallVolume');
        //Retrieve baseline volume based on country and store type
        String key = store == null ? null : store.Engagement_Model__c + store.Location_Type__c + store.Country__c;
        Integer baselineVol = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT).get(key) == null ? 0 : DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT).get(key);
        System.debug('baselineVol '+baselineVol);
        Decimal storeCallPct = store.Store_Call__c == null ? 0 : Decimal.valueOf(store.Store_Call__c.substringBefore('%')) / 100;
        Decimal teamMbrCallPct = teamMbrCall == null ? 0 : Decimal.valueOf(teamMbrCall.substringBefore('%')) / 100;
    	system.debug('baselineVol :: '+baselineVol);
    	system.debug('storeCallPct :: '+storeCallPct);
    	system.debug('teamMbrCallPct :: '+teamMbrCallPct);
        //Call volume = ROUNDUP(Baseline volume x Store Call % x Store Member Team Member Call %)
        Integer callVol = (Integer)(baselineVol * storeCallPct * teamMbrCallPct).round(System.RoundingMode.CEILING);

        return callVol;
    }
}