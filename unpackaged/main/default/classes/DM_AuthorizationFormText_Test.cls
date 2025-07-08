/*******************************************************************************************************
* Class Name      	: DM_AuthorizationFormText_Test
* @description		: Test class for DM_AuthorizationFormText
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class DM_AuthorizationFormText_Test {

    /**
     * @description makeData - Creates test data for the test class
     * @author Juan M. Cutrera
     */
    @testSetup
    static void makeData(){
        AuthorizationForm myAuthForm =  TestDataFactory.createAuthorizationForm();
        insert myAuthForm;
        authorizationFormText authorizationFormText = new authorizationFormText();
        authorizationFormText.Name = 'Test Authorization Form';
        authorizationFormText.External_Id__c = 'LegalHireShopPolicyEnglish';
        authorizationFormText.AuthorizationFormId = myAuthForm.Id;
        insert authorizationFormText;
    }

    /**
    * @description  Test method for DM_AuthorizationFormText functionality
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void getAuthorizationFormTextByExternalIdTest() {
        // Arrange: Create test data
        

        // Act: Query the inserted record
        authorizationFormText queriedFormText = DM_AuthorizationFormText.getAuthorizationFormTextByExternalId('LegalHireShopPolicyEnglish');

        // Assert: Validate the record was inserted correctly
        Assert.areNotEqual(null, queriedFormText, 'The record should exist.');
        Assert.areEqual('Test Authorization Form', queriedFormText.Name, 'The Name should match.');
    }

}