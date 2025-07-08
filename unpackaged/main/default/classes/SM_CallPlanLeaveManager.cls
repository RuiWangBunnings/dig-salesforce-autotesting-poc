/*******************************************************************************************************
* Class Name      	: SM_CallPlanLeaveManager
* Description		: Service layer callPlanLeaveManager LWC
* Author          	: Simplus - Yi Zhang
* Created On      	: 07/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              07/07/2020		1000				Initial version
******************************************************************************************************/
public without sharing class SM_CallPlanLeaveManager {
    /**
    * @description 
    * @author Yi Zhang | 09/07/2020 
    * @param runningUserId 
    * @param retrieveAMs    Should be true onload of LWC, all subsequent callout should be false
    * @return CallPlanLeaveManagerWrapper 
    **/
    @AuraEnabled
    public static CallPlanLeaveManagerWrapper getLeavesAndAMs(String runningUserId, Boolean retrieveAMs) {
        CallPlanLeaveManagerWrapper resp = new CallPlanLeaveManagerWrapper();
        // get user
        User user = DM_User.getUser(runningUserId);
        if(SM_CallPlanner.TM_PROFILES.contains(user.Profile.Name)) {            // Team Members
            // AMs
            resp.AMs = new List<User>{user};
            // leaves
            resp.leaves = DM_CallPlanLeave.getActiveLeaves(user.Id, null);
        } else if (user.Profile.Name == 'System Administrator') {               // System Administrator
            // AMs (Sys Admin sees all AMs)
            resp.AMs = retrieveAMs == true ? DM_User.getActiveUsersOfProfiles(SM_CallPlanner.TM_PROFILES) : null;
            // leaves
            resp.leaves = DM_CallPlanLeave.getActiveLeaves(null, null);
        } else {                                                                // Sales Manager (ASM)
            // AMs (ASM sees managed AMs)
            resp.AMs = retrieveAMs == true ? DM_User.getActiveUsersManagedBy(user.Id, SM_CallPlanner.TM_PROFILES) : null;
            // leaves
            resp.leaves = DM_CallPlanLeave.getActiveLeaves(null, user.Id);
        }
        return resp;
    }




    public class CallPlanLeaveManagerWrapper {
        @AuraEnabled
        public List<User> AMs;
        @AuraEnabled
        public List<Call_Plan_Leave__c> leaves;
    }
}