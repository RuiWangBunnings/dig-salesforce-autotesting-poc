/*******************************************************************************************************
* Class Name        : DM_CallPlanLeave
* Description       : Data Layer - Selector for Sobject Call_Plan_Leave__c
* Author            : Simplus - Yi Zhang
* Created On        : 2020-07-07
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-07-07      1000                Initial version
******************************************************************************************************/
public with sharing class DM_CallPlanLeave {
    /**
    * @description (deprecated)
    * @author Yi Zhang | 07-07-2020 
    * @param userId 
    * @return List<Call_Plan_Leave__c> 
    **/
    @AuraEnabled
    public static List<Call_Plan_Leave__c> getLeaves(String userId) {
        return new List<Call_Plan_Leave__c>([
            SELECT Id, Team_Member__c, Team_Member__r.Name, Start_Date__c, End_Date__c
            FROM Call_Plan_Leave__c
            // WHERE Team_Member__c = :userId
            // OR Team_Member__r.ManagerId = :userId
            ORDER BY Team_Member__r.Name ASC, Start_Date__c DESC
        ]);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 10/07/2020
    * @param AMId 
    * @param ASMId 
    * @return List<Call_Plan_Leave__c> 
    **/
    public static List<Call_Plan_Leave__c> getActiveLeaves(String AMId, String ASMId) {
        String query = 'SELECT Id, Team_Member__c, Team_Member__r.Name, Start_Date__c, End_Date__c '
        + ' FROM Call_Plan_Leave__c'
        + ' WHERE End_Date__c > TODAY';
        if(AMId != null) {
            query += ' AND Team_Member__c = \'' + AMId + '\'';
        } else if(ASMId != null) {
            query += ' AND Team_Member__r.ManagerId = \'' + ASMId + '\'';
        }
        query += ' ORDER BY Team_Member__r.Name ASC, Start_Date__c ASC';

        List<Call_Plan_Leave__c> leaves = Database.query(query);
        return leaves;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 09/07/2020
    * @param accountManagerIds 
    * @param leaveIds 
    * @return List<Call_Plan_Leave__c> 
    **/
    public static List<Call_Plan_Leave__c> getRelatedLeaves(Set<Id> accountManagerIds, Set<Id> leaveIds) {
        return new List<Call_Plan_Leave__c>([
            SELECT Id, Start_Date__c, End_Date__c, Team_Member__c
            FROM Call_Plan_Leave__c
            WHERE Team_Member__c IN :accountManagerIds
            AND Id NOT IN :leaveIds
        ]);
    }
}