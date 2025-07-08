/*******************************************************************************************************
* Class Name      	: SM_CustomerFamilyTreeDiscount
* Description		: Domain / Service layer for Customer Family Tree Discount
* Author          	: Bunnings Dev
* Created On      	: 21/02/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     21/02/2023		1000				Initial version - BUNDIG-14164
******************************************************************************************************/

public class SM_CustomerFamilyTreeDiscount {

    public static void invokeCustomerFamilyTreeDiscountServiceServiceAssignment(Map<Id, Map<String, String>> cftdMap) {
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();

        List<Map<String, Object>> ftdLogObjects = new List<Map<String, Object>>();
        Map<Id, Account> mapAccount = new Map<Id, Account>();

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        HttpRequest updateRequest = new HttpRequest();
        HttpResponse updateResponse = new HttpResponse();

        for (Id cftdId : cftdMap.keySet()) {
            Map<String, String> tempMap = cftdMap.get(cftdId);
            Map<String,String> wsParams = new Map<String, String>();            

            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{FAMILY_TREE_DISCOUNT_ID}}', tempMap.get('FamilyTreeDiscountId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            System.debug('***Request Param: '+tempMap.get('CountryCode') + ' / ' + tempMap.get('FamilyTreeDiscountId') + ' / ' + tempMap.get('CustomerId') + ' / ' + tempMap.get('TMNumber'));

            request = SM_WSHelper.buildHttpRequestFromWSDef('Family_Tree_Assign_Validate_Customer', wsParams);
            System.debug('***CFTD Validate Request: '+request);

            try {
                response = (new http()).send(request);
                System.debug('***FTD VALIDATE CUSTOMER - response.getBody(): '+response.getBody());
                System.debug('***FTD VALIDATE CUSTOMER - response.getStatusCode(): '+response.getStatusCode());

                if (response.getStatusCode() == 200) {
                    System.debug('*** FTD VALIDATE CUSTOMER SUCCESSFULL');

                    updateRequest = SM_WSHelper.buildHttpRequestFromWSDef('Family_Tree_Assign_Update_Customer', wsParams);
                    System.debug('***CFTD Update Request: '+updateRequest);

                    updateResponse = (new http()).send(updateRequest);
                    System.debug('***FTD UPDATE CUSTOMER - updateResponse.getBody(): '+updateResponse.getBody());
                    System.debug('***FTD UPDATE CUSTOMER - updateResponse.getStatusCode(): '+updateResponse.getStatusCode());

                    ftdLogObjects.add(mapFieldsFTDLog(
                        tempMap.get('CustomerId'), 'SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceAssignment', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                    );

                    if (updateResponse.getStatusCode() == 200) {
                        System.debug('*** FTD UPDATE CUSTOMER SUCCESSFULL');

                        // Update Account
                        Account acct = new Account();
                        acct.Id = tempMap.get('AccountId');
                        acct.Send_Data_to_CPS__c = false;
                        acct.CPS_Callout_Successful_SpendBand__c = true;
                        mapAccount.put(acct.Id, acct);
                        
                        ftdLogObjects.add(mapFieldsFTDLog(
                            tempMap.get('CustomerId'), 'SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceAssignment', 'Assign_Update', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                        );
                    }

                    if (updateResponse.getStatusCode() == 400 || updateResponse.getStatusCode() == 401 || response.getStatusCode() == 202 || response.getStatusCode() == 404 || response.getStatusCode() == 500) {
                        maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                            'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});
                                                    
                        ftdLogObjects.add(mapFieldsFTDLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCFTDiscountServiceAssignment', 'Assign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                        );
                    }
                    
                } else if (response.getStatusCode() == 400 ||response.getStatusCode() == 401 || response.getStatusCode() == 202 || response.getStatusCode() == 404 || response.getStatusCode() == 500) {                                        
                    maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                        'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});
                    
                    ftdLogObjects.add(mapFieldsFTDLog(
                        tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCFTDiscountServiceAssignment', 'Assign_Validate', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                    );
                }

            } catch (Exception err) {
                maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                    'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});

                ftdLogObjects.add(mapFieldsFTDLog(
                    tempMap.get('CustomerId'), 'SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceAssignment', 'Assign_Exception', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, err)
                );
            }
        }

        if (maptoSerialize != null && !maptoSerialize.isEmpty()) {
            System.debug('***maptoSerialize: ' +maptoSerialize);

            ApplicationLogger.logCalloutException('SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceAssignment', 
                request, response, JSON.serialize(maptoSerialize), 'Account','Trigger',null);
        }
        
        if (ftdLogObjects.size() > 0) {
            List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
            for(Map<String, Object> obj : ftdLogObjects) {
                pricingAssignemtLogs.add(ApplicationLogger.createPricingAssignmentCalloutLog(
                    (String) obj.get('powerpassNumber'), 
                    (String) obj.get('sourceApexMethod'), 
                    (String) obj.get('calloutType'), 
                    (HttpRequest) obj.get('request'), 
                    (HttpResponse) obj.get('response'), 
                    JSON.serialize((Map<Id, Map<String, String>>) obj.get('retryParams')), 
                    (Exception) obj.get('e')
                ));
            }
            System.debug('***pricingAssignemtLogs: '+pricingAssignemtLogs);

            ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
        }

        if (mapAccount != null && !mapAccount.isEmpty()) {
            UPDATE mapAccount.values();
        }        
    }

    public static void invokeCustomerFamilyTreeDiscountServiceDeletion(Map<Id, Map<String, String>> cftdMap) {
        Map<Id, Map<String, String>> maptoSerialize = new Map<Id, Map<String, String>>();

        List<Map<String, Object>> ftdLogObjects = new List<Map<String, Object>>();
        Map<Id, Account> mapAccount = new Map<Id, Account>();

        System.debug('***DELETION cftdMap: ' + JSON.serializePretty(cftdMap));

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        HttpRequest updateRequest = new HttpRequest();
        HttpResponse updateResponse = new HttpResponse();

        for (Id cftdId : cftdMap.keySet()) {
            Map<String, String> tempMap = cftdMap.get(cftdId);
            Map<String,String> wsParams = new Map<String, String>();
                        
            wsParams.put('{{COUNTRY_CODE}}', tempMap.get('CountryCode'));
            wsParams.put('{{FAMILY_TREE_DISCOUNT_ID}}', tempMap.get('FamilyTreeDiscountId'));
            wsParams.put('{{CUST_ID}}', tempMap.get('CustomerId'));
            wsParams.put('{{TM_NUMBER}}', tempMap.get('TMNumber'));

            System.debug('***Request Param: '+tempMap.get('CountryCode') + ' / ' + tempMap.get('FamilyTreeDiscountId') + ' / ' + tempMap.get('CustomerId') + ' / ' + tempMap.get('TMNumber'));

            request = SM_WSHelper.buildHttpRequestFromWSDef('Family_Tree_Unassign_Validate_Customer', wsParams);

            try {
                response = (new http()).send(request);
                System.debug('***CFTD VALIDATE CUSTOMER - response.getBody(): '+response.getBody());
                System.debug('***CFTD VALIDATE CUSTOMER - response.getStatusCode(): '+response.getStatusCode());

                if (response.getStatusCode() == 200) {
                    System.debug('***CFTD VALIDATE CUSTOMER SUCCESSFULL');

                    updateRequest = SM_WSHelper.buildHttpRequestFromWSDef('Family_Tree_Unassign_Update_Customer', wsParams);
                    System.debug('***CFTD Update Request: '+updateRequest);

                    updateResponse = (new http()).send(updateRequest);
                    System.debug('***CFTD UPDATE CUSTOMER - updateResponse.getBody(): '+updateResponse.getBody());
                    System.debug('***CFTD UPDATE CUSTOMER - updateResponse.getStatusCode(): '+updateResponse.getStatusCode());

                    if (updateResponse.getStatusCode() == 200) {
                        System.debug('***CFTD UPDATE CUSTOMER SUCCESSFULL');

                        // Update Account
                        Account acct = new Account();
                        acct.Id = tempMap.get('AccountId');
                        acct.Send_Data_to_CPS__c = false;
                        acct.CPS_Callout_Successful_SpendBand__c = true;
                        mapAccount.put(acct.Id, acct);
                        
                        ftdLogObjects.add(mapFieldsFTDLog(
                            tempMap.get('CustomerId'), 'SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceDeletion', 'Unassign_Update', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                        );
                    } else if (updateResponse.getStatusCode() == 400 || updateResponse.getStatusCode() == 401 || response.getStatusCode() == 202 || response.getStatusCode() == 404 || response.getStatusCode() == 500) {
                        maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                            'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});
                                                    
                        ftdLogObjects.add(mapFieldsFTDLog(
                            tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCFTDiscountServiceDeletion', 'Unassign_Update', updateRequest, updateResponse, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                        );
                    }
                } else if (response.getStatusCode() == 400 ||response.getStatusCode() == 401 || response.getStatusCode() == 202 || response.getStatusCode() == 404 || response.getStatusCode() == 500) {                                        
                    maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                        'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});
                    
                    ftdLogObjects.add(mapFieldsFTDLog(
                        tempMap.get('CustomerId'), 'SM_CustomerPriceList.invokeCFTDiscountServiceDeletion', 'Unassign_Validate', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, null)
                    );
                }

            } catch (Exception err) {
                maptoSerialize.put(cftdId, new Map<String, String>{'CustomerId' => tempMap.get('CustomerId'), 'FamilyTreeDiscountId' => tempMap.get('FamilyTreeDiscountId'),
                    'AccountId' => tempMap.get('AccountId'), 'TMNumber' => tempMap.get('TMNumber'), 'CountryCode' => tempMap.get('CountryCode')});

                ftdLogObjects.add(mapFieldsFTDLog(
                    tempMap.get('CustomerId'), 'SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceDeletion', 'Unassign_Exception', request, response, new Map<Id, Map<String, String>>{cftdId => tempMap}, err)
                );
            }
        }

        if (maptoSerialize != null && !maptoSerialize.isEmpty()) {
            System.debug('***maptoSerialize: ' +maptoSerialize);

            ApplicationLogger.logCalloutException('SM_CustomerFamilyTreeDiscount.invokeCFTDiscountServiceAssignment', 
                request, response, JSON.serialize(maptoSerialize), 'Account','Trigger',null);
        }
        
        if (ftdLogObjects.size() > 0) {
            List<ApplicationLog__c> pricingAssignemtLogs = new List<ApplicationLog__c>();
            for(Map<String, Object> obj : ftdLogObjects) {
                pricingAssignemtLogs.add(ApplicationLogger.createPricingAssignmentCalloutLog(
                    (String) obj.get('powerpassNumber'), 
                    (String) obj.get('sourceApexMethod'), 
                    (String) obj.get('calloutType'), 
                    (HttpRequest) obj.get('request'), 
                    (HttpResponse) obj.get('response'), 
                    JSON.serialize((Map<Id, Map<String, String>>) obj.get('retryParams')), 
                    (Exception) obj.get('e')
                ));
            }
            System.debug('***pricingAssignemtLogs: '+pricingAssignemtLogs);

            ApplicationLogger.insertApplicationLogs(pricingAssignemtLogs);
        }
        if (mapAccount != null && !mapAccount.isEmpty()) {
            UPDATE mapAccount.values();
        }
        
    }

    private static Map<String, Object> mapFieldsFTDLog(String powerpassNumber, String sourceApexMethod, String calloutType, HttpRequest request, HttpResponse response, Map<Id, Map<String, String>> cplMap, Exception err) {
        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('powerpassNumber', powerpassNumber);
        tempMap.put('sourceApexMethod', sourceApexMethod);
        tempMap.put('calloutType', calloutType);
        tempMap.put('request', request);
        tempMap.put('response', response);
        tempMap.put('mapToSerialize', cplMap);
        tempMap.put('retryParams', cplMap);
        tempMap.put('err', err);

        return tempMap;
    }
    
}