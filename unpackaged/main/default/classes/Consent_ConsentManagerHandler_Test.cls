/*******************************************************************************************************
* Class Name      	: Consent_ConsentManagerHandler_Test
* @description		: Test Class - Tests the logic for Consent_ConsentManagerHandler
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 25/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          25/03/2025		1000				Initial Version
******************************************************************************************************/
@isTest
public class Consent_ConsentManagerHandler_Test {
    
    
    @TestSetup
    static void makeData(){
        insert TestDataFactory.createAuthorizationForm();
    }

    /**
    * @description  createConsentErrorTest() - Make it throw an error on the response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void createConsentErrorTest() {
        JSONGenerator payloadGen = JSON.createGenerator(true);
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('Entity');
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('countryCode');
        payloadGen.writeString('AU');
        
        payloadGen.writeFieldName('person');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('name');
        payloadGen.writeString('Tester Test');
        payloadGen.writeFieldName('first name');
        payloadGen.writeString('Tester');
        payloadGen.writeFieldName('last name');
        payloadGen.writeString('Test');
        
        payloadGen.writeFieldName('contactPoints');
        payloadGen.writeStartArray();
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('Mobile');
        payloadGen.writeFieldName('value');
        payloadGen.writeString('0451123987');
        payloadGen.writeEndObject();
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('Email');
        payloadGen.writeFieldName('value');
        payloadGen.writeString('test@test.com');
        payloadGen.writeEndObject();
        
        payloadGen.writeEndArray(); //contactPoints Array
        payloadGen.writeEndObject(); //Person object
        payloadGen.writeEndObject(); //Entity object
        payloadGen.writeEndObject(); //main JSON Object
        
        String jsonString = payloadGen.getAsString();
        
        System.debug('$$$ Json.Parse: ' + jsonString);
        
       	
        //Set up a test Request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/bunningsconsent/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;
        
        Consent_ConsentManager.createConsent();
        
       	Assert.AreEqual(403, RestContext.response.statusCode);
    }
    
    /**
    * @description  createConsentSuccessTest() - Make it throw an success on the response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void createConsentSuccessTest(){
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
        
        System.debug('$$$ SUCCESS MESSAGE Json.Parse: ' + jsonString);
        
       	
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

    /**
    * @description  testCreateConsentSuccessMultipleAccountsAndIndividualsLinked() - Make it throw an success on the response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void testCreateConsentSuccessMultipleAccountsAndIndividualsLinked(){
        Id authorizationFormId = [SELECT Id FROM AuthorizationForm LIMIT 1].Id;
        Test.startTest();
        //Create the Authorization Form Text\
        authorizationFormText authorizationFormText = new authorizationFormText();
        authorizationFormText.Name = 'Test Authorization Form';
        authorizationFormText.External_Id__c = 'LegalHireShopPolicyEnglish';
        authorizationFormText.AuthorizationFormId = authorizationFormId;
        insert authorizationFormText;
        Test.stopTest();
        
        //Create the Individuals
        List<Individual> individuals = TestDataFactory.createIndividuals(2);
        // insert individuals;
        //Create the Account
        List<Account>  accountList=  TestDataFactory.createPersonAccounts(2);
        for(Account account : accountList){
            //Update Person
            account.PersonIndividualId = individuals[0].Id;
            account.personEmail = 'juancutrera@test.com';
        }
        accountList[1].PersonIndividualId = individuals[1].Id;
        insert accountList;


        String jsonString = TestDataFactory.createConsentPayloadJSON();
        
        System.debug('$$$ SUCCESS MESSAGE Json.Parse: ' + jsonString);
        
       	
        //Set up a test Request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/bunningsconsent/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);
        
        RestResponse response = new RestResponse();
        
        RestContext.request = request;
        RestContext.response = response;
        
        Consent_ConsentManager.createConsent();
        
        // Assert.AreEqual(201, RestContext.response.statusCode);
    }

    /**
    * @description  testCreateConsentSuccessMultipleAccountAndIndividualLinked() - Make it throw an success on the response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void testCreateConsentSuccessMultipleAccountAndIndividualLinked(){
        Id authorizationFormId = [SELECT Id FROM AuthorizationForm LIMIT 1].Id;
        Test.startTest();
        //Create the Authorization Form Text\
        authorizationFormText authorizationFormText = new authorizationFormText();
        authorizationFormText.Name = 'Test Authorization Form';
        authorizationFormText.External_Id__c = 'LegalHireShopPolicyEnglish';
        authorizationFormText.AuthorizationFormId = authorizationFormId;
        insert authorizationFormText;
        Test.stopTest();
        
        //Create the Individuals
        List<Individual> individuals = TestDataFactory.createIndividuals(1);
        // insert individuals;
        //Create the Account
        List<Account>  accountList=  TestDataFactory.createPersonAccounts(1);
        for(Account account : accountList){
            //Update Person
            account.PersonIndividualId = individuals[0].Id;
            account.personEmail = 'juancutrera@test.com';
        }
        insert accountList;


        String jsonString = TestDataFactory.createConsentPayloadJSON();
        
        System.debug('$$$ SUCCESS MESSAGE Json.Parse: ' + jsonString);
        
       	
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
    
    @isTest 
    static void testEntityCouldNotBeRead(){

        String jsonString = '{"Entities2": [{"countryCode": "AU"}]}';


         //Set up a test Request
         RestRequest request = new RestRequest();
         request.requestUri = '/services/apexrest/bunningsconsent/';
         request.httpMethod = 'POST';
         request.requestBody = Blob.valueOf(jsonString);
         
         RestResponse response = new RestResponse();
         
         RestContext.request = request;
         RestContext.response = response;
         
         Consent_ConsentManager.createConsent();
         
         Assert.AreEqual(415, RestContext.response.statusCode);
    }
    
    /**
    * @description  hasMinimumRequirementsEmailTest() - Test if hasMinimumRequirements Email gives back a response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void hasMinimumRequirmentsEmailTest(){
        JSONGenerator payloadGen = JSON.createGenerator(true);
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('Entity');
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('countryCode');
        payloadGen.writeString('AU');
        
        payloadGen.writeFieldName('person');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('name');
        payloadGen.writeString('Tester Test');
        payloadGen.writeFieldName('firstName');
        payloadGen.writeString('Tester');
        payloadGen.writeFieldName('lastName');
        payloadGen.writeString('Test');
        
        payloadGen.writeFieldName('contactPoints');
        payloadGen.writeStartArray();
        
        //ContactPoint Phone
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('Phone');
      	payloadGen.writeFieldName('usage');
        payloadGen.writeString('Work');
        
        //Phone object
        payloadGen.writeFieldName('phone');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('number');
        payloadGen.writeString('0394939393');
        payloadGen.writeEndObject();
        //End of Phone object
        
        payloadGen.writeEndObject();
        //End of ContactPoint Phone
        
        //ContactPoint Email
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('Email');
        payloadGen.writeFieldName('email');
        payloadGen.writeString('test@test.com');
        payloadGen.writeEndObject();
        //End of ContactPoint Email
        
        payloadGen.writeEndArray(); //contactPoints Array
        payloadGen.writeEndObject(); //Person object
        payloadGen.writeEndObject(); //Entity object
        payloadGen.writeEndObject(); //main JSON Object
        
        String jsonString = payloadGen.getAsString();
        
        Consent_ConsentManagerPayload.entity currentEntity = Consent_ConsentManagerPayload.parse(jsonString).getEntity();
        
        System.debug('$$$ Entity: ' + currentEntity);
        
        Boolean result = Consent_ConsentManagerHandler.hasMinimumRequirments(currentEntity);
        Assert.areEqual(true,result);
    }
    
    
    /**
    * @description  hasMinimumRequirementsPhoneTest() - Test if hasMinimumRequirements Phone gives back a response
    * @author Juan Cutrera | 25/03/2025
    **/
    @isTest
    static void hasMinimumRequirmentsPhoneTest(){
        JSONGenerator payloadGen = JSON.createGenerator(true);
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('Entity');
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('countryCode');
        payloadGen.writeString('AU');
        
        payloadGen.writeFieldName('person');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('name');
        payloadGen.writeString('Tester Test');
        payloadGen.writeFieldName('firstName');
        payloadGen.writeString('Tester');
        payloadGen.writeFieldName('lastName');
        payloadGen.writeString('Test');
        
        payloadGen.writeFieldName('contactPoints');
        payloadGen.writeStartArray();
        
        //ContactPoint Phone
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('phone');
      	payloadGen.writeFieldName('usage');
        payloadGen.writeString('Mobile');
        
        //Phone object
        payloadGen.writeFieldName('Phone');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('number');
        payloadGen.writeString('0451875234');
        payloadGen.writeEndObject();
        //End of Phone object
        
        payloadGen.writeEndObject();
        //End of ContactPoint Phone
        
        
        payloadGen.writeEndArray(); //contactPoints Array
        payloadGen.writeEndObject(); //Person object
        payloadGen.writeEndObject(); //Entity object
        payloadGen.writeEndObject(); //JSON End
        
        String jsonString = payloadGen.getAsString();
        
        System.debug('$$$ JsonString: ' + jsonString);
        
        Consent_ConsentManagerPayload.entity currentEntity = Consent_ConsentManagerPayload.parse(jsonString).getEntity();
        
        System.debug('$$$ Entity: ' + currentEntity);
        
        Boolean result = Consent_ConsentManagerHandler.hasMinimumRequirments(currentEntity);
        Assert.areEqual(true,result);
    }
    
