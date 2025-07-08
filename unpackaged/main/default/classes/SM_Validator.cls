/*******************************************************************************************************
* Class Name      	: SM_Validator
* Description		: Service layer, containing all complex validation rules used across the project
* Author          	: Simplus - Yi Zhang
* Created On      	: 17/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              17/07/2020		1000				Initial version
******************************************************************************************************/
public with sharing class SM_Validator {
    public static final List<Integer> VALID_GST_NUMBER_LENGTH = new List<Integer>{8, 9};
    public static final List<Integer> PRIMARY_WEIGHTS = new List<Integer>{3, 2, 7, 6, 5, 4, 3, 2};
    public static final List<Integer> SECONDARY_WEIGHTS = new List<Integer>{7, 4, 3, 2, 5, 2, 7, 6};

    /**
    * @description 
    * @author Yi Zhang | 17/07/2020 
    * @param gstNumberString  It is expected that the number (string) is whitespace-free
    * @return Boolean 
    **/
    public static Boolean isValidNZGSTNumber(String gstNumberString) {

        try {
            Integer gstNumber = Integer.valueOf(gstNumberString);

            /**
            Check digit validation

            The following steps are to be performed:
            1.   Check the valid range
            If the IRD number is < 10-000-000 or > 150-000-000 then the number is invalid. This step ensures that the IRD
            number is in the already issued range, or is in the range expected to be issued in the next 10 years.

            2.  Form the eight digit base number
            Remove the trailing check digit.
            If the resulting number is seven digits long, pad to eight digits by adding a leading zero.

             3. Calculate the check digit
            To each of the base number’s eight digits a weight factor is assigned. From left to right these are:
            3, 2, 7, 6, 5, 4, 3, 2.
            Sum together the products of the weight factors and their associated digits.
            Divide the sum by 11. If the remainder is 0 then the calculated check digit is 0.
            If the remainder is not 0 then subtract the remainder from 11, giving the calculated check digit.
            If the calculated check digit is in the range 0 to 9, go to step 5.
            If the calculated check digit is 10, continue with step 4.

            4.  Re-calculate the check digit
            To each of the base number’s eight digits a secondary weight factor is assigned. From left to right these are:
            7, 4, 3, 2, 5, 2, 7, 6.
            Sum together the products of the weight factors and their associated digits.
            Divide the sum by 11. If the remainder is 0 then the calculated check digit is 0.
            If the remainder is not 0 then subtract the remainder from 11, giving the 00 calculated check digit.
            If the calculated check digit is 10, the IRD number is invalid. 

            5.  Compare the check digit :
            Compare the calculated check digit to the last digit of the original IRD number.
            If they match, the IRD number is valid.							
             */

            // Length should be of 8 or 9 digit
            if(VALID_GST_NUMBER_LENGTH.contains(gstNumberString.length()) == false) {
                return false;
            }

            // Tax number should be between 10000000 and 150000000, cannot be 111111111
            if(gstNumber < 10000000 || gstNumber > 150000000 || gstNumber == 111111111) {
                return false;
            }

            // If 8 digits, pad with leading 0
            if(gstNumberString.length() == 8) {
                gstNumberString = '0' + gstNumberString;
            }

            // use primary weight factor
            Integer sum = 0;
            for(Integer i = 0; i < PRIMARY_WEIGHTS.size(); i ++) {
                sum+= Integer.valueOf(gstNumberString.substring(i, i + 1)) * PRIMARY_WEIGHTS[i];
            }
            Integer remainder = Math.mod(sum, 11);
            Integer calculatedCheckDigit = remainder == 0 ? remainder : 11 - remainder;

            // use secondary weight factor if calculated check digit is 10
            if(calculatedCheckDigit == 10) {
                sum = 0;
                for(Integer i = 0; i < SECONDARY_WEIGHTS.size(); i ++) {
                    sum+= Integer.valueOf(gstNumberString.substring(i, i + 1)) * SECONDARY_WEIGHTS[i];
                }
                remainder = Math.mod(sum, 11);
                calculatedCheckDigit = remainder == 0 ? remainder : 11 - remainder;
            }

            Integer checkDigit = Integer.valueOf(gstNumberString.substring(8)); // last digit
            return checkDigit == calculatedCheckDigit;

            // System.debug(LoggingLevel.DEBUG, 'sum : ' + sum);
            // System.debug(LoggingLevel.DEBUG, 'remainder : ' + remainder);
            // System.debug(LoggingLevel.DEBUG, 'Check Digit : ' + checkDigit);
            // System.debug(LoggingLevel.DEBUG, '9th Digit : ' + Integer.valueOf(gstNumberString.substring(8)));

        } catch(Exception e) {
            return false;
        }
    }
}