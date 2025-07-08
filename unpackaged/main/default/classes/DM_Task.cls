/*******************************************************************************************************
* Class Name      	: DM_Task
* Description		: Data Layer - Selector for Sobject Task
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_Task {
    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param whatId 
    * @param ownerId 
    * @return List<Task> 
    **/
    public static List<Task> getOpenTasks(String whatId, String ownerId) {
        return [
            SELECT Id, Status, IsClosed, Subject
            FROM Task 
            WHERE WhatId = :whatId
            AND OwnerId = :ownerId
            AND IsClosed = FALSE
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param whoIds 
    * @param ownerIds 
    * @return List<Task> 
    **/
    public static List<Task> getOpenTasksWithWhoIds(Set<Id> whoIds, Set<Id> ownerIds) {
        return [
            SELECT Id, WhoId, OwnerId
            FROM Task 
            WHERE WhoId IN :whoIds
            AND OwnerId IN :ownerIds
            AND IsClosed = FALSE
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param whatIds 
    * @param ownerIds 
    * @return List<Task> 
    **/
    public static List<Task> getOpenTasksWithWhatIds(Set<Id> whatIds, Set<Id> ownerIds) {
        return [
            SELECT Id, WhatId, OwnerId
            FROM Task 
            WHERE WhatId IN :whatIds
            AND OwnerId IN :ownerIds
            AND IsClosed = FALSE
        ];
    }
}