/*******************************************************************************************************
* Class Name      	: SM_ClientCredProvider
* Description		: This is a custom authentication provider to handle Client Credentials Grant Type
					  This is written or we have to have this because Salesforce doesn't 
					  support Client Credentials grant out of the box
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 02-Dec-2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Aldrin Rasdas         02-Dec-2020		1000				Initial version
* Bunnings Dev 			31/03/2022      1001                SFSUP-289 - Log COS API Callout details
******************************************************************************************************/
global class SM_ClientCredProvider extends Auth.AuthProviderPluginClass {
    private String authProvider = 'SM_ClientCredProvider';     
    private String customMetadataTypeApiName = 'SM_ClientCredProvider__mdt'; 
    
    private String tokenType = 'access';
    
    public String getCustomMetadataType() {
        return customMetadataTypeApiName;
    } 
    
    public PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate) {
        return new PageReference(authProviderConfiguration.get('Callback_URL__c') +'?state=' +stateToPropagate);
    } 
    
    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state ) {
        String namedCred = authProviderConfiguration.get('Auth_Provider_Named_Credential__c');
        return new Auth.AuthProviderTokenResponse(authProvider, 
                                                  retrieveToken(namedCred), 
                                                  tokenType, 
                                                  state.queryParameters.get('state'));        
    } 
    
    public override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken) {
        String namedCred = authProviderConfiguration.get('Auth_Provider_Named_Credential__c');
        return new Auth.OAuthRefreshResult(retrieveToken(namedCred), refreshToken);
    }
    
    public Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        return new Auth.UserData(null, null, null, null, null, null, '', null, authProvider, null, new Map<String,String>()); 
    }
    
    private String retrieveToken(String namedCredential) {
        String token = null;
        String body = null;
        
        HttpRequest req = new HttpRequest();
        HTTPResponse res = new HttpResponse();

        req.setEndpoint('callout:'+namedCredential);
        req.setHeader('Content-Type','application/x-www-form-urlencoded;charset=UTF-8');        
        req.setBody('grant_type=client_credentials&client_id={!$Credential.Username}&client_secret={!$Credential.Password}');        
        req.setMethod('POST'); 
        
        try {
            res = new Http().send(req); 
            if (res.getStatusCode() == 200) {
                token = getAccessToken(res);

                publishEventLog(req, res);
            } else {                
                publishEventLog(req, res);

                throw new Auth.AuthProviderPluginException('HTTP' + res.getStatusCode() + '-' + res.getStatus());
            }
        } catch (Exception e) {
            publishEventLog(req, res);
        }
        
        return token;
    }
    
    private String getAccessToken(HTTPResponse res) {
        
        String responseBody = res.getBody();
        
        Map<String,String> parsedResponse = (Map<String,String>) System.JSON.deserialize(responseBody, Map<String,String>.class);

        return parsedResponse.get('access_token');
    }

    private static void publishEventLog(HttpRequest request, HttpResponse response) {
        List<Application_Log__e> appLog = new List<Application_Log__e>();
        
        appLog.add(new Application_Log__e(Source__c = 'SM_ClientCredProvider.retrieveToken', Type__c = 'Outbound message', Method__c = request.getMethod(), 
            Function_Name__c = request.getMethod(), Endpoint_URL__c = request.getEndpoint(), Body__c = request.getBody()));

        // Publish event
        List<Database.SaveResult> results = Eventbus.publish(appLog);
        for (Database.SaveResult r : results) {
            if (r.isSuccess()) {
                System.debug('***Successfully published event');
            } else {
                for (Database.Error err : r.getErrors()) {
                    System.debug('***Error publishing: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
        
    }
}