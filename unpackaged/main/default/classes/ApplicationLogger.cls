/*******************************************************************************************************
* Class Name      	: ApplicationLogger
* Description		: class to handle generic exceptions. This will insert records to ExceptionLog__c for monitoring
* Author          	: Simplus - Haider Raza
* Created On      	: 06/03/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           06/03/2020		1000				Initial version
* Simplus MS            18/12/2020      1001                Added new method to Log COS API Callout Exception
* Simplus MS            09/09/2021      1002                Addded new method 'createPricingAssignmentCalloutLog' and 'insertApplicationLogs' to log all Callouts with their corresponding details, CCRM15-196
* Simplus MS            22/02/2022      1003                Log COS API Callout Success details - SFSUP-289 - New method 'logCallOutNoRetry' added with more parameters
* Bunnings Dev          31/10/2023      1004                BUNDIG-21549 - Add Reusable Error Handling Logging
* Jasper R. Galapon     12/12/2023      1005                BUNDIG-26295 - Added new method for Pricing Assignment Error Logging
* Bunnings Dev          25/09/2024      1006                Error Handling with Object id
* Jasper R. Galapon     21/01/2025      1007                BUNDIG-39766 - Added a new method for db Error logging
* Juan M. Cutrera       17/04/2025      1008                EDP2-20847 & EDP2-20848 - Added new method for logging 'Inbound Calls'
******************************************************************************************************/
/**
* @author       Haider Raza
* @date         06/03/2020
* @description  
**/
public class ApplicationLogger {

    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  Method that inserts record into the Exception Log object
    * @param sFunctionName  - Function where the error occurred.
    *        sObjectName    - Object where the error occurred.
    *        sSourceType    - Source of exception (e.g. Trigger, Batch Job, Controller Extension, etc.)
    *        e              - Exception object that was caught
    * @usage Applicationlogger.log(String sFunctionName, String sObjectName, String sSourceType, Exception e);
    **/
    public static void log(String sFunctionName, String sObjectName, String sSourceType, Exception e) {
        try {
            logException(sFunctionName, sObjectName, sSourceType, e);
        } catch(Exception ex) {
            logException('logException', 'ErrorLogException', 'Class', ex);
        }
    }

    private static void logException(String sFunctionName, String sObjectName, String sSourceType, Exception e) {
        try {
            ApplicationLog__c exLog = new ApplicationLog__c();
            exLog.Error_Message__c = e.getMessage();
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Function_Name__c = sFunctionName;
            exLog.Object_Name__c = sObjectName;
            exLog.Source_Type__c = sSourceType;
            exLog.Stack_Trace__c = e.getStackTraceString();
            exLog.Type__c = 'Exception';
            insert exLog;
        } catch (Exception ex) {
            throw(ex);
        }
    }
    /**
    * @author       Sowjanya Bitra
    * @date         25/09/2024
    * @description  Method that inserts record into the Exception Log object with Object id
    * @param sFunctionName  - Function where the error occurred.
    *        sObjectName    - Object where the error occurred.
    *        sSourceType    - Source of exception (e.g. Trigger, Batch Job, Controller Extension, etc.)
    *        e              - Exception object that was caught
    *        sObjectId      - Id of the object
    * @usage Applicationlogger.log(String sFunctionName, String sObjectName, String sSourceType, Exception e, String sObjectId);
    **/
    public static void logException(String sFunctionName, String sObjectName, String sSourceType, Exception e, String sObjectId) {
        try {
            logExceptionObjectId(sFunctionName, sObjectName, sSourceType, e, sObjectId);
        } catch(Exception ex) {
            logException('logException', 'ErrorLogException', 'Class', ex);
        }
    }

    private static void logExceptionObjectId(String sFunctionName, String sObjectName, String sSourceType, Exception e, String sObjectId) {
        try {
            ApplicationLog__c exLog = new ApplicationLog__c();
            exLog.Error_Message__c = e.getMessage();
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Function_Name__c = sFunctionName;
            exLog.Object_Name__c = sObjectName;
            exLog.Source_Type__c = sSourceType;
            exLog.Stack_Trace__c = e.getStackTraceString();
            exLog.Type__c = 'Exception';
            exLog.Object_Id__c = sObjectId;
            insert exLog;
        } catch (Exception ex) {
            throw(ex);
        }
    }
    /**
    * @author       Haider Raza
    * @date         06/04/2020
    * @description  Method that inserts record into the Outbound message Log object
    * @param source         - Function where the error occurred.
    *        endpointURL    - Endpoint URL
    *        body           - body of the message
    *        method         - Method: PUT, PUSH, DELETE, GET
    * @usage ApplicationLogger.log(String source, String endpointURL, String body, String method);
    **/
    public static void log(String source, String endpointURL, String body, String method){
        try{
            ApplicationLog__c obLog = new ApplicationLog__c(
                    Body__c             = body,
                    Method__c           = method,
                    Endpoint_URL__c     = endpointURL,
                    Source__c           = source,
                    Type__c             = 'Outbound message'
            );
            insert obLog;
        }catch (Exception ex){
            throw(ex);
        }
    }

