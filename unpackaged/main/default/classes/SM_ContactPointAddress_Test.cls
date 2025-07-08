/*******************************************************************************************************
* Class Name      	: SM_ContactPointAddress_Test
* @description		: Test class for SM_ContactPointAddress
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          10/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_ContactPointAddress_Test {

   @isTest 
   static void testBuildNewContactPointAddress(){
        // Arrange
        Consent_ConsentManagerPayload.ContactPoint contactPoint = TestDataFactory.createPayloadContactPoint('Mailing Address'); 

        // Act
        ContactPointAddress result = SM_ContactPointAddress.buildNewContactPointAddress(contactPoint);

        // Assert
        Assert.areNotEqual(null, result, 'Result should not be null');
   }

   @isTest 
   static void testUpsertContactPointAddresses(){
        Consent_ConsentManagerPayload.ContactPoint contactPoint = TestDataFactory.createPayloadContactPoint('Mailing Address'); 

        // Act
        ContactPointAddress result = SM_ContactPointAddress.buildNewContactPointAddress(contactPoint);
        result.Name= 'Test Address';
        List<ContactPointAddress> resultList = new List<ContactPointAddress>();
        resultList.add(result);
        SM_ContactPointAddress.upsertContactPointAddresses(resultList);
        List<ContactPointAddress> queriedAddresses = [SELECT Id, Name FROM ContactPointAddress WHERE Name = 'Test Address'];
        // Assert  
        Assert.areNotEqual(null, queriedAddresses, 'Queried addresses should not be null');
        Assert.areEqual(1, queriedAddresses.size(), 'There should be one address');

   }


   @isTest 
   static void TestUpsertContactPointAddressesDMLException(){
        Consent_ConsentManagerPayload.ContactPoint contactPoint = TestDataFactory.createPayloadContactPoint('Mailing Address'); 
        
        contactPoint.Address.stateCode = 'Test State';
        // Act
        ContactPointAddress result = SM_ContactPointAddress.buildNewContactPointAddress(contactPoint);
        List<ContactPointAddress> resultList = new List<ContactPointAddress>();
        resultList.add(result);
        try {
            SM_ContactPointAddress.upsertContactPointAddresses(resultList);
            Assert.fail('Expected DmlException was not thrown');
        } catch (Exception e) {
            Assert.isTrue(true);
        }

   }
}