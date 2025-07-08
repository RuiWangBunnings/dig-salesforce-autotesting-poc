/*******************************************************************************************************
* Class Name      	: SM_SalesRep
* Description		: Domain / Service layer for Sales_Rep__c object
* Author          	: Simplus - Yi Zhang
* Created On      	: 24/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              24/08/2020		1000				Initial version
* Yi Zhang              19/10/2020		2000				Revised to allow 1 active record for the same store per category
******************************************************************************************************/
public with sharing class SM_SalesRep {
    public static final String ERROR_SINGLE_ACTIVE_STORE_PER_CATEGORY = 'You can have only one active Sales Rep record for a Store for each category';
    public static final String ERROR_SINGLE_ACTIVE_TEAM_MEMBER = 'You can have only one active Sales Rep record for a Team Member';
    public static final String CATEGORY_DEFAULT = 'Default';
    
    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param newList 
    **/
    public static void beforeInsert(List<Sales_Rep__c> newList) {

        // validate single active store  / team member
        singleActiveStoreOrTeamMember(newList);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param newMap 
    **/
    public static void afterInsert(Map<Id, Sales_Rep__c> newMap) {

        List<Sales_Rep__c> activeSalesReps = new List<Sales_Rep__c>();
        List<Sales_Rep__c> activeStoreSalesReps = new List<Sales_Rep__c>();
        for(Sales_Rep__c sr : newMap.values()) {
            if(sr.Status__c == Constants.STATUS_ACTIVE) {
                activeSalesReps.add(sr);
                if(String.isNotBlank(sr.Assigned_to_Store__c) && sr.Category__c == CATEGORY_DEFAULT) {
                    activeStoreSalesReps.add(sr);
                }
            }
        }
        // assign sales rep Id
        assignSalesRepId(activeSalesReps);

        // update store's Sales rep Ids
        updateStoreSalesRepIds(activeStoreSalesReps);
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void beforeUpdate(Map<Id, Sales_Rep__c> oldMap, Map<Id, Sales_Rep__c> newMap) {

        // validate single active store  / team member
        singleActiveStoreOrTeamMember(newMap.values());
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Sales_Rep__c> oldMap, Map<Id, Sales_Rep__c> newMap) {

        List<Sales_Rep__c> activatedSalesReps = new List<Sales_Rep__c>();
        List<Sales_Rep__c> storeSalesRepsWithSalesRepIdChanged = new List<Sales_Rep__c>();
        List<Sales_Rep__c> deactivatedSalesReps = new List<Sales_Rep__c>();
        for(Sales_Rep__c newSalesRep : newMap.values()) {
            Sales_Rep__c oldSalesRep = oldMap.get(newSalesRep.Id);

            // for user update (either through direct link or store member)
            if(oldSalesRep.Status__c == Constants.STATUS_INACTIVE && newSalesRep.Status__c == Constants.STATUS_ACTIVE) {
                // scenario 1: inactive -> active
                activatedSalesReps.add(newSalesRep);
            } else if(oldSalesRep.Status__c == Constants.STATUS_ACTIVE && newSalesRep.Status__c == Constants.STATUS_INACTIVE) {
                // scenario 2: active -> inactive
                deactivatedSalesReps.add(oldSalesRep);
            } else if(newSalesRep.Status__c == Constants.STATUS_ACTIVE) {
                // scenario 3: active -> active, but store / team member changed
                if(newSalesRep.Assigned_to_Store__c != oldSalesRep.Assigned_to_Store__c
                || newSalesRep.Assigned_to_Team_Member__c != oldSalesRep.Assigned_to_Team_Member__c) {
                    activatedSalesReps.add(newSalesRep);
                    deactivatedSalesReps.add(oldSalesRep);
                }
                // scenario 4: active -> active, but current sales rep Id changed
                if(newSalesRep.Current_Sales_Rep_ID__c != oldSalesRep.Current_Sales_Rep_ID__c) {
                    activatedSalesReps.add(newSalesRep);
                }
            }

            // for store update (* -> active, current sales rep id changed)    
            // The introduction of Category__c field brings additional rule: 
            // Only sync to store if the Category__c is Default for Store Sales Rep records
            if(String.isNotBlank(newSalesRep.Assigned_to_Store__c) 
            && newSalesRep.Status__c == Constants.STATUS_ACTIVE 
            && newSalesRep.Category__c == CATEGORY_DEFAULT
            && newSalesRep.Current_Sales_Rep_ID__c != oldSalesRep.Current_Sales_Rep_ID__c) {
                storeSalesRepsWithSalesRepIdChanged.add(newSalesRep);
            }

        }

        // update users' sales rep Id
        assignSalesRepId(activatedSalesReps);
        removeSalesRepId(deactivatedSalesReps);

        // update store's sales rep id
        updateStoreSalesRepIds(storeSalesRepsWithSalesRepIdChanged);
    }

    /**
    * @description 
    * @author Yi Zhang | 16/10/2020 
    * @param salesReps 
    **/
    public static void updateStoreSalesRepIds(List<Sales_Rep__c> salesReps) {
        System.debug(LoggingLevel.DEBUG, 'updateStoreSalesRepIds salesReps: ' + salesReps);
        if(salesReps.isEmpty()) {
            return;
        }

        List<Id> storeIds = new List<Id>();
        for(Sales_Rep__c salesRep : salesReps) {
            storeIds.add(salesRep.Assigned_to_Store__c);
        }

        Map<Id, Store__c> stores = new Map<Id, Store__c>();
        for(Sales_Rep__c salesRep : DM_SalesRep.getActiveSalesRepsWithStoreIds(storeIds)) {
            if(salesRep.Category__c == CATEGORY_DEFAULT && salesRep.Current_Sales_Rep_ID__c != salesRep.Assigned_to_Store__r.Sales_Rep_ID__c) {
                Store__c store = salesRep.Assigned_to_Store__r;
                store.Sales_Rep_ID__c = salesRep.Current_Sales_Rep_ID__c;
                stores.put(store.Id, store);
            }
        }
        System.debug(LoggingLevel.DEBUG, 'stores: ' + stores);

        if(stores.size() > 0) {
            try {
                update stores.values();
            } catch(Exception e) {
                ApplicationLogger.log('SM_SalesRep.updateStoreSalesRepIds', 'Sales_Rep__c', 'Trigger', e);
            }
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param newList 
    **/
    public static void singleActiveStoreOrTeamMember(List<Sales_Rep__c> newList) {
        // New rules after the introduction of field Category__c
        // Rule 1: one active sales rep record per store per category
        // Rule 2: one active sales rep record per team member
        // Note there're already validation rules exist to prevent population of both store / team member fields

        // get active Sales Rep
        List<Sales_Rep__c> activeSalesReps = new List<Sales_Rep__c>();
        List<Id> salesRepIds = new List<Id>();
        List<Id> storeUserIds = new List<Id>(); // either store or user Id
        for(Sales_Rep__c sr : newList) {
            if(sr.Status__c == Constants.STATUS_ACTIVE) {
                activeSalesReps.add(sr);
                if(String.isNotBlank(sr.Id)) {
                    salesRepIds.add(sr.Id);
                }
                if(String.isNotBlank(sr.Assigned_to_Store__c)) {
                    storeUserIds.add(sr.Assigned_to_Store__c);
                } else {
                    storeUserIds.add(sr.Assigned_to_Team_Member__c);
                }
            }
        }
        if(activeSalesReps.isEmpty()) {
            return;
        }

        // find all existing active records of the same store / team member and collect store / user Ids
        List<Sales_Rep__c> existingRecords = DM_SalesRep.getActiveSalesReps(storeUserIds, salesRepIds);
        if(existingRecords.isEmpty()) {
            return;
        }
        // List<Id> existingStoreUserIds = new List<Id>();
        List<String> existingUniqueCombinations = new List<String>();
        // unique combinations:
        // for store, it's store id + category
        // for team member, it's team member id
        for(Sales_Rep__c sr : existingRecords) {
            if(String.isNotBlank(sr.Assigned_to_Store__c)) {
                // existingStoreUserIds.add(sr.Assigned_to_Store__c);
                existingUniqueCombinations.add(sr.Assigned_to_Store__c + sr.Category__c);
            } else {
                // existingStoreUserIds.add(sr.Assigned_to_Team_Member__c);
                existingUniqueCombinations.add(sr.Assigned_to_Team_Member__c);
            }
        }

        // if new / updated active record has the same store / team member, then throw error
        for(Sales_Rep__c sr : activeSalesReps) {
            if(String.isNotBlank(sr.Assigned_to_Store__c)) {
                if(existingUniqueCombinations.contains(sr.Assigned_to_Store__c + sr.Category__c)) {
                    sr.addError(ERROR_SINGLE_ACTIVE_STORE_PER_CATEGORY);
                }
            }
            if(String.isNotBlank(sr.Assigned_to_Team_Member__c)) {
                if(existingUniqueCombinations.contains(sr.Assigned_to_Team_Member__c)) {
                    sr.addError(ERROR_SINGLE_ACTIVE_TEAM_MEMBER);
                }
            }
        }
    }

    /**
    * @description      Sync Sales Rep Id to Store Member / User records
    * @author Yi Zhang | 16/10/2020 
    * @param salesRepList 
    **/
    public static void assignSalesRepId(List<Sales_Rep__c> salesRepList) {
        // param salesRepList has been filtered already
        // if from after update, team member / store field must have been updated or status updated

        if(salesRepList.isEmpty()) {
            return;
        }

        Map<Id, User> usersToUpdate = new Map<Id, User>();

        List<Id> storeIds = new List<Id>();
        Map<Id, String> storeIdSalesRepIdMap = new Map<Id, String>();
        // gather store Ids and take care of Sales Rep records with Team Member directly
        for(Sales_Rep__c sr : salesRepList) {
            if(String.isNotBlank(sr.Assigned_to_Store__c)) {
                storeIds.add(sr.Assigned_to_Store__c);
                storeIdSalesRepIdMap.put(sr.Assigned_to_Store__c, sr.Current_Sales_Rep_ID__c);    
            } else {
                usersToUpdate.put(sr.Assigned_to_Team_Member__c, new User(Id = sr.Assigned_to_Team_Member__c, Sales_Rep_ID__c = sr.Current_Sales_Rep_ID__c));
            }
        }

        // store related TS users (through location code)
        if(storeIds.size() > 0) {            
            // new logic since introduction of multiple sales rep records per store:
            // location code - category - sales rep id mapping
            Map<String, Map<String, String>> locCodeCategorySalesRepIdMap = mapLocCodeCategorySalesRepId(DM_SalesRep.getActiveSalesRepsWithStoreIds(storeIds));

            System.debug(LoggingLevel.DEBUG, 'locCodeCategorySalesRepIdMap: ' + locCodeCategorySalesRepIdMap);

            if(locCodeCategorySalesRepIdMap.size() > 0) {
                for(User user : DM_User.getTSUsersByLocationCode(new List<String>(locCodeCategorySalesRepIdMap.keySet()))) {
                    
                    System.debug(LoggingLevel.DEBUG, 'user: ' + user);

                    String locationCode = user.Location_Code__c;
                    Map<String, String> categorySalesRepIdMap = locCodeCategorySalesRepIdMap.get(locationCode);
                    // fallback (default) Sales Rep Id
                    user.Sales_Rep_ID__c = locCodeCategorySalesRepIdMap.get(locationCode).get(CATEGORY_DEFAULT);
                    // in case bunnings job role exists, try finding the corresponding Sales Rep Id
                    if(String.isNotBlank(user.Bunnings_Job_Role__c)) {
                        String category = DM_SalesRepCategoryMapping.jobRoleSalesRepCategoryMap.get(user.Bunnings_Job_Role__c);
                        if(category != null && categorySalesRepIdMap.containsKey(category)) {
                            user.Sales_Rep_ID__c = categorySalesRepIdMap.get(category);
                        }
                    }
                    usersToUpdate.put(user.Id, user);
                }
            }
        }

        System.debug(LoggingLevel.DEBUG, 'usersToUpdate: ' + JSON.serialize(usersToUpdate));

        if(usersToUpdate.size() > 0) {
            updateUsersAsync(JSON.serialize(usersToUpdate.values()));
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @param salesRepList 
    **/
    public static void removeSalesRepId(List<Sales_Rep__c> salesRepList) {
        // para salesRepList has been filtered already
        // if from after update, team member / store field must have been updated or status updated
        if(salesRepList.isEmpty()) {
            return;
        }

        Map<Id, User> usersToUpdate = new Map<Id, User>();

        List<Id> storeIds = new List<Id>();
        // gather store Ids and take care of Sales Rep records with Team Member directly
        for(Sales_Rep__c sr : salesRepList) {
            if(String.isNotBlank(sr.Assigned_to_Store__c)) {
                storeIds.add(sr.Assigned_to_Store__c);
            } else {
                usersToUpdate.put(sr.Assigned_to_Team_Member__c, new User(Id = sr.Assigned_to_Team_Member__c, Sales_Rep_ID__c = null));
            }
        }

        // store related TS users (through location code)
        if(storeIds.size() > 0) {
            // location code - category - sales rep id mapping
            Map<String, Map<String, String>> locCodeCategorySalesRepIdMap = mapLocCodeCategorySalesRepId(DM_SalesRep.getActiveSalesRepsWithStoreIds(storeIds));

            System.debug(LoggingLevel.DEBUG, 'locCodeCategorySalesRepIdMap: ' + locCodeCategorySalesRepIdMap);

            // this is necessary as map above might not have all location codes (in the event of default sales rep set to inactive)
            List<String> locationCodes = new List<String>();
            for(Store__c store : DM_Store.getStores(storeIds)) {
                locationCodes.add(store.Location_Code__c);
            }
            
            for(User user : DM_User.getTSUsersByLocationCode(locationCodes)) {
                System.debug(LoggingLevel.DEBUG, 'user: ' + user);

                String category = String.isNotBlank(user.Bunnings_Job_Role__c) ? DM_SalesRepCategoryMapping.jobRoleSalesRepCategoryMap.get(user.Bunnings_Job_Role__c) : CATEGORY_DEFAULT;
                category = String.isBlank(category) ? CATEGORY_DEFAULT : category;
                String locationCode = user.Location_Code__c;

                // if the store (location code) has no default Sales Rep record, set user's Sales Rep Id to null
                if(locCodeCategorySalesRepIdMap.containsKey(locationCode) == false) {
                    user.Sales_Rep_ID__c = null;
                // if the store (location code) has sale rep record(s), try finding the sales rep id with mapped category, if none, then set to default category
                } else {
                    Map<String, String> categorySalesRepIdMap = locCodeCategorySalesRepIdMap.get(locationCode);
                    if(categorySalesRepIdMap.containsKey(category) == false) {
                        user.Sales_Rep_ID__c = categorySalesRepIdMap.get(CATEGORY_DEFAULT);
                    } else {
                        user.Sales_Rep_ID__c = categorySalesRepIdMap.get(category);
                    }
                }
                usersToUpdate.put(user.Id, user);
            }
            
        }

        System.debug(LoggingLevel.DEBUG, 'usersToUpdate: ' + JSON.serialize(usersToUpdate));

        if(usersToUpdate.size() > 0) {
            updateUsersAsync(JSON.serialize(usersToUpdate.values()));
        }
    }


    /**
    * @description      Convert list of sales rep records to map: location code - category - sales rep ID (not salesforce Id)
    * @author Yi Zhang | 19/10/2020 
    * @param salesReps 
    * @return Map<String, Map<String, String>> 
    **/
    public static Map<String, Map<String, String>> mapLocCodeCategorySalesRepId(List<Sales_Rep__c> salesReps) {
        // maps:
        // primary key: location code
        // secondary key: category
        // value: sales rep ID (not salesforce Id)
        Map<String, Map<String, String>> maps = new Map<String, Map<String, String>>();
        for(Sales_Rep__c sr : salesReps) {
            String locationCode = sr.Assigned_to_Store__r.Location_Code__c;
            if(maps.containsKey(locationCode) == false) {
                maps.put(locationCode, new Map<String, String>());
            }
            maps.get(locationCode).put(sr.Category__c, sr.Current_Sales_Rep_ID__c);
        }
        return maps;
    }

    
    /**
    * @description
    * @author Yi Zhang | 24/08/2020 
    * @param usersJson 
    **/
    @future
    public static void updateUsersAsync(String usersJson) {
        List<User> users = (List<User>) JSON.deserialize(usersJson, List<User>.class);
        try {
            update users;
        } catch(Exception e) {
            ApplicationLogger.log('SM_SalesRep.updateUsersAsync', 'Sales_Rep__c', 'Trigger', e);
        }
    }
}