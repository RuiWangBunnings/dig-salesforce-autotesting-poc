/*******************************************************************************************************
* Class Name        : DM_CallTargets
* Description       : Data Layer - Selector for Sobject Call_Targets__c
* Author            : Simplus - Yi Zhang
* Created On        : 2020-06-18
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-18      1000                Initial version
******************************************************************************************************/
public with sharing class DM_CallTargets {
    /**
    * @description 
    * @author Yi Zhang | 18/06/2020 
    * @param accountManagerIds 
    * @param callTargetsIds 
    * @return List<Call_Targets__c> 
    **/
    public static List<Call_Targets__c> getRelatedCallTargets(Set<Id> accountManagerIds, Set<Id> callTargetsIds) {
        return new List<Call_Targets__c>([
            SELECT Id, Start_Date__c, End_Date__c, Team_Member__c, Total_Target__c
            FROM Call_Targets__c
            WHERE Team_Member__c IN :accountManagerIds
            AND Id NOT IN :callTargetsIds
        ]);
    }
}