/***************************************************************************************************
* Class Name      	: SM_WSHelper_Test
* Description		: Test class for SM_WSHelper class
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 11-Jan-2021
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         02-Dec-2020		1000				Initial version
*****************************************************************************************************/
@isTest
private class SM_WSHelper_Test {
	@isTest
    static void test01() {
        Map<String,String> params = new Map<String,String>();
        params.put('{{COUNTRY}}', 'AU');
        params.put('{{ACCT_NBR}}', '23094832');
        String endpoint = SM_WSHelper.getMergedEndpoint('Test_Class_Endpoint',params);
        HttpRequest req = SM_WSHelper.buildHttpRequestFromWSDef('Test_Class_Endpoint',params);  
        System.assertEquals(false, endpoint.contains('{{COUNTRY}}'));
        System.assertEquals(false, endpoint.contains('{{ACCT_NBR}}'));
        System.assertEquals(false, req.getEndpoint().contains('{{COUNTRY}}'));
        System.assertEquals(false, req.getEndpoint().contains('{{ACCT_NBR}}'));        
    }
}