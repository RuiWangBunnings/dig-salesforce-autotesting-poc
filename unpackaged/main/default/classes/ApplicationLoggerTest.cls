/*******************************************************************************************************
* Class Name      	: ApplicationLoggerTest
* Description		: Test class for ApplicationLogger
* Author          	: Simplus - Haider Raza
* Created On      	: 11/04/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           11/04/2020		1000				Initial version
* Simplus MS            17/08/2020      1001                New changes as part of CCRM-6890,6892
* Simplus MS            10/09/2020      1002                New changes as part of CCRM15-196
* Jasper R Galapon		31/10/2023		1003				BUNDIG-21549 - Added test method
* Juan M Cutrera   		16/04/2025		1004				EDP2-20848 - Added test method for callIn
******************************************************************************************************/
@isTest
private class ApplicationLoggerTest {
    static testMethod void forceException() {
        try {
            User userRecord = [SELECT Id FROM User LIMIT 1];
                String userName = userRecord.Name;
        } catch (exception ex) {
            ApplicationLogger.log('ApplicationLoggerTest', null, 'forceException', ex);
        }
        Integer exceptionLogSize = [SELECT COUNT() FROM ApplicationLog__c];
        System.assert(exceptionLogSize > 0);
    }

    static testMethod void obMessage(){
        Test.startTest();
        ApplicationLogger.log('testClass', 'https://ensmjy11ywtxq.x.pipedream.net', 'Hello world', 'POST');
        Test.stopTest();

        System.assert([SELECT Id FROM ApplicationLog__c].size() == 1);
    }
    static testMethod void forceExceptionLogger() {
        try {
            User userRecord = [SELECT Id FROM User LIMIT 1];
                String userName = userRecord.Name;
        } catch (exception ex) {
            ApplicationLogger.logException('ApplicationLoggerTest', null, 'forceException', ex,'7989899');
        }
        Integer exceptionLogSize = [SELECT COUNT() FROM ApplicationLog__c];
        System.assert(exceptionLogSize > 0);
    }
    static testMethod void logObCallout(){
        HttpRequest http = new HttpRequest();
        http.setBody('{"username":"335205","orderToken":"6345656","onHoldFlg":"N"}');
        HttpResponse response;
        Test.startTest();
        try {
            response = (new http()).send(http); 
        } catch(Exception e) {
            ApplicationLogger.logCallout('SM_Opportunity.sendClosedWonOpptyToCOS', http, response, '{"runningUserId":"0051m00000181IGAAY","onHoldFlg":"N","orderToken":"32545345","opptyId":"0061m000002x4T9AAI"}',e);
        
        }
        response = new HttpResponse();
        response.setBody('{calloutSuccess=false, closedWonOpptyStage=Opportunity:{Id=0061m000003VFmrAAG}}');
        ApplicationLogger.logCallout('SM_Opportunity.sendClosedWonOpptyToCOS', http, response, '{"runningUserId":"0051m00000181IGAAY","onHoldFlg":"N","orderToken":"32545345","opptyId":"0061m000002x4T9AAI"}',null);
        Test.stopTest();

        System.assert([SELECT Id FROM ApplicationLog__c].size() > 0);
    }

    static testMethod void asyncLog(){
        
        Test.startTest();
        ApplicationLogger.asyncLog('testFunction', 'sObject', 'sSourceType', 'message', 'typeName', 'stackTraceString');
        Test.stopTest();
        
        System.assert([SELECT Id FROM ApplicationLog__c].size() == 1);
    }

    static testMethod void logCalloutException(){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setBody('{"username":"335205","orderToken":"6345656","onHoldFlg":"N"}');
        HttpResponse response;
        
        Test.startTest();
        try {
            response = (new http()).send(httpReq); 
        } catch(Exception e) {
            ApplicationLogger.logCalloutException('sourceApexMethod', httpReq, response, 'retryParams', 'sObjectName', 'sObjectType', e);
        
        }
        response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"example":"test"}');
        response.setStatusCode(200);
        ApplicationLogger.logCalloutException('sourceApexMethod', httpReq, response, 'retryParams', 'sObjectName', 'sObjectType', null);
        Test.stopTest();

