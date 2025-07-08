/*******************************************************************************************************
* Class Name      	: SM_CalendarView
* Description		: Domain / Service layer for CalendarView
* Author          	: Simplus - Philip Clark
* Created On      	: 29/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          29/06/2020		1000				Initial version
* SM Simplus            11/06/2021      2000                Added deleteTSCalendarViews method - fix PROD_INC0965367
******************************************************************************************************/
public without sharing class SM_CalendarView {
    
    
    /**
    * @description 
    * @author Philip Clark | 29/06/2020 
    * @param userMap
    **/
    public static void createCalendarViews(map<Id,User> userMap) {
        system.debug('[SM_CalendarView.createCalendarViews] entering method');
        set<Id> profIdSet = new set<Id>();
        set<Id> userIdSet = new set<Id>();  // - PROD_INC0965367
        for(User u : userMap.values()) {
        	profIdSet.add(u.ProfileId);
            userIdSet.add(u.Id);            // - PROD_INC0965367
		}
        map<Id,String> profIdMap = new Map<Id,String>();
        for (Profile p : DM_Profile.getProfilebyId(profIdSet)) {
        	profIdMap.put(p.Id, p.Name);
		}
        // sort List View Ids by sObject / List View Developer Name concat string
        map<String,Id> concatSobjectListViewIdMap = new map<String,Id>();
        for (ListView lv : DM_ListView.getListViews()) {
            concatSobjectListViewIdMap.put(lv.SobjectType+lv.DeveloperName,lv.Id);
        }

        //get existing calendars of users to avoid created TS calendar duplication - PROD_INC0965367
        list<CalendarView> existingCVOfUserList = [SELECT Id, Name, OwnerId FROM CalendarView WHERE OwnerId IN :userIdSet];
        Map<Id,Set<String>> existingCVOfUserMap = new Map<Id,Set<String>>();
        for(ID userId : userIdSet) {
            Set<String> tempSet = new Set<String>();
            for(CalendarView CV : existingCVOfUserList) { if(CV.OwnerId == userId) tempSet.add(CV.Name); }
            existingCVOfUserMap.put(userId, tempSet);
        } // - PROD_INC0965367

        list<CV_Mapping__mdt> cvmList = DM_CVMapping.getCVMappings();
        list<CalendarView> newCVList = new list<CalendarView>();
        for(User u : userMap.values()) {
            for (CV_Mapping__mdt cvm : cvmList) {
                list<String> cvmProfNameSet = cvm.User_Profiles__c.split(',');
                
                //  PROD_INC0965367
                Boolean hasCVInstance = false;
                if(existingCVOfUserMap.containsKey(u.Id)) {
                    Set<String> CVChecker = existingCVOfUserMap.get(u.Id);
                    hasCVInstance = CVChecker.contains(cvm.MasterLabel);
                }

                // only use cvMaps associated with the user profile
                if (cvmProfNameSet.contains(profIdMap.get(u.ProfileId)) && !hasCVInstance) {
                // if (cvmProfNameSet.contains(profIdMap.get(u.ProfileId))) {
                    CalendarView cv = new CalendarView();
                    cv.Name = cvm.MasterLabel;
                    cv.Color = cvm.Colour__c;
                    cv.DisplayField = cvm.Display_Field__c;
                    cv.FillPattern = cvm.Fill_Pattern__c;
                    if (cvm.List_View__c!=null) {
                        String concatsObjLv = cvm.Object__c+cvm.List_View__c;
                        if (concatSobjectListViewIdMap.containsKey(concatsObjLv))
                            cv.ListViewFilterId = concatSobjectListViewIdMap.get(concatsObjLv);
                    }
                    cv.OwnerId = u.Id;
                    cv.SobjectType = cvm.Object__c;
                    cv.StartField = cvm.Field_for_Start__c;
        			system.debug('[SM_CalendarView.createCalendarViews] creating calendar view: '+cv);
                    newCVList.add(cv);
                }
            }
        }
        if (!newCVList.isEmpty()) {
            String cvListJson = JSON.serialize(newCVList);
            insertCVList(cvListJson);
        }
    }

    /**
    * @description Deletes TS CalendarViews on Users from TS to non-TS
    * @author SIMPLUS MS: Andy Pagtabunan | 10/06/2021 
    * @param map<Id User> userMap 
    **/
    public static void deleteTSCalendarViews(map<Id,User> userMap) {
        system.debug('[SM_CalendarView.deleteTSCalendarViews] entering method');
        Set<String> TSCalendarLabelList = new Set<String>();
        List<CV_Mapping__mdt> cvmList = DM_CVMapping.getCVMappings();
        for(CV_Mapping__mdt cvm : cvmList) { TSCalendarLabelList.add(cvm.MasterLabel); }
        List<CalendarView> CVsToDelete = [SELECT Id FROM CalendarView WHERE OwnerId IN :userMap.keySet() AND Name IN :TSCalendarLabelList];
        if(!CVsToDelete.isEmpty()) {
            String delCVListJson = JSON.serialize(CVsToDelete);
            deleteCVList(delCVListJson);
        }
    }
    
    /**
    * @description 
    * @author 	Philip Clark | 29/06/2020 
    * @param 	String
    **/
    @future
    public static void insertCVList (String cvListJson) {
        system.debug('[SM_CalendarView.upsertCVList] entering method');
        List<CalendarView> cvList = (List<CalendarView>) JSON.deserialize(cvListJson, List<CalendarView>.class);
        upsert cvList;
    }
    
    /**
    * @description 
    * @author Philip Clark | 29/06/2020 
    * @param userMap
    **/
    public static void deleteCalendarViews(map<Id,User> userMap) {
        system.debug('[SM_CalendarView.deleteCalendarViews] entering method');
        list<CalendarView> delCVList = DM_CalendarView.getCalendarViews(userMap.keySet());
        if (!delCVList.isEmpty()) {
            String delCVListJson = JSON.serialize(delCVList);
            deleteCVList(delCVListJson);
        }
    }
    
    /**
    * @description 
    * @author 	Philip Clark | 29/06/2020 
    * @param 	String
    **/
    @future
    public static void deleteCVList (String cvListJson) {
        system.debug('[SM_CalendarView.deleteCVList] entering method');
        List<CalendarView> cvList = (List<CalendarView>) JSON.deserialize(cvListJson, List<CalendarView>.class);
        delete cvList;
    }


}