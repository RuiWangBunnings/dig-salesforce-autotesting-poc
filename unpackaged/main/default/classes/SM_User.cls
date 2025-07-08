/*******************************************************************************************************
* Class Name        : SM_User
* Description    : Domain / Service layer for User
* Author            : Simplus - Philip Clark
* Created On        : 18/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          18/06/2020      1000                Initial version
* Philip Clark          01/07/2020      1001                Contract Delegated Approval
* Yi Zhang              20/08/2020      1002                New logic to enddate Store Member 
* Yi Zhang              24/08/2020      1003                New logic for Sale Rep Id / TS Role
* Yi Zhang              19/10/2020      1004                Revised to pick 1 Sales Rep Id among multiple ones
* Errol Yatar           19/01/2021      1005                Added new method initialiseApprovalRequestEmailSetting(List<User>), referenced inside beforeInsert() method. Returns List<User>.
* Simplus MS            11/06/2021      1006                Updated afterUpdate method - fix PROD_INC0965367
* Simplus MS            23/06/2021      1007                Added logic to include changes in Role for Store member creation - fix for PROD_INC0970025
* Simplus MS            27/07/2021      1008                Fix for PROD_0969834 - allow re-running of Manager Id/SalesRepId/TS Role population and Storemember creation if process failed on insert and on update
* Simplus MS 			18/10/2021		1009				Added logic for CCRM15-257 -  set the Marketing Cloud for AppExchange User field to default TRUE in user creation
* Simplus MS 			04/11/2021		1010				Added logic for CCRM15-259 - When a Sales Rep record is created, then update the User Record and accounts
* Simplus MS            16/11/2021      21000               CCRM15-407 - Automatically transfer accounts when TS moves store/leaves business/changes role
* Simplus MS            13/11/2021      22000               CCRM15-416 - The SF role needs to be populated automatically for all AMs
* Simplus MS            22/12/2021      23000               CCRM15-548 - ManagerId not populated if Profile set from nonTS to TS with LocationCode already set before Profile change
* Simplus MS 			24/12/2021		24000				CCRM15-454 - Store member records - automation, stop creating new record. update existing if same Team Member
* Simplus MS 			18/01/2022		25000				CCRM15-566 - TS onboarding email - Update fields for user's email address (INC 1104865)
* Simplus MS 			21/04/2022		26000				SFSUP-431 - Accounts being transferred to default user when not expected
******************************************************************************************************/

