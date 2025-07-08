/*******************************************************************************************************
* Class Name      	: SM_AuthorizationFormConsentBuilder_Test
* @description		: Test class for SM_AuthorizationFormConsentBuilder
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@IsTest
private class SM_AuthorizationFormConsentBuilder_Test {

    /**
    * @description  testSetName - Tests the setName method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetName() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setName('Test Authorization');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Test Authorization', result.Name, 'Name should match');
    }

    /**
    * @description  testSetAuthorizationFormTextId - Tests the setAuthorizationFormTextId method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetAuthorizationFormTextId() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setAuthorizationFormTextId('0cN920000001IVxEAM');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('0cN920000001IVxEAM', result.AuthorizationFormTextId, 'AuthorizationFormTextId should match');
    }

    /**
    * @description  testSetConsentGiverIndividualOnly - Tests the setConsentGiverIndividualOnly method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetConsentGiverIndividualOnly() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setConsentGiverIndividualOnly('0PK920000016ZlhGAE');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('0PK920000016ZlhGAE', result.Consent_Consent_Giver_Individual_Only__c, 'ConsentGiverIndividualOnly should match');
    }

    /**
    * @description  testSetConsentCaptureDateTime - Tests the setConsentCaptureDateTime method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetConsentCaptureDateTime() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();
        DateTime now = DateTime.now();

        // Act
        builder.setConsentCaptureDateTime(now);
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals(now, result.ConsentCapturedDateTime, 'ConsentCapturedDateTime should match');
    }

    /**
    * @description  testSetConsentCapturedSource - Tests the setConsentCapturedSource method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetConsentCapturedSource() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setConsentCapturedSource('Web');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Web', result.ConsentCapturedSource, 'ConsentCapturedSource should match');
    }

    /**
    * @description  testSetCountry - Tests the setCountry method of SM_AuthorizationFormConsentBuilder with a valid country value
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetCountry_Valid() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setCountry('AU');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('AU', result.Country__c, 'Country should match');
    }

    /**
    * @description  testSetCountry_Invalid - Tests the setCountry method of SM_AuthorizationFormConsentBuilder with an invalid country value
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetCountry_Invalid() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act & Assert
        try {
            builder.setCountry('InvalidCountry');
            System.assert(false, 'Expected an exception for invalid country');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid Country'), 'Exception message should indicate invalid country');
        }
    }

    /**
    * @description  testSetOwnerId - Tests the setOwnerId method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetOwnerId() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();
        String ownerId = '005A0000001BcDeFGH'; // Replace with a valid OwnerId from your org

        // Act
        builder.setOwnerId(ownerId);
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals(ownerId, result.OwnerId, 'OwnerId should match the value set');
    }

    /**
    * @description  testSetConsentCapturedSourceType - Tests the setConsentCapturedSourceType method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetConsentCapturedSourceType() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setConsentCapturedSourceType('Online');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Online', result.ConsentCapturedSourceType, 'ConsentCapturedSourceType should match');
    }

    /**
    * @description  testSetCreatedBySourceSystemModule - Tests the setCreatedBySourceSystemModule method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetCreatedBySourceSystemModule() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setCreatedBySourceSystemModule('Module1');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Module1', result.SourceSystemModule__c, 'SourceSystemModule__c should match');
    }

    /**
    * @description  testSetCreatedBySourceReferenceId - Tests the setCreatedBySourceReferenceId method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetCreatedBySourceReferenceId() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setCreatedBySourceReferenceId('REF123');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('REF123', result.SourceReferenceId__c, 'SourceReferenceId__c should match');
    }

    /**
    * @description  testSetSourceCustomerId - Tests the setSourceCustomerId method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetSourceCustomerId() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setSourceCustomerId('CUST001');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('CUST001', result.SourceCustomerId__c, 'SourceCustomerId__c should match');
    }

    /**
    * @description  testSetStoreLocationCode - Tests the setStoreLocationCode method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetStoreLocationCode() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setStoreLocationCode('LOC001');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('LOC001', result.Location__c, 'Location__c should match');
    }

    /**
    * @description  testSetStatus - Tests the setStatus method of SM_AuthorizationFormConsentBuilder with valid and invalid values
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetStatus() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setStatus('Seen');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Seen', result.Status, 'Status should match');

        // Act & Assert for invalid status
        try {
            builder.setStatus('InvalidStatus');
            System.assert(false, 'Expected an exception for invalid status');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid Status'), 'Exception message should indicate invalid status');
        }
    }

    /**
    * @description  testSetPowerPassCardNumber - Tests the setPowerPassCardNumber method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetPowerPassCardNumber() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setPowerPassCardNumber('CARD123');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('CARD123', result.Pp_Card_Number__c, 'Pp_Card_Number__c should match');
    }

    /**
    * @description  testSetPowerPassAccountNumber - Tests the setPowerPassAccountNumber method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetPowerPassAccountNumber() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setPowerPassAccountNumber('ACC123');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('ACC123', result.Pp_Account_Number__c, 'Pp_Account_Number__c should match');
    }

    /**
    * @description  testSetTeamMemberCard - Tests the setTeamMemberCard method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetTeamMemberCard() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setTeamMemberCard('TM123');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('TM123', result.Tm_Card_Number__c, 'Tm_Card_Number__c should match');
    }

    /**
    * @description  testSetTeamMemberEmployeeNumber - Tests the setTeamMemberEmployeeNumber method of SM_AuthorizationFormConsentBuilder
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testSetTeamMemberEmployeeNumber() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setTeamMemberEmployeeNumber('EMP123');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('EMP123', result.Tm_Employee_Number__c, 'Tm_Employee_Number__c should match');
    } 

    /**
     * @description testSetMessageId - Tests the setMessageId method of SM_AuthorizationFormConsentBuilder
     * @author Juan M. Cutrera
     * @return   return description
     */
    @isTest
    static void testSetMessageId(){
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();
        builder.setMessageId('123');
        AuthorizationFormConsent result = builder.build();

        System.assertEquals('123', result.Message_Id__c, 'Message_Id__c should match');
    }
    
    /**
     * @description testSetMessageIdExceeds255 - Tests the setMessageId method of SM_AuthorizationFormConsentBuilder when stringExceeds 255
     * @author Juan M. Cutrera
     * @return   return description
     */
    @isTest
    static void testSetMessageIdExceeds255(){
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();
        builder.setMessageId('Loremipsumdolorsitamet,consectetueradipiscingelit.Aeneancommodoligulaegetdolor.Aeneanmassa.Cumsociisnatoquepenatibusetmagnisdisparturientmontes,nasceturridiculusmus.Donecquamfelis,ultriciesnec,pellentesqueeu,pretiumquis,radipiscingelit.Aeneancommodoligulaegetdolor.Aeneanmassa.Cumsociisnatoquepenatibusetmagnisdisparturientmontes,');
        AuthorizationFormConsent result = builder.build();
        
        System.assertEquals(255, result.Message_Id__c.length(), 'Message_Id__c length should be trimmed to 255 character');
    }

    /**
    * @description  testBuild - Tests the build method of SM_AuthorizationFormConsentBuilder to ensure all fields are set correctly
    * @author Juan Cutrera | 08/04/2025
    * @return void
    **/
    @IsTest
    static void testBuild() {
        // Arrange
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();

        // Act
        builder.setName('Test Authorization')
               .setAuthorizationFormTextId('0cN920000001IVxEAM')
               .setConsentCapturedSource('Web')
               .setCountry('AU')
               .setMessageId('LegalHire|2025-04-16T01:54:00Z|COS|HireShop|32DA915CD7B284D9E06340041A0A714A|2010');
        AuthorizationFormConsent result = builder.build();

        // Assert
        System.assertEquals('Test Authorization', result.Name, 'Name should match');
        System.assertEquals('0cN920000001IVxEAM', result.AuthorizationFormTextId, 'AuthorizationFormTextId should match');
        System.assertEquals('Web', result.ConsentCapturedSource, 'ConsentCapturedSource should match');
        System.assertEquals('AU', result.Country__c, 'Country should match');
        System.assertEquals('LegalHire|2025-04-16T01:54:00Z|COS|HireShop|32DA915CD7B284D9E06340041A0A714A|2010', result.Message_Id__c, 'MessageId should match');
    }
}