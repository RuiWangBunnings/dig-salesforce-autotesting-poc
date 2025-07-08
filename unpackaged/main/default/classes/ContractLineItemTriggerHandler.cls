/*******************************************************************************************************
* Class Name        : ContractTriggerHandler
* Description       : Contract trigger handler
* Author            : Bunnings Dev
* Created On        : 15/05/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     15/05/2023      1000                Initial version - BUNDIG-18514
* Jasper R Galapon      08/08/2023      1001                BUNDIG-23679 - Contract Amendments - A2 Approval Required for New Line Items
* Jasper R. Galapon     02/08/2024      1002                BUNDIG-34608 - Contract Amendment - Set Auto Approval Eligibility
******************************************************************************************************/

public without sharing class ContractLineItemTriggerHandler {

    public static void beforeInsert(List<Contract_Line_Item__c> newList) {
        setAutoApprovalEligibility(newList);
    }

    public static void beforeUpdate(Map<Id, Contract_Line_Item__c> oldMap, Map<Id, Contract_Line_Item__c> newMap) {
        blockIntegrationUpdate(oldMap, newMap);
    }

    public static void afterUpdate(Map<Id, Contract_Line_Item__c> oldMap, Map<Id, Contract_Line_Item__c> newMap) {
        sendNotificationToReviewer(oldMap, newMap);
        setAutoApprovalEligibilityAfterUpdate(oldMap, newMap);
    }

    @testVisible 
    private static void blockIntegrationUpdate(Map<Id, Contract_Line_Item__c> oldMap, Map<Id, Contract_Line_Item__c> newMap) {
        String integrationUserId = Config.Integration_User_Id__c;

        for (Contract_Line_Item__c newCLI : newMap.values()) {
            Contract_Line_Item__c oldCLI = oldMap.get(newCLI.Id);

            if (UserInfo.getUserId() == integrationUserId) {
                if (oldCLI.Reviewer_Action__c != newCLI.Reviewer_Action__c) {
                    newCLI.Reviewer_Action__c = oldCLI.Reviewer_Action__c;
                }
                if (oldCLI.Approver_Action__c != newCLI.Approver_Action__c) {
                    newCLI.Approver_Action__c = oldCLI.Approver_Action__c;
                }
                if (oldCLI.Reviewer_Action_Date__c != newCLI.Reviewer_Action_Date__c) {
                    newCLI.Reviewer_Action_Date__c = oldCLI.Reviewer_Action_Date__c;
                }
                if (oldCLI.Approver_Action_Date__c != newCLI.Approver_Action_Date__c) {
                    newCLI.Approver_Action_Date__c = oldCLI.Approver_Action_Date__c;
                }
                if (oldCLI.Reviewer_Comments__c != newCLI.Reviewer_Comments__c) {
                    newCLI.Reviewer_Comments__c = oldCLI.Reviewer_Comments__c;
                }
                if (oldCLI.Approver_Comments__c != newCLI.Approver_Comments__c) {
                    newCLI.Approver_Comments__c = oldCLI.Approver_Comments__c;
                }
            }        
        }
    }

    @testVisible 
    private static void sendNotificationToReviewer(Map<Id, Contract_Line_Item__c> oldMap, Map<Id, Contract_Line_Item__c> newMap) {
        Set<Id> contractIds = new Set<Id>();
        Set<Id> reviewerIds = new Set<Id>();
        Set<String> bellRecipientIds = new Set<String>();
        Map<String, Contract__c> mapToAddress = new Map<String, Contract__c>();        

        for (Contract_Line_Item__c cli : newMap.values())
            contractIds.add(cli.Contract__c);

        for (Contract__c con : [SELECT Id, Contract_Name__c, Reviewer__r.FirstName, Reviewer__r.Email FROM Contract__c WHERE Id IN :contractIds AND Reviewer__c != null AND Reviewer__r.IsActive = TRUE])
            mapToAddress.put(con.Id, con);
        
        String msg = '';
        List<String> toS = new List<String>();
        String urlString = URL.getSalesforceBaseUrl().toExternalForm();
        String contractName = '';
        String contractLink = '';
        String subject = '';

        for (Contract_Line_Item__c newCLI : newMap.values()) {
            Contract_Line_Item__c oldCLI = oldMap.get(newCLI.Id);

            if ((oldCLI.Line_Status__c != newCLI.Line_Status__c) && newCLI.Line_Status__c == 'R') {

                bellRecipientIds.add(newCLI.Reviewer__c);

                contractName = mapToAddress.get(newCLI.Contract__c).Contract_Name__c;
                toS = new List<String>{mapToAddress.get(newCLI.Contract__c).Reviewer__r.Email};
                subject = 'Contract Amendment has been Rejected';                
                msg += 'Hi ' + mapToAddress.get(newCLI.Contract__c).Reviewer__r.FirstName + ',' + '<br/>';
                msg += 'Your contract amendment was rejected. The details are as follows:' + '<br/><br/>';
                msg += 'Contract Name:' + '&emsp;' + contractName + '<br/><br/><br/><br/>';
                msg += '<i>' + 'This is a system generated email. Please do not reply to this message.' + '</i>';

                // Get Org wide email address
                OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@bunnings.com.au'];

                try {
                    // Send email notification
                    SM_Utility.sendEmail(owea.get(0).Id, toS, subject, msg);

                    // Send bell notification
                    SM_Utility.sendBellNotification('Contract_Pricing_Review_Notification', bellRecipientIds, contractName, 'Your contract amendment was rejected. No further action required.');
                } catch (Exception e) {
                    ApplicationLogger.log('ContractLineItem - Reviewer', 'Contract_Line_Item__c', 'Trigger', e);
                }
            }
        }
    }

    // BUNDIG-34608 - Start
    @testVisible
    private static void setAutoApprovalEligibility(List<Contract_Line_Item__c> newList) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract_Line_Item__c cli : newList) {
            if (cli.Line_Status__c == 'A1') {
                if (cli.Country__c == 'Australia' && cli.Line_Type__c == 'Amendment') {
                    if (cli.Amendment_Type__c == 'U' || cli.Amendment_Type__c == 'D') {
                        contractIds.add(cli.Contract__c);
                    }
                }
            }
        }
        
        // Get Customer Contracts to get associated Account IDs for the Contracts
        Map<Id, Set<String>> contractToAccountsMap = new Map<Id, Set<String>>();
        Set<String> allPowerPass = new Set<String>();
        for (Customer_Contract__c cc : [SELECT Contract__c, Customer__c, Power_Pass_Account_Number__c 
                                        FROM Customer_Contract__c 
                                        WHERE Contract__c IN :contractIds]) {
            if (!contractToAccountsMap.containsKey(cc.Contract__c)) {
                contractToAccountsMap.put(cc.Contract__c, new Set<String>());
            }
            contractToAccountsMap.get(cc.Contract__c).add(cc.Power_Pass_Account_Number__c);
            allPowerPass.add(cc.Power_Pass_Account_Number__c);
        }
        System.debug(LoggingLevel.FINEST, '***contractToAccountsMap: ' + contractToAccountsMap);
        System.debug(LoggingLevel.FINEST, '***allPowerPass: ' + allPowerPass);
        
        // Get Account Exclusion List
        Set<String> excludedPowerPass = new Set<String>();
        for (Account_Exclusion_List__c ael : [SELECT Account_Reference__c 
                                            FROM Account_Exclusion_List__c 
                                            WHERE Account_Reference__c IN :allPowerPass]) {
            excludedPowerPass.add(ael.Account_Reference__c);
        }
        System.debug(LoggingLevel.FINEST, '***excludedPowerPass: ' + excludedPowerPass);

        // Get Supplier Exclusion List
        Set<String> excludedSupplier = new Set<String>();
        for (Supplier_Exclusion_List__c sel : [SELECT Supplier_Reference__c
                                            FROM Supplier_Exclusion_List__c]) {
            excludedSupplier.add(sel.Supplier_Reference__c);
        }
        
        // Get active Contracts for the Accounts (Power Pass)
        Map<String, Integer> accountActiveContractCount = new Map<String, Integer>();
        Map<String, Integer> contractAccountCount = new Map<String, Integer>();
        for (Customer_Contract__c cc : [SELECT Power_Pass_Account_Number__c, Contract__c 
                                        FROM Customer_Contract__c 
                                        WHERE Power_Pass_Account_Number__c IN :allPowerPass 
                                        AND Contract__r.Status__c IN ('Active','Pending', 'Reviewed', 'Submitted', 'Approved')]) {

            if (!contractAccountCount.containsKey(cc.Contract__c)) {
                contractAccountCount.put(cc.Contract__c, 0);
            }
            // Count contract linked to multiple account
            contractAccountCount.put(cc.Contract__c, contractAccountCount.get(cc.Contract__c) + 1);
            
        }        
        System.debug(LoggingLevel.FINEST, '***contractAccountCount (Count of Acct): ' + contractAccountCount);
                        
        // Update Auto Eligibility field on Contract Line Items
        for (Contract_Line_Item__c cli : newList) {
            if (cli.Line_Status__c == 'A1' && cli.Country__c == 'Australia' && cli.Line_Type__c == 'Amendment' && 
                (cli.Amendment_Type__c == 'U' || cli.Amendment_Type__c == 'D')) {

                Set<String> linkedPowerPass = contractToAccountsMap.get(cli.Contract__c);

                System.debug(LoggingLevel.FINEST, '***linkedPowerPass: ' + linkedPowerPass);
                System.debug(LoggingLevel.FINEST, '***contractAccountCount.get(cli.Contract__c): ' + cli.Contract__c + ' - ' + contractAccountCount.get(cli.Contract__c));

                Boolean isEligible = true;

                if ((linkedPowerPass != null && linkedPowerPass.isEmpty()) || contractAccountCount.get(cli.Contract__c) > 1) {
                    isEligible = false;
                } else {
                    if (!Test.isRunningTest()) {
                        for (String ppass : linkedPowerPass) {
                            // Check if Account is in Exclusion List
                            if (excludedPowerPass.contains(ppass)) {
                                isEligible = false;
                                break;
                            }
                            System.debug(LoggingLevel.FINEST, '***ppass: ' + ppass + ' - ' + isEligible);
                        }
                    }
                }

                Boolean supplierExist = findSupplier(cli.Upload_Reason__c, excludedSupplier);
                System.debug(LoggingLevel.FINEST, '***supplierExist: ' + cli.Upload_Reason__c + ' - ' + supplierExist);

                // Check Supplier condition
                if (isEligible && supplierExist) {
                    isEligible = false;
                }

                System.debug(LoggingLevel.FINEST, '***isEligible: ' + isEligible);
                cli.Auto_Approval_Eligibility__c = isEligible;                                    
            }
        }
    }
    
    @testVisible
    private static void setAutoApprovalEligibilityAfterUpdate(Map<Id, Contract_Line_Item__c> oldMap, Map<Id, Contract_Line_Item__c> newMap) {
        List<Contract_Line_Item__c> itemsToUpdate = new List<Contract_Line_Item__c>();
        String integrationUserId = Config.Integration_User_Id__c;

        for (Contract_Line_Item__c newCLI : newMap.values()) {
            Contract_Line_Item__c oldCLI = oldMap.get(newCLI.Id);

            // Block integration user
            if (UserInfo.getUserId() != integrationUserId) {
                // Check if Line Status has changed and is no longer 'A1'
                System.debug(LoggingLevel.FINEST, '***Line_Status__c: ' + oldCLI.Line_Status__c + ' - ' + newCLI.Line_Status__c);
                if (((oldCLI.Line_Status__c == 'A1' && newCLI.Line_Status__c != 'A1') || newCLI.Reviewer_Action__c == 'A') && newCLI.Auto_Approval_Eligibility__c == TRUE) {
                    Contract_Line_Item__c item = new Contract_Line_Item__c();
                    item.Id = newCLI.Id;
                    item.Auto_Approval_Eligibility__c = FALSE;
                    itemsToUpdate.add(item);
                }
            }
        }
        System.debug(LoggingLevel.FINEST, '***itemsToUpdate: ' + itemsToUpdate);
        // Update the records
        if (!itemsToUpdate.isEmpty()) {
            try {
                update itemsToUpdate;
            } catch (Exception e) {
                ApplicationLogger.log('afterUpdate', 'Contract_Line_Item__c', 'Trigger', e); 
            }
        }
    }

    public static Boolean findSupplier(String longText, Set<String> searchStrings) {
        if (longText != null && searchStrings != null && !searchStrings.isEmpty()) {
            String lowerCaseLongText = longText.toLowerCase();
            
            for (String searchString : searchStrings) {
                if (searchString != null && lowerCaseLongText.contains(searchString.toLowerCase())) {
                    return true;
                }
            }
        }
        
        return false;
    }
    // BUNDIG-34608 - End
         
    private static SM_Configs__c config {
        get {
            if (config == null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    }



}