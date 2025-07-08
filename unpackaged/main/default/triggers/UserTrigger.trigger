/*******************************************************************************************************
* Trigger Name     	: UserTrigger
* Description		: User trigger
* Author          	: Simplus - Philip Clark
* Created On      	: 18/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          18/06/2020		1000				Initial version
* Simplus MS            27/07/2021      1001                Fix for INC0969834 - allow re-running of Manager Id/SalesRepId/TS Role population and Storemember creation if process failed on insert and on update
******************************************************************************************************/
trigger UserTrigger on User (before insert, after insert, before update, after update) {

    switch on Trigger.operationType {
        when BEFORE_INSERT{
                SM_User.beforeInsert(Trigger.new);
        }
        when AFTER_INSERT {
                SM_User.afterInsert(Trigger.newMap);

                if(!SM_User.reRunOnBeforeInsert) {      //INC0969834
                    SM_User.reRunOnBeforeInsert = true;
                    SM_User.beforeInsert(Trigger.new);
                    SM_User.afterInsert(Trigger.newMap);
                    SM_User.reRunOnBeforeInsert = false;
                }
        }
        when BEFORE_UPDATE {
            if(!SM_User.reRunOnBeforeInsert && !SM_User.reRunOnBeforeUpdate)
                SM_User.beforeUpdate(Trigger.oldMap, Trigger.new);
        }
        when AFTER_UPDATE {
            if(!SM_User.reRunOnBeforeInsert && !SM_User.reRunOnBeforeUpdate) {
                SM_User.afterUpdate(Trigger.oldMap, Trigger.newMap);

                if(!SM_User.reRunOnBeforeUpdate) {
                    SM_User.reRunOnBeforeUpdate = true;
                    SM_User.beforeUpdate(Trigger.oldMap, Trigger.new);
                    SM_User.afterUpdate(Trigger.oldMap, Trigger.newMap);
                    SM_User.reRunOnBeforeUpdate = false;
                }
            }
        }
    }

}