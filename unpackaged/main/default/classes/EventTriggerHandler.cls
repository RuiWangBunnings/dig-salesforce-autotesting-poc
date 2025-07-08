/*******************************************************************************************************
* Class Name      	: EventTriggerHandler
* Description		: Trigger Handler for Event object
* Author          	: Simplus - John Paul Penaflor
* Created On      	: 21/02/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Penaflor    21/02/2020		1000				Initial version
* Yi Zhang              21/10/2020		2000				Removed inactive contact check
******************************************************************************************************/
public class EventTriggerHandler {

    /**
    * @description 
    * @author Yi Zhang | 12/08/2020 
    * @param newMap 
    **/
    public static void afterInsert(Map<Id, Event> newMap) {
        updateRelatedAccountScheduledEngagementCall(newMap);
    }

    /**
    * @description 
    * @author Yi Zhang | 12/08/2020 
    * @param newMap 
    **/
    public static void updateRelatedAccountScheduledEngagementCall(Map<Id, Event> newMap) {
        // Event of type standard and purpose : engagement call & AccountId != null
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Event e : newMap.values()) {
            if(e.AccountId != null && e.RecordTypeId == DM_RecordType.rtId_Event_Standard && e.Sub_type__c == Constants.EVENT_PURPOSE_ENGAGEMENT_CALL && e.ActivityDate != null) {
                accountsToUpdate.put(e.AccountId, new Account(Id = e.AccountId, Scheduled_Engagement_Call__c = e.ActivityDate));
            }
        }

        SM_Account.updateScheduledEngagementCall(accountsToUpdate);
    }
}