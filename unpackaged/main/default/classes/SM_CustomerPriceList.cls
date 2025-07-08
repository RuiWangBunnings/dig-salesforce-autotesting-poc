/*******************************************************************************************************
* Class Name      	: SM_CustomerPriceList
* Description		: Domain / Service layer for Customer Price List
* Author          	: Simplus MS
* Created On      	: 16/12/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           16/12/2020		1000				Initial version
* Simplus MS           14/05/2021		2000				modifications CCRM-13728
* Simplus MS           09/09/2021       2001                modifications CCRM15-196
******************************************************************************************************/

public class SM_CustomerPriceList {
    public static final String CALLOUT_SUCCESS_KEY = 'calloutSuccess';        

    /**
    * @description 
    * @author Simplus MS | 09/09/2021 
    * @param String powerpassNumber 
    * @param String sourceApexMethod 
    * @param String calloutType 
    * @param HttpRequest request 
    * @param HttpResponse response 
    * @param Map<Id Map<String String>> cplMap 
    * @param Exception e 
    * @return Map<String, Object> 
    **/
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

    /**
    * @description 
    * @author Simplus MS | 16/12/2020 
    * @param customerPriceListMap 
    **/
     public static Map<String, Object> invokeCustomerPriceListServiceAssignment(Map<Id, Map<String, String>> cplMap, Boolean createLog){        
        Map<Id, Account> accountListMap = new Map<Id, Account>();
        Map<String, Object> returnMap = new Map<String, Object>{CALLOUT_SUCCESS_KEY=>false};
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        HttpRequest updateRequest = new HttpRequest();
        HttpResponse updateResponse = new HttpResponse();
        
        List<Map<String, Object>> pricingAssigmentLogObjs = new List<Map<String, Object>>();    // CCRM15-196
        
        for(Id priceListId : cplMap.keySet()){
            Map<String, String> tempMap = cplMap.get(priceListId);
            
            Map<String,String> wsParams = new Map<String, String>();
            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{PRICE_LIST_ID}}', tempMap.get('PriceListId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            request = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Assign_Validate_Customer', wsParams);

            try{
                response = (new http()).send(request);
                System.debug(response.getBody());
                System.debug(response.getStatusCode());
                // Map<String, String> params = (Map<String, String>)JSON.deserialize(response.getBody(), Map<String, String>.class);
                if(response.getStatusCode() == 200){    
                    System.debug('Inside 1st API Callout success');
                    updateRequest = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Assign_Update_Customer', wsParams);
                    updateResponse = (new http()).send(updateRequest);
                    System.debug(updateResponse.getBody());
                    System.debug(updateResponse.getStatusCode());
                    // CCRM15-196
                    pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null)
                    );
                    // END_CCRM15-196 

                    if(updateResponse.getStatusCode() == 200){
                        if(createLog == true){
                            Account acct = new Account();
                            acct.Id = tempMap.get('AccountId');
                            acct.CPS_Callout_Successful_SpendBand__c = true;
                            acct.Send_Data_to_CPS__c = false;
                            accountListMap.put(acct.Id, acct);
                        }else{
                            //
                        }
                        returnMap.put(CALLOUT_SUCCESS_KEY, true);
                        // CCRM15-196
                        pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 'Assign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{priceListId => tempMap}, null)
                        );
                        // END_CCRM15-196 
                    }                    
                    
