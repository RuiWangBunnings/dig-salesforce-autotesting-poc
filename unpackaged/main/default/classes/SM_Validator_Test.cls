/*******************************************************************************************************
* Class Name      	: SM_Validator_Test
* Description		: Test class for SM_Validator
* Author          	: Simplus - Yi Zhang
* Created On      	: 19/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              19/07/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_Validator_Test {
    @isTest
    public static void isValidNZGSTNumberTest() {

        Test.startTest();
        // valid numbers
        List<String> validGSTNumbers = new List<String>{
            '115391208',
            '104077595',
            '104499775',
            '47453623',
            '107710280',
            '41519827',
            '120597116',
            '106922470',
            '109995223',
            '15121521',
            '107667857',
            '121273349',
            '107710280',
            '069447554',
            '119010872',
            '116360872',
            '106187721',
            '22000084',
            '119284831',
            '85486395',
            '114348181',
            '91216379',
            '113970606'
        };
        for(String s : validGSTNumbers) {
            System.assertEquals(true, SM_Validator.isValidNZGSTNumber(s), s + ' should be a valid NZ GST Number');
        }

        // invalid numbers
        List<String> invalidGSTNumbers = new List<String>{
            '069123466',
            '16233268',
            '11356241',
            '36522512',
            '106071951',
            '108555387',
            '119152848',
            '157643388',
            '111111111',
            '1040775.31',
            '1104077595'
        };
        for(String s : invalidGSTNumbers) {
            System.assertEquals(false, SM_Validator.isValidNZGSTNumber(s), s + ' should be an invalid NZ GST Number');
        }
        Test.stopTest();
    }
}