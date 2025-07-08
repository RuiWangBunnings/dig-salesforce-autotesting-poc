/*******************************************************************************************************
* Class Name      	: SM_WebServiceResponses_Test
* @description		: Test class - Test class for Web Service Responses
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 21/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          21/03/2025		1000				Initial Version
******************************************************************************************************/
@isTest
public class Consent_ConsentManagerPayload_Test {

    /**
    * @description  entityTest - Test for the Entity class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void entityTest() {
        Consent_ConsentManagerPayload.Entity entity = new Consent_ConsentManagerPayload.Entity();
        entity.countryCode = 'AU';
        entity.consent = new Consent_ConsentManagerPayload.Consent();
        entity.person = new Consent_ConsentManagerPayload.Person();
        entity.capture = new Consent_ConsentManagerPayload.Capture();

        Assert.areEqual('AU', entity.getCountryCode());
        Assert.isNotNull(entity.getConsent());
        Assert.isNotNull(entity.getPerson());
        Assert.isNotNull(entity.getCapture());
    }

    /**
    * @description  addressTest - Test for the Address class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void addressTest() {
        Consent_ConsentManagerPayload.Address address = new Consent_ConsentManagerPayload.Address();
        address.lotNumber = '5';
        address.streetNumber = '13';
        address.streetName = 'Sample';
        address.streetType = 'Street';
        address.suburb = 'Suburb';
        address.locality = 'Locality';
        address.postCode = '3030';
        address.stateCode = 'VIC';
        address.countryCode = 'Australia';

        Assert.areEqual('5', address.getLotNumber());
        Assert.areEqual('13', address.getStreetNumber());
        Assert.areEqual('Sample', address.getStreetName());
        Assert.areEqual('Street', address.getStreetType());
        Assert.areEqual('Suburb', address.getSuburb());
        Assert.areEqual('Locality', address.getLocality());
        Assert.areEqual('3030', address.getPostCode());
        Assert.areEqual('VIC', address.getStateCode());
        Assert.areEqual('Australia', address.getCountryCode());
        Assert.areEqual('5 13 Sample Street', address.getStreetAddress());
    }

    /**
    * @description  phoneTest - Test for the Phone class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void phoneTest() {
        Consent_ConsentManagerPayload.Phone phone = new Consent_ConsentManagerPayload.Phone();
        phone.phoneNumber = '0451123987';
        Consent_ConsentManagerPayload.Phone phone2 = new Consent_ConsentManagerPayload.Phone();
        phone2.phoneNumber = '61451123987';
        Consent_ConsentManagerPayload.Phone notMobile = new Consent_ConsentManagerPayload.Phone();
        notMobile.phoneNumber = '80641234';

        Assert.isTrue(phone.isMobile(), 'Phone should be mobile');
        Assert.isTrue(phone2.isMobile(), 'Phone should be mobile');
        Assert.isFalse(notMobile.isMobile(), 'Phone should be mobile');
    }

    /**
     * @description testSetPhoneNumber - Test for the setPhoneNumber method
     * @author Juan M. Cutrera
     */
    @isTest
    static void testSetPhoneNumber(){
        Consent_ConsentManagerPayload.Phone phone = new Consent_ConsentManagerPayload.Phone();
        phone.setPhoneNumber(null);
        Assert.isNull(phone.getPhoneNumber(), 'There should not be a phone number');

    }

