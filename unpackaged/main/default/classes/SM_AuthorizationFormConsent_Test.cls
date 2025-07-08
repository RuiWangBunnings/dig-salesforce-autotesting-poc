/*******************************************************************************************************
* Class Name      	: SM_AuthorizationFormConsent_Test
* @description		: Test class for SM_AuthorizationFormConsent
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@IsTest
private class SM_AuthorizationFormConsent_Test {

    /**
    * @description  testBuildNewAuthorizationFormConsent - Tests the buildNewAuthorizationFormConsent method with valid input
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testBuildNewAuthorizationFormConsent() {
        // Arrange
        Consent_ConsentManagerPayload.Entity entity = new Consent_ConsentManagerPayload.Entity();
        Consent_ConsentManagerPayload.Person person = new Consent_ConsentManagerPayload.Person();
        person.firstName = 'John';
        person.lastName = 'Doe';
        entity.person = person;

        Consent_ConsentManagerPayload.Consent consent = new Consent_ConsentManagerPayload.Consent();
        Consent_ConsentManagerPayload.EffectivePeriod effectivePeriod = new Consent_ConsentManagerPayload.EffectivePeriod();
        effectivePeriod.startDateTime = DateTime.now();
        consent.effectivePeriod = effectivePeriod;
        entity.consent = consent;

        Consent_ConsentManagerPayload.Capture capture = new Consent_ConsentManagerPayload.Capture();
        capture.source = 'Web';
        capture.engagementChannel = 'InStore';
        capture.identifier = 'MessageId';
        entity.capture = capture;

        // Act
        AuthorizationFormConsent result = SM_AuthorizationFormConsent.buildNewAuthorizationFormConsent(entity);

        // Assert
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual('John Doe', result.Name, 'Name should match');
        Assert.areEqual('Web', result.ConsentCapturedSource, 'ConsentCapturedSource should match');
        Assert.areEqual('InPerson', result.ConsentCapturedSourceType, 'ConsentCapturedSourceType should match');
        Assert.areEqual('MessageId', result.Message_Id__c, 'ConsentCapturedSourceType should match');
    }

    /**
    * @description  testBuildNewAuthorizationFormConsent_NullEntity - Tests the buildNewAuthorizationFormConsent method with a null entity
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testBuildNewAuthorizationFormConsent_NullEntity() {
        // Act
        AuthorizationFormConsent result = SM_AuthorizationFormConsent.buildNewAuthorizationFormConsent(null);

        // Assert
        Assert.isNull(result, 'Result should be null for a null entity');
    }

    /**
    * @description  testBuildNewAuthorizationFormConsent_MissingFields - Tests the buildNewAuthorizationFormConsent method with missing fields in the entity
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testBuildNewAuthorizationFormConsent_MissingFields() {
        // Arrange
        Consent_ConsentManagerPayload.Entity entity = new Consent_ConsentManagerPayload.Entity();

        // Act
        AuthorizationFormConsent result = SM_AuthorizationFormConsent.buildNewAuthorizationFormConsent(entity);

        // Assert
        Assert.isNotNull(result, 'Result should not be null even with missing fields');
        Assert.isNull(result.Name, 'Name should be null when person details are missing');
    }
}