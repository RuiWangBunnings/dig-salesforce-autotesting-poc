/*******************************************************************************************************
* Class Name      	: SM_RESTCallout
* Description		: Service layer for RESTful Web Services
* Author          	: Simplus - Yi Zhang
* Created On      	: 13/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              13/08/2020		1000				Initial version
******************************************************************************************************/
public class SM_RESTCallout {
    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param endpoint 
    * @param method 
    * @param body 
    * @return HttpRequest 
    **/
    public static HttpRequest createHttpRequest(String endpoint, String method, String body) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(endpoint);
        if (body != null && !String.isEmpty(body)) {
            request.setBody(body);
        }
        request.setHeader('Content-Type', 'application/json');
        return request;
    }

    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param request 
    * @return HttpResponse 
    **/
    public static HttpResponse makeCallout(HttpRequest request) {
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }
}