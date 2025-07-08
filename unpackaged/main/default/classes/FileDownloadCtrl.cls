/***************************************************************************************************
* Class Name      	: FileDownloadCtrl
* Description		: This is the controller class for FileDownload.cmp Aura component 
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 02-Dec-2020
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         02-Dec-2020		1000				Initial version
* Jasper R. Galapon		11/06/2024		1001				BUNDIG-26468/27490 - Request and download amendments only contract
*****************************************************************************************************/
public class FileDownloadCtrl {
    public class OutputFile {
        @auraEnabled
        public string recordId;
        @auraEnabled
        public boolean isError = false;
        @auraEnabled
        public string fileBlob;
        @auraEnabled
        public string errorMessage;
    }
    
    //Class added for CCRM15-484 - Aldrin
    public class ResponseObject {
        @auraEnabled
        public OutputFile file;
        
        @auraEnabled
        public ApplicationLog__c log;
    }
    
    //Modified for CCRM15-484 - Aldrin - BUNDIG-26511 - Modified to have additional parameter for amendment download
    @AuraEnabled    
    public static ResponseObject getFile(Map<String, String> params, String endPoint) {
        System.debug(LoggingLevel.FINEST, '***File Download: ' + endPoint);
        
        
        HttpRequest req = SM_WSHelper.buildHttpRequestFromWSDef(endPoint, params); // BUNDIG-26468/27490
        //HttpRequest req = SM_WSHelper.buildHttpRequestFromWSDef('PLCON_FileDownload', params); // BUNDIG-26468/27490
        Long startTime = System.now().getTime();
        HttpResponse resp;
        OutputFile file;
        
        ResponseObject ro = new ResponseObject();
        
        //The try catch block is added for CCRM15-484 - Aldrin
        try {
            resp = (new http()).send(req);
            Long endTime = System.now().getTime();
            Long elapsed = endTime - startTime;
            file = new OutputFile();
            String recIdKey = '{{RECORD_ID}}';
            file.recordId = (params!=null && params.containsKey(recIdKey)) ? params.get(recIdKey) : null;
            if (resp.getStatusCode() == 200) {                
                file.fileBlob = resp.getBody().replace('"','');
            	ro.log = createCalloutLog('File Download Controller', req, resp, elapsed);
            } else {
                file.isError = true;
                file.errorMessage = getError(resp.getBody());
                file.errorMessage = !string.isblank(file.errorMessage) ? file.errorMessage :
                String.valueOf(resp.getStatusCode()) + ' - ' + resp.getStatus();  
                ro.log = createCalloutErrorLog('File Download Controller', 'Callout/API Exception', req, resp, elapsed, file.errorMessage, null);
            }      
            
			    
        } catch (Exception e) {
            throw new AuraHandledException(JSON.serialize(
                createCalloutErrorLog('File Download Controller', 'Runtime Exception', req, resp, (System.now().getTime()) - startTime, e.getMessage(), e.getStackTraceString())
            ));            
        }  

        ro.file = file;
        return ro;
    }
    
    private static string getError(String payload) {
        try {
            Map<String, Object> o = (Map<String, Object>)SM_WSHelper.parseJSON(payload);
            List<Object> cerrors = (List<Object>)JSON.deserializeUntyped(JSON.serialize(o.get('errors')));
            o = SM_WSHelper.parseJSON(JSON.serialize(cerrors[0]));
            return (String)o.get('error');               
        } catch (Exception ex) {
            return '';
        }
    }

	//Added for CCRM15-484 - Aldrin    
    private static string getEndPoint(HTTPRequest req) {
        String endPoint = '';
        try {
            endPoint = req.getEndpoint();
        } catch (Exception e) {system.debug(e.getMessage() + '\n\n' + e.getStackTraceString());}
        return endPoint;
    }    
    
    //Added for CCRM15-484 - Aldrin
    private static ApplicationLog__c createCalloutLog(String source, HTTPRequest req, HTTPResponse res, long calloutDuration){
        ApplicationLog__c log = new ApplicationLog__c(
            Body__c             = req.getBody(),
            Method__c           = req.getMethod(),
            Endpoint_URL__c     = getEndPoint(req),
            Source__c           = source,
            Type__c             = 'Outbound message',
            Retry_Count__c      = 0,
            Retry_Params__c		= 'N/A',
            Response_Status_Code__c = res.getStatusCode(),
            Response_Status__c	= res.getStatus(),
            Callout_Duration__c = calloutDuration,
            Source_Type__c		= 'Apex Callout'
        );   
        return log;
    }    
    
    //Added for CCRM15-484 - Aldrin
    private static ApplicationLog__c createCalloutErrorLog(String source, String exceptionType, HTTPRequest req, HTTPResponse res, long calloutDuration,
                                                          String errorMessage, String stackTraceString){
        ApplicationLog__c log = new ApplicationLog__c(
            Body__c             = req.getBody(),
            Method__c           = req.getMethod(),
            Endpoint_URL__c     = getEndPoint(req),
            Source__c           = source,
            Type__c             = 'Outbound message',
            Retry_Count__c      = 0,
            Retry_Params__c		= 'N/A',
            Response_Status_Code__c = res==null ? null : res.getStatusCode(),
            Response_Status__c	= res==null ? '' : res.getStatus(),
            Response_Body__c	= res==null ? '' : res.getBody(),
            Callout_Duration__c = calloutDuration,
            Error_Message__c 	= errorMessage,
            Stack_Trace__c		= stackTraceString,
            Source_Type__c		= 'Apex Callout',
            Object_Name__c		= 'N/A',
            Function_Name__c	= 'FileDownloadCtrl.getFile',
            Exception_Type__c	= exceptionType            
        );   
        return log;
    }       
    
    //Added for CCRM15-484 - Aldrin
    @AuraEnabled
    public static void saveLogs(String strLogs) {   
        List<ApplicationLog__c> logs = (List<ApplicationLog__c>) JSON.deserialize(strLogs, List<ApplicationLog__c>.class);
        if (logs.size()>0) insert logs;
    }
}