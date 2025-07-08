/*******************************************************************************************************
* Class Name      	: SM_MatchingRulesHelper_Test
* @description		: Test class for SM_MatchingRulesHelper
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_MatchingRulesHelper_Test {

    @TestSetup
    static void makeData(){
        insert TestDataFactory.createAuthorizationForm();
    }

    /**
     * @description testGetPersonAccountsBasedOnEmailOrMobile 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testGetPersonAccountsBasedOnEmailOrMobile(){
        Test.startTest();
        SM_MatchingRulesHelper.getPersonAccountsBasedOnEmailOrMobile('matchingEmail', 'matchingMobilePhone');
        Test.stopTest();
    }

    /**
     * @description testGetIndividualsByIds 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testGetIndividualsByIds(){
        Test.startTest();
        SM_MatchingRulesHelper.getIndividualsByIds(new List<Id>{'001xx000003NGtYAAW'});
        Test.stopTest();
    }

    /**
     * @description testGetContactPointEmailsByParentId 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testGetContactPointEmailsByParentId(){
        Test.startTest();
        SM_MatchingRulesHelper.getContactPointEmailsByParentId('001xx000003NGtYAAW');
        Test.stopTest();
    }

    /**
     * @description testGetContactPointPhonesByParentId 
     * @author Juan M. Cutrera
     */
    @isTest
    static void testGetContactPointPhonesByParentId(){
        Test.startTest();
        SM_MatchingRulesHelper.getContactPointPhonesByParentId('001xx000003NGtYAAW');
        Test.stopTest();
    }

    /**
     * @description testGetContactPointAddressesByParentId 
     * @author Juan M. Cutrera
     */
    @isTest
    static void testGetContactPointAddressesByParentId(){
        Test.startTest();
        SM_MatchingRulesHelper.getContactPointAddressesByParentId('001xx000003NGtYAAW');
        Test.stopTest();
    }

    /**
     * @description testGetAuthorizationFormTextByExternalId 
     * @author Juan M. Cutrera
     */
    @isTest
    static void testGetAuthorizationFormTextByExternalId(){
        Id authorizationFormId = [SELECT Id FROM AuthorizationForm LIMIT 1].Id;
        Test.startTest();
        //Create the Authorization Form Text\
        authorizationFormText authorizationFormText = new authorizationFormText();
        authorizationFormText.Name = 'Test Authorization Form';
        authorizationFormText.External_Id__c = 'LegalHireShopPolicyEnglish';
        authorizationFormText.AuthorizationFormId = authorizationFormId;
        insert authorizationFormText;
        SM_MatchingRulesHelper.getAuthorizationFormTextByExternalId('LegalHireShopPolicyEnglish');
        Test.stopTest();
    }

    
}