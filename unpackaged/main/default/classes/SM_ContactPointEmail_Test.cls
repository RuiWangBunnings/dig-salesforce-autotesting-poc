/*******************************************************************************************************
* Class Name      	: SM_ContactPointEmail_Test
* @description		: Test class for SM_ContactPointEmail
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_ContactPointEmail_Test {

    @TestSetup
    static void makeData(){
        TestDataFactory.createIndividuals(1);
    }

    /**
     * @description TestBuildNewContactPointEmail 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void TestBuildNewContactPointEmail(){
        Consent_ConsentManagerPayload.ContactPoint contactPoint = new Consent_ConsentManagerPayload.ContactPoint();
        contactPoint.email = 'test@test.com';
        ContactPointEmail result = SM_ContactPointEmail.buildNewContactPointEmail(contactPoint);
        Assert.AreNotEqual(null, result, 'Result should not be null');
    }

    /**
     * @description TestUpsertContactPointEmails 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void TestUpsertContactPointEmails(){
        List<ContactPointEmail> contactPointEmailList = new List<ContactPointEmail>();
        //TODO do this logic on TestDataFactory
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;
        for(Integer i = 0; i < 2; i++){
            ContactPointEmail contactPointEmail = new ContactPointEmail();
            contactPointEmail.EmailAddress  = 'contactPointEmail' + i + '@test.com';
            contactPointEmail.ParentId = parentId; 
            contactPointEmailList.add(contactPointEmail);
        }

        Test.startTest();
        SM_ContactPointEmail.upsertContactPointEmails(contactPointEmailList);
        Test.stopTest();
        List<ContactPointEmail> queriedEmails = [SELECT Id, EmailAddress FROM ContactPointEmail WHERE ParentId = :parentId];
        Assert.areEqual(2, queriedEmails.size(), 'There should be one record.');
    }

    /**
     * @description TestUpsertContactPointEmails_Exception 
     * @author Juan M. Cutrera
     */
    @isTest
    static void TestUpsertContactPointEmails_Exception(){
        List<ContactPointEmail> contactPointEmailList = new List<ContactPointEmail>();
        //TODO do this logic on TestDataFactory
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;
        for(Integer i = 0; i < 2; i++){
            ContactPointEmail contactPointEmail = new ContactPointEmail();
            contactPointEmail.ParentId = parentId; 
            contactPointEmailList.add(contactPointEmail);
        } 

        Test.startTest();
        try{
            SM_ContactPointEmail.upsertContactPointEmails(contactPointEmailList);
            Assert.fail('Expected exception to be thrown');

        }catch(Exception e){
            Assert.isTrue(true);
        }
        Test.stopTest();

    }

}