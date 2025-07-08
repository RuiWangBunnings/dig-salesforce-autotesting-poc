/*******************************************************************************************************
* Class Name      	: SM_Task
* Description		: Service layer for Task object
* Author          	: Simplus - Philip Clark
* Created On      	: 19/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          19/06/2020		1000				Initial version
* Bunnings Dev          23/05/2022      2000                SFSUP-716 - LifeCycle Model roll-out
******************************************************************************************************/
public without sharing class SM_Task {

    /**
    * @description 
    * @author Philip Clark | 19/06/2020
    * @param whatId 
    * @param ownerId 
    * @return List<Task> 
    **/
    public static Task createTask(String whatId, String ownerId, String Subject, String Description, Date DueDate) {
        return new Task(
            whatId = whatId,
            ownerId = ownerId,
            Subject = Subject,
            Description = Description,
            ActivityDate = DueDate,
            RecordTypeId = DM_RecordType.rtId_Task_Standard
        );
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param whatId 
    * @param ownerId 
    * @param subject 
    * @param dueDate 
    * @return Task 
    **/
    public static Task createCallCycleTask(String whatId, String ownerId, String subject, Date dueDate) {
        return new Task(
            RecordTypeId = DM_RecordType.rtId_Task_CallCycle,
            WhatId = whatId,
            OWnerId = ownerId,
            Subject = subject,
            Sub_type__c = 'Engagement Call', // Purpose
            Type = 'Phone',
            Status = 'Open',
            ActivityDate = dueDate
        );
    }


    /**
    * @description SFSUP-716
    * @author Bunnings Dev | 23/05/2022
    * @param whatId 
    * @param ownerId 
    * @param subject
    * @param subType
    * @param dueDate 
    * @return Task 
    **/
    public static Task createLifeCycleCallCycleTask(String recTypeId, String whatId, String ownerId, String subject, String subType, Date dueDate) {
        return new Task(
            RecordTypeId = recTypeId,
            WhatId = whatId,
            OWnerId = ownerId,
            Subject = subject,
            Sub_type__c = subType,
            Type = 'Phone',
            Status = 'Open',
            ActivityDate = dueDate
        );
    }



    /**
    * @description      CCRM-85
    * @author Yi Zhang | 16/07/2020 
    * @param whatId 
    * @param ownerId 
    * @param callReason 
    * @param recordTypeId 
    * @return Task 
    **/
    public static Task createManualCallCycleTask(
        String whatId, 
        String ownerId,
        String callReason,
        String recordTypeId
    ) {
        return createCallCycleTask(whatId, ownerId, 'Business Determined - ' + callReason, Date.today());
    }


    /**
     * @description insertTask insert a task into Salesforce
     * @author Juan M. Cutrera
     * @param  task task The task object in Memory that needs to be inserted
     * @return      return returns the Task inserted
     */
    public static Task insertTask(Task task) {
        try {
            insert task;
        } catch (Exception e) {
            throw new SM_TaskException('Task could not be created: ' + e.getMessage());
        }
        return task;
    }

    private class SM_TaskException extends Exception {}
}