    /**
    * @description  Either HttpResponse / Exception is null
    * @author Yi Zhang | 13/08/2020 
    * @param sourceApexMethod 
    * @param request 
    * @param response 
    * @param retryParams 
    * @param e              
    **/
    public static void logCallout(String sourceApexMethod, HttpRequest request, HttpResponse response, String retryParams, Exception e) {
        try {
            ApplicationLog__c log = new ApplicationLog__c(
                    Body__c             = request.getBody(),
                    Method__c           = request.getMethod(),
                    Endpoint_URL__c     = request.getEndpoint(),
                    Source__c           = sourceApexMethod,
                    Type__c             = 'Outbound message',
                    Retry_Count__c      = 7,
                    Retry_Params__c     = retryParams
            );

            if(response != null) {
                // response came with error
                log.Response_Status_Code__c = response.getStatusCode();
                log.Response_Status__c = response.getStatus();
                log.Response_Body__c = response.getBody();
            } else {
                // exception thrown when making callout
                log.Error_Message__c = e.getMessage();
                log.Exception_Type__c = e.getTypeName();
                log.Stack_Trace__c = e.getStackTraceString();
            }

            insert log;
        } catch(Exception ex) {
            throw ex;
        }
    }


    /**
     * @description logCallIn - Build a new Inbound message Log object for both Successuful and Error
     * @author Juan M. Cutrera | 16/04/2025
     * @param  sourceApexMethod sourceApexMethod description
     * @param  request          request description
     * @param  response         response description
     * @param  e                e description
     */
    public static void logCallIn(String sourceApexMethod, RestRequest request, RestResponse response,Exception e) {
        try {
            ApplicationLog__c log = new ApplicationLog__c(
            Body__c             = request.requestBody != null ? request.requestBody.toString() : null,
            Method__c           = request.httpMethod,
            Endpoint_URL__c     = request.requestURI,
            Source__c           = sourceApexMethod,
            Type__c             = 'Inbound message'
        );


        log.Response_Status_Code__c = response.statusCode;
        log.Response_Body__c = response.responseBody != null ? response.responseBody.toString() : null;
        
        
        // Response came with error
        if ((response?.statusCode.toString().startsWith('4') || response?.statusCode.toString().startsWith('5') )&& e != null) {
            log.Error_Message__c = e.getMessage();
            log.Exception_Type__c = e.getTypeName();
                log.Stack_Trace__c = e.getStackTraceString();
        }

            insert log;
        } catch(Exception ex) {
            throw ex;
        }
    }

    /**
    * @description 
    * @author Simplus MS | 10/09/2021 
    * @param List<ApplicationLog__c> appLogs 
    **/
    public static void insertApplicationLogs(List<ApplicationLog__c> appLogs) {
        try{
            insert appLogs;
        } catch (Exception ex){
            throw(ex);
        }
    }

    /**
    * @description 
    * @author Simplus MS | 09/09/2021 
    * @param String powerpassNumber 
    * @param String sourceApexMethod 
    * @param String calloutType 
    * @param HttpRequest request 
    * @param HttpResponse response 
    * @param String retryParams 
    * @param Exception e 
    * @return ApplicationLog__c 
    **/
    public static ApplicationLog__c createPricingAssignmentCalloutLog(String powerpassNumber, String sourceApexMethod, String calloutType, HttpRequest request, HttpResponse response, String retryParams, Exception e) {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c = powerpassNumber,
            Type__c = 'Outbound message',
            Source_Type__c = 'Pricing Assignment Request-' + calloutType,
            Object_Name__c = 'Customer_Price_List__c',
            Function_Name__c = sourceApexMethod,
            Body__c = request.getBody(),
            Method__c = request.getMethod(),
            Endpoint_URL__c = request.getEndpoint(),
            Retry_Params__c = retryParams,
            Retry_Count__c = null
        );

