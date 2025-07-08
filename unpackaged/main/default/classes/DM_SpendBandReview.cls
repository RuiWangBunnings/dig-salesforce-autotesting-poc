/*******************************************************************************************************
* Class Name      	: DM_SpendBandReview
* Description		: Data Layer - Selector for Sobject Spend_Band_Review__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 18/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              18/05/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_SpendBandReview {

    /**
    * @description Level 1 Approver is the same as owner for this object
    * @author Yi Zhang | 18/05/2020 
    * @param accountIds 
    * @param approverIds 
    * @return Map<Id, Spend_Band_Review__c> 
    **/
    public static Map<Id, Spend_Band_Review__c> getSpendBandReviewsForApprover1(Set<Id> accountIds, Set<Id> approverIds) {
        
        return new Map<Id, Spend_Band_Review__c>([
            SELECT Id, Account__c, Level_1_Approver__c
            FROM Spend_Band_Review__c
            WHERE Account__c IN :accountIds
            AND Level_1_Approver__c IN :approverIds
            AND Level_1_Action__c = null
        ]);
    }
}