/*******************************************************************************************************
* Class Name      	: SM_Case
* Description		: Service layer for Case epic.
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    05/06/2020		1000				Initial version
* Jasper R. Galapon     19/06/2023      2000                BUNDIG-21197 - New/Renewal Contracts - No Case Created When A1 Rejects
******************************************************************************************************/
public without sharing class SM_Case {
    /**
    * @description - method to create a case with associated contract and comment
    * @author John Paul Peñaflor | 05/06/2020
    * @param String contractId 
    * @return Boolean 
    **/
    @AuraEnabled
    public static Boolean createCase(Contract__c contract, String comment) {
        try {
            System.debug('***CREATING A CASE');
            String recordTypeName = contract.Country__c == 'Australia' ?  Constants.AU_CONTRACT_CASE : Constants.NZ_CONTRACT_CASE;
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

            // BUNDIG-21197
            String caseOwner = contract.Country__c == 'Australia' ? 'AU_Contract_Team_Queue' : 'NZ_Contract_Team_Queue';
            Id caseOwnerId = [SELECT Id FROM Group WHERE DeveloperName =:caseOwner].Id;

            Case caseRec = new Case();
            caseRec.RecordTypeId = caseRecordTypeId;
            caseRec.OwnerId = caseOwnerId;
            caseRec.Type = 'Contract Request';
            caseRec.Subtype__c = 'Contract Review - Changes Required';
            caseRec.Contract_Number__c = contract.Id;
            caseRec.Description = comment;
            
            insert caseRec;
            return true;
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.createCase', 'Contract__c', 'Trigger', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}