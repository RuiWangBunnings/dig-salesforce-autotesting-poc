/***************************************************************************************************
* Class Name      	: SM_WSHelper
* Description		: Webservice helper class 
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 02-Dec-2020
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         02-Dec-2020		1000				Initial version
* Jasper R. Galapon		22-May-2024		1001				BUNDIG-26468/27490 - Request and download amendments only contract
* Jasper R. Galapon     12-Jul-2024     1002                BUNDIG-31597 - Fix issue in findAndReplaceKeyword
*****************************************************************************************************/
public class SM_WSHelper {
    //returns endpoint definitions (SM_WS_Endpoint_Definition__mdt)
    private static map<String, SM_WS_Endpoint_Definition__mdt> endpointDefs {
        get {
            if (endpointDefs==null) {
                endpointDefs = new Map<String, SM_WS_Endpoint_Definition__mdt>();
                List<SM_WS_Endpoint_Definition__mdt> defs = [SELECT id, Service_Endpoint__c, Method__c, 
                                                                  DeveloperName, Additional_Headers__c
                                                                  FROM SM_WS_Endpoint_Definition__mdt
                                                                  WHERE isActive__c=true];
                for (SM_WS_Endpoint_Definition__mdt def : defs) {
                    endpointDefs.put(def.DeveloperName, def);
                }
            }
            return endpointDefs;
        }
        private set;
    }
    
    //returns the active named credential to use
    private static string ActiveNamedCredential {
        get {
            return SM_Configs__c.getInstance().API_Named_Credential__c;
        }
    }
    
    //given a correct key (DeveloperName), this returns WS endpoint definition (SM_WS_Endpoint_Definition__mdt)
    private static SM_WS_Endpoint_Definition__mdt getSeviceEndpointDef(String key) {
        SM_WS_Endpoint_Definition__mdt retVal = null;        
        retVal = endpointDefs.containsKey(key) ? endpointDefs.get(key) : new SM_WS_Endpoint_Definition__mdt( Method__c = 'GET');
        return retVal;
    } 
    
    //util to find and replace string within a string
    private static string findAndReplaceKeyword(Map<String, String> keyValMap, String target) {
        System.debug(LoggingLevel.FINEST, '***keyValMap: ' + keyValMap);        
        System.debug(LoggingLevel.FINEST, '***keyValMap.size(): ' + keyValMap.size());
        
        if (string.isBlank(target)) return '';
        if (keyValMap == null || keyValMap.size()==0) return target;
        String temp = target;
        
        for (String key : keyValMap.keySet()) {
            // BUNDIG-26468/27490 - Modified to handle optional effective date for amendment download
            //if (!String.isblank(keyValMap.get(key))) temp = temp.replace(key, keyValMap.get(key));
            System.debug(LoggingLevel.FINEST, '***key: ' + key + ' / keyValMap : ' + keyValMap.get(key));
            if (key == '{{EFF_DATE}}' && keyValMap.get(key) == '') {
                target = target.replace('EffectiveDate={{EFF_DATE}}&','');
                temp = temp.remove(key);
            } else {
                if (keyValMap.get(key) != null) {
                	temp = temp.replace(key, keyValMap.get(key));
                }
            }
        }
        return temp;        
    }    
    
    //util to parse JSON text
    public static Map<String, Object> parseJSON(String data) {
        Map<String, Object> o;
        
        try {
            o = (Map<String,Object>) JSON.deserializeUntyped(data);
        } catch (Exception ex) {
            o = new Map<String, Object>();
        }
        
        return o;
    }        
    
    //using endpoint key (DevName) and keyval map, it returns a relative endpoint with merged values
    public static String getMergedEndpoint(String endpointKey, Map<String,String> keyVals) {
        SM_WS_Endpoint_Definition__mdt epdef = endpointDefs.containsKey(endpointKey) ? endpointDefs.get(endpointKey) : new SM_WS_Endpoint_Definition__mdt();
        return getMergedEndpoint(epdef, keyvals);
    }
    
    //using endpointdef and keyval map, it returns a relative endpoint with merged values
    public static string getMergedEndpoint(SM_WS_Endpoint_Definition__mdt epdef, Map<String,String> keyVals) {        
        return String.isblank(epdef.Service_Endpoint__c) ? '' : findAndReplaceKeyword(keyvals, epdef.Service_Endpoint__c);
    }
    
    //using endpoint key (DevName) and keyval map, it returns http request object with all the parameters already set
    //based on endpoint definition
    public static HttpRequest buildHttpRequestFromWSDef(String endpointKey, Map<String,String> keyVals) {
        String endpoint;
        HttpRequest req = new HttpRequest();
        SM_WS_Endpoint_Definition__mdt epdef = getSeviceEndpointDef(endpointKey);
        if (epdef!=null) {
            Map<String, Object> headers = parseJSON(epdef.Additional_Headers__c);
            if (headers.size()==0) headers = parseJSON('{' + epdef.Additional_Headers__c + '}');
            endpoint = getMergedEndpoint(epdef, keyVals);
            
            // BUNDIG-26468/27490 - EFF DATE is optional, need to removed it from the Service Endpoint
            if (!Test.isRunningTest()) {
                if (keyVals.get('{{EFF_DATE}}') == '') {
                    endpoint = endpoint.replace('EffectiveDate=&', '');
                }
            }
 			System.debug(LoggingLevel.FINEST, '***endpoint: ' + endpoint);
            
            req.setEndpoint('callout:' + ActiveNamedCredential + '/' + endpoint);
            req.setMethod(epdef.Method__c);        
            req.setTimeout(120000);
            for (String key : headers.keySet()) {
                req.setHeader(key, String.valueOf(headers.get(key)));
            }
        }
        return req;
    }
}