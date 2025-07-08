/*******************************************************************************************************
* Class Name      	: DM_ContactPointAddress_Test
* @description		: Test class for DM_ContactPointAddress
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class DM_ContactPointAddress_Test {


    /**
     * @description makeData - Creates test data for the test class
     * @author Juan M. Cutrera
     */
    @TestSetup
    static void makeData(){
        ContactPointAddress cpa = TestDataFactory.createContactPointAddress();
        insert cpa;

    }

    /**
     * @description  Test method for getContactPointAddressesByParentId
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getContactPointAddressesByParentIdTest() {
        // Arrange: Create test data
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;

        // Act: Query the inserted record
        List<ContactPointAddress> queriedAddresses = DM_ContactPointAddress.getContactPointAddressesByParentId(parentId);

        // Assert: Validate the record was inserted correctly
        Assert.areNotEqual(null, queriedAddresses, 'The list should not be null.');
        Assert.areEqual(1, queriedAddresses.size(), 'There should be one record.');
        Assert.areEqual('Test Contact Point Address', queriedAddresses[0].Name, 'The Name should match.');
    }

    /**
     * @description  Test method for getContactPointAddressesByParentId with null parentId
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getContactPointAddressesByParentId_NullParentIdTest() {
        // Act: Call the method with null parentId
        List<ContactPointAddress> queriedAddresses = DM_ContactPointAddress.getContactPointAddressesByParentId(null);

        // Assert: Validate the result
        Assert.areNotEqual(null, queriedAddresses, 'The list should not be null.');
        Assert.areEqual(0, queriedAddresses.size(), 'There should be no records.');
    }
}