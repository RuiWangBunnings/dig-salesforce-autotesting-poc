/*******************************************************************************************************
* Class Name      	: SM_ContactPointEmailBuilder_Test
* @description		: Test class for SM_ContactPointEmailBuilder
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
@IsTest
private class SM_ContactPointEmailBuilder_Test {

    /**
    * @description  testSetParentId - Tests the setParentId method of SM_ContactPointEmailBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetParentId() {
        // Arrange
        SM_ContactPointEmailBuilder builder = new SM_ContactPointEmailBuilder();

        // Act
        builder.setParentId('001A000001BcDeF');
        ContactPointEmail result = builder.build();

        // Assert
        System.assertEquals('001A000001BcDeF', result.ParentId, 'ParentId should match');
    }

    /**
    * @description  testSetEmailAddress - Tests the setEmailAddress method of SM_ContactPointEmailBuilder
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testSetEmailAddress() {
        // Arrange
        SM_ContactPointEmailBuilder builder = new SM_ContactPointEmailBuilder();

        // Act
        builder.setEmailAddress('test@example.com');
        ContactPointEmail result = builder.build();

        // Assert
        System.assertEquals('test@example.com', result.EmailAddress, 'EmailAddress should match');
    }

    /**
    * @description  testBuild - Tests the build method of SM_ContactPointEmailBuilder to ensure all fields are set correctly
    * @author Juan Cutrera | 04/04/2025
    **/
    @IsTest
    static void testBuild() {
        // Arrange
        SM_ContactPointEmailBuilder builder = new SM_ContactPointEmailBuilder();

        // Act
        builder.setParentId('001A000001BcDeF')
               .setEmailAddress('test@example.com');
        ContactPointEmail result = builder.build();

        // Assert
        System.assertEquals('001A000001BcDeF', result.ParentId, 'ParentId should match');
        System.assertEquals('test@example.com', result.EmailAddress, 'EmailAddress should match');
    }
}