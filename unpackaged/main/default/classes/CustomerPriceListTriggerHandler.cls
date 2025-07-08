/*******************************************************************************************************
* Class Name        : CustomerPriceListTriggerHandler
* Description       : CustomerPriceList trigger handler
* Author            : Simplus MS
* Created On        : 15/12/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           15/12/2020       1000                Initial version - CCRM-297
* Simplus MS           14/05/2021       2000                modifications CCRM-13728
* Simplus MS           29/06/2021       3000                modifications CCRM-13792
* Simplus MS 		   01/12/2021		4000				modifications CCRM15-478
* Simplus MS		   21/12/2021							For CCRM 15-541, More Errors in Upserting Customer Price List using DataLoader
* Bunnings Dev         20/04/2022       6000                Modifications for SFSUP-371
* Bunnings Dev         17/10/2022       7000                For BUNDIG-11663 Stop replication of customer price list from parent to child accounts
* Jasper R. Galapon    20/12/2023       8000                BUNDIG-28058 - Count of related Active Customer Price List on Account
* Jasper R. Galapon    27/12/2023       9000                BUNDIG-28052 - Pricing Assignment Redesign - API Sequencing
******************************************************************************************************/
public without sharing class CustomerPriceListTriggerHandler {
    /**
    * @description 
    * @author Simplus MS | 15/12/2020 
    * @param oldMap
    **/
    //-- commenting this out since the logic in this is not correct.
    /*
    public static void afterUpdate(Map<Id, Customer_Price_List__c> oldMap, Map<Id, Customer_Price_List__c> newMap){
        Set<Id> acctIds = new Set<Id>();
        Map<String, String> cplMap = new Map<String, String>();

        for(Id cplId : newMap.keySet()){
            acctIds.add(newMap.get(cplId).Account__c);
        }

        List<Account> acctList = [SELECT Power_Pass_Account_Number__c, RecordType.Name, LastModifiedById
                                  FROM Account
                                  WHERE Id IN : acctIds];
        
        String countryCode = '';
        if (String.valueOf(acctList[0].RecordType.Name).startsWith('AU')) {
                countryCode = 'AU';
        }
        else {
                countryCode = 'NZ';
        }

        List<User> userList = [SELECT Team_Member_ID__c from User
                               WHERE Id =: acctList[0].LastModifiedById];


        for(Id cplId : oldMap.keySet()) {
            Customer_Price_List__c oldCPL = oldMap.get(cplId);
            Customer_Price_List__c newCPL = newMap.get(cplId);

            if(oldCPL.Status__c == 'Active' && newCPL.Status__c == 'Inactive'){
                cplMap.put('PriceListId', newMap.get(cplId).Customer_Price_List_ID__c);
                cplMap.put('AccountId' , newMap.get(cplId).Account__c);
                cplMap.put('CustomerId' , acctList[0].Power_Pass_Account_Number__c);
                cplMap.put('CountryCode' , countryCode);
                cplMap.put('TMNumber', userList[0].Team_Member_ID__c);

                SM_CustomerPriceList.invokeCustomerPriceListServiceDeletionAsync(cplMap);
            }
        }
    }
    */

    /**
    * @description after update trigger for BUNDIG-28058
    * @author Jasper R. Galapon | 20/12/2023
    * @param newList
    **/
    public static void afterUpdate(List<Customer_Price_List__c> oldList, List<Customer_Price_List__c> newList) {
        countCustomerPriceListForAccount(newList);
    }
    /**
    * @description after delete trigger for BUNDIG-28058
    * @author Jasper R. Galapon | 20/12/2023
    * @param oldList
    **/
    public static void afterDelete(List<Customer_Price_List__c> oldList) {
        countCustomerPriceListForAccount(oldList);
    }
    
    /**
    * @description after insert trigger for CCRM-13792
    * @author Simplus - Karlo De Leon | 05/07/2021 
    * @param newList 
    **/
    public static void afterInsert(List<Customer_Price_List__c> newList) {
        //CCRM-13792
       // updateChildAccountCPL(null, newList); //For BUNDIG-11663 Stop replication of customer price list from parent to child accounts

        // BUNDIG-28058
        countCustomerPriceListForAccount(newList);
    }

    /** APIs
     * PA flow -> Approval -> 
     *      * 
     * Unassign Validate
     * Unassign Update
     * Assign Validate
     * Assign Update
     * SB2 [1 cpls] - Sb3 [1 cpl]
     * Account Field [Locking]
     */ 
    //CCRM-13728
    public static void handleCPSPricingAssignment(Map<Id, Customer_Price_List__c> oldMap, Map<Id, Customer_Price_List__c> newMap) {
        Set<Id> acctIds = new Set<Id>();
        Map<Id, Map<String, String>> cplMap = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> delCplMap = new Map<Id, Map<String, String>>(); 
        Set<Id> priceListIds = new Set<id>();
        Map<Id, Price_List__c> pricListMap;

        System.debug(LoggingLevel.FINEST,'***handleCPSPricingAssignment - oldMap: ' + oldMap);        
        System.debug(LoggingLevel.FINEST,'***handleCPSPricingAssignment - newMap: ' + newMap);
        
        for(Id cplId : newMap.keySet()){
            acctIds.add(newMap.get(cplId).Account__c); 
            priceListIds.add(newMap.get(cplId).Price_List__c);
        }
        System.debug(LoggingLevel.FINEST,'***newMap.keySet(): ' + newMap.keySet()); 
        
        pricListMap = new Map<Id, Price_List__c>([SELECT Id, Price_List_Header_ID__c
                                                 FROM Price_List__c
                                                 WHERE Id IN :priceListIds]);
     
       System.debug(LoggingLevel.FINEST,'***pricListMap: ' + pricListMap);
      
        List<Account> acctList = [SELECT Id, Power_Pass_Account_Number__c, RecordType.DeveloperName, 
                                  LastModifiedBy.Team_Member_ID__c, Send_Data_to_CPS__c, Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c, Spend_Band__r.Name
                                  FROM Account
                                  WHERE Id IN : acctIds];
        System.debug(LoggingLevel.FINEST,'***acctList: ' + acctList); 
         
        Map<Id,Account> accountMap = new Map<Id,Account>(acctList);
        System.debug(LoggingLevel.FINEST,'***accountMap: ' + accountMap);
        
        List<User> userList = [SELECT Team_Member_ID__c from User
                               WHERE Id =: acctList[0].LastModifiedById];
        System.debug(LoggingLevel.FINEST,'***userList: ' + userList); 

        for(Id cplId : oldMap.keySet()) {
            System.debug(LoggingLevel.FINEST, '***cplId: ' + cplId);

            Customer_Price_List__c oldCPL = oldMap.get(cplId);
            Customer_Price_List__c newCPL = newMap.get(cplId);
            Account acct = accountMap.get(newCPL.Account__c); 
            Price_List__c priceList = pricListMap.get(newCPL.Price_List__c);

            System.debug(LoggingLevel.FINEST, '***priceList: ' + priceList);

            string action = string.isblank(newCPL.Action__c) ? '' : newCPL.Action__c;  
            string assignmentStat = string.isblank(newCPL.Pricing_Assignment_Status__c) ? '' : newCPL.Pricing_Assignment_Status__c; 
            string oldAction = string.isblank(oldCPL.Action__c) ? '' : oldCPL.Action__c; 
            string oldAssignmentStat = string.isblank(oldCPL.Pricing_Assignment_Status__c) ? '' : oldCPL.Pricing_Assignment_Status__c; 

            System.debug(LoggingLevel.FINEST, '***action: ' + action + ' / oldAction: ' + oldAction);
            
            if ((action != oldAction //action changed, or
                 || assignmentStat != oldAssignmentStat //pricing assignment status changed, AND
                ) 
                && assignmentStat=='Submitted to CPS')//after approval - status becomes submitted to CPS
            {
                String countryCode = 'NZ';
                if (String.valueOf(acct.RecordType.DeveloperName).startsWith('AU')) {
                    countryCode = 'AU';
                }       
                  
                System.debug(LoggingLevel.FINEST,'***countryCode: ' + countryCode);

                Map<String, String> paramMap = new Map<String, String>();
                paramMap.put('PriceListId', priceList.Price_List_Header_ID__c); 
                paramMap.put('AccountId' , newCPL.Account__c); 
                paramMap.put('CustomerId' , acct.Power_Pass_Account_Number__c);              
                paramMap.put('CountryCode' , countryCode); 
                // SFSUP-371 - Change reference of Team Member Number from Account Last Modified By to Pricing Assignment Approval Submitter
                //paramMap.put('TMNumber', acct.lastModifiedBy.Team_Member_ID__c);
                String teamMbrId = String.isBlank(acct.Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c) ? '0' : acct.Pricing_Assignment_Approval_Submitter__r.Team_Member_ID__c;
                paramMap.put('TMNumber', teamMbrId);                 
                paramMap.put('CustomerPriceListId', newCPL.Start_Date__c>System.Date.today() ? String.valueOf(cplId) : ''); //14-may: additional item for CCRM-13728   
                
                System.debug(LoggingLevel.FINEST,'***paramMap: ' + paramMap);                
                if (
                    action=='Assignment' //pricing assignment - happens after approval
                    && String.isblank(newCPL.Customer_Price_List_ID__c) //created by salesforce (pricing assignment flow)
                    && acct.Send_Data_to_CPS__c //send data to CPS is checked (happens after approval)
                ) 
                {
                    cplMap.put(newCPL.Price_List__c, paramMap);                  
                }
                else if (
                    action=='Removal' //pricing assignment - happens after approval
                    && !String.isblank(newCPL.Customer_Price_List_ID__c) //created by salesforce (pricing assignment flow)              
                ) 
                {
                    delCplMap.put(newCPL.Price_List__c, paramMap);                    
                }
            }
        }

        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap);
        System.debug(LoggingLevel.FINEST, '***cplMap SERIALIZE: '+JSON.serialize(cplMap));
        System.debug(LoggingLevel.FINEST, '***delCplMap: ' + delCplMap);
        System.debug(LoggingLevel.FINEST, '***delCplMap SERIALIZE: '+JSON.serialize(delCplMap));


        // BUNDIG-28052 - Commented out due to changes in EBS processing
        // if (cplMap!=null && cplMap.size()>0) invokeCustomerPriceListServiceAssignmentAsync(JSON.serialize(cplMap));        
        // if (delCplMap!=null && delCplMap.size()>0) invokeCustomerPriceListServiceDeletionAsync(JSON.serialize(delCplMap));

        //CCRM-13792
        //updateChildAccountCPL(oldMap, newMap.values()); //For BUNDIG-11663 Stop replication of customer price list from parent to child accounts

        // BUNDIG-28052 - New method due to changes in EBS processing
        System.debug(LoggingLevel.FINEST, '***delCPLMap: ' + delCPLMap.size() + ' / ' + delCPLMap);
        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap.size() + ' / ' + cplMap);
        
        if (cplMap.size() > 0 || delCplMap.size() > 0) {
           invokeCPLQueueables(accountMap, JSON.serialize(cplMap), JSON.serialize(delCplMap));
        }
    }
    
    // BUNDIG-26295 - Commented out due to changes in EBS processing
    /*@future(callout=true)
    public static void invokeCustomerPriceListServiceAssignmentAsync(String cplMapText) {
        System.debug('***cplMapText SERIALIZE: '+cplMapText);
        Map<Id, Map<String, String>> cplMap = (Map<id, Map<String, String>>) JSON.deserialize(cplMapText, Map<id, Map<String, String>>.class);        
                
        SM_CustomerPriceList.invokeCustomerPriceListServiceAssignment(cplMap, true);                
    }*/

    // BUNDIG-26295 - Method to call CPL queueables
    public static void invokeCPLQueueables(Map<Id, Account> mapAccount, String cplMapText, String delCPLText) {
        System.debug(LoggingLevel.FINEST, '***cplMapText: ' + cplMapText);        
        System.debug(LoggingLevel.FINEST, '***delCPLText: ' + delCPLText);              

        Map<Id, Map<String, String>> cplMap = (Map<id, Map<String, String>>) JSON.deserialize(cplMapText, Map<id, Map<String, String>>.class);
        Map<Id, Map<String, String>> delCPLMap = (Map<id, Map<String, String>>) JSON.deserialize(delCPLText, Map<id, Map<String, String>>.class);
        
        System.debug('***INSIDE invokeCPLQueueables');
        System.debug(LoggingLevel.FINEST, '***delCPLMap: ' + delCPLMap.size() + ' / ' + delCPLMap);
        System.debug(LoggingLevel.FINEST, '***cplMap: ' + cplMap.size() + ' / ' + cplMap);

        Decimal assignDelay = DM_Initialisation.getCCRMInitialisation().Pricing_Assignment_Assign_Delay__c;
        System.debug(LoggingLevel.FINEST, '***Assign Delay: ' + assignDelay);

        for (Account acc : mapAccount.values()) {
            System.debug(LoggingLevel.FINEST, '***Spend Band: ' + acc.Spend_Band__r.Name);

            Map<Id, Map<String, String>> tmpMap = new Map<Id, Map<String, String>>();

            // Changing Spend Band/Price List
            if (acc.Spend_Band__r.Name != '1' && acc.Spend_Band__r.Name != 'PWR') {
                if (delCPLMap.size() > 0) {
                    Map<String, String> mapInner = new Map<String, String>();

                    for (Id delCPLMapId : delCPLMap.keySet()) {
                        mapInner = delCPLMap.get(delCPLMapId);
                        System.debug(LoggingLevel.FINEST, '***cplMap Inner: ' + mapInner);
                        tmpMap.put(delCPLMapId, mapInner);

                        System.debug(LoggingLevel.FINEST, '***Removing Customer Price List: ' + delCPLMapId);
                        System.enqueueJob(new cplUnassignValidateCustomerQueueable(tmpMap, null));
                        mapInner.clear();
                    }
                }

                tmpMap.clear();
                if (cplMap.size() > 0) {
                    Map<String, String> mapInner = new Map<String, String>();

                    for (Id cplMapId : cplMap.keySet()) {
                        mapInner = cplMap.get(cplMapId);
                        System.debug(LoggingLevel.FINEST, '***cplMap Inner: ' + mapInner);
                        tmpMap.put(cplMapId, mapInner);

                        System.debug(LoggingLevel.FINEST, '***Adding Customer Price List: ' + cplMapId);
                        System.enqueueJob(new cplAssignValidateCustomerQueueable(tmpMap), Integer.valueOf(assignDelay));
                        mapInner.clear();
                    }
                }                
            } else {
                // Upgrade Spend Band from 1/PWR - New Accounts
                if (delCPLMap.size() == 0 && cplMap.size() > 0) {
                    Map<String, String> mapInner = new Map<String, String>();

                    for (Id cplMapId : cplMap.keySet()) {
                        mapInner = cplMap.get(cplMapId);
                        System.debug(LoggingLevel.FINEST, '***cplMap Inner: ' + mapInner);
                        tmpMap.put(cplMapId, mapInner);

                        System.debug(LoggingLevel.FINEST, '***Upgrade Spend Band from 1/PWR: ' + cplMapId);
                        System.enqueueJob(new cplAssignValidateCustomerQueueable(tmpMap));
                        mapInner.clear();
                    }
                }
            }
        }
                        
    }
    
    // BUNDIG-26295 - Commented out due to changes in EBS processing
    /*@future(callout=true)
    public static void invokeCustomerPriceListServiceDeletionAsync(String cplMapText) {
        Set<Id> idsToDelete = new Set<id>();
        List<Customer_Price_List__c> cplsToDelete = new List<Customer_Price_List__c>();
        Map<Id, Map<String, String>> cplMap = (Map<id, Map<String, String>>) JSON.deserialize(cplMapText, Map<id, Map<String, String>>.class);
        SM_CustomerPriceList.invokeCustomerPriceListServiceDeletion(cplMap, true);
    }*/
    
    /**
    * @description Update CPL from child accounts for CCRM-13792
    * @author Simplus - Karlo De Leon | 01/07/2021 
    * @param oldList 
    * @param newList 
    **/
    //For BUNDIG-11663 Stop replication of customer price list from parent to child accounts
    /*public static void updateChildAccountCPL(Map<Id,Customer_Price_List__c> oldList, List<Customer_Price_List__c> newList) {
        
        if (newList.isEmpty()){
            return;
        }
        
        Map<Id,Customer_Price_List__c> newCPLMap = new Map<Id,Customer_Price_List__c>(newList);
        Map<Id,Id> childParentIdMap = new Map<Id,Id>();
        Map<Id,List<Customer_Price_List__c>> acctIds = new Map<Id,List<Customer_Price_List__c>>(); //FOR UPDATE: OLDLIST GROUPED BY ACCOUNT || FOR INSERT: SET OF PARENT ACCOUNTS
        Map<Id, List<Customer_Price_List__c>> existingChildCPLs = new Map<Id, List<Customer_Price_List__c>>(); //FOR UPDATE: Map<ParentAccount, List<ChildCPL>>>
        List<Customer_Price_List__c> lstCPL = new List<Customer_Price_List__c>(); //CPL FOR UPDATE OR INSERT
        List<Customer_Price_List__c> childCPL = new List<Customer_Price_List__c>();
        
        if (oldList <> null) { //FOR UPDATED ACTIVE AND FUTURE CPLs
            for (Customer_Price_List__c row : newList) {
                Customer_Price_List__c cpl = new Customer_Price_List__c();
                cpl = oldList.get(row.Id);
                if (cpl != null && cpl.Account__c != null){ //Added null checker for CCRM15-478
                    if ((cpl.Start_Date__c > System.today() || cpl.Status__c == 'Active')) {
                        acctIds.put(cpl.Account__c, new List<Customer_Price_List__c>()); 
                    }
                    if(acctIds != null && !acctIds.isEmpty() && acctIds.containsKey(cpl.Account__c)){ //Added map containsKey checker for CCRM15-478
                        acctIds.get(cpl.Account__c).add(cpl); 
                    }
                          
                }
            }

            if (acctIds.size() > 0) {
                existingChildCPLs = retrieveChildCPL(acctIds);
                
                if (existingChildCPLs.size() > 0) {
                    System.debug('Parent List Size>> '+newList.size()+' newList' +newList);
                    
                    for (Customer_Price_List__c cplNewVer : newList) { 
                        if (existingChildCPLs.containsKey(cplNewVer.Account__c)){
                            childCPL = existingChildCPLs.get(cplNewVer.Account__c);
                        }
                    }
                    
                        //Added empty list checker for CCRM15-478
                        if (childCPL != null && !childCPL.isEmpty()){
                            //Create a map of child and parent Ids for CCRM 15-541
                             for (Customer_Price_List__c cplRow : childCPL) {
                                 childParentIdMap.put(cplRow.Id,cplRow.Parent_CPL__c);
                             }
                            System.debug('Child And Parent Id Map>> '+childParentIdMap);
                            
                            
                            for (Customer_Price_List__c cplRow : childCPL) {
                                Customer_Price_List__c cplOldVer = new Customer_Price_List__c();
                                Customer_Price_List__c cplNewVer = new Customer_Price_List__c();
                                cplOldVer = oldList.get(childParentIdMap.get(cplRow.Id));//for CCRM 15-541
                                cplNewVer = newCPLMap.get(childParentIdMap.get(cplRow.Id));//for CCRM 15-541
                                System.debug('cplOldVer '+cplOldVer);
                                System.debug('cplNewVer '+cplNewVer);
                                if (cplOldVer != null){
                                    if (cplOldVer.Status__c != null && cplRow.Status__c != null){
                                        if (//cplOldVer.Start_Date__c == cplRow.Start_Date__c &&
                                            cplOldVer.End_Date__c == cplRow.End_Date__c &&
                                            cplOldVer.Status__c == cplRow.Status__c &&
                                            cplOldVer.Change_Requested_On__c == cplRow.Change_Requested_On__c &&
                                            cplOldVer.Action__c == cplRow.Action__c &&
                                            cplOldVer.Pricing_Assignment_Status__c == cplRow.Pricing_Assignment_Status__c) {
                                                /*
                                                    * FOR CLARIFICATION SINCE START DATE ON CHILD ACCOUNT DEPENDS ON THE DATE WHEN THE CONTRACT GROUP WAS UPDATED
                                                    if (cplNewVer.Start_Date__c != cplOldVer.Start_Date__c) {
                                                    cplRow.Start_Date__c = cplNewVer.Start_Date__c;
                                                    }*/
                                                /*if (cplNewVer.End_Date__c != cplOldVer.End_Date__c) {
                                                    cplRow.End_Date__c = cplNewVer.End_Date__c;
                                                }
                                                if (cplNewVer.Status__c != cplOldVer.Status__c) {
                                                    cplRow.Status__c = cplNewVer.Status__c;
                                                }
                                                if (cplNewVer.Change_Requested_On__c != cplOldVer.Change_Requested_On__c) {
                                                    cplRow.Change_Requested_On__c = cplNewVer.Change_Requested_On__c;
                                                }
                                                if (cplNewVer.Action__c != cplOldVer.Action__c) {
                                                    cplRow.Action__c = cplNewVer.Action__c;
                                                }
                                                if (cplNewVer.Pricing_Assignment_Status__c != cplOldVer.Pricing_Assignment_Status__c) {
                                                    cplRow.Pricing_Assignment_Status__c = cplNewVer.Pricing_Assignment_Status__c;
                                                }
                                                lstCPL.add(cplRow);
                                            }
                                    }
                                }
                            }
                        }
                }
            }
            if (lstCPL.size() > 0) {
                System.debug('List to update '+lstCPL.size()+' '+lstCPL);
                //Added try catch for CCRM15-478
                try {
                    UPDATE lstCPL;
                } catch(Exception e) {
                    ApplicationLogger.log('CustomerPriceListTriggerHandler.updateChildAccountCPL', 'Customer_Price_List__c', 'Trigger', e);
                }
                
            }
        } else { //FOR NEW CPLs
            List<Account> childAccts = new List<Account>();
            for (Customer_Price_List__c row : newList) {
                if ((row.Start_Date__c > System.today() || row.Status__c == 'Active')) {
                    acctIds.put(row.Account__c, null);
                }
            }
            if (acctIds.size() > 0) {
                for (Account rowAcct : retrieveChildAccounts(new List<Id>(acctIds.keySet()))) {
                    for (Customer_Price_List__c rowCPL : newList) {
                        lstCPL.add(new Customer_Price_List__c(Account__c = rowAcct.Id,
                                                              Action__c = rowCPL.Action__c,
                                                              Change_Requested_On__c = rowCPL.Change_Requested_On__c,
                                                              CreatedById = rowCPL.CreatedById,
                                                              Customer_Price_List_ID__c = null, //row.Customer_Price_List_ID__c,
                                                              End_Date__c = rowCPL.End_Date__c,
                                                              LastModifiedById = rowCPL.LastModifiedById,
                                                              Price_List__c = rowCPL.Price_List__c,
                                                              Pricing_Assignment_Status__c = rowCPL.Pricing_Assignment_Status__c,
                                                              Start_Date__c = rowCPL.Start_Date__c,
                                                              Status__c = rowCPL.Status__c,
                                                              Parent_CPL__c = rowCPL.Id));
                    }
                }
            }
            
            if (lstCPL.size() > 0) {
                //Added try catch for CCRM15-478
                try {
                    INSERT lstCPL;
                } catch(Exception e) {
                    ApplicationLogger.log('CustomerPriceListTriggerHandler.updateChildAccountCPL', 'Customer_Price_List__c', 'Trigger', e);
                }
            }
        }
    }*/
    
    /**
    * @description Retrieves all CPL per child account
    * @author Simplus - Karlo De Leon | 29/06/2021 
    * @param acctIds
    **/
    //For BUNDIG-11663 Stop replication of customer price list from parent to child accounts
    /*public static Map<Id, List<Customer_Price_List__c>> retrieveChildCPL(Map<Id,List<Customer_Price_List__c>> acctIds) {
        Map<Id, List<Customer_Price_List__c>> mapCPL = new Map<Id, List<Customer_Price_List__c>>();
        List<Customer_Price_List__c> lstCPL = new List<Customer_Price_List__c>([SELECT Id, Account__r.Id, Account__r.Contract_Group__c, Action__c, Change_Requested_On__c, 
                                                                                CreatedById, End_Date__c, 
                                                                                LastModifiedById, Name, Price_List__c, Pricing_Assignment_Status__c, 
                                                                                Start_Date__c, Status__c, Parent_CPL__c
                                                                                FROM Customer_Price_List__c
                                                                                WHERE Account__r.Contract_Group__c IN : acctIds.keySet() AND
                                                                                (Status__c = 'Active' OR Start_Date__c > TODAY)]);
        System.debug('Child List Size '+lstCPL.size()+' lstCPL '+lstCPL);
        for (Customer_Price_List__c row : lstCPL) {
            List<Customer_Price_List__c> cpl = acctIds.get(row.Account__r.Contract_Group__c);
            for (Customer_Price_List__c reference : cpl) {
                if (//reference.Start_Date__c == row.Start_Date__c &&
                    reference.End_Date__c == row.End_Date__c &&
                    reference.Status__c == row.Status__c &&
                    reference.Change_Requested_On__c == row.Change_Requested_On__c &&
                    reference.Action__c == row.Action__c &&
                    reference.Pricing_Assignment_Status__c == row.Pricing_Assignment_Status__c) {
                        if (!mapCPL.containsKey(row.Account__r.Contract_Group__c)) {
                            mapCPL.put(row.Account__r.Contract_Group__c, new List<Customer_Price_List__c>());
                        }
                        mapCPL.get(row.Account__r.Contract_Group__c).add(row);
                    }
            }
        }
        return mapCPL;
    }*/
    
    /**
    * @description Retrieves all child account
    * @author Simplus - Karlo De Leon | 05/07/2021 
    * @param acctIds
    **/
    //For BUNDIG-11663 Stop replication of customer price list from parent to child accounts
   /* public static List<Account> retrieveChildAccounts(List<Id> acctIds) {
        return [SELECT Id FROM Account WHERE Contract_Group__c IN : acctIds];
    }*/

    // BUNDIG-28058
    public static void countCustomerPriceListForAccount(List<Customer_Price_List__c> cplList) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Integer> accountRecordCountMap = new Map<Id, Integer>();
        
        for (Customer_Price_List__c cpl : cplList) {
            if (cpl.CPL_Status__c == 'Active') {
                accountIds.add(cpl.Account__c);
            }
        }
        for (AggregateResult aggregateResult : [SELECT Account__c, COUNT(Id) cplCount
            FROM Customer_Price_List__c WHERE Account__c IN :accountIds
            AND CPL_Status__c = 'Active'
            GROUP BY Account__c]) {
                Id parentId = (Id) aggregateResult.get('Account__c');
                Integer intCount = (Integer) aggregateResult.get('cplCount');
                // Don't count if only 1 Price List is present
                if (intCount > 1)
                    accountRecordCountMap.put(parentId, intCount);
        }
        List<Account> acctToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            Account acct = new Account(Id = accountId, Duplicate_Active_Customer_Price_List__c = accountRecordCountMap.get(accountId));
            acctToUpdate.add(acct);
        }
        update acctToUpdate;
    }

}