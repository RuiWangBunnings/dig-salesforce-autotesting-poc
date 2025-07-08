/*******************************************************************************************************
* Class Name      	: SM_StringFormatter_Test
* Description		: Test class for SM_StringFormatter
* Author          	: Simplus - Philip Clark
* Created On      	: 06/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          06/07/2020		1000				Initial version
******************************************************************************************************/
@IsTest
private class SM_StringFormatter_Test {
    
    /**
    *  Method name  :  testABN
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testABN() {
        String abnInput = '12345678910';
        
        Test.startTest();
        
        String abnOutput = SM_StringFormatter.abnFormat(abnInput);
        
        Test.stopTest();
        
        system.assertEquals('12 345 678 910',abnOutput,'ABN not formatted correctly');
    }
    
    /**
    *  Method name  :  testACN
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testACN() {
        String acnInput = '123456789';
        
        Test.startTest();
        
        String acnOutput = SM_StringFormatter.acnFormat(acnInput);
        
        Test.stopTest();
        
        system.assertEquals('123 456 789',acnOutput,'ACN not formatted correctly');
    }
    
    /**
    *  Method name  :  testACN
    *  Description  :  
    *  Author       :  Philip Clark
    **/
    @IsTest
    static void testGST() {
        String gstInput = '123x456 789';
        
        Test.startTest();
        
        String gstOutput = SM_StringFormatter.gstFormat(gstInput);
        
        Test.stopTest();
        
        system.assertEquals('123456789',gstOutput,'GST number not formatted correctly');
    }

}