/*******************************************************************************************************
* Class Name      	: DM_Event
* Description		: Data Layer - Selector for Sobject Event
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/05/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_Event {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param whatId 
    * @param ownerId 
    * @return List<Event> 
    **/
    public static List<Event> getOpenEvents(String whatId, String ownerId) {
        datetime currentDateTime = datetime.now();
        return [
            SELECT Id, EndDateTime, WhatId, OwnerId
            FROM Event 
            WHERE WhatId = :whatId
            AND OwnerId = :ownerId
            AND EndDateTime > :currentDateTime
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param whoIds 
    * @param ownerIds 
    * @return List<Event> 
    **/
    public static List<Event> getOpenEventsWithWhoIds(Set<Id> whoIds, Set<Id> ownerIds) {
        datetime currentDateTime = datetime.now();
        return [
            SELECT Id, EndDateTime, WhoId, OwnerId
            FROM Event 
            WHERE WhoId IN :whoIds
            AND OwnerId IN :ownerIds
            AND EndDateTime > :currentDateTime
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param whatIds 
    * @param ownerIds 
    * @return List<Event> 
    **/
    public static List<Event> getOpenEventsWithWhatIds(Set<Id> whatIds, Set<Id> ownerIds) {
        datetime currentDateTime = datetime.now();
        return [
            SELECT Id, EndDateTime, WhatId, OwnerId
            FROM Event 
            WHERE WhatId IN :whatIds
            AND OwnerId IN :ownerIds
            AND EndDateTime > :currentDateTime
        ];
    }
}