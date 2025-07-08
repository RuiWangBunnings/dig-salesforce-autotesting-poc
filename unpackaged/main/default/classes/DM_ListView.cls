/*******************************************************************************************************
* Class Name      	: DM_ListView
* Description		: Data Layer - Selector for ListView object
* Author          	: Simplus - Philip Clark
* Created On      	: 29/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark			29/06/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_ListView {
    
    /**
    * @description 
    * @author Philip Clark | 29/06/2020 
    * @return List<ListView> 
    **/
    public static list<ListView> getListViews() { 
        return [
            SELECT Id, SobjectType, DeveloperName 
            FROM ListView 
        ];
    }

}