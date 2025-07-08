/*******************************************************************************************************
* Class Name      	: SM_WebServiceResponses
* @description		: Service Layer - A generic class for Web Service Responses
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 21/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          21/03/2025		1000				Initial Version
******************************************************************************************************/
public class SM_WebServiceResponses {

    /**
    * @description  returnError - Return a web response error to RESTContext
    * @author Juan Cutrera | 25/03/2025
    * @param statusCode
    * @param message
    **/
    public static void returnError(Integer statusCode, String message,String classMethod, Exception e) {
        
        
      // Respond in JSON
      RestContext.response.headers.put('Content-Type', 'application/json');
      
      // Set the response status code
      RestContext.response.statusCode = statusCode;
      
      // Set the response header to be just like a Salesforce REST API header
      RestContext.response.responseBody = Blob.valueOf(
        JSON.serializePretty(new List<Map<String,String>>{
            new Map<String,String>{
                'message'  => message,
                'status' => 'Error'
            }
        }
      ));
        ApplicationLogger.logCallIn(classMethod, RestContext.request, RestContext.response,e);

    }
    
    
    /**
    * @description  returnSuccess - Return a web response success to RESTContext
    * @author Juan Cutrera | 25/03/2025
    * @param statusCode
    * @param message
    **/
    public static void returnSuccess(Integer statusCode, String message,boolean logApplication, String classMethod) {
        
        // Respond in JSON
        RestContext.response.headers.put('Content-Type', 'application/json');
        
        // Set the response status code
        RestContext.response.statusCode = statusCode;
        
      // Set the response header to be just like a Salesforce REST API header
        RestContext.response.responseBody = Blob.valueOf(
        JSON.serializePretty(new List<Map<String,String>>{
            new Map<String,String>{
                'message' => message,
                'status'   => 'Success'
            }
        }
      ));

      //Application Log if required
      if(logApplication){
        ApplicationLogger.logCallIn(classMethod, RestContext.request, RestContext.response,null);
      }
     }
}