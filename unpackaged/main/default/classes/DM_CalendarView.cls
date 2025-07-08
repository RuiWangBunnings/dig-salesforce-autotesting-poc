/*******************************************************************************************************
* Class Name      	: DM_CalendarView
* Description		: Data Layer - Selector for sObject CalendarView
* Author          	: Simplus - Philip Clark
* Created On      	: 29/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark			29/06/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_CalendarView {
    
    /**
    * @description 
    * @author Philip Clark | 29/06/2020 
    * @param set<Id> 
    * @return List<CalendarView> 
    **/
    public static List<CalendarView> getCalendarViews(set<Id> userIds) {
        return [
            SELECT Id 
            FROM CalendarView
            WHERE OwnerId IN :userIds
        ];
    }

}