public without sharing class SM_User {
    
    private static final String ERROR_UNAUTHORISED_DELEGATED_APPROVER_UPDATE = 'You are not authorised to change delegated approver for this user.';
    //  PARTIAL_START-PROD_0969834
    public static Boolean reRunOnBeforeInsert = false;  
    public static Boolean reRunOnBeforeUpdate = false;  
    private Enum Process { SET_MANAGER, SET_SALESREPID_AND_ROLE, CREATE_STOREMEMBER, CREATE_CALENDARVIEWS, DELETE_CALENDARVIEWS, DELETE_TS_CALENDARVIEWS }
    private Enum TriggerStep { ON_INSERT, ON_UPDATE }
    //  PARTIAL_END-PROD_0969834
    
    /**
    * @description 
    * @author Philip Clark | 23/06/2020 
    * @param newMap
    * MODIFICATION - Simplus MS-28.07.2021 - re-execution of setTSManager, populateSalesRepIDAndRole, populateAddress, initialiseApprovalRequestEmailSetting
    **/
    public static void beforeInsert(List<User> newList) {
        try {
            //CCRM15-257 : Added by Simplus MS 18.Oct.2021 
            Map<Id,Profile> standardProfileIds = new Map<id,Profile>([SELECT Id,UserLicenseId FROM Profile WHERE UserLicenseId  IN (SELECT Id FROM UserLicense WHERE Name ='Salesforce')]);
            
            Map<String,User> originalUserMap = new Map<String,User>();  //  userName-Userobj Map
            Map<String,User> mapToUpdateAfterRerun = new Map<String,User>();
            if(reRunOnBeforeInsert) {
                originalUserMap = mapUserNameToUser(newList);
                mapToUpdateAfterRerun = originalUserMap;
            }
            
            if(!reRunOnBeforeInsert) {
                //Start - CCRM15-257 : Updated by Simplus MS 18.Oct.2021 - Added logic to set the Marketing Cloud for AppExchange User field to default TRUE in the creation of a standard user -  CCRM15-257
                for (User u : newList){
                    if (standardProfileIds.keyset().contains(u.ProfileId)){
                        u.et4ae5__ExactTargetForAppExchangeUser__c = TRUE;
                    }
                }
                //End - CCRM15-257
                
                newList = setTSManager(null, newList);
                newList = populateAMRole(null, newList); //Added by Simplus MS 13.Dec.2021 for CCRM15-416
                newList = populateStoreEmail(null, newList); //Added by Simplus MS 18.Jan.2022 for CCRM15-566
            }
            else {
                List<User> tempNewList = (List<User>) filterForRerun(null, mapToUpdateAfterRerun.values(), Process.SET_MANAGER, TriggerStep.ON_INSERT);
                if(!tempNewList.isEmpty()) {
                    System.debug('Retriggered insert setManager');
                    tempNewList = setTSManager(null, tempNewList);
                    mapToUpdateAfterRerun.putAll(mapUserNameToUser(tempNewList));
                }
            }
            if(!reRunOnBeforeInsert)
                newList = populateSalesRepIDAndRole(null, newList);
            else {
                List<User> tempNewList = (List<User>) filterForRerun(null, mapToUpdateAfterRerun.values(), Process.SET_SALESREPID_AND_ROLE, TriggerStep.ON_INSERT);
                if(!tempNewList.isEmpty()) {
                    System.debug('Retriggered insert populateSalesRepIDAndRole');
                    tempNewList = populateSalesRepIDAndRole(null, tempNewList);
                    mapToUpdateAfterRerun.putAll(mapUserNameToUser(tempNewList));
                }
            }
            if(!reRunOnBeforeInsert) {
                newList = populateAddress(null, newList);
                newList = initialiseApprovalRequestEmailSetting(newList);
            }
            if(reRunOnBeforeInsert && originalUserMap.values() != mapToUpdateAfterRerun.values()) {
                for(User u : mapToUpdateAfterRerun.values()) {
                    if(u.Id == null)
                        mapToUpdateAfterRerun.remove(u.UserName);
                }
                update mapToUpdateAfterRerun.values();
                system.debug('XXXXXXXXXXXXX - has update');
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_User.beforeInsert', 'User', 'Trigger', e);
        }
    }
    
    /**
    * @author Simplus MS | 31/07/2021 
    **/
    private static Map<String,User> mapUserNameToUser(List<User> userList) {
        Map<String,User> tempMap = new Map<String,User>();
        for(User u : userList) {
            tempMap.put(u.UserName, u);
        }
        return tempMap;
    }
    
    /**
    * @description 
    * @author Philip Clark | 18/06/2020 
    * @param newMap
    * MODIFICATION - Simplus MS-28.07.2021 - re-execution of SM_StoreMember.createStoreMember
    **/
    public static void afterInsert(Map<Id,User> newMap) {
        try {
            
            Map<Id,Set<String>> userLocMap = new Map<Id,Set<String>>();
            Map<Id,User> activeTSUserMap = new Map<Id,User>();
            for (User u : newMap.Values()) {
                if (u.Is_TS__c == true && u.Location_Code__c != null) {
                    System.debug('userLocMap>> '+userLocMap);
                    if(!userLocMap.containsKey(u.Id))
                        userLocMap.put(u.Id,new Set<String>());
                    userLocMap.get(u.Id).add(u.Location_Code__c);
                }
                if (u.isActive == TRUE)
                    activeTSUserMap.put(u.Id,u);
            }
            System.debug('reRunOnBeforeInsert '+reRunOnBeforeInsert+'userLocMap '+userLocMap);
            if (!userLocMap.isEmpty()) {
                if(!reRunOnBeforeInsert) 
                    SM_StoreMember.createStoreMember(userLocMap, Constants.STOREMEMBER_TS_ROLENAME, true);
                else {
                    userLocMap = (Map<Id,Set<String>>) filterForRerun(null, userLocMap, Process.CREATE_STOREMEMBER, TriggerStep.ON_INSERT);
                    if(userLocMap != null) {
                        System.debug('retriggered insert createStoreMember');
                        SM_StoreMember.createStoreMember(userLocMap, Constants.STOREMEMBER_TS_ROLENAME, true);
                    }
                }
            }
            if(reRunOnBeforeInsert) return;
            if (!activeTSUserMap.isEmpty()) SM_CalendarView.createCalendarViews(activeTSUserMap);
            
        } catch(Exception e) {
            ApplicationLogger.asyncLog('SM_User.afterInsert', 'User', 'Trigger', e.getMessage(), e.getTypeName(), e.getStackTraceString());
        }
    }
    
    /**
    * @description 
    * @author Philip Clark | 23/06/2020 
    * @param oldMap
    * @param newMap
    * MODIFICATION - Simplus MS-28.07.2021 - re-execution of setTSUser, populateSalesRepIDAndRole, populateAddress, initialiseApprovalRequestEmailSetting
    **/
    public static void beforeUpdate(map<Id,User> oldMap, list<User> newList) {

        
        if(reRunOnBeforeInsert) return;
        
        try {
            Map<String,User> originalUserMap = new Map<String,User>();
            Map<String,User> mapToUpdateAfterRerun = new Map<String,User>();
            if(reRunOnBeforeUpdate) {
                originalUserMap = mapUserNameToUser(newList);
                mapToUpdateAfterRerun = originalUserMap;
            }
            
            if(!reRunOnBeforeUpdate) newList = setTSManager(oldMap, newList);
            else {
                List<User> tempNewList = (List<User>) filterForRerun(oldMap, originalUserMap.values(), Process.SET_MANAGER, TriggerStep.ON_UPDATE);
                if(tempNewList.isEmpty()) {
                    System.debug('Retriggered update setManager');
                    tempNewList = setTSManager(oldMap, tempNewList);
                    mapToUpdateAfterRerun.putAll(mapUserNameToUser(tempNewList));
                }
            }
            if(!reRunOnBeforeUpdate) {
                newList = populateSalesRepIDAndRole(oldMap, newList);
                newList = populateAMRole(oldMap, newList); //Added by Simplus MS 13.Dec.2021 for CCRM15-416
                newList = populateStoreEmail(oldMap, newList); //Added by Simplus MS 18.Jan.2022 for CCRM15-566
            }  
            else {
                List<User> tempNewList = (List<User>) filterForRerun(oldMap, originalUserMap.values(), Process.SET_SALESREPID_AND_ROLE, TriggerStep.ON_UPDATE);
                if(newList.isEmpty()) {
                    System.debug('Retriggered update setManager');
                    tempNewList = populateSalesRepIDAndRole(oldMap, tempNewList);
                    mapToUpdateAfterRerun.putAll(mapUserNameToUser(tempNewList));
                }
            }
            
            if(!reRunOnBeforeUpdate) {
                newList = populateAddress(oldMap, newList);
                checkDelegatedApproverChanger(oldMap, newList);
            }
            
            if(reRunOnBeforeUpdate && originalUserMap.values() != mapToUpdateAfterRerun.values()) {
                update mapToUpdateAfterRerun.values();
                system.debug('XXXXXXXXXXXXX - has update on updateRerun');
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_User.beforeUpdate', 'User', 'Trigger', e);
        }
    }
    
    /**
    * @description 
    * @author Philip Clark | 18/06/2020 
    * @param oldMap
    * @param newMap
    **/
    public static void afterUpdate(Map<Id,User> oldMap, Map<Id,User> newMap) {
        
        Map<Id,Store_Member__c> inactiveStoreMembersMap = new Map<Id,Store_Member__c>();
        
        if(reRunOnBeforeInsert) return;
        if(!reRunOnBeforeUpdate) {
            inactiveStoreMembersMap = enddateInactiveUsersStoreMembers(oldMap, newMap);
            //updateTSAssignedStores(oldMap, newMap); //logic is transferred inside updateTSOwnedAccounts method to avoid LOCK_ROW issue
            updateTSOwnedAccounts(oldMap, newMap); //Added for CCRM15-259
            notifyManagerOfNewDelegatedApprover(oldMap, newMap);
        }
        
        try {
            Map<String,Id> profIdMap = new Map<String,Id>();
            for (Profile p : DM_Profile.getProfilebyName(null)) {
                profIdMap.put(p.Name,p.Id);
            }
            map<Id,set<String>> addTCLocMap = new map<Id,set<String>>();
            map<Id,User> activateUserMap = new map<Id,User>();
            map<Id,User> deactivateUserMap = new map<Id,User>();
            Map<Id,User> activeNonTSUserMap = new Map<Id,User>(); // PROD_INC0965367
            set<Id> delegatedUserIds = new set<Id>();
            set<Id> undelegatedUserIds = new set<Id>();
            for (User u : newMap.Values()) {
                // add TC store member
                // Updated by Simplus MS 23.Jun.2021 - Added logic to include changes in Role for Store member creation - fix for PROD_INC0970025
                Boolean newRoleIsTS = null;
                Boolean oldRoleIsTS = null;
                System.debug('UserRoleId>> '+u.UserRoleId);
                try { newRoleIsTS = u.UserRoleId!=null ? u.UserRole.Name.contains(Label.Trade_Specialist) : null; } catch(Exception e){}
                try { oldRoleIsTS = oldMap.get(u.Id).UserRoleId!=null ? oldMap.get(u.Id).UserRole.Name.contains(Label.Trade_Specialist) : null; } catch(Exception e){}
                if ((
                    u.ProfileId!=oldMap.get(u.Id).ProfileId 
                    || u.Location_Code__c!=oldMap.get(u.Id).Location_Code__c 
                    || oldMap.get(u.Id).isActive == false 
                    || (newRoleIsTS == true && (oldRoleIsTS == false || oldRoleIsTS == null))
                )
                    && (u.ProfileId==profIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME) || u.ProfileId==profIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME)) 
                    && u.Location_Code__c != null
                    && u.isActive == true
                    && !inactiveStoreMembersMap.containsKey(u.Id))//For CCRM15-454
                {
                    if(!addTCLocMap.containsKey(u.Id))
                        addTCLocMap.put(u.Id,new set<String>());
                    addTCLocMap.get(u.Id).add(u.Location_Code__c);
                }
                if (u.isActive != oldMap.get(u.Id).isActive) {
                    if (u.isActive == TRUE)         // create calendar views
                        activateUserMap.put(u.Id,u);
                    else if (u.isActive == FALSE)   // delete calendar views
                        deactivateUserMap.put(u.Id,u);
                } 
                //  START - FIX FOR PROD_INC0965367
                else if ((u.isActive == true && oldMap.get(u.Id).isActive == true) && u.ProfileId != oldMap.get(u.Id).ProfileId) {  
                    if (        
                        (u.ProfileId == profIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME) && oldMap.get(u.Id).ProfileId != profIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME)) || 
                        (u.ProfileId == profIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME) && oldMap.get(u.Id).ProfileId != profIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME))
                    ) { 
                        //  assign for calendar creation if new Profile is AU Trade Specialist but not NZ Trade Specialist and vice versa
                        activateUserMap.put(u.Id,u); 
                    } else if (
                        (oldMap.get(u.Id).ProfileId == profIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME) && u.ProfileId != profIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME)) ||
                        (oldMap.get(u.Id).ProfileId == profIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME) && u.ProfileId != profIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME))
                    ) {
                        //  assign for calendar deletion if new Profile is not AU/NZ Trade Specialist
                        activeNonTSUserMap.put(u.Id,u);
                    }   
                }
                //  END - FIX FOR PROD_INC0965367
                
                if (u.DelegatedApproverId!=oldMap.get(u.Id).DelegatedApproverId) {
                    if (u.DelegatedApproverId != null) 
                        delegatedUserIds.add(u.Id);
                    else if (u.DelegatedApproverId == null) 
                        undelegatedUserIds.add(u.Id);
                }
            }
            System.debug('reRunOnBeforeUpdate>> '+reRunOnBeforeUpdate+' addTCLocMap>> '+addTCLocMap);
            if (!addTCLocMap.isEmpty()) {
                if(!reRunOnBeforeUpdate) SM_StoreMember.createStoreMember(addTCLocMap, Constants.STOREMEMBER_TS_ROLENAME, true);
                else {
                    addTCLocMap = (Map<Id,Set<String>>) filterForRerun(null, addTCLocMap, Process.CREATE_STOREMEMBER, TriggerStep.ON_UPDATE);
                    if(addTCLocMap != null) {
                        System.debug('retriggered update createStoreMember');
                        SM_StoreMember.createStoreMember(addTCLocMap, Constants.STOREMEMBER_TS_ROLENAME, true);
                    }
                }
            }
            
            if(reRunOnBeforeUpdate)
                return;
            
            if (!activateUserMap.isEmpty()) SM_CalendarView.createCalendarViews(activateUserMap);  
            if (!deactivateUserMap.isEmpty()) SM_CalendarView.deleteCalendarViews(deactivateUserMap); 
            if (!activeNonTSUserMap.isEmpty()) SM_CalendarView.deleteTSCalendarViews(activeNonTSUserMap); // PROD_INC0965367
            if (!delegatedUserIds.isEmpty()) {
                list<Contract__c> updatedContracts = SM_Contract.setReviewersApprovers(null,DM_Contract.getContractsbyReviewerApprover(delegatedUserIds),FALSE);
                if (!updatedContracts.isEmpty()) {
                    String contractListJson = JSON.serialize(updatedContracts);
                    SM_Contract.updateContractsAsync(contractListJson);
                }
            }
            if (!undelegatedUserIds.isEmpty()) SM_Contract.resetReviewersApprovers(undelegatedUserIds);
        } catch(Exception e) {
            ApplicationLogger.asyncLog('SM_User.afterUpdate', 'User', 'Trigger', e.getMessage(), e.getTypeName(), e.getStackTraceString());
        }
    }
    
    /**
    * @description 
    * @author Yi Zhang | 22/09/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void notifyManagerOfNewDelegatedApprover(Map<Id,User> oldMap, Map<Id,User> newMap) {
        for(User newUser : newMap.values()) {
            User oldUser = oldMap.get(newUser.Id);
            if(oldUser.DelegatedApproverId != newUser.DelegatedApproverId && newUser.DelegatedApproverId != null && newUser.ManagerId != null) {
                // send notification
                // generate notification
                Map<String, Object> flowInput = new Map<String, Object>();
                flowInput.put('customNotificationTypeName', 'Delegated Approver Changed');
                flowInput.put('targetId', newUser.Id);
                flowInput.put('recipientIds', new List<String>{newUser.ManagerId});
                flowInput.put('notificationTitle', newUser.FirstName + ' ' + newUser.LastName);
                flowInput.put('notificationBody', newUser.FirstName + ' ' + newUser.LastName + '\'s delegated approver has been set. ');
                Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
                sendCustomNotifiFlow.start();
            }
        }
    }
    
    /**
    * @description      Only when updating the user
    * @author Yi Zhang | 21/09/2020 
    * @param oldMap 
    * @param newList 
    **/
    public static void checkDelegatedApproverChanger(Map<Id, User> oldMap, List<User> newList) {
        Id currentUserId = UserInfo.getUserId();
        List<User> usersDelegatedApproverChangedByOthers = new List<User>();
        for(User newUser : newList) {
            User oldUser = oldMap.get(newUser.Id);

            // when delegated approver is changed other than the user self, check current user's profile
            if(oldUser.DelegatedApproverId != newUser.DelegatedApproverId && currentUserId != newUser.Id) {
                usersDelegatedApproverChangedByOthers.add(newUser);
            }
        }
        if(usersDelegatedApproverChangedByOthers.isEmpty() == false) {
            User currentUser = DM_User.getUser(currentUserId);
            // if current user's profile is not listed in Initialisation__mdt.CCRM_Initialisation.Delegated_Approver_Profile_Exemption__c
            // show error
            if(DM_Initialisation.ccrmInitialisation.Delegated_Approver_Profile_Exemption__c.contains(currentUser.Profile.Name) == false) {
                for(User user : usersDelegatedApproverChangedByOthers) {
                    user.addError(ERROR_UNAUTHORISED_DELEGATED_APPROVER_UPDATE);
                }
            }
        }
    }
    
    /**
    * @description 
    * @author Yi Zhang | 21/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    /** 07.Dec.2021 - Commented by Simplus MS - transferred the whole logic inside updateTSOwnedAccounts to resolve UNABLE_TO_LOCK_ROW issue since the two methods both update accounts
    public static void updateTSAssignedStores(Map<Id, User> oldMap, Map<Id, User> newMap) {
        // update assigned store of accounts owned by the user when:
        // - user is active, and
        // - user is a TS
        // - location is changed
        
        // Reuse method written by Francis Benzon SM_Account.mapAssignedStore
        
        // get users met criteria
        Map<Id, Id> ownerIdMap = new Map<Id, Id>(); // build this map as params for mapAssignedStore, both key & value are user Id
        for(User oldUser : oldMap.values()) {
            User newUser = newMap.get(oldUser.Id);
            if(
                newUser.isActive == true 
                && newUser.Is_TS__c == true
                && oldUser.Location_Code__c != newUser.Location_Code__c 
                && String.isNotBlank(newUser.Location_Code__c)) {
                    ownerIdMap.put(newUser.Id, newUser.Id);
                }
        }
        if(ownerIdMap.isEmpty()) {
            return;
        }
        
        // get accounts owned by users
        List<Account> accounts = DM_Account.getAccountsOwnedBy(ownerIdMap.values());
        System.debug('accounts '+accounts);
        if(accounts.isEmpty()) {
            return;
        }
        
        // find new account - store mapping
        Map<Id, Id> accountStoreIdMap = SM_Account.mapAssignedStore(accounts, ownerIdMap);
        System.debug('accountStoreIdMap396 '+accountStoreIdMap);
        if(accountStoreIdMap.isEmpty()) {
            return;
        }
        
        // build account list and send it off to async (can't do DML of other objects along with User object)
        List<Account> accountsToUpdate = new List<Account>();
        for(Id accountId : accountStoreIdMap.keySet()) {
            accountsToUpdate.add(new Account(Id = accountId, Assigned_Store__c = accountStoreIdMap.get(accountId)));
        }
        SM_Account.updateAccountList(JSON.serialize(accountsToUpdate));
        
    }
    **/
    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static Map<Id, Store_Member__c> enddateInactiveUsersStoreMembers(Map<Id,User> oldMap, Map<Id,User> newMap) {
        String locationCode;
        List<Id> userIds = new List<Id>();
        List<Id> inactiveUserIds = new List<Id>();
        Map<Id, Store_Member__c> membersMap = new Map<Id, Store_Member__c>();
        Map<Id, Store_Member__c> inactiveMembersMap = new Map<Id, Store_Member__c>();
        Map<Id,Store_Member__c> inactiveStoreMembersMap = new Map<Id, Store_Member__c>();
        Map<Id, Store_Member__c> promotedTSMembersMap = new Map<Id, Store_Member__c>();
        List<Id> storesToPromoteDefaultTS = new List<Id>();
        List<Id> storesToAlertRCM = new List<Id>();
        Map<Id, Task> taskMap = new Map<Id, Task>();    // Key is store Id, one store should have max one task
        
        for(User oldUser : oldMap.values()) {
            User newUser = newMap.get(oldUser.Id);
            // get all deactivated users or users no longer TS or location code changed
            if((oldUser.isActive == true && newUser.isActive == false)
               || (oldUser.Is_TS__c == true && newUser.Is_TS__c == false)
               || oldUser.Location_Code__c != newUser.Location_Code__c) {
                   userIds.add(oldUser.Id);
               }
            // get all the store members which are inactive
             if(newUser.isActive == true && oldUser.isActive == false
                    || newUser.Is_TS__c == true && oldUser.Is_TS__c == false
               || newUser.Location_Code__c != oldUser.Location_Code__c)//|| newUser.Location_Code__c != oldUser.Is_TS__c)
            {
                locationCode = newUser.Location_Code__c;
                inactiveUserIds.add(oldUser.Id);
            }
        }
        System.debug('userIds>> '+userIds+' inactiveUserIds>> '+inactiveUserIds);
        
        if(!userIds.isEmpty())
            // get all active store members for the userIds
            membersMap = new Map<Id, Store_Member__c>(DM_StoreMember.getStoreMembers(userIds, Constants.STOREMEMBER_ACTIVE_STATUS));
        if(!inactiveUserIds.isEmpty())
            // get all inactive store members for the userIds
            inactiveMembersMap = new Map<Id, Store_Member__c>(DM_StoreMember.getInactiveStoreMembers(inactiveUserIds, Constants.STOREMEMBER_INACTIVE_STATUS, locationCode));
        
        System.debug('Incactive Store Members Map>>  '+inactiveMembersMap);
        System.debug('active Store members Map>>  '+membersMap);
        
        //Create a Map of team memeber and store member record
         for(Store_Member__c member : inactiveMembersMap.values()) {
             inactiveStoreMembersMap.put(member.Team_Member__c, member);
         }
        System.debug('inactive Store Members Map**>> '+inactiveStoreMembersMap);
        
        // set active store members to inactive, and unselect Default TS
        for(Store_Member__c member : membersMap.values()) {
            member.End_Date__c = Date.today();
            member.Status__c = Constants.STOREMEMBER_INACTIVE_STATUS;
            if(member.Default_Trade_Specialist__c == true) {
                member.Default_Trade_Specialist__c = false;
                storesToPromoteDefaultTS.add(member.Store__c);
            }
        }
        //For CCRM15-454
        if(!inactiveMembersMap.isEmpty()) {
            for(Store_Member__c member : inactiveMembersMap.values()) {//for new scenario when sm is inactive and enddate is populated
                if(member.End_Date__c != null && member.Status__c == Constants.STOREMEMBER_INACTIVE_STATUS) {
                    member.End_Date__c = null;
                    member.Status__c = Constants.STOREMEMBER_ACTIVE_STATUS;
                    
                    if(member.Default_Trade_Specialist__c == true) {
                        member.Default_Trade_Specialist__c = false;
                        storesToPromoteDefaultTS.add(member.Store__c);
                    }
                    membersMap.put(member.Id, member);
                }
            }
        }
        System.debug('Store members to Update>> '+membersMap);
        // promote a remaining active TS to Default
        if(storesToPromoteDefaultTS.size() > 0) {
            for(Store__c store : DM_Store.getStoresWithActiveTSs(storesToPromoteDefaultTS)) {
                Boolean TSPromoted = false;
                if(store.User_Stores__r != null && store.User_Stores__r.size() > 0) {
                    // make sure active ones aren't those deactivated ones (which might happen accidentally)
                    for(Store_Member__c member : store.User_Stores__r) {
                        if(membersMap.containsKey(member.Id) == false) {
                            member.Default_Trade_Specialist__c = true;
                            promotedTSMembersMap.put(member.Id, member);
                            TSPromoted = true;
                            break;
                        }
                    }                    
                } 
                
                if(TSPromoted == false) {
                    storesToAlertRCM.add(store.Id);
                }
            }
        }
        
        // in case no remaining active TS, alert store's RCM
        if(storesToAlertRCM.size() > 0) {
            for(Store__c store : DM_Store.getStoresWithOneActiveRCM(storesToAlertRCM)) {
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
        System.debug('membersMap.values() '+membersMap);
        // future methods
        if(membersMap.size() > 0 || promotedTSMembersMap.size() > 0 || inactiveMembersMap.size() > 0) {
            SM_StoreMember.updateStoreMemberLists(
                JSON.serialize(membersMap.values()),
                JSON.serialize(promotedTSMembersMap.values()));
        }
        if(taskMap.size() > 0) {
            SM_StoreMember.upsertTaskList(JSON.serialize(taskMap.values()));
        }
        return inactiveStoreMembersMap;   
    }
    
    
    /**
    * @description 
    * @author Philip Clark | 23/06/2020 
    * @param newMap
    **/
    public static list<User> setTSManager(map<Id,User> oldMap, list<User> userList) {
        // system.debug('[SM_User.setTSUser] entering method');
        try {
            
            // Create one map for RCM identification and store only location code 
            map<String,Id> locCodeRSMMap = new map<String,Id>();
            for (User u : userList) {
                if (u.Is_TS__c == true) {
                    locCodeRSMMap.put(u.Location_Code__c,null);
                    
                }
            }
            
            set<String> roleSet = new set<String> {Constants.STOREMEMBER_RCM_ROLENAME};
                for (Store__c s : DM_Store.getStoreByLocCode(locCodeRSMMap.keySet(), Constants.STOREMEMBER_ACTIVE_STATUS, roleSet)) {
                    for (Store_Member__c sm : s.User_Stores__r) {
                        locCodeRSMMap.put(s.Location_Code__c,sm.Team_Member__c);
                    }
                }
            
            for (User u : userList) {
                if (
                    (u.Is_TS__c == true
                    && (oldMap==null || u.Location_Code__c!=oldMap.get(u.Id).Location_Code__c) 
                    && u.Location_Code__c!=null)
                ) {
                        
                    // where a trade specialist user is created identified by their profile, their manager is set
                    // based on RCM of the store.
                    if (locCodeRSMMap.get(u.Location_Code__c)!=null) {
                        u.ManagerId = locCodeRSMMap.get(u.Location_Code__c);
                        // system.debug('[SM_User.setTSUser] setting ManagerId: '+u.ManagerId);
                    }
                } else if((u.Is_TS__c == true && u.Location_Code__c != null && u.ManagerId == null)) { // CCRM15-548
                    if (locCodeRSMMap.get(u.Location_Code__c)!=null) {
                        u.ManagerId = locCodeRSMMap.get(u.Location_Code__c);
                        // system.debug('[SM_User.setTSUser] setting ManagerId: '+u.ManagerId);
                    }
                }
            }   
        } catch(Exception e) {
            ApplicationLogger.log('SM_User.setTSUser', 'User', 'Trigger', e);
        }
        return userList;
    }    
    
    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param oldMap 
    * @param newList 
    * @return List<User> 
    **/
    public static List<User> populateSalesRepIDAndRole(Map<Id, User> oldMap, List<User> newList) {
        
        List<String> locationCodes = new List<String>();
        
        if(oldMap == null) {
            // insert
            for(User newUser : newList) {
                if(isActiveTS(newUser) == true && String.isNotBlank(newUser.Location_Code__c)) {
                    locationCodes.add(newUser.Location_Code__c);
                }
            }
        } else {
            // update
            for(User newUser : newList) {
                User oldUser = oldMap.get(newUser.Id);
                
                if(noLongerAnActiveTS(oldUser, newUser) == true) {
                    // scenario 1: If user is no longer an active TS, remove Sales Rep ID
                    newUser.Sales_Rep_ID__c = null;
                } else if(becomeActiveTS(oldUser, newUser) == true && String.isNotBlank(newUser.Location_Code__c)) {
                    // scenario 2: If user becomes an active TS, find the Sales Rep record assigned to the store and populate Sales Rep ID
                    locationCodes.add(newUser.Location_Code__c);
                } else if(isActiveTS(newUser) == true && oldUser.Location_Code__c != newUser.Location_Code__c) {
                    // senario 3: If active TS' location code is changed, find the Sales Rep record assigned to the store and populate Sales Rep ID 
                    if(String.isBlank(newUser.Location_Code__c)) {  // in case location code is removed, removed sales rep id as well
                        newUser.Sales_Rep_ID__c = null;
                    } else {
                        locationCodes.add(newUser.Location_Code__c);
                    }
                } else if(isActiveTS(newUser) == true && oldUser.Bunnings_Job_Role__c != newUser.Bunnings_Job_Role__c) {
                    // scenaro 4: If active TS' job role is changed, source sales rep id field might change '+newUser.Location_Code__c);
                    locationCodes.add(newUser.Location_Code__c);
                }
            }
        }
        
        if(locationCodes.isEmpty()) {
            return newList;
        }
        
        // get Sales Rep records
        // location code - category - sales rep id mapping
        Map<String, Map<String, String>> locationCodeSalesRepIdMap = SM_SalesRep.mapLocCodeCategorySalesRepId(DM_SalesRep.getActiveSalesRepsWith(locationCodes));
        // TS Role is also based on Location Code -> Store -> Store's Operations Region Code -> Role Name -> Role Id
        // get location code - ts role id Map by combining:
        // location code - operations region Map
        // operations region - ts role name Map
        // ts role name - ts role id Map
        Map<String, String> locationCodeOpRegCodeMap = new Map<String, String>();
        Map<String, String> opRegCodeRoleNameMap = new Map<String, String>();
        Map<String, String> locationCodeRoleNameMap = new Map<String, String>();
        Map<String, String> roleNameIdMap = new Map<String, String>();
        Map<String, String> locationCodeRoleIdMap = new Map<String, String>();
        // get location code - operations region Map (through Store)
        for(Store__c store : DM_Store.getStoresWithValidOpRegCodeByLocationCode(locationCodes)) {
            locationCodeOpRegCodeMap.put(store.Location_Code__c, store.Operations_Region_Code__c);
        }
        // get operations region - ts role name Map (through Operations Region TS Roles metadata)
        if(locationCodeOpRegCodeMap.size() > 0) {
            for(Operations_Region_TS_Role__mdt optr : DM_OperationsRegionTSRole.getRecordsByOpRegCode(locationCodeOpRegCodeMap.values())) {
                opRegCodeRoleNameMap.put(optr.Operations_Region__c, optr.Trade_Specialist_Role__c);
            }
            // combine locationCodeOpRegCodeMap & opRegCodeRoleNameMap into locationCodeRoleNameMap
            locationCodeRoleNameMap = combineMaps(locationCodeOpRegCodeMap, opRegCodeRoleNameMap);
        }
        // get ts role name - ts role id Map
        if(locationCodeRoleNameMap.size() > 0) {
            for(UserRole ur : DM_UserRole.getRolesByName(locationCodeRoleNameMap.values())) {
                roleNameIdMap.put(ur.Name, ur.Id);
            }
            // combine locationCodeRoleNameMap & roleNameIdMap into locationCodeRoleIdMap
            locationCodeRoleIdMap = combineMaps(locationCodeRoleNameMap, roleNameIdMap);
            
        }
        
        
        if(locationCodeSalesRepIdMap.isEmpty() && locationCodeRoleIdMap.isEmpty()) {
            return newList;
        }
        
        if(oldMap == null) {
            // insert
            for(User newUser : newList) {
                if(isActiveTS(newUser) && String.isNotBlank(newUser.Location_Code__c)) {
                    if(locationCodeSalesRepIdMap.containsKey(newUser.Location_Code__c)) {
                        // default
                        newUser.Sales_Rep_ID__c = locationCodeSalesRepIdMap.get(newUser.Location_Code__c).get(SM_SalesRep.CATEGORY_DEFAULT);
                        // override when bunnings job role is populated and metadata specifies the field
                        if(String.isNotBlank(newUser.Bunnings_Job_Role__c)) {
                            String category = DM_SalesRepCategoryMapping.jobRoleSalesRepCategoryMap.get(newUser.Bunnings_Job_Role__c);
                            if(category != null && locationCodeSalesRepIdMap.get(newUser.Location_Code__c).containsKey(category)) {
                                newUser.Sales_Rep_ID__c = locationCodeSalesRepIdMap.get(newUser.Location_Code__c).get(category);
                            }
                        }
                    }
                    if(locationCodeRoleIdMap.containsKey(newUser.Location_Code__c)) {
                        newUser.UserRoleId = locationCodeRoleIdMap.get(newUser.Location_Code__c);
                    }
                }
            }
        } else {
            // update
            for(User newUser : newList) {
                User oldUser = oldMap.get(newUser.Id);
                // become an active TS, or an active TS changes location code, or an active TS changes job role
                if(String.isNotBlank(newUser.Location_Code__c) && (
                    becomeActiveTS(oldUser, newUser) == true 
                    || (isActiveTS(newUser) == true && oldUser.Location_Code__c != newUser.Location_Code__c)
                    || (isActiveTS(newUser) == true && oldUser.Bunnings_Job_Role__c != newUser.Bunnings_Job_Role__c)
                )) {
                    // System.debug('role changed');
                    // System.debug('locationCodeSalesRepIdMap:' + locationCodeSalesRepIdMap);
                    // System.debug('newUser.Location_Code__c:' + newUser.Location_Code__c);
                    if(locationCodeSalesRepIdMap.containsKey(newUser.Location_Code__c)) {
                        // default
                        newUser.Sales_Rep_ID__c = locationCodeSalesRepIdMap.get(newUser.Location_Code__c).get(SM_SalesRep.CATEGORY_DEFAULT);
                        // override when bunnings job role is populated and metadata specifies the field
                        if(String.isNotBlank(newUser.Bunnings_Job_Role__c)) {
                            String category = DM_SalesRepCategoryMapping.jobRoleSalesRepCategoryMap.get(newUser.Bunnings_Job_Role__c);
                            if(category != null && locationCodeSalesRepIdMap.get(newUser.Location_Code__c).containsKey(category)) {
                                newUser.Sales_Rep_ID__c = locationCodeSalesRepIdMap.get(newUser.Location_Code__c).get(category);
                            }
                        }
                    }
                    if(locationCodeRoleIdMap.containsKey(newUser.Location_Code__c)) {
                        newUser.UserRoleId = locationCodeRoleIdMap.get(newUser.Location_Code__c);
                    }
                }
            }
        }
        return newList;
    }
    
    /**
    * @description CCRM15-416 - The SF role needs to be populated automatically for all AMs
    * @author Simplus MS | 14/12/2021 
    * @param oldMap 
    * @param newList 
    * @return List<User> 
    **/
    public static List<User> populateAMRole(Map<Id, User> oldMap, List<User> newList) {
        
        system.debug('inside populateAMRole');
        Set<String> AMProfiles = new Set<String>{Constants.AU_ACCOUNT_MANAGER_PROFILENAME, Constants.NZ_ACCOUNT_MANAGER_PROFILENAME};
        Map<String,Id> AMProfileIdMap = new Map<String,Id>();
        Map<String, String> userManagerMap = new Map<String, String>();
        Map<String, String> managerRoleMap = new Map<String, String>();
        Map<String, String> roleNameIdMap = new Map<String, String>();
        Map<String, String> roleAssignmentMap = new Map<String, String>();
        String roleASM_Name;
        String roleAM_Name;
        
        //Get Profile Ids of Account managers
        for (Profile p : DM_Profile.getProfilebyName(AMProfiles)) {
            AMProfileIdMap.put(p.Name,p.Id);
        }
   
        //Get all user roles
        for(UserRole ur : DM_UserRole.getAllRoles()) {
            roleNameIdMap.put(ur.Name, ur.Id);
        }
        
        //Get all Account_Manager_Role_Assignment__mdt records
        for(Account_Manager_Role_Assignment__mdt amr : [Select Id, Country__c, Manager_Role__c, Subordinate_Role__c From Account_Manager_Role_Assignment__mdt]) {
            roleAssignmentMap.put(amr.Manager_Role__c, amr.Subordinate_Role__c);
        }
        
        if(oldMap == null) {
            //insert
            for (User u : newList){
                if(u.isActive == TRUE && 
                   (u.ProfileId == AMProfileIdMap.get(Constants.AU_ACCOUNT_MANAGER_PROFILENAME) || u.Profile.Name == AMProfileIdMap.get(Constants.NZ_ACCOUNT_MANAGER_PROFILENAME))
                   && u.ManagerId != null) {
                       userManagerMap.put(u.Id, u.ManagerId);
                   }
            }
        } else {
            //update
            for (User u : newList){
                User oldUser = oldMap.get(u.Id);
                if(u.isActive == TRUE && 
                   (u.ProfileId == AMProfileIdMap.get(Constants.AU_ACCOUNT_MANAGER_PROFILENAME) || u.Profile.Name == AMProfileIdMap.get(Constants.NZ_ACCOUNT_MANAGER_PROFILENAME))
                   && u.ManagerId != null && u.ManagerId != oldUser.ManagerId) {
                       userManagerMap.put(u.Id, u.ManagerId);
                   }
            }
        }

        if (userManagerMap.values().isEmpty()) return newList;
        
        List<User> lManagers = [Select Id, UserRoleId, UserRole.Name From User Where Id IN: userManagerMap.values()];
        for (User u : lManagers){
            managerRoleMap.put(u.Id, u.UserRole.Name);
        }
        
        if (managerRoleMap.isEmpty()) return newList;

        for(User u : newList) {
            if (userManagerMap.containsKey(u.Id)){
                if (u.ManagerId != null && managerRoleMap.containsKey(u.ManagerId)) roleASM_Name = managerRoleMap.get(u.ManagerId);
                if (roleASM_Name != null && roleAssignmentMap.containsKey(roleASM_Name)) roleAM_Name = roleAssignmentMap.get(roleASM_Name);
                if (roleAM_Name != null && roleNameIdMap.containsKey(roleAM_Name)) u.UserRoleId = roleNameIdMap.get(roleAM_Name);
            }
        }
        
        return newList;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 21/10/2020 
    * @param oldMap 
    * @param newList 
    * @return List<User> 
    **/
    public static List<User> populateAddress(Map<Id, User> oldMap, List<User> newList) {
        
        List<String> locationCodes = new List<String>();
        
        if(oldMap == null) {
            // insert
            for(User newUser : newList) {
                if(newUser.isActive == true && String.isNotBlank(newUser.Location_Code__c)) {
                    locationCodes.add(newUser.Location_Code__c);
                }
            }
        } else {
            // update
            for(User newUser : newList) {
                User oldUser = oldMap.get(newUser.Id);
                if(newUser.isActive == true && oldUser.Location_Code__c != newUser.Location_Code__c && String.isNotBlank(newUser.Location_Code__c)) {
                    locationCodes.add(newUser.Location_Code__c);
                }
            }
        }
        
        if(locationCodes.isEmpty()) {
            return newList;
        }
        
        // get stores with address details and convert to map
        Map<String, Store__c> storeMap = new Map<String, Store__c>();
        for(Store__c store : DM_Store.getStoresWithAddressByLocationCode(locationCodes)) {
            storeMap.put(store.Location_Code__c, store);
        }
        
        // map address field by field
        if(storeMap.isEmpty() == false) {
            if(oldMap == null) {
                // insert
                for(User newUser : newList) {
                    if(newUser.isActive == true && String.isNotBlank(newUser.Location_Code__c)) {
                        newUser = mapStoreAddressToUserAddress(newUser, storeMap.get(newUser.Location_Code__c));
                    }
                }
            } else {
                // update
                for(User newUser : newList) {
                    User oldUser = oldMap.get(newUser.Id);
                    if(newUser.isActive == true && oldUser.Location_Code__c != newUser.Location_Code__c && String.isNotBlank(newUser.Location_Code__c)) {
                        // additional requirement for update: store must be of certain types
                        Store__c store = storeMap.get(newUser.Location_Code__c);
                        if(store != null && SM_Store.STORE_LOCATION_TYPES_FOR_ADDRESS_UPDATE.contains(store.Location_Type__c)) {
                            newUser = mapStoreAddressToUserAddress(newUser, store);
                        }
                    }
                }
            }
        }
        
        
        return newList;
    }
    
        /**
    * @description CCRM15-566 - TS onboarding email - Update fields for user's email address
    * @author Simplus MS | 18/01/2022 
    * @param oldMap 
    * @param newList 
    * @return List<User> 
    **/
    public static List<User> populateStoreEmail(Map<Id, User> oldMap, List <User> newList) {
        Map<User, String> locationCodeToUserMap = new Map<User, String>();
        Map<String, String> locationCodeToEmailMap = new Map<String, String>();
        Map<Id, User> usersToReturn = new Map<Id, User>();
        
        if(oldMap == null) {
            //insert
            for (User u : newList) {
                usersToReturn.put(u.Id, u); //putting all users for return
                if (u.Location_Code__c != null && u.isActive == true){
                    locationCodeToUserMap.put(u, u.Location_Code__c);
                }
            }
        }else {
            //update
            for (User u : newList) {
                usersToReturn.put(u.Id, u); //putting all users for return
                Boolean newRoleIsTS = null;
                Boolean oldRoleIsTS = null;
                try { newRoleIsTS = u.UserRoleId!=null ? u.UserRole.Name.contains(Label.Trade_Specialist) : null; } catch(Exception e){}
                try { oldRoleIsTS = oldMap.get(u.Id).UserRoleId!=null ? oldMap.get(u.Id).UserRole.Name.contains(Label.Trade_Specialist) : null; } catch(Exception e){}
                if ((u.ProfileId!=oldMap.get(u.Id).ProfileId || u.Location_Code__c!=oldMap.get(u.Id).Location_Code__c || oldMap.get(u.Id).isActive == false 
                     || (newRoleIsTS == true && (oldRoleIsTS == false || oldRoleIsTS == null)))
                    && u.Location_Code__c != null && u.isActive == true){
                        locationCodeToUserMap.put(u, u.Location_Code__c);
                    }
            }
        }

        if (!locationCodeToUserMap.isEmpty()){
            for (Store__c st : [Select Id, Trade_Specialist_Email__c, Location_Code__c From Store__c Where Location_Code__c IN: locationCodeToUserMap.values() ]){
                locationCodeToEmailMap.put(st.Location_Code__c, st.Trade_Specialist_Email__c);
            }
        }
        
        if (!locationCodeToEmailMap.isEmpty()){
            for (User u : locationCodeToUserMap.keySet()){
                usersToReturn.get(u.Id).Store_Email__c = locationCodeToEmailMap.get(u.Location_Code__c);
            }
        }

        return usersToReturn.values();
    }
    /**
    * @description 
    * @author Yi Zhang | 21/10/2020 
    * @param user 
    * @param store 
    * @return User 
    **/
    public static User mapStoreAddressToUserAddress(User user, Store__c store) {
        if(store != null) {
            user.Street = String.isBlank(store.Address_Line_1__c) ? '' : store.Address_Line_1__c;
            user.Street += String.isBlank(store.Address_Line_2__c) ? '' : ('\n' + store.Address_Line_2__c);
                user.Street += String.isBlank(store.Address_Line_3__c) ? '' : ('\n' + store.Address_Line_3__c);
                    user.City = store.City__c;
            user.State = store.State__c;
            user.PostalCode = store.Postcode__c;
            user.Country = store.Country__c;
            user.Store_Email__c = store.Trade_Specialist_Email__c; //Added by Simplus MS 18.Jan.2022 for CCRM15-566
        }
        return user;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 22/10/2020 
    * @param usersJson 
    * @param functionName 
    * @param objectName 
    **/
    @future
    public static void updateUsersAsync(String usersJson, String functionName, String objectName) {
        List<User> users = (List<User>) JSON.deserialize(usersJson, List<User>.class);
        try {
            update users;
        } catch(Exception e) {
            ApplicationLogger.log(functionName, objectName, 'Trigger', e);
        }
    }
    
    private static Boolean isActiveTS(User user) {
        return user.isActive == true && user.IS_TS__c == true;
    }
    
    private static Boolean noLongerAnActiveTS(User oldUser, User newUser) {
        return oldUser.isActive == true && oldUser.IS_TS__c == true && (newUser.isActive == false || newUser.IS_TS__c == false);
    }
    
    private static Boolean becomeActiveTS(User oldUser, User newUser) {
        return newUser.isActive == true && newUser.IS_TS__c == true && (oldUser.isActive == false || oldUser.IS_TS__c == false);
    }
    
    public static Map<String, String> combineMaps(Map<String, String> map1, Map<String, String> map2) {
        // map1's value = map2's key
        Map<String, String> outputMap = new Map<String, String>();
        if(map2.isEmpty()) {
            return outputMap;
        }
        
        for(String key : map1.keySet()) {
            String val = map1.get(key);
            if(map2.containsKey(val)) {
                outputMap.put(key, map2.get(val));
            }
        }
        return outputMap;
    }
    
    @TestVisible private static String defaultApprovalRequestEmailSetting;
    
    private static List<User> initialiseApprovalRequestEmailSetting(List<User> newList) {
        if (!Test.isRunningTest()) {
            defaultApprovalRequestEmailSetting = DM_Initialisation.ccrmInitialisation.DefaultApprovalRequestEmailSetting__c;
        }
        
        for (User usr : newList) {
            if (defaultApprovalRequestEmailSetting == Constants.INIT_APPRVEMAIL_NO_EMAILS) {
                usr.UserPreferencesReceiveNoNotificationsAsApprover = true;
                usr.UserPreferencesReceiveNotificationsAsDelegatedApprover = false;
            }
            else if (defaultApprovalRequestEmailSetting == Constants.INIT_APPRVEMAIL_APPROVER_ONLY) {
                usr.UserPreferencesReceiveNoNotificationsAsApprover = false;
                usr.UserPreferencesReceiveNotificationsAsDelegatedApprover = false;
            }
            else if (defaultApprovalRequestEmailSetting == Constants.INIT_APPRVEMAIL_DELEGATE_ONLY) {
                usr.UserPreferencesReceiveNoNotificationsAsApprover = true;
                usr.UserPreferencesReceiveNotificationsAsDelegatedApprover = true;
            }
            else if (defaultApprovalRequestEmailSetting == Constants.INIT_APPRVEMAIL_ALL) {
                usr.UserPreferencesReceiveNoNotificationsAsApprover = false;
                usr.UserPreferencesReceiveNotificationsAsDelegatedApprover = true;
            }
        }
        
        return newList;
    }
    
    /**
    * @description                  Fix for PROD_0969834 to filter User records with specific unpopulated fields per use case
    * @author                       Simplus MS | 27/07/2021    
    * @param Map<Id User> param1    expects oldMap of User, named param1 for uniformity
    * @param Object param2          expects an ambiguous object
    * @param Process proc 
    * @param TriggerStep step 
    * @return Object                cast return object for method use
    **/
    public static Object filterForRerun(Map<Id,User> param1, Object param2, Process proc, TriggerStep step) {
        
        List<User> tempList = new List<User>();
        
        // filters non populated ManagerId
        if((step == TriggerStep.ON_INSERT || step == TriggerStep.ON_UPDATE) && proc == Process.SET_MANAGER) {
            List<User> newList = (List<User>) param2;
            Set<Id> userIds = new Map<Id,User>(newList).keySet();
            List<User> dbUserList = [
                SELECT Id, Is_TS__c, Location_Code__c, ManagerId, isActive, Sales_Rep_ID__c, Bunnings_Job_Role__c, Street, City, State, PostalCode, Country, UserPreferencesReceiveNoNotificationsAsApprover, UserPreferencesReceiveNotificationsAsDelegatedApprover, UserName
                FROM User WHERE Id IN :userIds
            ];
            for(User u : dbUserList) {
                if(u.Is_TS__c == true 
                   && (param1==null || u.Location_Code__c!=param1.get(u.Id).Location_Code__c) 
                   && u.Location_Code__c!=null && u.ManagerId == null) { 
                       tempList.add(u);
                   }
            }
            return tempList;
        }
        
        // filters non populated salesrepId and roleId
        if(step == TriggerStep.ON_INSERT && proc == Process.SET_SALESREPID_AND_ROLE) {
            List<User> newList = (List<User>) param2;
            Set<Id> userIds = new Map<Id,User>(newList).keySet();
            List<User> dbUserList = [
                SELECT Id, Is_TS__c, Location_Code__c, ManagerId, isActive, Sales_Rep_ID__c, Bunnings_Job_Role__c, Street, City, State, PostalCode, Country, UserPreferencesReceiveNoNotificationsAsApprover, UserPreferencesReceiveNotificationsAsDelegatedApprover, UserName, UserRoleId
                FROM User WHERE Id IN :userIds
            ];
            for(User u : dbUserList) {
                if(salesRepIdOrRoleNotSet(u) && u.Is_TS__c == true) { 
                    tempList.add(u);
                }
            }
            return tempList;
        }
        
        // filters non populated salesrepId and roleId
        if(step == TriggerStep.ON_UPDATE && proc == Process.SET_SALESREPID_AND_ROLE) {
            List<User> newList = (List<User>) param2;
            Set<Id> userIds = new Map<Id,User>(newList).keySet();
            List<User> dbUserList = [
                SELECT Id, Is_TS__c, Location_Code__c, ManagerId, isActive, Sales_Rep_ID__c, Bunnings_Job_Role__c, Street, City, State, PostalCode, Country, UserPreferencesReceiveNoNotificationsAsApprover, UserPreferencesReceiveNotificationsAsDelegatedApprover, UserName, UserRoleId
                FROM User WHERE Id IN :userIds
            ];
            Map<Id,User> oldMap = param1;
            for(User newUser : dbUserList) {
                User oldUser = oldMap.get(newUser.Id);
                if(noLongerAnActiveTS(oldUser, newUser) == true && newUser.Sales_Rep_ID__c != null) 
                    tempList.add(newUser);
                else if(becomeActiveTS(oldUser, newUser) == true && String.isNotBlank(newUser.Location_Code__c) && salesRepAndRoleNotChanged(oldUser, newUser)) 
                    tempList.add(newUser);
                else if(isActiveTS(newUser) == true && oldUser.Location_Code__c != newUser.Location_Code__c) {
                    if(String.isBlank(newUser.Location_Code__c) && newUser.Sales_Rep_ID__c != null) 
                        tempList.add(newUser);
                    else if(salesRepAndRoleNotChanged(oldUser, newUser)) 
                        tempList.add(newUser);
                }
                else if(isActiveTS(newUser) == true && oldUser.Bunnings_Job_Role__c != newUser.Bunnings_Job_Role__c && salesRepAndRoleNotChanged(oldUser, newUser)) 
                    tempList.add(newUser);
            }
            return tempList;
        }
        
        // filters non created storemember on related store
        if((step == TriggerStep.ON_INSERT && step == TriggerStep.ON_UPDATE) && proc == Process.CREATE_STOREMEMBER) {
            Map<Id,Set<String>> userLocMap = (Map<Id,Set<String>>) param2;
            Set<Id> userIds = userLocMap.keySet();
            List<Store_Member__c> dbSmList = [
                SELECT Id, Team_Member__c FROM Store_Member__c 
                WHERE Status__c = :Constants.STOREMEMBER_ACTIVE_STATUS AND Team_Member__c IN :userIds
            ];
            for(Store_Member__c sm : dbSmList) {
                if(userLocMap.containsKey(sm.Team_Member__c))
                    userLocMap.remove(sm.Team_Member__c);
            }
            return userLocMap;
        }
        
        return null;
    }
    
    /**
    * @description CCRM15-259
    * @author Simplus MS | 04.Nov.2021
    * @param oldMap 
    * @param newMap 
    * modification: CCRM15-407
    **/
    public static void updateTSOwnedAccounts(Map<Id, User> oldMap, Map<Id, User> newMap) {
        system.debug('inside method updateTSOwnedAccounts >>');
        Map<Id, String> ownerIdMapSalesRep = new Map<Id, String>();
        Map<Id,String> accountOwnerAndTMMap = new Map<Id,String>();
        Map<Id,Date> userLastModifiedDateMap = new Map<Id,Date>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Id defaultOwnerIdAU, defaultOwnerIdNZ;
        
        //Logic below is from updateTSAssignedStores
        // update assigned store of accounts owned by the user when:
        // - user is active, and
        // - user is a TS
        // - location is changed
        
        // Reuse method written by Francis Benzon SM_Account.mapAssignedStore
        
        // get users met criteria
        Map<Id, Id> ownerIdMap = new Map<Id, Id>(); // build this map as params for mapAssignedStore, both key & value are user Id
        Set<Id> tsOwnerSet = new Set<Id>();
        Map<Id, Profile> tsProfileMap = new Map<Id, Profile>([Select ID, Name FROM Profile WHERE Name LIKE '%Trade Specialist%']);

        for(User oldUser : oldMap.values()) {
            User newUser = newMap.get(oldUser.Id);
            
            if(newUser.isActive == true && oldUser.Sales_Rep_ID__c != newUser.Sales_Rep_ID__c) {
                ownerIdMapSalesRep.put(newUser.Id, newUser.Sales_Rep_ID__c);
            }
            
            // SFSUP-431 - Accounts being transferred to default user when not expected
            if(!tsProfileMap.containsKey(newUser.ProfileId) && tsProfileMap.containsKey(oldUser.ProfileId)) {
                tsOwnerSet.add(newUser.Id);
            }
            
            userLastModifiedDateMap.put(newUser.Id,date.newinstance(newUser.LastModifiedDate.year(), newUser.LastModifiedDate.month(), newUser.LastModifiedDate.day()));
            
            // If user is active and Location Code or Role is changed update account owner to default user
            if(newUser.isActive == true && String.isNotBlank(newUser.Location_Code__c) && String.isNotBlank(oldUser.Location_Code__c) && 
               (oldUser.Location_Code__c != newUser.Location_Code__c || (oldUser.Bunnings_Job_Role__c != newUser.Bunnings_Job_Role__c && String.isNotBlank(newUser.Bunnings_Job_Role__c) && String.isNotBlank(oldUser.Bunnings_Job_Role__c)))) {
                   System.debug('User is Active>> '+newUser.isActive);
                   ownerIdMap.put(newUser.Id, newUser.Id);
               }
            // If user is inactive update account owner to default user
            if(newUser.isActive != true) {
                System.debug('User is InActive>> '+newUser.isActive);
                ownerIdMap.put(newUser.Id, newUser.Id);
            }
        }
        
        //To Update Account_Owner_Sales_Id__c of accounts owned by User - CCRM15-259
        if (ownerIdMapSalesRep.isEmpty() == false){
            // get accounts owned by users
            List<Account> accountsOwned = DM_Account.getAccountsOwnedBy(new List<Id>(ownerIdMapSalesRep.keySet()));
            System.debug('accountsOwned '+accountsOwned);
            
            if(accountsOwned.isEmpty()){
                return;
            } else {
                for (Account acc : accountsOwned){
                    acc.Account_Owner_Sales_Id__c = ownerIdMapSalesRep.get(acc.OwnerId);
                    if (accountMap.containsKey(acc.Id)){
                        accountMap.get(acc.Id).Account_Owner_Sales_Id__c = acc.Account_Owner_Sales_Id__c;
                    }else {
                        accountMap.put(acc.Id, acc);
                    }
                    
                }
            }
        }

        List<User> auUsers = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c});
            if(auUsers.isEmpty() == false) {
                defaultOwnerIdAU = auUsers[0].Id;
            }
        List<User> nzUser = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Default_NZ_Account_Owner__c});
            if(nzUser.isEmpty() == false) {
                defaultOwnerIdNZ = nzUser[0].Id;
            }
        
        System.debug('tsOwnerSet: '+tsOwnerSet);
        // SFSUP-431 - Accounts being transferred to default user when not expected
        if(!tsOwnerSet.isEmpty()) {
            // get accounts owned by users   
            List<Account> accounts = DM_Account.getAccountsOwnedBy(new List<Id>(tsOwnerSet));
            System.debug('accounts '+accounts);
            
                if(!accounts.isEmpty()) {
                
                /*List<User> auUsers = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c});
                if(auUsers.isEmpty() == false) {
                    defaultOwnerIdAU = auUsers[0].Id;
                }
                List<User> nzUser = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Default_NZ_Account_Owner__c});
                if(nzUser.isEmpty() == false) {
                    defaultOwnerIdNZ = nzUser[0].Id;
                }*/
                System.debug('defaultOwnerIdNZ >>'+defaultOwnerIdNZ+' defaultOwnerIdAU '+defaultOwnerIdAU);
                
                for(Account acc : accounts) {
                    
                    if(acc.RecordType.Name.startsWith('AU')){
                        acc.OwnerId = defaultOwnerIdAU;
                    }else if(acc.RecordType.Name.startsWith('NZ')){
                        acc.OwnerId = defaultOwnerIdNZ;
                    }
                    accountMap.put(acc.Id, acc);
                }
            }
        }


        if(ownerIdMap.isEmpty() == false) {
            
            // get accounts owned by users
            List<Account> accounts = DM_Account.getAccountsOwnedBy(ownerIdMap.values());
            System.debug('accounts '+accounts);
            
            if(accounts.isEmpty()) {
                return;
            }
            
            // find new account - store mapping
            Map<Id, Id> accountStoreIdMap = SM_Account.mapAssignedStore(accounts, ownerIdMap);
            
            /**
            // build account list and send it off to async (can't do DML of other objects along with User object)
            List<Account> accountsToUpdate = new List<Account>();
            for(Id accountId : accountStoreIdMap.keySet()) {
                //accountsToUpdate.add(new Account(Id = accountId, Assigned_Store__c = accountStoreIdMap.get(accountId)));
                if (accountStoreIdMap.containsKey(accountId)){
                    accountMap.put(accountId, new Account(Id = accountId, Assigned_Store__c = accountStoreIdMap.get(accountId)));
                }
            }
            **/
            //Get Default User Id from metadata
            
            /*List<User> auUsers = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c});
            if(auUsers.isEmpty() == false) {
                defaultOwnerIdAU = auUsers[0].Id;
            }
            List<User> nzUser = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Default_NZ_Account_Owner__c});
            if(nzUser.isEmpty() == false) {
                defaultOwnerIdNZ = nzUser[0].Id;
            }*/
            System.debug('defaultOwnerIdNZ >>'+defaultOwnerIdNZ+' defaultOwnerIdAU '+defaultOwnerIdAU);
            
            for(Account acc : accounts) {
                
                accountOwnerAndTMMap.put(acc.Id, acc.Owner.Name+' - '+acc.Owner.Team_Member_ID__c);
                System.debug('Account Owner Id and Team Member No>> '+accountOwnerAndTMMap);
                
                if(acc.Owner.Profile.Name.contains(Label.Trade_Specialist)) {
                    acc.Last_Owner_Transfer_Date__c = userLastModifiedDateMap.get(acc.OwnerId);
                    System.debug('Role '+acc.Owner.UserRole.Name);
                    if(acc.RecordType.Name.startsWith('AU'))
                        acc.OwnerId = defaultOwnerIdAU;
                    else if(acc.RecordType.Name.startsWith('NZ'))
                        acc.OwnerId = defaultOwnerIdNZ;
                    acc.Previous_Owner__c = accountOwnerAndTMMap.get(acc.Id);
                }
                
                if (accountMap.containsKey(acc.Id)){
                    accountMap.get(acc.Id).Last_Owner_Transfer_Date__c = acc.Last_Owner_Transfer_Date__c;
                    accountMap.get(acc.Id).OwnerId = acc.OwnerId;
                    accountMap.get(acc.Id).Previous_Owner__c = acc.Previous_Owner__c;
                } else {
                    accountMap.put(acc.Id, acc);
                }
                System.debug('Account Owner Id>> '+acc.OwnerId);
            }
        }
        //send update accounts to async (can't do DML of other objects along with User object)
        //using Queueable since the process is sometimes initiated in a future method: SM_SalesRep.updateUsersAsync
        //Future method cannot be called from a future or batch method
        System.enqueueJob(new SM_UpdateSObjectsQueueable(accountMap.values(), 'SM_User.updateTSOwnedAccounts', TRUE, 'Account'));
        //ystem.enqueueJob(new SM_UpdateAccountsSalesRepQueueable(accountMap.values()));
        
    }
    
    /**
    * @description 
    * @author Simplus MS | 27/07/2021
    * @param User newUser 
    * @return Boolean 
    **/
    private static Boolean salesRepIdOrRoleNotSet(User newUser) {
        return (newUser.Sales_Rep_ID__c == null || newUser.UserRoleId == null);
    }
    /**
    * @description 
    * @author Simplus MS | 27/07/2021
    * @param User oldUser 
    * @param User newUser 
    * @return Boolean 
    **/
    private static Boolean salesRepAndRoleNotChanged(User oldUser, User newUser) {
        return (oldUser.Sales_Rep_ID__c == newUser.Sales_Rep_ID__c
                || oldUser.UserRoleId == newUser.UserRoleId == null);
    }
    

}