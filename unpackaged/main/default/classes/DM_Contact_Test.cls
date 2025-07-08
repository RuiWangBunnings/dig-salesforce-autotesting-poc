/*******************************************************************************************************
* Class Name      	: DM_Contact_Test
* Description		: Test class for DM_Contact
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-06-15
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-15		1000				Initial version
* Jasper R. Galapon		2024-04-04		1001				BUNDIG-23006 - Increase test coverage
******************************************************************************************************/
@isTest
public class DM_Contact_Test {
    @isTest
    public static void testGetContacts() {
        
        Test.startTest();
        	System.assertEquals(0, DM_Contact.getContacts('test', 'test').size(), 'no contact created, no contact retrieved');
            System.assertEquals(0, DM_Contact.getContacts(new Set<Id>{null}, new Set<Id>{null}).size(), 'no contact created, no contact retrieved');
        	System.assertEquals(0, DM_Contact.getContactsBasedOnAcctOwner(UserInfo.getUserId()).size());
        Test.stopTest();

    }
}