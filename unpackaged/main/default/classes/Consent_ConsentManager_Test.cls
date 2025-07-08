/*******************************************************************************************************
* Class Name      	: Consent_ConsentManager_Test
* @description		: Test class - The Test class for WebService for Consent
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 25/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          25/03/2025		1000				Initial Version
******************************************************************************************************/
@isTest
public class Consent_ConsentManager_Test {
    
    @TestSetup
    static void makeData(){
        insert TestDataFactory.createAuthorizationForm();
    }
    
    /**
    * @description  createConsentTest() - Tests out the Consent Web Service
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void createConsentTest() {
        Id authorizationFormId = [SELECT Id FROM AuthorizationForm LIMIT 1].Id;
        Test.startTest();
        //Create the Authorization Form Text\
        authorizationFormText authorizationFormText = new authorizationFormText();
        authorizationFormText.Name = 'Test Authorization Form';
        authorizationFormText.External_Id__c = 'LegalHireShopPolicyEnglish';
        authorizationFormText.AuthorizationFormId = authorizationFormId;
        insert authorizationFormText;
        Test.stopTest();

        String jsonString = TestDataFactory.createConsentPayloadJSON();
        
       	
        //Set up a test Request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/bunningsconsent/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;
        
        Consent_ConsentManager.createConsent();
        
        Assert.AreEqual(201, RestContext.response.statusCode);
    }
}