    /**
    * @description  contactPointTest - Test for the ContactPoint class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void contactPointTest() {
        Consent_ConsentManagerPayload.ContactPoint contactPoint = new Consent_ConsentManagerPayload.ContactPoint();
        contactPoint.type = 'Phone';
        contactPoint.usage = 'Work';
        contactPoint.email = 'maryj@gmail.com';
        contactPoint.phone = new Consent_ConsentManagerPayload.Phone();
        contactPoint.phone.phoneNumber = '03220202';
        contactPoint.freeFormAddress = '123 Freeform St';
        contactPoint.address = new Consent_ConsentManagerPayload.Address();
        contactPoint.address.lotNumber = '5';

        Assert.areEqual('Phone', contactPoint.getType());
        Assert.areEqual('Work', contactPoint.getUsage());
        Assert.areEqual('maryj@gmail.com', contactPoint.getEmail());
        Assert.isNotNull(contactPoint.getPhone());
        Assert.areEqual('03220202', contactPoint.getPhone().getPhoneNumber());
        Assert.areEqual('123 Freeform St', contactPoint.getFreeFormAddress());
        Assert.isNotNull(contactPoint.getAddress());
        Assert.areEqual('5', contactPoint.getAddress().getLotNumber());
    }

    /**
    * @description  myAccountTest - Test for the MyAccount class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void myAccountTest() {
        Consent_ConsentManagerPayload.MyAccount account = new Consent_ConsentManagerPayload.MyAccount();
        account.accountNumber = '123456';
        account.card = new Consent_ConsentManagerPayload.Card();
        account.card.cardSequenceNumber = 1;
        account.card.cardHolderName = 'Mary Smith';
        account.user = new Consent_ConsentManagerPayload.MyUser();
        account.user.id = 's';
        account.user.idp = 'x';
        account.user.reference = 'x';

        Assert.areEqual('123456', account.getAccountNumber());
        Assert.isNotNull(account.getCard());
        Assert.areEqual(1, account.getCard().getCardSequenceNumber());
        Assert.areEqual('Mary Smith', account.getCard().getCardHolderName());
        Assert.isNotNull(account.getUser());
        Assert.areEqual('s', account.getUser().getId());
        Assert.areEqual('x', account.getUser().getIdp());
        Assert.areEqual('x', account.getUser().getReference());
    }

    /**
    * @description  teamTest - Test for the Team class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void teamTest() {
        Consent_ConsentManagerPayload.Team team = new Consent_ConsentManagerPayload.Team();
        team.teamMemberNumber = '1234566';
        team.cardNumber = '1';
        team.isPrimary = true;

        Assert.areEqual('1234566', team.getTeamMemberNumber());
        Assert.areEqual('1', team.getCardNumber());
        Assert.isTrue(team.isPrimary());
    }

    /**
    * @description  captureTest - Test for the Capture class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void captureTest() {
        Consent_ConsentManagerPayload.Capture capture = new Consent_ConsentManagerPayload.Capture();
        capture.captureDateTime = (DateTime)JSON.deserialize('"2023-11-01T07:12:50Z"', DateTime.class);
        capture.engagementChannel = 'InStore';
        capture.source = 'COS';
        capture.sourceModule = 'HireShop';
        capture.sourceReference = 'X12345';
        capture.locationCode = '2010';
        capture.identifier = '12345';

        Assert.isNotNull(capture.getCaptureDateTime());
        Assert.areEqual('InStore', capture.getEngagementChannel());
        Assert.areEqual('COS', capture.getSource());
        Assert.areEqual('HireShop', capture.getSourceModule());
        Assert.areEqual('X12345', capture.getSourceReference());
        Assert.areEqual('2010', capture.getLocationCode());
        Assert.areEqual('12345', capture.getIdentifier());
    }

    /**
    * @description  consentTest - Test for the Consent class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void consentTest() {
        Consent_ConsentManagerPayload.Consent consent = new Consent_ConsentManagerPayload.Consent();
        consent.dataUsePurpose = new Consent_ConsentManagerPayload.DataUsePurpose();
        consent.effectivePeriod = new Consent_ConsentManagerPayload.EffectivePeriod();
        consent.consentStatus = 'Seen';

        Assert.isNotNull(consent.getDataUsePurpose());
        Assert.isNotNull(consent.getEffectivePeriod());
        Assert.areEqual('Seen', consent.getConsentStatus());
    }

    /**
    * @description  effectivePeriodTest - Test for the EffectivePeriod class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void effectivePeriodTest() {
        Consent_ConsentManagerPayload.EffectivePeriod effectivePeriod = new Consent_ConsentManagerPayload.EffectivePeriod();
        effectivePeriod.startDateTime = (DateTime)JSON.deserialize('"2023-11-01T07:12:50Z"', DateTime.class);
        effectivePeriod.endDateTime = (DateTime)JSON.deserialize('"2023-12-01T07:12:50Z"', DateTime.class);

        Assert.isNotNull(effectivePeriod.getStartDateTime());
        Assert.isNotNull(effectivePeriod.getEndDateTime());
    }

    /**
    * @description  personTest - Test for the Person class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void personTest() {
        // Arrange
        Consent_ConsentManagerPayload.Person person = new Consent_ConsentManagerPayload.Person();
        person.name = 'Mary Smith';
        person.firstName = 'Mary';
        person.lastName = 'Smith';
    
        // Create phone contact point
        Consent_ConsentManagerPayload.ContactPoint phoneContact = new Consent_ConsentManagerPayload.ContactPoint();
        phoneContact.type = 'Phone';
        phoneContact.usage = 'Mobile';
        Consent_ConsentManagerPayload.Phone phone = new Consent_ConsentManagerPayload.Phone();
        phone.phoneNumber = '0451123987';
        phoneContact.phone = phone;
    
        // Create email contact point
        Consent_ConsentManagerPayload.ContactPoint emailContact = new Consent_ConsentManagerPayload.ContactPoint();
        emailContact.type = 'Email';
        emailContact.usage = 'Personal';
        emailContact.email = 'mary.smith@example.com';
    
        // Create address contact point
        Consent_ConsentManagerPayload.ContactPoint addressContact = new Consent_ConsentManagerPayload.ContactPoint();
        addressContact.type = 'Address';
        addressContact.usage = 'Mailing';
        Consent_ConsentManagerPayload.Address address = new Consent_ConsentManagerPayload.Address();
        address.streetNumber = '13';
        address.streetName = 'Sample';
        address.streetType = 'Street';
        address.suburb = 'Suburb';
        address.postCode = '3030';
        address.stateCode = 'VIC';
        address.countryCode = 'Australia';
        addressContact.address = address;

        Consent_ConsentManagerPayload.ContactPoint otherContact = new Consent_ConsentManagerPayload.ContactPoint();
        otherContact.type = 'Other';
        otherContact.usage = 'Other';

    
        // Add contact points to person
        person.contactPoints = new List<Consent_ConsentManagerPayload.ContactPoint>{phoneContact, emailContact, addressContact,otherContact};
    
        // Add account and team
        person.account = new Consent_ConsentManagerPayload.MyAccount();
        person.team = new Consent_ConsentManagerPayload.Team();
    
        // Act
        Map<String, List<Consent_ConsentManagerPayload.ContactPoint>> contactPointsByType = person.getContactPointsByType();
        Consent_ConsentManagerPayload.ContactPoint retrievedPhoneContact = person.getContactPoint('Phone', 'Mobile');
        Consent_ConsentManagerPayload.ContactPoint retrievedEmailContact = person.getContactPoint('Email', 'Personal');
        Consent_ConsentManagerPayload.ContactPoint retrievedAddressContact = person.getContactPoint('Address');
        Consent_ConsentManagerPayload.ContactPoint retrievedOtherContact = person.getContactPoint('Other');
    
        // Assert
        Assert.areEqual('Mary Smith', person.getFullName());
        Assert.areEqual('Mary', person.getFirstName());
        Assert.areEqual('Smith', person.getLastName());
        Assert.isNotNull(person.getContactPoints());
        Assert.areEqual(4, person.getContactPoints().size());
        Assert.isNotNull(person.getAccount());
        Assert.isNotNull(person.getTeam());
    
        // Assert for getContactPointsByType
        Assert.isNotNull(contactPointsByType, 'ContactPointsByType map should not be null');
        Assert.isTrue(contactPointsByType.containsKey('Phone'), 'ContactPointsByType should contain Phone');
        Assert.isTrue(contactPointsByType.containsKey('Email'), 'ContactPointsByType should contain Email');
        Assert.isTrue(contactPointsByType.containsKey('Address'), 'ContactPointsByType should contain Address');
        Assert.areEqual(1, contactPointsByType.get('Phone').size(), 'Phone contact points count should match');
        Assert.areEqual(1, contactPointsByType.get('Email').size(), 'Email contact points count should match');
        Assert.areEqual(1, contactPointsByType.get('Address').size(), 'Address contact points count should match');
        Assert.areEqual(1, contactPointsByType.get('Other').size(), 'Other contact points count should match');
    
        // Assert for getContactPoint by type and usage
        Assert.isNotNull(retrievedPhoneContact, 'Phone contact point should not be null');
        Assert.areEqual('0451123987', retrievedPhoneContact.getPhone().getPhoneNumber(), 'Phone number should match');
        Assert.isNotNull(retrievedEmailContact, 'Email contact point should not be null');
        Assert.areEqual('mary.smith@example.com', retrievedEmailContact.getEmail(), 'Email should match');
    
        // Assert for getContactPoint by type
        Assert.isNotNull(retrievedAddressContact, 'Address contact point should not be null');
        Assert.areEqual('13', retrievedAddressContact.getAddress().getStreetNumber(), 'Street number should match');
        Assert.areEqual('Sample', retrievedAddressContact.getAddress().getStreetName(), 'Street name should match');
    }

    /**
    * @description  dataUsePurposeTest - Test for the DataUsePurpose class and its getters
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void dataUsePurposeTest() {
        Consent_ConsentManagerPayload.DataUsePurpose dataUsePurpose = new Consent_ConsentManagerPayload.DataUsePurpose();
        dataUsePurpose.code = 'LegalHireShopPolicyEnglish';
        dataUsePurpose.name = 'Legal Hire';
        dataUsePurpose.version = '2023';
        dataUsePurpose.asOfDateTime = (DateTime)JSON.deserialize('"2023-11-01T07:12:50Z"', DateTime.class);

        Assert.areEqual('LegalHireShopPolicyEnglish', dataUsePurpose.getCode());
        Assert.areEqual('Legal Hire', dataUsePurpose.getName());
        Assert.areEqual('2023', dataUsePurpose.getVersion());
        Assert.isNotNull(dataUsePurpose.getAsOfDateTime());
    }

    /**
    * @description  parseTest - Test for the parse method in Consent_ConsentManagerPayload class
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void parseTest() {
        String jsonString = TestDataFactory.createConsentPayloadJSON();
        Consent_ConsentManagerPayload payload = Consent_ConsentManagerPayload.parse(jsonString);

        Assert.isNotNull(payload);
        Assert.isNotNull(payload.getEntity());
        Assert.areEqual('AU', payload.getEntity().getCountryCode());
    }


    
}