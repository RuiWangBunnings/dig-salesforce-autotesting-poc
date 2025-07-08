/*******************************************************************************************************
* Class Name        : cplUnassignValidateCustomerQueueable
* Description       : Customer Price List Queueable Unassign Validate Customer
*                   : This also calls cplUnassignUpdateCustomerQueueable
* Author            : Jasper R. Galapon
* Created On        : 02/1/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          02/1/2024       1000                BUNDIG-26295 - Initial version
******************************************************************************************************/

public class cplUnassignValidateCustomerQueueable implements Queueable, Database.AllowsCallouts {
    private Map<Id, Map<String, String>> delCPLMap;
    private Map<Id, Map<String, String>> cplMap;

    public cplUnassignValidateCustomerQueueable(Map<Id, Map<String, String>> delCPLMap, Map<Id, Map<String, String>> cplMap) {
        this.delCPLMap = delCPLMap;
        this.cplMap = cplMap;
    }


    public void execute(QueueableContext context) {
        List<Map<String, Object>> pricingAssigment_ErrorLogObj = new List<Map<String, Object>>();

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        
        System.debug('***INSIDE cplUnassignValidateCustomerQueueable');
        System.debug(LoggingLevel.FINEST, '***delCPLMap: ' + delCPLMap);
        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap);

