/*******************************************************************************************************
* Class Name      	: SM_WebServiceResponses_Test
* @description		: Test class - Test class for Web Service Responses
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 21/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          21/03/2025		1000				Initial Version
******************************************************************************************************/
@isTest
public class SM_WebServiceResponses_Test {
    
    
    /**
    * @description  createErrorTest - Create an Error Test
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void createErrorTest(){
        RestResponse response = new RestResponse();
        RestRequest mockRequest = new RestRequest();
        mockRequest.requestBody = Blob.valueOf('{"key":"value"}');
        mockRequest.httpMethod = 'POST';
        mockRequest.requestURI = '/services/bunningsconsent/';
        response.responseBody = Blob.valueOf('{"key":"value"}');
        RestContext.request = mockRequest;
        RestContext.response = response;
        
        Test.startTest();

        SM_WebServiceResponses.returnError(404, 'This is a test error','classMethod',null);
        Test.stopTest();
        Assert.AreEqual(404, RestContext.response.statusCode);
        
    }
    
    /**
    * @description  createSuccessTest - Create an Success Test
    * @author Juan Cutrera | 25/03/2025 
    **/
    @isTest
    static void createSuccessTest(){
        RestResponse response = new RestResponse();
        RestRequest mockRequest = new RestRequest();
        mockRequest.requestBody = Blob.valueOf('{"key":"value"}');
        mockRequest.httpMethod = 'POST';
        mockRequest.requestURI = '/services/bunningsconsent/';
        response.responseBody = Blob.valueOf('{"key":"value"}');
        RestContext.request = mockRequest;
        RestContext.response = response;
        
        Test.startTest();
        SM_WebServiceResponses.returnSuccess(200, 'Success!',true,'classMethod');
        Test.stopTest();
        Assert.AreEqual(200, RestContext.response.statusCode);    
    }
    

}