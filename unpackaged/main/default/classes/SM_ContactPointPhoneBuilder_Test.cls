/*******************************************************************************************************
* Class Name      	: SM_ContactPointPhoneBuilder_Test
* @description		: Test class for SM_ContactPointPhoneBuilder 
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
@IsTest
private class SM_ContactPointPhoneBuilder_Test {

    /**
    * @description  testSetParentId - Tests the setParentId method of SM_ContactPointPhoneBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetParentId() {
        // Arrange
        SM_ContactPointPhoneBuilder builder = new SM_ContactPointPhoneBuilder();

        // Act
        builder.setParentId('001A000001BcDeF');
        ContactPointPhone result = builder.build();

        // Assert
        System.assertEquals('001A000001BcDeF', result.ParentId, 'ParentId should match');
    }

    /**
    * @description  testSetPhoneNumber - Tests the setTelephoneNumber method of SM_ContactPointPhoneBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetPhoneNumber() {
        // Arrange
        SM_ContactPointPhoneBuilder builder = new SM_ContactPointPhoneBuilder();

        // Act
        builder.setTelephoneNumber('1234567890');
        ContactPointPhone result = builder.build();

        // Assert
        System.assertEquals('1234567890', result.telephoneNumber, 'PhoneNumber should match');
    }

    /**
    * @description  testSetPhoneType - Tests the setPhoneType method of SM_ContactPointPhoneBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetPhoneType() {
        // Arrange
        SM_ContactPointPhoneBuilder builder = new SM_ContactPointPhoneBuilder();

        // Act
        builder.setPhoneType('Mobile');
        ContactPointPhone result = builder.build();

        // Assert
        System.assertEquals('Mobile', result.PhoneType, 'PhoneType should match');
    }
}