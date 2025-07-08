/*******************************************************************************************************
* Class Name      	: SM_ContactPointAddressBuilder_Test
* @description		: Test class for SM_ContactPointAddressBuilder
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
@IsTest
private class SM_ContactPointAddressBuilder_Test {

    /**
    * @description  testSetAddressBasicFields - Tests the setAddress method with basic fields
    * @author Juan Cutrera | 04/04/2025

    **/
    @IsTest
    static void testSetAddressBasicFields() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();

        // Act
        builder.setAddress('123 Main St', 'Sydney', 'NSW', '2000', 'Australia');
        ContactPointAddress result = builder.build();

        // Assert
        Assert.areEqual(result.Street, '123 Main St', 'Street should match');
        Assert.areEqual(result.City, 'Sydney', 'City should match');
        Assert.areEqual(result.State, 'NSW', 'State should match');
        Assert.areEqual(result.PostalCode, '2000', 'PostalCode should match');
        Assert.areEqual(result.Country, 'Australia', 'Country should match');
    }


    /**
    * @description  testSetAddressTypeValid - Tests the setAddressType method with a valid address type
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetAddressTypeValid() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();
        String validAddressType = 'Billing'; // Replace with a valid picklist value

        // Act
        builder.setAddressType(validAddressType);
        ContactPointAddress result = builder.build();

        // Assert
        Assert.areEqual(result.AddressType, validAddressType, 'AddressType should match');
    }

    /**
    * @description  testSetAddressTypeInvalid - Tests the setAddressType method with an invalid address type
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetAddressTypeInvalid() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();
        String invalidAddressType = 'InvalidType';

        // Act & Assert
        try {
            builder.setAddressType(invalidAddressType);
            Assert.fail('Expected an exception for invalid address type');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('Invalid Address Type'), 'Exception message should indicate invalid address type');
        }
    }

    /**
    * @description  testSetName - Tests the setName method of SM_ContactPointAddressBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetName() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();

        // Act
        builder.setName('Test Address');
        ContactPointAddress result = builder.build();

        // Assert
        Assert.areEqual(result.Name, 'Test Address', 'Name should match');
    }

    /**
    * @description  testSetParentId - Tests the setParentId method of SM_ContactPointAddressBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetParentId() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();

        // Act
        builder.setParentId('001A000001BcDeF');
        ContactPointAddress result = builder.build();

        // Assert
        Assert.areEqual(result.ParentId, '001A000001BcDeF', 'ParentId should match');
    }

    /**
    * @description  testSetOwnerId - Tests the setOwnerId method of SM_ContactPointAddressBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetOwnerId() {
        // Arrange
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();

        // Act
        builder.setOwnerId('005A0000001BcDeFGH');
        ContactPointAddress result = builder.build();

        // Assert
        Assert.areEqual(result.OwnerId, '005A0000001BcDeFGH', 'OwnerId should match');
    }
}