        for (Id priceListId : delCPLMap.keySet()) {
            Map<String, String> tempMap = delCPLMap.get(priceListId);
            Map<String,String> wsParams = new Map<String, String>();
            Map<Id, Account> mapAccount = new Map<Id, Account>();
            
            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{PRICE_LIST_ID}}', tempMap.get('PriceListId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            try {
                request = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Unassign_Validate_Customer', wsParams);
                response = (new http()).send(request);
                System.debug(LoggingLevel.FINEST, '***cplUnassignValidateCustomerQueueable: request: ' + request);
                System.debug(LoggingLevel.FINEST, '***cplUnassignValidateCustomerQueueable : response.getBody(): ' + response.getBody());
                System.debug(LoggingLevel.FINEST, '***cplUnassignValidateCustomerQueueable : response.getStatusCode(): ' + response.getStatusCode());

                String sResponse = response.getBody();

                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(sResponse);
                String statusCode = jsonMap.get('statusCode').toString();
                String statusDescr = jsonMap.get('statusDescription').toString();

                // Get Error Meaning
                String statusMeaning = SM_Utility.pricingAssignmentErrorDescription(statusDescr.toUpperCase());

                System.debug(LoggingLevel.FINEST, '***UnAssign_Validate Get Body: ' + jsonMap);
                System.debug(LoggingLevel.FINEST, '***UnAssign_Validate statusDescription: ' + jsonMap.get('statusDescription'));

                if (response.getStatusCode() == 200 ) {
                    System.debug('***INSIDE Price_List_Unassign_Validate_Customer');                    
                    
                    if (statusCode == 'S' && statusDescr.toUpperCase() == 'VALIDATION SUCCESSFUL') {
                        System.debug('***INSIDE UNASSIGN SUCCESSFUL VALIDATION');
                        System.debug('***statusDescr' + ' - ' + statusDescr.toUpperCase());
                    
                        // Create Application log
                        pricingAssigment_ErrorLogObj.add(
                            SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                                tempMap.get('CustomerId'), 'cplUnassignValidateCustomerQueueable', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusDescr + ' - ' + statusMeaning) 
                        );
                        
                        // Update Account
                        Account acct = new Account();
                        acct.Id = tempMap.get('AccountId');
                        acct.Send_Data_to_CPS__c = false;
                        acct.CPS_Callout_Successful_SpendBand__c = true;
                        mapAccount.put(acct.Id, acct);

                        if (!Test.isRunningTest()) {
                            // Call Unassign Update Queueable
                            System.debug('***cplUnassignUpdateCustomerQueueable enqueued');
                            System.enqueueJob(new cplUnassignUpdateCustomerQueueable(delCPLMap, cplMap));
                        }
                    
                    } else {
                        // Status Code not S
                        // Check if statusCode and statusDescr is valid
                        if (statusCode == '' && statusDescr == '') {
                            statusDescr = 'Request timeout';
                            statusMeaning = 'The Pricing Assignment request took too long to complete and has timed out.';
                        }
                        System.debug(LoggingLevel.FINEST, '***statusDescr: ' + statusDescr + ' / statusMeaning: ' + statusMeaning);
                                                
                        // Update Account - Error message
                        Account acct = new Account();
                        acct.Id = tempMap.get('AccountId');
                        acct.Pricing_Assignment_Error_Code_Descr__c = statusDescr;
                        acct.Pricing_Assignment_Error_Meaning__c = statusMeaning;
                        mapAccount.put(acct.Id, acct);

                        // Create Application log
                        pricingAssigment_ErrorLogObj.add(
                            SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                                tempMap.get('CustomerId'), 'cplUnassignValidateCustomerQueueable', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusMeaning) 
                        );
                    }
                
                } else {
                    // Status Code not 200                                         
                    // Update Account - Error message
                    Account acct = new Account();
                    acct.Id = tempMap.get('AccountId');
                    acct.Pricing_Assignment_Error_Code_Descr__c = String.valueOf(response.getStatusCode());
                    acct.Pricing_Assignment_Error_Meaning__c = response.getStatus();
                    mapAccount.put(acct.Id, acct);

                    // Create Application log
                    pricingAssigment_ErrorLogObj.add(  
                        SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                            tempMap.get('CustomerId'), 'cplAssignUpdateCustomerQueueable', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusDescr + ' - ' + statusMeaning) 
                    );
                }

                if (pricingAssigment_ErrorLogObj.size() > 0) {
                    List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
                    for(Map<String, Object> obj : pricingAssigment_ErrorLogObj) {
                        pricingAssignemtLogs.add(
                            ApplicationLogger.createPricingAssignmentCalloutErrorLog(
                                (String) obj.get('POWERPASSNUMBER'), 
                                (String) obj.get('SOURCEAPEXMETHOD'), 
                                (String) obj.get('CALLOUTTYPE'), 
                                (HttpRequest) obj.get('REQUEST'), 
                                (HttpResponse) obj.get('RESPONSE'), 
                                JSON.serialize((Map<Id, Map<String, String>>) obj.get('RETRYPARAMS')), 
                                (Exception) obj.get('E'),
                                (String) obj.get('ERRORMESSAGE')
                            )
                        );
                    }
                    ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
                }

                if (mapAccount != null && !mapAccount.isEmpty()) {
                    UPDATE mapAccount.values();
                }

            } catch  (System.CalloutException e) {
                System.debug('***Callout Error: ' + e);
                System.debug('***response.toString: '+ response.toString());

                // Update Account and Create application log
                Map<String, Object> fieldsToUpdate = new Map<String, Object>{'Pricing_Assignment_Error_Code_Descr__c' => response.toString(), 'Pricing_Assignment_Error_Meaning__c' => e.toString()};
                Map<String, Object> appLogFields = new Map<String, Object>{'Source__c' => tempMap.get('AccountId'), 'Type__c' => 'Outbound message', 'Source_Type__c' => 'Queueable',
                    'Object_Name__c' => 'Customer_Price_List__c', 'Function_Name__c' => 'cplUnAssignValidateCustomerQueueable', 'Response_Body__c' => response.toString(),
                    'Method__c' => request.getMethod(), 'Endpoint_URL__c' => request.getEndpoint(), 'Error_Message__c' => e.toString()};
                
                if (tempMap.get('AccountId') != null) {
                    if (!Test.isRunningTest())
                        System.enqueueJob(new cplExceptionErrorQueueable(tempMap.get('AccountId'), fieldsToUpdate, appLogFields));
                }
            }
        }        
    }

}