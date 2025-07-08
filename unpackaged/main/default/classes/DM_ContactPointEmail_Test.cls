/*******************************************************************************************************
* Class Name      	: DM_ContactPointEmail_Test
* @description		: Test class for DM_ContactPointEmail
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class DM_ContactPointEmail_Test {

    /**
     * @description makeData - Creates test data for the test class
     * @author Juan M. Cutrera
     */
    @TestSetup
    static void makeData(){
        //TODO put it on test Data Factory
        insert TestDataFactory.createContactPointEmail();
    }

    @isTest
    static void getContactPointEmailsByParentIdTest() {
        // Arrange: Create test data
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;

        // Act: Query the inserted record
        List<ContactPointEmail> queriedEmails = DM_ContactPointEmail.getContactPointEmailsByParentId(parentId);

        // Assert: Validate the record was inserted correctly
        Assert.areNotEqual(null, queriedEmails, 'The list should not be null.');
        Assert.areEqual(1, queriedEmails.size(), 'There should be one record.');
        Assert.areEqual('test@test.com', queriedEmails[0].EmailAddress, 'The Name should match.');
    }

    /**
     * @description  Test method for getContactPointEmailsByParentId with null parentId
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getContactPointEmailsByParentId_NullParentIdTest() {
        // Act: Call the method with null parentId
        List<ContactPointEmail> queriedEmails = DM_ContactPointEmail.getContactPointEmailsByParentId(null);

        // Assert: Validate the result
        Assert.areNotEqual(null, queriedEmails, 'The list should not be null.');
        Assert.areEqual(0, queriedEmails.size(), 'There should be no records.');
    }
}