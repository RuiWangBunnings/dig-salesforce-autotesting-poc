/*******************************************************************************************************
* Class Name      	: DM_Profile
* Description		: Data Layer - Selector for Sobject Profile
* Author          	: Simplus - Philip Clark
* Created On      	: 23/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          23/06/2020		1000				Initial version
* Philip Clark          29/06/2020		1001				Added method getProfilebyId
******************************************************************************************************/
public with sharing class DM_Profile {
    
    /**
    * @description  
    * @author       Philip Clark | 23/06/2020 
    * @param        set<String> 
    * @return       list<Profile> 
    **/
    public static list<Profile> getProfilebyName(set<String> profNameSet) {
        List<Profile> retList = new List<Profile>();
        if (profNameSet!=null) {
            retList = [
                SELECT Id, Name 
                FROM Profile 
                WHERE Name IN: profNameSet
            ];
		} else 
        {
            retList = [
                SELECT Id, Name 
                FROM Profile 
            ];
        }
        return retList;
	}
    
    /**
    * @description  
    * @author       Philip Clark | 29/06/2020 
    * @param        set<Id> 
    * @return       list<Profile> 
    **/
    public static list<Profile> getProfilebyId(set<Id> profIdSet) {
        return new list<Profile> ([
            SELECT Id, Name 
            FROM Profile 
            WHERE Id IN: profIdSet
        ]);
	}
}