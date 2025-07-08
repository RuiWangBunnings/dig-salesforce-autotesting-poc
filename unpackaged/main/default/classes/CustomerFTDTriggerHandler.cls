/*******************************************************************************************************
* Class Name        : CustomerFTDTriggerHandler
* Description       : Customer Family Tree Discount trigger handler
* Author            : Bunnings Dev
* Created On        : 20/02/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     20/02/2023      1000                Initial version - BUNDIG-14164
******************************************************************************************************/

public without sharing class CustomerFTDTriggerHandler {
    
    public static void afterUpdate(Map<Id, Customer_Family_Tree_Discount__c> oldMap, Map<Id, Customer_Family_Tree_Discount__c> newMap) {
        System.debug('***AFTER UPDATE - Customer Familty Tree Discount');
        handleFTDAssignment(oldMap, newMap);
    }


    private static void handleFTDAssignment(Map<Id, Customer_Family_Tree_Discount__c> oldMap, Map<Id, Customer_Family_Tree_Discount__c> newMap) {
        Set<Id> acctIds = new Set<Id>();
        Set<Id> cftdIds = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, Family_Tree_Discount__c> ftdMap;

        Map<Id, Map<String, String>> cftdMap = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> delcftdMap = new Map<Id, Map<String, String>>();

        for (Id cftdId : newMap.keySet()) {
            acctIds.add(newMap.get(cftdId).Account__c);
            cftdIds.add(newMap.get(cftdId).Family_Tree_Discount__c);
        }

        ftdMap = new Map<Id, Family_Tree_Discount__c>([SELECT Id, Family_Tree_Discount_ID__c FROM Family_Tree_Discount__c WHERE Id IN :cftdIds]);

        for (Account acc : [SELECT Id, Power_Pass_Account_Number__c, RecordType.DeveloperName, Country__c, Family_Tree_Discount_Changed__c, Family_Tree_Discount_Approval__c,
                            LastModifiedBy.Team_Member_ID__c, Send_Data_to_CPS__c, Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c
                            FROM Account
                            WHERE Id IN : acctIds]) {
            accountMap.put(acc.Id, acc);
        }
        System.debug('***accountMap: '+accountMap.values());

        for (Id cftdId : oldMap.keySet()) {
            
            Customer_Family_Tree_Discount__c oldCFTD = oldMap.get(cftdId);
            Customer_Family_Tree_Discount__c newCFTD = newMap.get(cftdId);
            Account acct = accountMap.get(newCFTD.Account__c);
            Family_Tree_Discount__c familyTreeDiscount = ftdMap.get(newCFTD.Family_Tree_Discount__c);

            String action = String.isBlank(newCFTD.Action__c) ? '' : newCFTD.Action__c;
            String assignmentStat = String.isBlank(newCFTD.Pricing_Assignment_Status__c) ? '' : newCFTD.Pricing_Assignment_Status__c;
            String oldAction = String.isBlank(oldCFTD.Action__c) ? '' : oldCFTD.Action__c;
            String oldAssignmentStat = String.isBlank(oldCFTD.Pricing_Assignment_Status__c) ? '' : oldCFTD.Pricing_Assignment_Status__c;            

            Map<String, String> paramMap = new Map<String, String>();

            System.debug('***JASPER: '+action+' - '+oldAction+' - '+assignmentStat+' - '+oldAssignmentStat+' - '+acct.Family_Tree_Discount_Approval__c);
        
            if (acct.Country__c == 'New Zealand') {
                if (action != oldAction || assignmentStat != oldAssignmentStat) {
                    if (assignmentStat == 'Submitted to CPS' || !acct.Family_Tree_Discount_Approval__c) {
                        paramMap.put('FamilyTreeDiscountId', familyTreeDiscount.Family_Tree_Discount_ID__c);                    
                        paramMap.put('AccountId' , newCFTD.Account__c);
                        paramMap.put('CustomerId' , acct.Power_Pass_Account_Number__c);                
                        paramMap.put('CountryCode' , 'NZ');

                        String teamMbrId = String.isBlank(acct.Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c) ? '0' : acct.Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c;
                        paramMap.put('TMNumber', teamMbrId);

                        System.debug('***paramMap: '+paramMap);
                    }
                }

                // if (action == 'Assignment' && String.isBlank(newCFTD.Customer_Family_Tree_Id__c) && acct.Send_Data_to_CPS__c) {
                if (action == 'Assignment' && String.isBlank(newCFTD.Customer_Family_Tree_Id__c)) {
                    cftdMap.put(newCFTD.Family_Tree_Discount__c, paramMap);                    
                // } else if (action == 'Removal'&& !String.isBlank(newCFTD.Customer_Family_Tree_Id__c)) {
                } else if (assignmentStat == 'Pending Removal Approval'&& !String.isBlank(newCFTD.Customer_Family_Tree_Id__c)) {
                    delcftdMap.put(newCFTD.Family_Tree_Discount__c, paramMap);
                }
            }            
        }

        System.debug('***cftdMap: '+cftdMap);
        System.debug('***delcftdMap: '+delcftdMap);

        if (cftdMap != null && cftdMap.size() > 0) 
            invokeCustomerFamilyTreeDiscountServiceServiceAssignmentAsync(JSON.serialize(cftdMap));

        if (delcftdMap != null && delcftdMap.size() > 0)
            invokeCustomerFamilyTreeDiscountServiceDeletionAsync(JSON.serialize(delcftdMap));
        
    }

    @future(callout=true)
    public static void invokeCustomerFamilyTreeDiscountServiceServiceAssignmentAsync(String cftdMapText) {
        Map<Id, Map<String, String>> cftdMap = (Map<id, Map<String, String>>) JSON.deserialize(cftdMapText, Map<Id, Map<String, String>>.class);
        SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceServiceAssignment(cftdMap);
    }

    @future(callout=true)
    public static void invokeCustomerFamilyTreeDiscountServiceDeletionAsync(String cftdMapText) {
        Map<Id, Map<String, String>> cftdMap = (Map<id, Map<String, String>>) JSON.deserialize(cftdMapText, Map<Id, Map<String, String>>.class);
        SM_CustomerFamilyTreeDiscount.invokeCustomerFamilyTreeDiscountServiceDeletion(cftdMap);
    }
}