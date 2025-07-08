/*******************************************************************************************************
* Class Name      	: SM_ContactPointPhone_Test
* @description		: Test class for  SM_ContactPointPhone_Test
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_ContactPointPhone_Test {

    @TestSetup
    static void makeData(){
        TestDataFactory.createIndividuals(1);
    }
    /**
     * @description TestBuildNewContactPointPhone
     * @author Juan M. Cutrera
     */
    @isTest 
    static void TestBuildNewContactPointPhone(){
        Consent_ConsentManagerPayload.ContactPoint contactPoint = new Consent_ConsentManagerPayload.ContactPoint();
        contactPoint.phone = new Consent_ConsentManagerPayload.Phone();
        contactPoint.phone.phoneNumber = '123456789';
        ContactPointPhone result = SM_ContactPointPhone.buildNewContactPointPhone(contactPoint);
        Assert.AreNotEqual(null, result, 'Result should not be null');
    }
    

    /**
     * @description TestUpsertContactPointPhones
     * @author Juan M. Cutrera
     */
    static void TestUpsertContactPointPhones(){
        List<ContactPointPhone> contactPointPhoneList = new List<ContactPointPhone>();
        //TODO do this logic on TestDataFactory
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;
        for(Integer i = 0; i < 2; i++){
            ContactPointPhone contactPointPhone = new ContactPointPhone();
            contactPointPhone.TelephoneNumber  = '123456789' + i;
            contactPointPhone.ParentId = parentId; 
            contactPointPhoneList.add(contactPointPhone);
        }

        Test.startTest();
        SM_ContactPointPhone.upsertContactPointPhones(contactPointPhoneList);
        Test.stopTest();
        List<ContactPointPhone> queriedPhones = [SELECT Id, TelephoneNumber FROM ContactPointPhone WHERE ParentId = :parentId];
        Assert.areEqual(2, queriedPhones.size(), 'There should be two records.');
    }

    /**
     * @description TestUpsertContactPointPhones_Exception
     * @author Juan M. Cutrera
     */
    @isTest
    static void TestUpsertContactPointPhones_Exception(){
        List<ContactPointPhone> contactPointPhoneList = new List<ContactPointPhone>();
        //TODO do this logic on TestDataFactory
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;
        for(Integer i = 0; i < 2; i++){
            ContactPointPhone contactPointPhone = new ContactPointPhone();
            //Have no TelephoneNunmber
            contactPointPhone.ParentId = parentId; 
            contactPointPhoneList.add(contactPointPhone);
        } 
        Test.startTest();
        try {
            SM_ContactPointPhone.upsertContactPointPhones(contactPointPhoneList);
            Assert.fail('Expected exception to be thrown');
        }catch(Exception e){
            Assert.isTrue(true);
        }
        Test.stopTest();
        
    }
}