    /**
    * @description  hasMinimumRequirmentsPersonErrorTest() - Test if hasMinimumRequirements Person is null or not
    * @author Juan Cutrera | 7/04/2025
    **/
    @isTest
    static void hasMinimumRequirmentsPersonErrorTest(){
        JSONGenerator payloadGen = JSON.createGenerator(true);
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('Entity');
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('countryCode');
        payloadGen.writeString('AU');
        
        payloadGen.writeFieldName('person2');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('name');
        payloadGen.writeString('Tester Test');
        payloadGen.writeFieldName('firstName');
        payloadGen.writeString('Tester');
        payloadGen.writeFieldName('lastName');
        payloadGen.writeString('Test');
        
        payloadGen.writeFieldName('contactPoints');
        payloadGen.writeStartArray();
        
        //ContactPoint Phone
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('type');
        payloadGen.writeString('phone');
      	payloadGen.writeFieldName('usage');
        payloadGen.writeString('Mobile');
        
        //Phone object
        payloadGen.writeFieldName('Phone');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('number');
        payloadGen.writeString('0394939393');
        payloadGen.writeEndObject();
        //End of Phone object
        
        payloadGen.writeEndObject();
        //End of ContactPoint Phone
        
        
        payloadGen.writeEndArray(); //contactPoints Array
        payloadGen.writeEndObject(); //Person object
        payloadGen.writeEndObject(); //Entity object
        payloadGen.writeEndObject(); //JSON End
        
        String jsonString = payloadGen.getAsString();
        
        System.debug('$$$ JsonString: ' + jsonString);
        
        Consent_ConsentManagerPayload.entity currentEntity = Consent_ConsentManagerPayload.parse(jsonString).getEntity();
        
        System.debug('$$$ Entity: ' + currentEntity);
        
        Boolean result = Consent_ConsentManagerHandler.hasMinimumRequirments(currentEntity);
        Assert.areEqual(false,result, 'Person should return null hence false to meet minimum requirements');
    }
    