                    if(updateResponse.getStatusCode() == 202 || updateResponse.getStatusCode() == 400 || updateResponse.getStatusCode() == 404 || updateResponse.getStatusCode() == 500){
                        if(createLog == true ) {
                            maptoSerialize.put(priceListId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'PriceListId' => tempMap.get('PriceListId'),
                            'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'),
                            'CountryCode' => tempMap.get('CountryCode')});
                            
                        }else{
                            returnMap.put(CALLOUT_SUCCESS_KEY, false);
                        }
                        // CCRM15-196
                        pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 'Assign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{priceListId => tempMap}, null)
                        );
                        // END_CCRM15-196 
                    }
                }else if(response.getStatusCode() == 202 || response.getStatusCode() == 400 ||response.getStatusCode() == 404 || response.getStatusCode() == 500){                    
                    System.debug('status code ::' +createLog);
                    if(createLog == true ) {
                        maptoSerialize.put(priceListId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'PriceListId' => tempMap.get('PriceListId'),
                                                                        'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'),
                                                                        'CountryCode' => tempMap.get('CountryCode')});
                        
                    }else{
                             returnMap.put(CALLOUT_SUCCESS_KEY, false);
                    }
                    // CCRM15-196
                    pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null)
                    );
                    // END_CCRM15-196 
                }

            }catch(Exception e){
                if(createLog){
                    maptoSerialize.put(priceListId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'PriceListId' => tempMap.get('PriceListId'),
                                                                        'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'),
                                                                        'CountryCode' => tempMap.get('CountryCode')});
                }else{
                    returnMap.put(CALLOUT_SUCCESS_KEY, false);
                }
                // CCRM15-196
                pricingAssigmentLogObjs.add(
                    mapFieldsForPricingAssignmentLog(
                        tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 'Assign_Exception', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, e)
                );
                // END_CCRM15-196 
            }
            
        }
        
        if(maptoSerialize!=null && !maptoSerialize.isEmpty()){
            System.debug('maptoSerialize::' +maptoSerialize);
            ApplicationLogger.logCalloutException(
                'SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment', 
                request, 
                response, 
                JSON.serialize(maptoSerialize),
                'Account',
                'Trigger',
                null);
            }
            // CCRM15-196
            if(pricingAssigmentLogObjs.size() > 0) {
                List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
                for(Map<String, Object> obj : pricingAssigmentLogObjs) {
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
                }
                ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
            }
            // END_CCRM15-196 
            
            if(accountListMap!=null && !accountListMap.isEmpty()) update accountListMap.values();
            return returnMap;
     }
    
    /**
    * @description API Callout for Unassign/Deletion of Customer Price List
    * @author Simplus MS | 16/12/2020 
    * @param customerPriceListMap,createlog
    **/
    
    //14-may: additional item for CCRM-13728
    
    public static Map<String, Object> invokeCustomerPriceListServiceDeletion(Map<Id, Map<String, String>> cplMap, Boolean createLog){
        List<Account> acctList = new List<Account>();
        Set<Account> accounts = new Set<Account>();
        List<Customer_Price_List__c> cplList = new List<Customer_Price_List__c>();
        List<ApplicationLog__c> logList = new List<ApplicationLog__c>();
        Map<String, Object> returnMap = new Map<String, Object>{CALLOUT_SUCCESS_KEY=>false};
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        HttpRequest updateRequest = new HttpRequest();
        HttpResponse updateResponse = new HttpResponse();
        
        List<Map<String, Object>> pricingAssigmentLogObjs = new List<Map<String, Object>>();    // CCRM15-196

        String cplIdKey = 'CustomerPriceListId';
        
        System.debug('DEBUG cplMap: ' + JSON.serializePretty(cplMap));
        
        for(Id priceListId : cplMap.keySet()){
            Map<String, String> params = cplMap.get(priceListId);
            Map<String,String> wsParams = new Map<String, String>();
            wsParams.put('{{COUNTRY_CODE}}', params.get('CountryCode'));
            wsParams.put('{{PRICE_LIST_ID}}', params.get('PriceListId'));
            wsParams.put('{{CUST_ID}}', params.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', params.get('TMNumber'));
            
            request = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Unassign_Validate_Customer', wsParams);
            
            try{
                response = (new http()).send(request);
                System.debug(response.getBody());
                Map<String, String> responseParams = (Map<String, String>)JSON.deserialize(response.getBody(), Map<String, String>.class);
                if(response.getStatusCode() == 200 ){
                    updateRequest = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Unassign_Update_Customer', wsParams);
                    updateResponse = (new http()).send(updateRequest);
                    System.debug(updateResponse.getBody());
                    // CCRM15-196
                    pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            params.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => params}, null)
                    );
                    // END_CCRM15-196 

                    if(updateResponse.getStatusCode() == 200){
                        // CCRM15-196
                        pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            params.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 'Unassign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{priceListId => params}, null)
                        );
                        // END_CCRM15-196
                        Account acct = new Account();
                        acct.Id = params.get('AccountId');
                        acct.CPS_Callout_Successful_SpendBand__c = true;
                        accounts.add(acct);
                        returnMap.put(CALLOUT_SUCCESS_KEY, true);
                          
                        String cplId = params.containsKey(cplIdKey) ? params.get(cplIdKey) : '';
                        if (!string.isBlank(cplId)) cplList.add(new Customer_Price_List__c(id=cplId));
                    } else {         
                        returnMap.put(CALLOUT_SUCCESS_KEY, createLog);
                        if(createLog) {
                            logList.add(prepareLog(
                                'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 
                                updateRequest, 
                                updateResponse, 
                                JSON.serialize(new Map<id, Map<String, String>>{priceListId=>params}),
                                'Account',
                                'Trigger',
                                null));
                            
                        }
                        // CCRM15-196
                        pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            params.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 'Unassign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{priceListId => params}, null)
                        );
                        // END_CCRM15-196
                    }
                } else {
                    returnMap.put(CALLOUT_SUCCESS_KEY, createLog);
                    if(createLog) {
                        logList.add(prepareLog(
                            'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 
                            request, 
                            response, 
                            JSON.serialize(new Map<id, Map<String, String>>{priceListId=>params}),
                            'Account',
                            'Trigger',
                            null));
                    }
                    // CCRM15-196
                    pricingAssigmentLogObjs.add(
                        mapFieldsForPricingAssignmentLog(
                            params.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => params}, null)
                    );
                    // END_CCRM15-196 
                }
            }catch(Exception e){
                System.debug('ERROR: ' + e.getMessage());
                System.debug('ERROR: ' + e.getStackTraceString());
                returnMap.put(CALLOUT_SUCCESS_KEY, createLog);
                if(createLog){
                    logList.add(prepareLog(
                        'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 
                        request, 
                        response, 
                        JSON.serialize(new Map<id, Map<String, String>>{priceListId=>params}),
                        'Account',
                        'Trigger',
                        e));
                }
                // CCRM15-196
                pricingAssigmentLogObjs.add(
                    mapFieldsForPricingAssignmentLog(
                        params.get('CustomerId'), 'SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion', 'Unassign_Exception', request, response, new Map<Id, Map<String, String>>{priceListId => params}, e)
                );
                // END_CCRM15-196 
            }            
        }
        
        acctList.addAll(accounts);
        if(acctList.size()>0) update acctList;   
        if(cplList.size()>0) delete cplList;
        if(logList.size()>0) insert logList;

        // CCRM15-196
        if(pricingAssigmentLogObjs.size() > 0) {
            List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
            for(Map<String, Object> obj : pricingAssigmentLogObjs) {
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
            }
            ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
        }
        // END_CCRM15-196 
        
        return returnMap;        
    }
    
    static ApplicationLog__c prepareLog(String sourceApexMethod, HttpRequest request, HttpResponse response, String retryParams, String sObjectName, 
                        String sObjectType, Exception e) 
    {
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
            Source_Type__c      = sourceApexMethod,
            Response_Status_Code__c = response.getStatusCode(),
            Response_Status__c = response.getStatus(),
            Response_Body__c = response.getBody()        
        );
        return log;
    }
}