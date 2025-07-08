/*******************************************************************************************************
* Class Name      	: DM_PowerpassAssignmentRule
* Description		: Data Layer - Selector for Custom Metdata Type Powerpass_Assignment_Rule__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 22/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              22/10/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_PowerpassAssignmentRule {
    
    /**
    * @description 
    * @author Yi Zhang | 22/10/2020 
    * @return Map<String, List<Powerpass_Assignment_Rule__mdt>>   Key is Account_Type__c + Home_Store_Model__c + Segment__c
    **/
    public static Map<String, List<Powerpass_Assignment_Rule__mdt>> ruleMap {
        get {
            if(ruleMap == null) {
                ruleMap = new Map<String, List<Powerpass_Assignment_Rule__mdt>>();
                for(Powerpass_Assignment_Rule__mdt rule: [SELECT Id, Account_Type__c, Assign_to_Store_Member__c, Create_Onboarding_Task__c,
                Credit_Limit_Ceiling__c, Credit_Limit_Floor__c, Days_from_Account_Creation__c, Home_Store_Model__c, 
                Segment__c, Set_Digitally_Managed_Flag__c, Country__c
                FROM Powerpass_Assignment_Rule__mdt
                ORDER BY Credit_Limit_Floor__c DESC]) {
                    string segment = rule.Segment__c;
                    if(segment != null){
                        segment = segment.toLowerCase();
                    }
                    String key = rule.Account_Type__c + rule.Home_Store_Model__c + segment + rule.Country__c;
                    if(ruleMap.containsKey(key) == false) {
                        ruleMap.put(key, new List<Powerpass_Assignment_Rule__mdt>());
                    }
                    ruleMap.get(key).add(rule);
                }
            }
            return ruleMap;
        } set;
    }
}