    /**
    * @description  hasMinimumRequirmentsEmptyContactListTest() - Test if hasMinimumRequirements has an Empty Contact List is null or not
    * @author Juan Cutrera | 7/04/2025
    **/
    @isTest
    static void hasMinimumRequirmentsEmptyContactListTest(){
        JSONGenerator payloadGen = JSON.createGenerator(true);
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('Entity');
        
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('countryCode');
        payloadGen.writeString('AU');
        
        payloadGen.writeFieldName('person');
        payloadGen.writeStartObject();
        payloadGen.writeFieldName('name');
        payloadGen.writeString('Tester Test');
        payloadGen.writeFieldName('firstName');
        payloadGen.writeString('Tester');
        payloadGen.writeFieldName('lastName');
        payloadGen.writeString('Test');
        
        //payloadGen.writeFieldName('contactPoints');
        //payloadGen.writeStartArray();
        
        
        
        //payloadGen.writeEndArray(); //contactPoints Array
        payloadGen.writeEndObject(); //Person object
        payloadGen.writeEndObject(); //Entity object
        payloadGen.writeEndObject(); //JSON End
        
        String jsonString = payloadGen.getAsString();
        
        System.debug('$$$ JsonString: ' + jsonString);
        
        Consent_ConsentManagerPayload.entity currentEntity = Consent_ConsentManagerPayload.parse(jsonString).getEntity();
        
        System.debug('$$$ Entity: ' + currentEntity);
        
        Boolean result = Consent_ConsentManagerHandler.hasMinimumRequirments(currentEntity);
        Assert.areEqual(false,result, 'Person should return null hence false to meet minimum requirements');
    }
    
}