        System.assert([SELECT Id FROM ApplicationLog__c].size() > 0);
    }

    // Commented out, method not being used and not in higher org - Jasper - 2/11/2023
    // static testMethod void logCallOutNoRetry(){
    //     HttpRequest httpReq = new HttpRequest();
    //     httpReq.setBody('{"username":"335205","orderToken":"6345656","onHoldFlg":"N"}');
    //     HttpResponse response;
        
    //     Test.startTest();
    //     try {
    //         response = (new http()).send(httpReq); 
    //     } catch(Exception e) {
    //         ApplicationLogger.logCallOutNoRetry('sourceApexMethod', httpReq, response, e);
        
    //     }
    //     response = new HttpResponse();
    //     response.setHeader('Content-Type', 'application/json');
    //     response.setBody('{"example":"test"}');
    //     response.setStatusCode(200);
    //     ApplicationLogger.logCallOutNoRetry('sourceApexMethod', httpReq, response, null);
    //     Test.stopTest();

    //     System.assert([SELECT Id FROM ApplicationLog__c].size() > 0);
    // }

    private static Map<String, Object> mapFieldsForPricingAssignmentLog(String powerpassNumber, String sourceApexMethod, String calloutType, HttpRequest request, HttpResponse response, Map<Id, Map<String, String>> cplMap, Exception e) {
        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('powerpassNumber', powerpassNumber);
        tempMap.put('sourceApexMethod', sourceApexMethod);
        tempMap.put('calloutType', calloutType);
        tempMap.put('request', request);
        tempMap.put('response', response);
        tempMap.put('mapToSerialize', cplMap);
        tempMap.put('retryParams', cplMap);
        tempMap.put('e', e);

        return tempMap;
    }

    static testMethod void logPricingAssignemntCalloutLog() {
        Map<String,String> wsParams = new Map<String, String>();
            wsParams.put('{{COUNTRY_CODE}}', 'test');
            wsParams.put('{{PRICE_LIST_ID}}', 'test');
            wsParams.put('{{CUST_ID}}', 'test');
            wsParams.put('{{TM_NUMBER}}', 'test');
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        response.setBody('test');
        response.setStatusCode(0);

        List<Map<String, Object>> logObjs = new List<Map<String, Object>>();

        Test.startTest();
        logObjs.add(
                mapFieldsForPricingAssignmentLog(
                    'testCustomerId', 'Test.logPricingAssignemntCalloutLog', 'Test', request, response, new Map<Id, Map<String, String>>{'a0M9D000001EL3e000' => wsParams}, null)
        );
        if(logObjs.size() > 0) {
            List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
            for(Map<String, Object> obj : logObjs) {
                pricingAssignemtLogs.add(
                    ApplicationLogger.createPricingAssignmentCalloutLog(
                        (String) obj.get('powerpassNumber'), 
                        (String) obj.get('sourceApexMethod'), 
                        (String) obj.get('calloutType'), 
                        (HttpRequest) obj.get('request'), 
                        (HttpResponse) obj.get('response'), 
                        JSON.serialize((Map<Id, Map<String, String>>) obj.get('retryParams')), 
                        (Exception) obj.get('e')
                    )
                );
                
                pricingAssignemtLogs.add(
                    ApplicationLogger.createPricingAssignmentCalloutErrorLog(
                        (String) obj.get('powerpassNumber'),
                        (String) obj.get('sourceApexMethod'),
                        (String) obj.get('calloutType'), 
                        (HttpRequest) obj.get('request'),
                        (HttpResponse) obj.get('response'), 
                        JSON.serialize((Map<Id, Map<String, String>>) obj.get('retryParams')), 
                        (Exception) obj.get('e'),
                        null                        
                    )
                );
            }
            pricingAssignemtLogs.add(
                    ApplicationLogger.createPricingAssignmentCalloutLog(
                        'powerpassNumber', 
                        'sourceApexMethod', 
                        'calloutType', 
                        (HttpRequest) logObjs[0].get('request'), 
                        null, 
                        'retryParams', 
                        new OtherException('This is bad')
                    )
                );
            pricingAssignemtLogs.add(
                    ApplicationLogger.createPricingAssignmentCalloutLog(
                        'powerpassNumber', 
                        'sourceApexMethod', 
                        'calloutType', 
                        (HttpRequest) logObjs[0].get('request'), 
                        (HttpResponse) logObjs[0].get('response'), 
                        'retryParams', 
                        new OtherException('This is bad')
                    )
                );
                // ApplicationLogger.createPricingAssignmentCalloutLog(
                //     (String) obj.get('powerpassNumber'), 
                //     (String) obj.get('sourceApexMethod'), 
                //     (String) obj.get('calloutType'), 
                //     (HttpRequest) obj.get('request'), 
                //     (HttpResponse) obj.get('response'), 
                //     JSON.serialize((Map<Id, Map<String, String>>) obj.get('retryParams')), 
                //     (Exception) obj.get('e')
                // )
            ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
        }
        Test.stopTest();
    }
    
    public class OtherException extends Exception {}
    
    static testMethod void testErrorLogging() {        
        Test.startTest();
        	List<ApplicationLogger.errorWrapper> fInput = new List<ApplicationLogger.errorWrapper>();
        	ApplicationLogger.errorWrapper a = new ApplicationLogger.errorWrapper();
            a.sourceName = 'LWC';
        	a.functionName = 'LWC Function';
        	a.errorMessage = 'LWC Error';
        	a.sourceType = 'LWC';
        	a.errorType = 'Exception';
            fInput.add(a);                  	
        	
        	ApplicationLogger.lwcErrorLogging(fInput);
        	ApplicationLogger.flowErrorLogging(fInput);
        Test.stopTest();
    }

    /**
     * @description testLogCallIn - test logging of Inbound Messages like webservices
     * @author Juan M. Cutrera
     */
    @isTest
    static void testLogCallIn() {
        // Step 1: Create mock RestRequest and RestResponse
        RestRequest mockRequest = new RestRequest();
        mockRequest.requestBody = Blob.valueOf('{"key":"value"}');
        mockRequest.httpMethod = 'POST';
        mockRequest.requestURI = '/services/bunningsconsent/';

        RestResponse mockResponse = new RestResponse();
        mockResponse.statusCode = 200;
        mockResponse.responseBody = Blob.valueOf('{"message":"Success"}');

        // Step 2: Call the logCallIn method
        Test.startTest();
        ApplicationLogger.logCallIn('ApplicationLoggerTest.testLogCallIn', mockRequest, mockResponse, null);
        Test.stopTest();

        // Step 3: Verify the log was created
        List<ApplicationLog__c> logs = [SELECT Body__c, Method__c, Endpoint_URL__c, Source__c, Type__c, Response_Status_Code__c, Response_Body__c FROM ApplicationLog__c];
        Assert.areEqual(1, logs.size(), 'One log should have been created.');
        ApplicationLog__c log = logs[0];

        // Step 4: Assert the log fields
        Assert.areEqual('{"key":"value"}', log.Body__c, 'The request body should match.');
        Assert.areEqual('POST', log.Method__c, 'The HTTP method should match.');
        Assert.areEqual('/services/bunningsconsent/', log.Endpoint_URL__c, 'The request URI should match.');
        Assert.areEqual('ApplicationLoggerTest.testLogCallIn', log.Source__c, 'The source method should match.');
        Assert.areEqual('Inbound message', log.Type__c, 'The log type should be "Inbound message".');
        Assert.areEqual(200, log.Response_Status_Code__c, 'The response status code should match.');
        Assert.areEqual('{"message":"Success"}', log.Response_Body__c, 'The response body should match.');
    }

    /**
     * @description testLogCallInWithException test - logging of Inbound Messages like webservices
     * @author Juan M. Cutrera
     */
    @isTest
    static void testLogCallInWithException() {
        // Step 1: Create mock RestRequest and RestResponse
        RestRequest mockRequest = new RestRequest();
        mockRequest.requestBody = Blob.valueOf('{"key":"value"}');
        mockRequest.httpMethod = 'POST';
        mockRequest.requestURI = '/services/bunningsconsent/';

        RestResponse mockResponse = new RestResponse();
        mockResponse.statusCode = 500;
        mockResponse.responseBody = Blob.valueOf('{"error":"Internal Server Error"}');

        // Step 2: Simulate an exception
        Exception mockException = new DmlException('Test exception');

        // Step 3: Call the logCallIn method
        Test.startTest();
        ApplicationLogger.logCallIn('ApplicationLoggerTest.testLogCallInWithException', mockRequest, mockResponse, mockException);
        Test.stopTest();

        // Step 4: Verify the log was created
        List<ApplicationLog__c> logs = [SELECT Body__c, Method__c, Endpoint_URL__c, Source__c, Type__c, Response_Status_Code__c, Response_Body__c, Error_Message__c, Exception_Type__c, Stack_Trace__c FROM ApplicationLog__c];
        Assert.areEqual(1, logs.size(), 'One log should have been created.');
        ApplicationLog__c log = logs[0];

        // Step 5: Assert the log fields
        Assert.areEqual('{"key":"value"}', log.Body__c, 'The request body should match.');
        Assert.areEqual('POST', log.Method__c, 'The HTTP method should match.');
        Assert.areEqual('/services/bunningsconsent/', log.Endpoint_URL__c, 'The request URI should match.');
        Assert.areEqual('ApplicationLoggerTest.testLogCallInWithException', log.Source__c, 'The source method should match.');
        Assert.areEqual('Inbound message', log.Type__c, 'The log type should be "Inbound message".');
        Assert.areEqual(500, log.Response_Status_Code__c, 'The response status code should match.');
        Assert.areEqual('{"error":"Internal Server Error"}', log.Response_Body__c, 'The response body should match.');
        Assert.areEqual('Test exception', log.Error_Message__c, 'The error message should match.');
        Assert.areEqual('System.DmlException', log.Exception_Type__c, 'The exception type should match.');
        Assert.isNotNull(log.Stack_Trace__c, 'The stack trace should not be null.');
    }
    
}