        if(response != null) {
            if (response.getStatusCode() == 0 && e != null){
                // exception thrown when making callout
                log.Error_Message__c = String.valueOf(e);
                log.Exception_Type__c = e.getTypeName();
                log.Stack_Trace__c = e.getStackTraceString();
            } else {
                // response came with error
            log.Response_Status_Code__c = response.getStatusCode();
            log.Response_Status__c = response.getStatus();
            log.Response_Body__c = response.getBody();
            }
        } else if(response == null) {
            // exception thrown when making callout
            log.Error_Message__c = e.getMessage();
            log.Exception_Type__c = e.getTypeName();
            log.Stack_Trace__c = e.getStackTraceString();
        }
        return log;
    }

    /**
    * @description Log COS API Callout Exception details - CCRM-6890,6892 - New method added with more parameters
    * @author Simplus MS | 14/12/2020 
    * @param sourceApexMethod 
    * @param request 
    * @param response 
    * @param retryParams 
    * @param e              
    **/
    public static void logCalloutException(String sourceApexMethod, HttpRequest request, HttpResponse response, String retryParams, String sObjectName, 
                        String sObjectType, Exception e) {
        try {
            ApplicationLog__c log = new ApplicationLog__c(
                    Body__c             = request.getBody(),
                    Method__c           = request.getMethod(),
                    Endpoint_URL__c     = request.getEndpoint(),
                    Source__c           = sourceApexMethod,
                    Type__c             = 'Outbound message',
                    Retry_Count__c      = 3,
                    Retry_Params__c     = retryParams,
                    Function_Name__c    = request.getMethod(),
                    Object_Name__c      = sObjectName,
                    Source_Type__c      = sourceApexMethod
            );

            if(response != null) {
                // response came with error
                log.Response_Status_Code__c = response.getStatusCode();
                log.Response_Status__c = response.getStatus();
                log.Response_Body__c = response.getBody();
            } else {
                // exception thrown when making callout
                log.Error_Message__c = e.getMessage();
                log.Exception_Type__c = e.getTypeName();
                log.Stack_Trace__c = e.getStackTraceString();
            }

            insert log;
        } catch(Exception ex) {
            throw ex;
        }
    }

    /**
    * @description Log COS API Callout Success details - SFSUP-289 - New method added with more parameters
    * @author Simplus MS | 22/02/2022 
    * @param sourceApexMethod 
    * @param request 
    * @param response 
    * @param retryParams
    * NOTE: Commented out, method not being used and not in higher org - Jasper - 2/11/2023           
    **/
    // public static void logCallOutNoRetry(String sourceApexMethod, HttpRequest request, HttpResponse response, Exception e) { //, String retryParams, String sObjectName, String sObjectType
    //     try {
    //         ApplicationLog__c log = new ApplicationLog__c(
    //                 Body__c             = request.getBody(),
    //                 Method__c           = request.getMethod(),
    //                 Endpoint_URL__c     = request.getEndpoint(),
    //                 Source__c           = sourceApexMethod,
    //                 Type__c             = 'Outbound message',
    //                 Function_Name__c    = request.getMethod()
    //                 //Retry_Count__c      = 3,
    //                 // Retry_Params__c     = retryParams,
    //                 // Object_Name__c      = sObjectName,
    //                 // Source_Type__c      = sourceApexMethod
    //         );

    //         if(response != null) {
    //             // response came with error
    //             log.Response_Status_Code__c = response.getStatusCode();
    //             log.Response_Status__c = response.getStatus();
    //             log.Response_Body__c = response.getBody();
    //         } else {
    //             log.Error_Message__c = e.getMessage();
    //             log.Exception_Type__c = e.getTypeName();
    //             log.Stack_Trace__c = e.getStackTraceString();
    //         }

    //         insert log;
    //     } catch(Exception ex) {
    //         throw ex;
    //     }
    // }

    /**
    * @author       Philip Clark
    * @date         25/06/2020
    * @description  Method that asynchronously inserts record into the Exception Log object
    * @param sFunctionName  - Function where the error occurred.
    *        sObjectName    - Object where the error occurred.
    *        sSourceType    - Source of exception (e.g. Trigger, Batch Job, Controller Extension, etc.)
    *        e              - Serialised exception object that was caught
    * @usage Applicationlogger.asyncLog(String sFunctionName, String sObjectName, String sSourceType, String e);
    **/
    @future
    public static void asyncLog(String sFunctionName, String sObjectName, String sSourceType, String message, String typeName, String stackTraceString) {
        ApplicationLog__c exLog = new ApplicationLog__c();
        exLog.Error_Message__c = message;
        exLog.Exception_Type__c = typeName;
        exLog.Function_Name__c = sFunctionName;
        exLog.Object_Name__c = sObjectName;
        exLog.Source_Type__c = sSourceType;
        exLog.Stack_Trace__c = stackTraceString;
        exLog.Type__c = 'Exception';
        insert exLog;
    }

    /**
     * @date        31/10/2023
     * @description Log LWC error - BUNDIG-21549
     * @param       Error Wrapper Class
    **/
    @AuraEnabled
    public static void lwcErrorLogging(List<errorWrapper> lwcErrorInput) {
        List<ApplicationLog__c> appLogToInsert = new List<ApplicationLog__c>();

        for (errorWrapper f : lwcErrorInput) {
            appLogToInsert.add(new ApplicationLog__c(Source__c = f.sourceName, Function_Name__c = f.functionName, Error_Message__c = f.errorMessage, Source_Type__c = f.sourceType, Type__c = f.errorType));
        }

        if (!appLogToInsert.isEmpty()) {
            try {
                INSERT appLogToInsert;
            } catch (Exception e) {
                ApplicationLogger.log('ApplicationLogger.lwcErrorLogging', 'Application Logger', 'ApplicationLogger', e);
            }
        }
    }

    /**
     * @date        31/10/2023
     * @description Log flow error - BUNDIG-21549
     * @param       Error Wrapper Class
    **/
    @InvocableMethod(Label = 'Flow Error Logging' Description = 'Creates error log from flow')
    public static void flowErrorLogging(List<errorWrapper> flowErrorInput) {
        List<ApplicationLog__c> appLogToInsert = new List<ApplicationLog__c>();

        for (errorWrapper f : flowErrorInput) {
            appLogToInsert.add(new ApplicationLog__c(Source__c = f.sourceName, Function_Name__c = f.functionName, Error_Message__c = f.errorMessage, Source_Type__c = f.sourceType, Type__c = f.errorType));
        }

        if (!appLogToInsert.isEmpty()) {
            try {
                INSERT appLogToInsert;
            } catch (Exception e) {
                ApplicationLogger.log('ApplicationLogger.flowErrorLogging', 'Application Logger', 'ApplicationLogger', e);
            }
        }
    }

    /**
     * @date        31/10/2023
     * @description Wrapper class - BUNDIG-21549
    **/
    public class errorWrapper {
        @InvocableVariable
        public String sourceName;

        @InvocableVariable
        public String functionName;

        @InvocableVariable
        public String errorMessage;

        @InvocableVariable
        public String sourceType;

        @InvocableVariable
        public String errorType;
    }

    /**
     * Create Pricing Assignment Callout Error Log
    **/
    public static ApplicationLog__c createPricingAssignmentCalloutErrorLog(String powerpassNumber, String sourceApexMethod, String calloutType, HttpRequest request, HttpResponse response, String retryParams, Exception e, String ErrMsg) {
        ApplicationLog__c log = new ApplicationLog__c(
            Source__c = powerpassNumber,
            Type__c = 'Outbound message',
            Source_Type__c = 'Pricing Assignment Request-' + calloutType,
            Object_Name__c = 'Customer_Price_List__c',
            Function_Name__c = sourceApexMethod,
            Body__c = request.getBody(),
            Method__c = request.getMethod(),
            Endpoint_URL__c = request.getEndpoint(),            
            Retry_Params__c = retryParams,            
            Retry_Count__c = null,
            Error_Message__c = ErrMsg
        );

        if(response != null) {
            if (response.getStatusCode() == 0 && e != null){
                // exception thrown when making callout
                log.Error_Message__c = String.valueOf(e);
                log.Exception_Type__c = e.getTypeName();
                log.Stack_Trace__c = e.getStackTraceString();
            } else {
                // response came with error
            log.Response_Status_Code__c = response.getStatusCode();
            log.Response_Status__c = response.getStatus();
            log.Response_Body__c = response.getBody();
            }
        } else if(response == null) {
            // exception thrown when making callout
            log.Error_Message__c = e.getMessage();
            log.Exception_Type__c = e.getTypeName();
            log.Stack_Trace__c = e.getStackTraceString();
        }
        return log;
    }
    
}