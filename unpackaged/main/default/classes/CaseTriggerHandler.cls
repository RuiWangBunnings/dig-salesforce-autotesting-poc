/*******************************************************************************************************
* Class Name        : CaseTriggerHandler
* Description       : Trigger Handler for Case
* Author            : Simplus - Levi Davision
* Created On        : 2020-07-24
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Levi Davision         2020-07-24      1000                Initial version
* MS Simplus            2021-06-15      2000                Added to check to case AccountId in checkContractGroupField method
* MS Simplus            2021-06-18      3000                Update checkContractGroupField method to provide error only on specific recordtypes
* Simplus MS			15/02/2022		4000				Added for SFSUP-302 - Person Account Changes
******************************************************************************************************/
public with sharing class CaseTriggerHandler {
    
    /**
    * @description 
    * @author Levi Davision | 24/07/2020 
    * @param newList 
    **/
    public static void afterInsert(List<Case> newList) {
        List<Case> runCaseAssignmentApexCases = new List<Case>();
        for(Case cs :newList){
            if(cs.Run_Case_Assignment_via_Apex__c){
                runCaseAssignmentApexCases.add(cs);
            }
        }
        setAutoAssignment(runCaseAssignmentApexCases);
    }

    /**
    * @description - provide error message on Case creation when 
    * @author Anderson Pagtabunan | 07/06/2021 
    * @param newList 
    **/
    public static void checkContractGroupField(List<Case> newList) {
        List<String> recTypeDevNamesFilter = new List<String>{'NZ_Contract_Requests','AU_Contract_Requests'};
        List<RecordType> recTypeList = [SELECT Id FROM RecordType WHERE DeveloperName IN :recTypeDevNamesFilter];
        List<Id> rectypeFilterIds = new List<Id>{};
        for(RecordType recType : recTypeList) { rectypeFilterIds.add(recType.Id); }
        
        Map<Id, Id> caseIdToAccIdMap = new Map<Id, Id>();
        for(Case curCase : newList) {
            if(curCase.AccountId != null){
                caseIdToAccIdMap.put(curCase.Id, curCase.AccountId);
            }
        }
        
        if(!caseIdToAccIdMap.isEmpty()){
            
                Map<Id, Account> accIdToAccountMap = new Map<Id, Account>([
                SELECT Id, Name, Contract_Group__c, Contract_Group__r.Name, RecordTypeId
                FROM Account 
                WHERE Id IN :caseIdToAccIdMap.values()
                AND RecordTypeId != :DM_RecordType.rtId_Account_PersonAccount]);
    
            if(!accIdToAccountMap.isEmpty()) {
                for(Case curCase : newList) {
                    if(accIdToAccountMap.get(caseIdToAccIdMap.get(curCase.Id)).Contract_Group__c != null &&
                    rectypeFilterIds.contains(curCase.RecordTypeId)) {
                        curCase.addError(
                            'This case\'s related account is part of a pricing group. Please initiate the request from the master account '+ accIdToAccountMap.get(caseIdToAccIdMap.get(curCase.Id)).Contract_Group__r.Name +' or discuss with the master account owner'
                        );
                    }
                }
            }
            
        }
    }

    /**
    * @description 
    * @author Levi Davision | 24/07/2020 
    * @param newList 
    **/
    public static void setAutoAssignment(List<Case> newList) {

        // Set auto assignment rules for cases. setoptions only 
        // are possible after completion of a dml operation.
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule= true;  

        List<Case> lstCase = new List<Case>();
        for(Case c : newList) {
            c.setOptions(dmo);
            Case objCase = c.clone(true,true);
            lstCase.add(objCase);
        } 
        update lstCase;
    }
}