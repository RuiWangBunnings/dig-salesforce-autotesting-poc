/*******************************************************************************************************
* Class Name      	: SM_RESTCalloutMock
* Description		: Service layer for RESTful Web Services Mock
* Author          	: Simplus - Yi Zhang
* Created On      	: 13/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              13/08/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_RESTCalloutMock implements HttpCalloutMock {
    
    protected final String body;
    protected final Integer statusCode;
    protected final Boolean throwCalloutException;

    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param body 
    * @param statusCode 
    * @param throwCalloutException 
    **/
    public SM_RESTCalloutMock(String body, Integer statusCode, Boolean throwCalloutException) {
        this.body = body;
        this.statusCode = statusCode;
        this.throwCalloutException = throwCalloutException;
    }

    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param request 
    * @return HttpResponse 
    **/
    public HttpResponse respond(HttpRequest request) {
        //return a callout exception to test for error handling
        if (this.throwCalloutException) {
            CalloutException e = new CalloutException();
            e.setMessage('You have received a callout error');
            throw e;
        } else {
            //return normal response
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setStatus('Complete');
            response.setBody(body);
            return response;
            
        }
    }
}