/*******************************************************************************************************
* Class Name      	: SM_PersonBuilder_Test
* @description		: Test class for SM_PersonBuilder
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_PersonBuilder_Test {

    /**
    * @description  Test method for setSalutation
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSalutation() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setSalutation('Mr.');
        Account account = builder.build();
        Assert.areEqual('Mr.', account.Salutation, 'Salutation should be set correctly.');
    }

    /**
    * @description  Test method for setFirstName
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetFirstName() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setFirstName('John');
        Account account = builder.build();
        Assert.areEqual('John', account.FirstName, 'FirstName should be set correctly.');
    }

    /**
    * @description  Test method for setLastName
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetLastName() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setLastName('Doe');
        Account account = builder.build();
        Assert.areEqual('Doe', account.LastName, 'LastName should be set correctly.');
    }

    /**
    * @description  Test method for setAccountOwner
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetAccountOwner() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setAccountOwner('0059200000LUtz8AAD');
        Account account = builder.build();
        Assert.areEqual('0059200000LUtz8AAD', account.OwnerId, 'OwnerId should be set correctly.');
    }

    /**
    * @description  Test method for setEmail
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetEmail() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setEmail('test@example.com');
        Account account = builder.build();
        Assert.areEqual('test@example.com', account.PersonEmail, 'Email should be set correctly.');
    }

    /**
    * @description  Test method for setPersonMobilePhone
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetPersonMobilePhone() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setPersonMobilePhone('1234567890');
        Account account = builder.build();
        Assert.areEqual('1234567890', account.PersonMobilePhone, 'MobilePhone should be set correctly.');
    }

    /**
    * @description  Test method for setPersonOtherPhone
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetPersonOtherPhone() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setPersonOtherPhone('1234567890');
        Account account = builder.build();
        Assert.areEqual('1234567890', account.PersonOtherPhone, 'MobilePhone should be set correctly.');
    }
    

    /**
     * @description testSetPowerPassAccountNumber Test method for SetPowerPassAccountNumber
     * @author Juan M. Cutrera
     */
    @isTest
    static void testSetPowerPassAccountNumber() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setPowerPassAccountNumber('1234567890');
        Account account = builder.build();
        Assert.areEqual('1234567890', account.Power_Pass_Account_Number__c, 'PowerPassAccountNumber should be set correctly.');
    }



    /**
     * @description testSetDescription Test Method for setDescription
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testSetDescription(){
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setDescription('Test description');
        Account account = builder.build();
        Assert.areEqual('Test description', account.Description__c, 'Description should be set correctly.');
    }

    /**
     * @description testSetAccountState
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testSetAccountState(){
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setAccountState('VIC');
        Account account = builder.build();
        Assert.areEqual('VIC', account.Account_State__c, 'Account_State__c should be set correctly.');
    }

    @isTest 
    static void testSetAccountStateException(){
        SM_PersonBuilder builder = new SM_PersonBuilder();
        try{
            builder.setAccountState('InvalidState');
            Account account = builder.build();
            Assert.fail('Exception should be thrown');
        }catch(Exception e){
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Exception should be thrown');
        }

    }

    /**
    * @description  Test method for setBillingAddress
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetBillingAddress() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setBillingAddress('123 Main St', 'City', 'State', '12345', 'Country');
        Account account = builder.build();
        Assert.areEqual('123 Main St', account.BillingStreet, 'BillingStreet should be set correctly.');
        Assert.areEqual('City', account.BillingCity, 'BillingCity should be set correctly.');
        Assert.areEqual('State', account.BillingState, 'BillingState should be set correctly.');
        Assert.areEqual('12345', account.BillingPostalCode, 'BillingPostalCode should be set correctly.');
        Assert.areEqual('Country', account.BillingCountry, 'BillingCountry should be set correctly.');
    }

    /**
    * @description  Test method for setPersonMailingAddress
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetMailingAddress() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setMailingAddress('123 Main St', 'City', 'State', '12345', 'Country');
        Account account = builder.build();
        Assert.areEqual('123 Main St', account.PersonMailingStreet, 'PersonMailingStreet should be set correctly.');
        Assert.areEqual('City', account.PersonMailingCity, 'PersonMailingCity should be set correctly.');
        Assert.areEqual('State', account.PersonMailingState, 'PersonMailingState should be set correctly.');
        Assert.areEqual('12345', account.PersonMailingPostalCode, 'PersonMailingPostalCode should be set correctly.');
        Assert.areEqual('Country', account.PersonMailingCountry, 'PersonMailingCountry should be set correctly.');
    }

    /**
    * @description  Test method for setSourceSystem
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSourceSystem() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setSourceSystem('CRM');
        Account account = builder.build();
        Assert.areEqual('CRM', account.SourceSystem__c, 'SourceSystem should be set correctly.');
    }

    /**
    * @description  Test method for setSourceSystemModule
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSourceSystemModule() {
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setSourceSystemModule('Module1');
        Account account = builder.build();
        Assert.areEqual('Module1', account.SourceSystemModule__c, 'SourceSystemModule should be set correctly.');
    }

    /**
     * @description testSetPersonIndividual 
     * @author Juan M. Cutrera
     */
    @IsTest
    static void testSetPersonIndividual(){
        SM_PersonBuilder builder = new SM_PersonBuilder();
        builder.setPersonIndividual('0PK920000019YJdGAM');
        Account account = builder.build();
        Assert.areEqual('0PK920000019YJdGAM', account.PersonIndividualId, 'IndividualId should be set correctly.');
    }



}