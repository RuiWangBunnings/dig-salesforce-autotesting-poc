/*******************************************************************************************************
* Class Name      	: SM_Individual_Test
* @description		: Test class for SM_Individual
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_Individual_Test {

    /**
     * @description testBuildNewIndividual
     * @author 
     */
    @IsTest
    static void testBuildNewIndividual(){
        Consent_ConsentManagerPayload.Entity entity = new Consent_ConsentManagerPayload.Entity();
        entity.countryCode = 'AU';
        entity.person = new Consent_ConsentManagerPayload.Person();
        entity.person.firstName = 'John';
        entity.person.lastName = 'Doe';
        entity.person.contactPoints = new List<Consent_ConsentManagerPayload.ContactPoint>();
        Consent_ConsentManagerPayload.ContactPoint contactPoint = new Consent_ConsentManagerPayload.ContactPoint();
        contactPoint.address = new Consent_ConsentManagerPayload.Address();
        contactPoint.type = 'Address';
        contactPoint.address.stateCode = 'NSW';
        entity.person.contactPoints.add(contactPoint);
        entity.capture = new Consent_ConsentManagerPayload.Capture();
        entity.capture.source = 'TestSource';
        entity.capture.sourceModule = 'TestModule';
        entity.capture.sourceReference = 'TestSystemId';
        
        Individual result = SM_Individual.buildNewIndividual(entity);
        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    /**
     * @description testUpsertIndividual 
     * @author Juan M. Cutrera
     */
    @IsTest
    static void testUpsertIndividual(){
        Individual result = new Individual(
            FirstName = 'John',
            LastName = 'Doe',
            Country__c = 'AU',
            State__c = 'NSW',
            SourceSystem__c = 'TestSource',
            SourceSystemModule__c = 'TestModule',
            SourceCustomerId__c = 'TestSystemId'
        );
        test.startTest();
        SM_Individual.upsertIndividual(result);
        test.stopTest();
        Assert.areNotEqual(null, result.Id, 'Result should not be null');
    }

    @IsTest
    static void testUpsertIndividual_Exception(){
        //No lastName will throw an exception
        Individual result = new Individual(
            FirstName = 'John',
            Country__c = 'AU',
            State__c = 'NSW',
            SourceSystem__c = 'TestSource',
            SourceSystemModule__c = 'TestModule',
            SourceCustomerId__c = 'TestSystemId'
        );
        test.startTest();
        try {
            SM_Individual.upsertIndividual(result);
            Assert.fail('Expected exception to be thrown');
        } catch (Exception e) {
            Assert.isTrue(true);
        }
        test.stopTest();
    }
}