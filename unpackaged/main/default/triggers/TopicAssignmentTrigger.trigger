/*******************************************************************************************************
* Trigger Name      : TopicAssignmentTrigger
* Description       : Trigger for TopicAssignments object to map topic assignments across related objects
* Author            : Simplus - Francis Benzon	
* Created On        : 22/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon	    22/06/2020      1000                Initial version
******************************************************************************************************/
trigger TopicAssignmentTrigger on TopicAssignment (before insert, before update, before delete, after insert, after update, after delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            TopicAssignmentTriggerHandler.afterInsert(Trigger.new, Trigger.newMap);
        }

        if(Trigger.isDelete) {
            TopicAssignmentTriggerHandler.afterDelete(Trigger.old, Trigger.oldMap);
        }
    }

    System.debug('*** TopicAssignmentTrigger ***');
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            TopicAssignmentTriggerHandler.beforeInsert(Trigger.new);
        }

        if(Trigger.isDelete) {
            TopicAssignmentTriggerHandler.beforeDelete(Trigger.old);
        }
    }
}