/*******************************************************************************************************
* Class Name      	: DM_Contract
* Description		: Data Layer - Selector for Sobject Contract__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-05-21
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-21		1000				Initial version
* Philip Clark			01/07/2020		1001				getContractsbyOrigReviewerApprover
* Yi Zhang              2020-07-16		1002			    Remove 4 deleted fields from all queries
* Simplus Ms            2022-02-24		1003			    Logic added for SFSUP-361 - Contract review - History comment from A1 & A2
******************************************************************************************************/
public with sharing class DM_Contract {
    
    /**
    * @description 
    * @author Yi Zhang | 21/05/2020 
    * @param contractIds 
    * @return List<Contract__c> 
    **/
    public static List<Contract__c> getContracts(List<String> contractIds) {
        // Contract Number, Contract Name, State, Cost Zone to start with
        return [
            SELECT Id, Contract_Name__c, Name, State__c, Cost_Zone__c, Country__c, Status__c,
            Previous_Header_ID__c, Contract_Locked__c, 
            Original_Approver__c, Approver__c, Approver__r.Name, Approver_Action__c, Approver_Action_Date__c, Approver_Comments__c,
            Original_Reviewer__c, Reviewer__c, Reviewer__r.Name, Reviewer_Action__c, Reviewer_Action_Date__c, Reviewer_Comments__c, 
            Contract_Approval_Status__c, Project__c, Previous_Approver_Record__c,Previous_Reviewer_Record__c
            FROM Contract__c
            WHERE Id IN :contractIds
        ];
    }

    /**
    * @description 
    * @author Simplus Ms | 24/02/2022 
    * @param contractId 
    * @return List<Contract__History> 
    **/
    public static List<Contract__History> getContractHistory(Id contractId) {
        return [
            SELECT Id, CreatedDate, Field, CreatedBy.Name, OldValue, NewValue, Parent.Name FROM Contract__History WHERE ParentId = :contractId
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
    * @description 
    * @author Philip Clark | 01/07/2020 
    * @param userIds 
    * @return List<Contract__c> 
    **/
    public static List<Contract__c> getContractsbyReviewerApprover(set<Id> userIds) {
        // Contract Number, Contract Name, State, Cost Zone to start with
        return [
            SELECT Id, Contract_Name__c, Name, State__c, Cost_Zone__c, Country__c, Status__c,
            Previous_Header_ID__c, Contract_Locked__c, 
            Original_Approver__c, Approver__c, Approver__r.Name, Approver_Action__c, Approver_Action_Date__c, Approver_Comments__c,
            Original_Reviewer__c, Reviewer__c, Reviewer__r.Name, Reviewer_Action__c, Reviewer_Action_Date__c, Reviewer_Comments__c, 
            Contract_Approval_Status__c, Previous_Approver_Record__c, Previous_Reviewer_Record__c
            FROM Contract__c
            WHERE Approver__c IN :userIds OR Reviewer__c IN :userIds
        ];
    }
    
    /**
    * @description 
    * @author Philip Clark | 01/07/2020 
    * @param userIds 
    * @return List<Contract__c> 
    **/
    public static List<Contract__c> getContractsbyOrigReviewerApprover(set<Id> userIds) {
        // Contract Number, Contract Name, State, Cost Zone to start with
        return [
            SELECT Id, Contract_Name__c, Name, State__c, Cost_Zone__c, Country__c, Status__c,
            Previous_Header_ID__c, Contract_Locked__c, 
            Original_Approver__c, Approver__c, Approver__r.Name, Approver_Action__c, Approver_Action_Date__c, Approver_Comments__c,
            Original_Reviewer__c, Reviewer__c, Reviewer__r.Name, Reviewer_Action__c, Reviewer_Action_Date__c, Reviewer_Comments__c, 
            Contract_Approval_Status__c, Previous_Approver_Record__c, Previous_Reviewer_Record__c
            FROM Contract__c
            WHERE Original_Approver__c IN :userIds OR Original_Reviewer__c IN :userIds
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 21/05/2020 
    * @param contractId 
    * @return Contract__c 
    **/
    public static Contract__c getContract(String contractId) {
        return getContracts(new List<String>{contractId})[0];
    }
}