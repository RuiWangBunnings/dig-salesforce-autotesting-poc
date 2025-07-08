/*******************************************************************************************************
* Class Name        : EventTrigger
* Description       : Trigger for Event object
* Author            : Simplus - John Paul Penaflor
* Created On        : 21/02/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* John Paul Penaflor    21/02/2020      1000                Initial version
* Yi Zhang              21/10/2020      2000                Removed inactive contact check
******************************************************************************************************/
trigger EventTrigger on Event (before insert, before update, after insert, after update) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            EventTriggerHandler.afterInsert(Trigger.newMap);
        }
    }
}