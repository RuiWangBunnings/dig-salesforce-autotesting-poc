/*******************************************************************************************************
* Class Name      	: SM_IndividualBuilder_Test
* @description		: Test class for SM_IndividualBuilder
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_IndividualBuilder_Test {

    /**
    * @description  Test method for setFirstName
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetFirstName() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setFirstName('John');
        Individual individual = builder.build();
        System.assertEquals('John', individual.FirstName, 'FirstName should be set correctly.');
    }

    /**
    * @description  Test method for setLastName
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetLastName() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setLastName('Doe');
        Individual individual = builder.build();
        System.assertEquals('Doe', individual.LastName, 'LastName should be set correctly.');
    }

    /**
    * @description  Test method for setAccountOwner
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetAccountOwner() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setAccountOwner('0059200000LUtz8AAD');
        Individual individual = builder.build();
        System.assertEquals('0059200000LUtz8AAD', individual.OwnerId, 'OwnerId should be set correctly.');
    }

    /**
    * @description  Test method for setCountry
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetCountry() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setCountry('AU');
        Individual individual = builder.build();
        System.assertEquals('AU', individual.Country__c, 'Country should be set correctly.');
    }

    /**
    * @description  Test method for setState
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetState() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setState('VIC');
        Individual individual = builder.build();
        System.assertEquals('VIC', individual.State__c, 'State should be set correctly.');
    }

    /**
    * @description  Test method for setSourceSystem
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSourceSystem() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setSourceSystem('COS');
        Individual individual = builder.build();
        System.assertEquals('COS', individual.SourceSystem__c, 'SourceSystem should be set correctly.');
    }

    /**
    * @description  Test method for setSourceSystemModule
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSourceSystemModule() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setSourceSystemModule('HireShop');
        Individual individual = builder.build();
        System.assertEquals('HireShop', individual.SourceSystemModule__c, 'SourceSystemModule should be set correctly.');
    }

    /**
    * @description  Test method for setSourceCustomerId
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testSetSourceCustomerId() {
        SM_IndividualBuilder builder = new SM_IndividualBuilder();
        builder.setSourceCustomerId('CUST12345');
        Individual individual = builder.build();
        System.assertEquals('CUST12345', individual.SourceCustomerId__c, 'SourceCustomerId should be set correctly.');
    }
}