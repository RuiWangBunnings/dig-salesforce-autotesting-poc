/*******************************************************************************************************
* Class Name        : cplUnassignUpdateCustomerQueueable
* Description       : Customer Price List Queueable Unassign Update Customer
*                   : This also calls cplAssignValidateCustomerQueueable
* Author            : Jasper R. Galapon
* Created On        : 02/1/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          02/1/2024       1000                BUNDIG-26295 - Initial version
******************************************************************************************************/

public class cplUnassignUpdateCustomerQueueable implements Queueable, Database.AllowsCallouts {
    private Map<Id, Map<String, String>> delCPLMap;
    private Map<Id, Map<String, String>> cplMap;

    public cplUnassignUpdateCustomerQueueable(Map<Id, Map<String, String>> delCPLMap, Map<Id, Map<String, String>> cplMap) {
        this.delCPLMap = delCPLMap;
        this.cplMap = cplMap;
    }

    public void execute(QueueableContext context) {
        List<Map<String, Object>> pricingAssigment_ErrorLogObj = new List<Map<String, Object>>();

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();

        System.debug('***cplUnassignUpdateCustomerQueueable');
        System.debug(LoggingLevel.FINEST, '***delCPLMap: ' + delCPLMap);
        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap);

        for (Id priceListId : delCPLMap.keySet()) {
            Map<Id, Account> mapAccount = new Map<Id, Account>();
            Map<String, String> tempMap = delCPLMap.get(priceListId);
            Map<String,String> wsParams = new Map<String, String>();
            
            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{PRICE_LIST_ID}}', tempMap.get('PriceListId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            try {
                request = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Unassign_Update_Customer', wsParams);
                response = (new http()).send(request);
                System.debug(LoggingLevel.FINEST, '***request: ' + request);
                System.debug(LoggingLevel.FINEST, '***response.getBody(): ' + response.getBody());
                System.debug(LoggingLevel.FINEST, '***resonse.getStatusCode(): ' + response.getStatusCode());

                String sResponse = response.getBody();

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(sResponse);
                String statusCode = responseMap.get('statusCode').toString();
                String statusDescr = responseMap.get('statusDescription').toString();
                System.debug(LoggingLevel.FINEST, '***statusResponse: ' + statusCode + ' / ' + statusDescr);

                // Get Error Meaning
                String statusMeaning = SM_Utility.pricingAssignmentErrorDescription(statusDescr.toUpperCase());

                if (response.getStatusCode() == 200) {
                    System.debug('***INSIDE Successful Unassign Update Customer');
                    
                    if (statusCode == 'S' && statusDescr.toUpperCase() == 'CUSTOMER UNASSIGNED FROM PRICELIST') {
                        
                        // Create Application log
                        pricingAssigment_ErrorLogObj.add(
                            SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                                tempMap.get('CustomerId'), 'cplUnassignUpdateCustomerQueueable', 'Unassign_Update', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusDescr + ' - ' + statusMeaning) 
                        );

                        if (!Test.isRunningTest()) {
                            if (cplMap != null) {
                                System.debug(LoggingLevel.FINEST, '***Inside cplUnassignUpdateCustomerQueueable cplMap: ' + cplMap.size());
                                if (cplMap.size() > 0) {
                                    // Call Assign Validate Queueable
                                    System.debug('***cplAssignValidateCustomerQueueable enqueued');
                                    System.enqueueJob(new cplAssignValidateCustomerQueueable(cplMap));
                                }
                            }
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
                                tempMap.get('CustomerId'), 'cplUnassignUpdateCustomerQueueable', 'Unassign_Update', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusMeaning) 
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
                            tempMap.get('CustomerId'), 'cplUnassignUpdateCustomerQueueable', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusDescr + ' - ' + statusMeaning) 
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

                System.debug(LoggingLevel.FINEST, '***mapAccount.values(): ' + mapAccount.values());
                if (mapAccount != null && !mapAccount.isEmpty()) {
                    UPDATE mapAccount.values();
                } 
            
            } catch (System.CalloutException e) {
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