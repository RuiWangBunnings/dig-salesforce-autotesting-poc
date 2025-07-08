/*******************************************************************************************************
* Class Name        : cplAssignValidateCustomerQueueable
* Description       : Customer Price List Queueable Assign Validate Customer
*                   : This also calls Assign_Update
* Author            : Jasper R. Galapon
* Created On        : 14/12/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          14/12/2023      1000                BUNDIG-26295 - Initial version
******************************************************************************************************/

public class cplAssignValidateCustomerQueueable implements Queueable, Database.AllowsCallouts {
    private Map<Id, Map<String, String>> cplMap;    

    public cplAssignValidateCustomerQueueable(Map<Id, Map<String, String>> cplMap) {
        this.cplMap = cplMap;
    }

    public void execute(QueueableContext context) {
        List<Map<String, Object>> pricingAssigment_ErrorLogObj = new List<Map<String, Object>>();

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();

        System.debug('***cplAssignValidateCustomerQueueable');
        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap);

       for (Id priceListId : cplMap.keySet()) {        

            Map<String, String> tempMap = cplMap.get(priceListId);          
            Map<String, String> wsParams = new Map<String, String>();
            Map<Id, Account> mapAccount = new Map<Id, Account>();
            
            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{PRICE_LIST_ID}}', tempMap.get('PriceListId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            System.debug(LoggingLevel.FINEST, '***Request Param: '+tempMap.get('CountryCode') + ' / ' + tempMap.get('PriceListId') + ' / ' + tempMap.get('CustomerId') + ' / ' + tempMap.get('TMNumber'));          
            System.debug(LoggingLevel.FINEST, '***Request: '+request);

            try {
                request = SM_WSHelper.buildHttpRequestFromWSDef('Price_List_Assign_Validate_Customer', wsParams); 
                response = (new http()).send(request); 

                System.debug(LoggingLevel.FINEST, '***request: ' + request);
                System.debug(LoggingLevel.FINEST, '***response.getBody(): ' + response.getBody());
                System.debug(LoggingLevel.FINEST, '***response.getStatusCode(): ' + response.getStatusCode());
                
                if (response.getStatusCode() == 200) {
                    System.debug('*** Inside 1st API Callout success - Price_List_Assign_Validate_Customer ' + tempMap.get('PriceListId') );

                    String sResponse = response.getBody();

                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(sResponse);
                    String statusCode = jsonMap.get('statusCode').toString();
                    String statusDescr = jsonMap.get('statusDescription').toString();

                    // Get Error Meaning
                    String statusMeaning = SM_Utility.pricingAssignmentErrorDescription(statusDescr.toUpperCase());

                    System.debug(LoggingLevel.FINEST, '***Assign_Validate Get Body: ' + jsonMap);
                    System.debug(LoggingLevel.FINEST, '***Assign_Validate statusDescription: ' + jsonMap.get('statusDescription'));

                    // Assign validate is successful
                    if (statusCode == 'S' && statusDescr.toUpperCase() == 'SUCCESSFULL VALIDATION OF CUSTOMER ASSIGNMENT TO PRICELIST') {
                        System.debug('***INSIDE SUCCESSFUL VALIDATION');
                    
                        // Create Application log
                        pricingAssigment_ErrorLogObj.add(
                            SM_Utility.mapFieldsForPricingAssignmentErrorLog(
                                tempMap.get('CustomerId'), 'cplAssignValidateCustomerQueueable', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusDescr + ' - ' + statusMeaning) 
                        );
                        
                        // Update Account
                        Account acct = new Account();
                        acct.Id = tempMap.get('AccountId');
                        acct.Send_Data_to_CPS__c = false;
                        acct.CPS_Callout_Successful_SpendBand__c = true;
                        mapAccount.put(acct.Id, acct);

                        // Call Assign Update Queueable
                        if (!Test.isRunningTest())
                            System.enqueueJob(new cplAssignUpdateCustomerQueueable(cplMap));

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
                                tempMap.get('CustomerId'), 'cplAssignValidateCustomerQueueable', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, statusMeaning) 
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
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.cplAssignValidateCustomerQueueable', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{priceListId => tempMap}, null, null) 
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

            } catch (Exception e) {
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