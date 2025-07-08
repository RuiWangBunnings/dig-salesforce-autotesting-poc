/***************************************************************************************************
* Class Name      	: SM_ClientCredProvider_Test
* Description		: Apex test class to cover for SM_ClientCredProvider test coverage
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 03-Mar-2022
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         03-Mar-2022		1000				Initial version
*****************************************************************************************************/
@istest
private class SM_ClientCredProvider_Test {
    class AuthCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) { 
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String json = '{"token_type":"test","access_token":"random101"}';
            response.setBody(json);
            response.setStatusCode(200);
            return response; 
        }
    }
    
	@istest
    static void testMethod1() {        
        Map<String, String> configs = new Map<String, String>();
        configs.put('Callback_URL__c','nothing');
        configs.put('Additional_Headers__c','{"content-Type":"json/application"}');
        configs.put('Additional_Parameters__c','{"nothing":"hill"}');
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());
        SM_ClientCredProvider ap = new SM_ClientCredProvider();
        Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(new Map<String,String>(),'',new Map<String,String>());
        ap.getCustomMetadataType();
        ap.initiate(configs, '');
        ap.getUserInfo(configs, null);
        Auth.AuthProviderTokenResponse cbResult = ap.handleCallback(configs, cbState);
        Auth.OAuthRefreshResult refreshResult = ap.refresh(configs, '');      
  
        //System.assertEquals('random101', cbResult.oauthToken);
        //System.assertEquals('random101', refreshResult.accessToken);
    }
}