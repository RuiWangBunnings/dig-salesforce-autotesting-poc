/*******************************************************************************************************
* Class Name      	: DM_ContactPointPhone_Test
* @description		: Test class for DM_ContactPointPhone
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class DM_ContactPointPhone_Test {

    /**
     * @description makeData - Creates test data for the test class
     * @author Juan M. Cutrera
     */
    @TestSetup
    static void makeData(){
       insert TestDataFactory.createContactPointPhone(); 
    }

    /**
     * @description  Test method for getContactPointPhonesByParentId
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getContactPointPhonesByParentIdTest() { 
        // Arrange: Create test data
        Id parentId = [SELECT Id FROM Individual LIMIT 1].Id;

        // Act: Query the inserted record
        List<ContactPointPhone> queriedPhones = DM_ContactPointPhone.getContactPointPhonesByParentId(parentId);

        // Assert: Validate the record was inserted correctly
        Assert.areNotEqual(null, queriedPhones, 'The list should not be null.');
        Assert.areEqual(1, queriedPhones.size(), 'There should be one record.');
        Assert.areEqual('0451876567', queriedPhones[0].TelephoneNumber, 'The TelephoneNumber should match.');
    }
    /**
     * @description  Test method for getContactPointPhonesByParentId with null parentId
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getContactPointPhonesByParentId_NullParentIdTest() {
        // Act: Call the method with null parentId
        List<ContactPointPhone> queriedPhones = DM_ContactPointPhone.getContactPointPhonesByParentId(null);

        // Assert: Validate the result
        Assert.areNotEqual(null, queriedPhones, 'The list should not be null.');
        Assert.areEqual(0, queriedPhones.size(), 'There should be no records.');
    }

}