/*******************************************************************************************************
* Class Name      	: SM_ContractReview
* Description		: Service layer for contract review epic.
* Author          	: Simplus - Yi Zhang
* Created On      	: 21/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              21/05/2020		1000				Initial version
* Philip Clark			01/07/2020		1001				Contract Delegated Approval (Moved to SM_Contract)
* Simplus MS            05/02/2021      1002                CCRM-8664 - Validation added to display error to user when Status is Pending & ContractApprovalStatus is Customer Rejected.
* Simplus MS 			01/06/2021		1003				CCRM-13835 - Fix added to only allow view the contract review of Amendement if the user is either Approver or Reviewer
* Simplus Ms            2022-02-24		1004			    Logic added for SFSUP-361 - Contract review - History comment from A1 & A2
* Jasper R. Galapon     5/04/2023       1005                BUNDIG-18216 - Access the Review contract page under certain conditions
* Jasper R. Galapon     15/05/2023      1006                BUNDIG-18514 - Contract Amendments - Line Status Reverts Back to Previous Status
* Jasper R. Galapon     18/07/2023      1007                BUNDIG-23197 - Split Review button for Contract and Amendment Review
* Jasper R. Galapon     08/08/2023      1008                BUNDIG-23679 - Contract Amendments - A2 Approval Required for New Line Items
* Jasper R. Galapon     25/08/2023      1009                BUNDIG-19094 - Contract Amendments - Prevent A1 from Actioning Review
* Jasper R. Galapon     28/08/2023      1010                BUNDIG-19095 - Contract Amendements - Prevent A2 from Actioning Review
******************************************************************************************************/
public without sharing class SM_ContractReview {

    public static final String CONTRACT_TYPE_NEW       = 'New';
    public static final String CONTRACT_TYPE_RENEWAL   = 'Renewal';
    public static final String CONTRACT_TYPE_AMENDMENT = 'Amendment';

    public static final String MESSAGE_LOCKED_CONTRACT = 'The contract has been locked by CPS';
    public static final String MESSAGE_UNAUTHORISED    = 'You do not have any contract items to review';
    

    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param contractId 
    * @param runningUserId
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled(cacheable=true)
    public static ContractReviewWrapper getContractMetadata(String contractId, String runningUserId) {
        ContractReviewWrapper resp = new ContractReviewWrapper();
        System.debug('contractId '+contractId);
        Contract__c contract = DM_Contract.getContract(contractId);
        resp.contract = contract;

        Initialisation__mdt init = DM_Initialisation.getCCRMInitialisation();

        // get contract type
        // if(DM_ContractLineItem.getAmendmentItems(contractId) > 0) {
        //     resp.contractType = CONTRACT_TYPE_AMENDMENT;
        // } else {
        //     resp.contractType = String.isBlank(contract.Previous_Header_ID__c) ? CONTRACT_TYPE_NEW : CONTRACT_TYPE_RENEWAL;
        // }

        // BUNDIG-23197
        resp.contractType = String.isBlank(contract.Previous_Header_ID__c) ? CONTRACT_TYPE_NEW : CONTRACT_TYPE_RENEWAL;

        // find out read only
        resp.readOnly = false;
        List<String> readOnlyProfiles = init.Contract_Review_Read_Only_Profile__c.split(', ');
        User runningUser = DM_User.getUser(runningUserId);
        if(runningUser != null && readOnlyProfiles.contains(runningUser.Profile.Name)) {
            resp.readOnly = true;
        }
        // reviewer / approver overrides
        if(resp.contract.Reviewer__c == runningUserId || resp.contract.Approver__c == runningUserId) {
            resp.readOnly = false;
        }

        // determine the access based on lock flag
        if(resp.contract.Contract_Locked__c == true) {
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_LOCKED_CONTRACT;
            return resp;
        }

        resp.userHasAccess = true;
        // BUNDIG-23197 - Commented out - splitting contract and amendment lines
        // based on the contract type, reviewer field, approver field as well as running user to determine the access
        // if(resp.contractType == CONTRACT_TYPE_NEW || resp.contractType == CONTRACT_TYPE_RENEWAL) {
                        
        //     // BUNDIG-18216
        //     System.debug('***CONTRACT STAT: '+resp.contract.Status__c + ' - ' + resp.contract.Approver__c + ' - ' + runningUserId + ' - Approver Action: ' + resp.contract.Approver_Action__c + ' - Reviewer Action: ' + resp.contract.Reviewer_Action__c);
        //     // if(
        //     //     (resp.contract.Status__c != Constants.CONTRACT_STATUS_PENDING && resp.contract.Status__c != Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Status__c != Constants.CONTRACT_STATUS_APPROVED) || 
        //     //     (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer__c != runningUserId) ||
        //     //     (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Approver__c != runningUserId) || 
        //     //     (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Reviewer__c != runningUserId) || 
        //     //     (resp.readOnly == true && resp.contract.Contract_Approval_Status__c != Constants.CONTRACT_APPROVAL_STATUS_PENDING) ||
        //     //     (resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Contract_Approval_Status__c == Constants.CONTRACT_REJECTED) // Added for CCRM-8664 - If Status pending & CustomerApprovalStatus CustomerRejected, show error to user
        //     // ) {
        //     //     resp.userHasAccess = false;
        //     //     resp.noAccessMessage = MESSAGE_UNAUTHORISED;
        //     //     return resp;
        //     // }
            
        //     if (
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Reviewer__c == runningUserId && resp.contract.Contract_Approval_Status__c == 'Customer Approved') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Reviewer__c == runningUserId && resp.contract.Contract_Approval_Status__c == 'Customer Rejected') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'A' && resp.contract.Approver_Action__c == 'A') ||            
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'A' && resp.contract.Approver_Action__c == null) ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Approver__c == runningUserId && resp.contract.Reviewer_Action__c == 'A' && resp.contract.Approver_Action__c == null) ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'A') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == 'A') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == 'A') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'R') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REJECTED && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'R') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REJECTED && resp.contract.Approver__c == runningUserId && resp.contract.Reviewer_Action__c == 'R') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == 'R') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == 'R') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c == 'A') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == 'A') ||
        //         (resp.readOnly == false && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == null)
        //         )
        //             {
        //             resp.userHasAccess = false;
        //             resp.noAccessMessage = MESSAGE_UNAUTHORISED;
        //             return resp;
        //         }

        // }

        // // retrieve CLIs
        // if(resp.contractType == CONTRACT_TYPE_AMENDMENT) {
                        
        //     // for amendement, retrieve CLIs that meet the critera CCRM-106
        //     if(runningUserId == resp.contract.Reviewer__c) {
        //         resp.contractLineItems = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1'});
        //     } else if(runningUserId == resp.contract.Approver__c) {
        //         // BUNDIG-22849 - Added Line Status
        //         // resp.contractLineItems = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2'});
        //         resp.contractLineItems = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2', 'R1'});
        //     } else {
        //         // read only, both A1/A2
        //         system.debug('Amendment both A1/A2');
        //         resp.contractLineItems = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1', 'A2'});
        //     }
        //     // update access if null or 0 CLI retrieved
        //     // Simplus MS - CCRM-13835 - Fix added to only allow view the contract review of Amendement if the user is either Approver or Reviewer
        //     if(resp.contractLineItems == null || resp.contractLineItems.isEmpty() == true || ((runningUserId != resp.contract.Reviewer__c) && (runningUserId != resp.contract.Approver__c)) ) {
        //         resp.userHasAccess = false;
        //         resp.noAccessMessage = MESSAGE_UNAUTHORISED;
        //         return resp;
        //     }
            
        // } else {
        //     // for new / renewal, retrieve CLIs
        //     resp.contractLineItems = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{null, Constants.CLI_LINE_TYPE_CONTRACT}, new List<String>{null});
        // }

        // get applicable zones
        // resp.contractCZs = DM_CZMapping.getApplicableCZs(contract.Country__c, contract.State__c, contract.Cost_Zone__c);
        // if(resp.contractCZs == null && String.isNotBlank(contract.Cost_Zone__c) && contract.Cost_Zone__c.contains('CZ')) {
        //     resp.contractCZs = contract.Cost_Zone__c.replace('AU ', '').replace('NZ ', '');
        // }

        if(resp.contractType == CONTRACT_TYPE_NEW || resp.contractType == CONTRACT_TYPE_RENEWAL) {
            // RUNNING USER ID (Contract) - No access if runningUserId is not A1/A2
            if (runningUserId != resp.contract.Reviewer__c && runningUserId != resp.contract.Approver__c) {
                System.debug('***RUNNING USER ID (Contract) - No access if runningUserId is not A1/A2');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // REVIEW/APPROVER (Contract) - No access if contract is draft/expired/rejected/awaiting system response
            if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_DRAFT || resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE
                || resp.contract.Status__c == Constants.CONTRACT_STATUS_EXPIRED || resp.contract.Status__c == Constants.CONTRACT_STATUS_REJECTED || resp.contract.Status__c == Constants.CONTRACT_STATUS_AWAITING_SYSTEM_RESPONSE)) {
                    System.debug('***REVIEW/APPROVER (Contract) - No access if contract is draft/expired/rejected/awaiting system response');
                    resp.userHasAccess = false;
                    resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                    return resp;
            }
            // REVIEWER (Contract) - No access if contract is reviewed
            if (!resp.readOnly && resp.contract.Reviewer__c == runningUserId && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Reviewer_Action__c != null && resp.contract.Approver_Action__c == null) {
                System.debug('***REVIEWER (Contract) - No access if contract is reviewed');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // REVIEWER (Contract) - No access while Waiting for integration update
            if (!resp.readOnly && resp.contract.Reviewer__c == runningUserId && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer_Action__c != null && resp.contract.Approver_Action__c == null) {
                System.debug('***REVIEWER (Contract) - No access while Waiting for integration update');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // REVIEWER (Contract) - No access if contract approval status is customer approved or customer rejected
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c != null && resp.contract.Approver_Action__c != null
                && (resp.contract.Contract_Approval_Status__c == Constants.CONTRACT_APPROVED || resp.contract.Contract_Approval_Status__c == Constants.CONTRACT_REJECTED)) {
                    System.debug('***REVIEWER (Contract) - No access if contract approval status is customer approved or customer rejected');
                    resp.userHasAccess = false;
                    resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                    return resp;
            }
            // REVIEWER (Contract) - Show contract lines if contract status is pending or contract rejected by approver
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Reviewer__c == runningUserId 
                && (resp.contract.Reviewer_Action__c == null || resp.contract.Reviewer_Action__c == 'A') && (resp.contract.Approver_Action__c == null || resp.contract.Approver_Action__c == 'R')) {
                System.debug('***REVIEWER (Contract) - Show contract lines if contract status is pending  or contract rejected by approver');
                resp.contractLineItems = DM_contractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_CONTRACT}, new List<String>{null});
                System.debug('***resp.contractLineItems: ' + resp.contractLineItems);
            }
            // REVIEWER (Contract) - Show contract lines if contract status is approved
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Reviewer__c == runningUserId && resp.contract.Reviewer_Action__c != null 
                && resp.contract.Contract_Approval_Status__c == Constants.CONTRACT_APPROVAL_STATUS_PENDING) {
                System.debug('***REVIEWER (Contract) - Show contract lines if contract status is approved');
                resp.contractLineItems = DM_contractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_CONTRACT}, new List<String>{null});
                System.debug('***resp.contractLineItems: ' + resp.contractLineItems);
            }
            // APPROVER (Contract) - No access if contract is pending
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c == null) {
                System.debug('***APPROVER (Contract) - No access if contract is pending');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // APPROVER (Contract) - No access if contract is approved
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED && resp.contract.Approver__c == runningUserId && resp.contract.Approver_Action__c != null) {
                System.debug('***APPROVER (Contract) - No access if contract is approved');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // REVIEWER/APPROVER (Contract) - No access while waitinig for integration update - Interim state
            if (!resp.readOnly && (resp.contract.Reviewer__c == runningUserId || resp.contract.Approver__c == runningUserId) && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Reviewer_Action__c != null && resp.contract.Approver_Action__c != null) {
                System.debug('***REVIEWER/APPROVER (Contract) - No access while waitinig for integration update - Interim state');
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_UNAUTHORISED;
                return resp;
            }
            // APPROVER (Contract) - Show contract lines if contract status is reviewed
            if (!resp.readOnly && resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED && resp.contract.Approver__c == runningUserId && resp.contract.Reviewer_Action__c != null && resp.contract.Approver_Action__c == null) {
                System.debug('***APPROVER (Contract) - Show contract lines if contract status is reviewed');
                resp.contractLineItems = DM_contractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_CONTRACT}, new List<String>{null});
                System.debug('***resp.contractLineItems: ' + resp.contractLineItems);
            }
        }
        
        resp.contractCZs = getApplicableCostZones(contract);

        // get fields for tables
        if(resp.contractCZs != null) {
            List<String> applicableSCs = resp.contractCZs.split(', ');
            // get special buy fields based on applicable cost zones
            resp.sbFields = generateSpecialBuyLWCFields(DM_ContractReviewField.getSpecialBuyFields(applicableSCs));
            // get contract line item fields based on applicable cost zones
            resp = generateContractLineLWCFields(DM_ContractReviewField.getContractLineFields(applicableSCs, contract.Country__c, resp.contractType), resp);
        }

        // find item numbers
        Set<String> itemNumbers= new Set<String>();
        Map<String, Contract_Line_Item__c> cliMap = new Map<String, Contract_Line_Item__c>();
        for(Contract_Line_Item__c cli : resp.contractLineItems) {
            cliMap.put(cli.Name, cli);
        }

        // get special buy ids
        List<Account> accounts = DM_Account.getAccountsWithCustomerSpecialBuys(contractId);
        List<Id> specialBuyIds = new List<Id>();
        for(Account a : accounts) {
            if(a.Customer_Special_Buys__r != null && a.Customer_Special_Buys__r.size() > 0) {
                for(Customer_Special_Buy__c csb : a.Customer_Special_Buys__r) {
                    specialBuyIds.add(csb.Special_Buy__c);
                }
            }
        }
        // get not expired special buy items
        // map CLIs to SBLIs
        resp.contractLineItemsForSpecialBuys = new List<Contract_Line_Item__c>();
        if(specialBuyIds.size() > 0) {
            for(Special_Buy_Line_Item__c sbli : DM_SpecialBuyLineItem.getNotExpiredSpecialBuyLineItems(specialBuyIds)) {
                if(cliMap.containsKey(sbli.Name)) {
                    Contract_Line_Item__c cli = cliMap.get(sbli.Name).clone(true, true, false, false);
                    cli.Special_Buy_Item__c = sbli.Id;
                    cli.Special_Buy_Item__r = sbli;
                    resp.contractLineItemsForSpecialBuys.add(cli);
                }
            }
        }

        // retrieve Percent GP from custom metadata 
        resp.underGPPercent = init.Contract_Review_Percent_GP__c;

        return resp;
    }

    /**
    * @description 
    * @author Jasper R. Galapon | BUNDIG-23197 | 19/07/2023
    * @param contractId 
    * @param runningUserId
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled(cacheable=true)
    public static ContractReviewWrapper getContractAmendmentMetadata(String contractId, String runningUserId) {
        ContractReviewWrapper resp = new ContractReviewWrapper();
        System.debug('contractId '+contractId);
        Contract__c contract = DM_Contract.getContract(contractId);
        resp.contract = contract;

        Initialisation__mdt init = DM_Initialisation.getCCRMInitialisation();

        // Set contract type
        resp.contractType = CONTRACT_TYPE_AMENDMENT;

        // find out read only
        resp.readOnly = false;
        List<String> readOnlyProfiles = init.Contract_Review_Read_Only_Profile__c.split(', ');
        User runningUser = DM_User.getUser(runningUserId);
        if(runningUser != null && readOnlyProfiles.contains(runningUser.Profile.Name)) {
            resp.readOnly = true;
        }
        // reviewer / approver overrides
        if(resp.contract.Reviewer__c == runningUserId || resp.contract.Approver__c == runningUserId) {
            resp.readOnly = false;
        }

        // determine the access based on lock flag
        if(resp.contract.Contract_Locked__c == true) {
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_LOCKED_CONTRACT;
            return resp;
        }

        resp.userHasAccess = true;

        // BUNDIG-19094
        // List<Contract_Line_Item__c> reviewerAmendmentLines = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1'});
        List<Contract_Line_Item__c> reviewerAmendmentLines = DM_ContractLineItem.getAmendmentItemsByReviewOrApprover(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1'}, 'Reviewer');
        // BUNDIG-19095
        // List<Contract_Line_Item__c> approverAmendmentLines = DM_ContractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2'});
        List<Contract_Line_Item__c> approverAmendmentLines = DM_ContractLineItem.getAmendmentItemsByReviewOrApprover(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2'}, 'Approver');
        

        System.debug('***AmendmentLines - Reviewer: ' + reviewerAmendmentLines.size() + ' - Approver: ' + approverAmendmentLines.size());

        // RUNNING USER ID (Contract) - No access if runningUserId is not A1/A2
        if (runningUserId != resp.contract.Reviewer__c && runningUserId != resp.contract.Approver__c) {
            System.debug('***RUNNING USER ID (Contract) - No access if runningUserId is not A1/A2');
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_UNAUTHORISED;
            return resp;
        }
        // REVIEWER/APPROVER (Amendment) - No access if contract status is draft/active/expired
        if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_DRAFT || resp.contract.Status__c == Constants.CONTRACT_STATUS_EXPIRED)
            && (resp.contract.Reviewer__c == runningUserId || resp.contract.Approver__c == runningUserId)) {
            System.debug('***REVIEWER/APPROVER (Amendment) - No access if contract status is draft/active/expired');
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_UNAUTHORISED;
            return resp;
        }
        // REVIEWER (Amendment) - No access if contract lines is pending/reviewed/approved/active/submitted
        if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING || resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED || resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED
            || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE || resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE) 
            && resp.contract.Reviewer__c == runningUserId && reviewerAmendmentLines.size() == 0) {
            System.debug('***REVIEWER (Amendment) - No access if contract lines is pending/reviewed/approved/active/submitted');
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_UNAUTHORISED;
            return resp;
        }
        // REVIEWER (Amendment) - Show amendment lines if contract status is pending/reviewed/approved/submitted
        if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING || resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED || resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED
            || resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE) && resp.contract.Reviewer__c == runningUserId
            && reviewerAmendmentLines.size() > 0) {
            System.debug('***REVIEWER (Amendment) - Show amendment lines if contract status is pending/reviewed/approved/submitted');
            // BUNDIG-19094
            // resp.contractLineItems = DM_contractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1'});
            resp.contractLineItems = DM_ContractLineItem.getAmendmentItemsByReviewOrApprover(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A1'}, 'Reviewer');
            System.debug('***resp.contractLineItems: ' + resp.contractLineItems.size());
        }
        // APPROVER (Amendment) - No access if contract status is pending/reviewed/approved/active/submitted
        if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING || resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED || resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED
            || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE || resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED) && resp.contract.Approver__c == runningUserId && approverAmendmentLines.size() == 0) {
            System.debug('***APPROVER (Amendment) - No access if contract status is pending/reviewed/approved/active/submitted');
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_UNAUTHORISED;
            return resp;
        }
        // APPROVER (Amendment) - Show amendment lines if contract status is pending/reviewed/approved/submitted
        if (!resp.readOnly && (resp.contract.Status__c == Constants.CONTRACT_STATUS_PENDING || resp.contract.Status__c == Constants.CONTRACT_STATUS_REVIEWED || resp.contract.Status__c == Constants.CONTRACT_STATUS_APPROVED
        || resp.contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED || resp.contract.Status__c == Constants.CONTRACT_STATUS_ACTIVE) && resp.contract.Approver__c == runningUserId
        && approverAmendmentLines.size() > 0) {
            System.debug('***APPROVER (Amendment) - Show amendment lines if contract status is pending/reviewed/approved/submitted');
            // BUNDIG-19095
            // resp.contractLineItems = DM_contractLineItem.getItemsWithSpecialBuyItems(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2'});
            resp.contractLineItems = DM_ContractLineItem.getAmendmentItemsByReviewOrApprover(contractId, new List<String>{Constants.CLI_LINE_TYPE_AMENDMENT}, new List<String>{'A2'}, 'Approver');
            System.debug('***resp.contractLineItems: ' + resp.contractLineItems);
        }
        
        resp.contractCZs = getApplicableCostZones(contract);

        // get fields for tables
        if(resp.contractCZs != null) {
            List<String> applicableSCs = resp.contractCZs.split(', ');
            // get special buy fields based on applicable cost zones
            resp.sbFields = generateSpecialBuyLWCFields(DM_ContractReviewField.getSpecialBuyFields(applicableSCs));
            // get contract line item fields based on applicable cost zones
            resp = generateContractLineLWCFields(DM_ContractReviewField.getContractLineFields(applicableSCs, contract.Country__c, resp.contractType), resp);
        }

        // find item numbers
        Set<String> itemNumbers= new Set<String>();
        Map<String, Contract_Line_Item__c> cliMap = new Map<String, Contract_Line_Item__c>();
        for(Contract_Line_Item__c cli : resp.contractLineItems) {
            cliMap.put(cli.Name, cli);
        }

        // get special buy ids
        List<Account> accounts = DM_Account.getAccountsWithCustomerSpecialBuys(contractId);
        List<Id> specialBuyIds = new List<Id>();
        for(Account a : accounts) {
            if(a.Customer_Special_Buys__r != null && a.Customer_Special_Buys__r.size() > 0) {
                for(Customer_Special_Buy__c csb : a.Customer_Special_Buys__r) {
                    specialBuyIds.add(csb.Special_Buy__c);
                }
            }
        }
        // get not expired special buy items
        // map CLIs to SBLIs
        resp.contractLineItemsForSpecialBuys = new List<Contract_Line_Item__c>();
        if(specialBuyIds.size() > 0) {
            for(Special_Buy_Line_Item__c sbli : DM_SpecialBuyLineItem.getNotExpiredSpecialBuyLineItems(specialBuyIds)) {
                if(cliMap.containsKey(sbli.Name)) {
                    Contract_Line_Item__c cli = cliMap.get(sbli.Name).clone(true, true, false, false);
                    cli.Special_Buy_Item__c = sbli.Id;
                    cli.Special_Buy_Item__r = sbli;
                    resp.contractLineItemsForSpecialBuys.add(cli);
                }
            }
        }

        // retrieve Percent GP from custom metadata 
        resp.underGPPercent = init.Contract_Review_Percent_GP__c;

        return resp;
    }

    /**
    * @description 
    * @author Yi Zhang | 28/07/2020 
    * @param contract 
    * @return String 
    **/
    public static String getApplicableCostZones(Contract__c contract) {
        // Country: Australia | New Zealand
        // State: VIC;NSW (multi-picklist)
        // Cost Zones: AU CZ 1;AU CZ 2 (multi-picklist)
        if(String.isBlank(contract.Country__c) || String.isBlank(contract.State__c) || String.isBlank(contract.Cost_Zone__c)) {
            return null;
        }

        // a list of applicable cost zones based on the combination of all selected states and cost zones
        List<String> applicableCostZones = new List<String>();

        List<String> states = contract.State__c.split(';');
        List<String> costZones = contract.Cost_Zone__c.split(';');
        for(String state : states) {
            for(String costZone : costZones) {
                String key = contract.Country__c + state + costZone;
                // try find applicable cost zone in the custom metadata type
                String acz = DM_CZMapping.costZoneMap.get(contract.Country__c + state + costZone);
                // if no zone found, check if the single cost zone is present
                if(acz == null && costZone.contains('CZ')) {
                    acz = costZone.replace('AU ', '').replace('NZ ', '');
                }
                if(acz != null) {
                    applicableCostZones.add(acz);
                }
            }
        }
        
        applicableCostZones = new List<String>((String.join(applicableCostZones, ', ')).split(', '));
        return String.join(new List<String>(new Set<String>(applicableCostZones)), ', ');
    }

    /**
    * @description  Method to save updated contract line items when Save button is clicked on UI
    * @author Yi Zhang | 09/06/2020 
    * @param updatedItems 
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled
    public static ContractReviewWrapper saveContractLineItems(List<Contract_Line_Item__c> updatedItems) {
        try {
            ContractReviewWrapper resp = new ContractReviewWrapper();
            System.debug(LoggingLevel.DEBUG, updatedItems);
            // check lock status, if locked return error message, otherwise update the items
            Contract_Line_Item__c item = DM_ContractLineItem.getItem(updatedItems[0].Id);
            if(item.Contract__r.Contract_Locked__c == true) {
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_LOCKED_CONTRACT;    
            } else {
                update updatedItems;
                resp.userHasAccess = true;
            }
            return resp;
        } catch(Exception e) {
            // log
            ApplicationLogger.log('SM_ContractReview.saveContractLineItems', 'Contract__c', 'LWC Controller', e);
            // throw error
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description  Method to get contract history
    * @author Yi Zhang | 09/06/2020 
    * @param updatedItems 
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled
    public static List<String> getContractHistory(Id contractId) {
        try {
            List<String> contractHistoryList = new List<String>();
            List<Contract__History> getContractHistory = DM_Contract.getContractHistory(contractId);
            for(Contract__History ch: getContractHistory){
                String oldValue = (String)ch.OldValue;
                String newValue = (String)ch.NewValue;
                String field = ch.Field.replace('__c', '');
                if(String.isNotBlank(oldValue) && String.isNotBlank(newValue) && !oldValue.startsWith('005') && !newValue.startsWith('005')){
                    contractHistoryList.add(ch.CreatedDate.format('dd/MM/yyyy hh:mm:ss a') + ' | ' + field.replace('_', ' ') + ' | ' + ch.CreatedBy.Name 
                    + ' | Previous Value: ' + oldValue + ' | New Value: ' + newValue);
                } else if(String.isNotBlank(oldValue) && String.isBlank(newValue) && !oldValue.startsWith('005')){
                    contractHistoryList.add(ch.CreatedDate.format('dd/MM/yyyy hh:mm:ss a') + ' | ' + field.replace('_', ' ') + ' | ' + ch.CreatedBy.Name 
                    + ' | Previous Value: ' + oldValue + ' | New Value: ' + newValue);
                } else if(String.isNotBlank(newValue) && String.isBlank(oldValue) && !newValue.startsWith('005')){
                    contractHistoryList.add(ch.CreatedDate.format('dd/MM/yyyy hh:mm:ss a') + ' | ' + field.replace('_', ' ') + ' | ' + ch.CreatedBy.Name 
                    + ' | Previous Value: ' + oldValue + ' | New Value: ' + newValue);
                }
            }
            System.debug('contractHistoryList Size: '+contractHistoryList.size());
            return contractHistoryList;
        } catch(Exception e) {
            // log
            ApplicationLogger.log('SM_ContractReview.getContractHistory', 'Contract__c', 'LWC Controller', e);
            // throw error
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 6/12/2020 
    * @param Set<Id> lineItemIds 
    * @param String approvalStatus 
    * @param String comments 
    * @param Id userId 
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled
    public static ContractReviewWrapper saveAmendementContractLineItems(List<String> lineItemIds, String approvalStatus, String comments, Id userId, String costZones) {
        try {
            ContractReviewWrapper resp = new ContractReviewWrapper();
            List<String> costZonesList = new List<String>(costZones.split(', '));
            System.debug(LoggingLevel.DEBUG, lineItemIds);
            // check lock status, if locked return error message, otherwise update the items
            Contract_Line_Item__c item = DM_ContractLineItem.getItem(lineItemIds[0]);
            if(item.Contract__r.Contract_Locked__c == true) {
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_LOCKED_CONTRACT;    
            } else {
                List<Contract_Line_Item__c> contractLineItems = DM_ContractLineItem.getItems(lineItemIds);
                for(Contract_Line_Item__c contractLineItem : contractLineItems){
                    String status = contractLineItem.Line_Status__c;
                    
                    if(status == 'A1'){
                        contractLineItem.Reviewer__c = userId;
                        contractLineItem.Reviewer_Action__c = approvalStatus;
                        contractLineItem.Reviewer_Action_Date__c = Datetime.now();
                        contractLineItem.Reviewer_Comments__c = comments;
                        if(approvalStatus == 'A'){
                            Boolean skipApprover = true;
                            // BUNDIG-18514 - Commented out - Let integration user update this field
                            // contractLineItem.Line_Status__c = 'A2'; // TODO: Add logic for margins
                            Decimal newMargin = 0;
                            for(String costZone : costZonesList){
                                costZone = costZone.replace(' ', '');
                                
                                // Field mapping
                                // CZ1 Sell (Ex-GST) = Price_CZ1__c / CZ1 Cost = Cost_CZ1__c / Previous CZ1 Margin % = Previous_Margin_CZ1__c / New CZ1 Margin % = newMargin

                                Decimal price = (Decimal) contractLineItem.get('Price_' + costZone + '__c') != null ? (Decimal) contractLineItem.get('Price_' + costZone + '__c') : 0; // added checker if null - JP 08/04
                                Decimal cost = (Decimal) contractLineItem.get('Cost_' + costZone + '__c') != null ? (Decimal) contractLineItem.get('Cost_' + costZone + '__c') : 0; // added checker if null- JP 08/04
                                Decimal previousMargin = (Decimal) contractLineItem.get('Previous_Margin_' + costZone + '__c') != null ? (Decimal) contractLineItem.get('Previous_Margin_' + costZone + '__c') : 0;

                                newMargin = price != 0 ? 100 * ((price - cost) / price) : 0; // Check if Price is = 0. Default to 0 if true - JP 08/04
                                System.debug(LoggingLevel.FINEST, '***newMargin: ' + newMargin + ' / previousMargin: ' + previousMargin + ' / price: ' + price + ' / cost: ' + cost + ' / newMargin>=previousMargin: ' + Boolean.valueOf(newMargin>=previousMargin));
                                
                                // BUNDIG-23679
                                // skipApprover = skipApprover && (newMargin >= previousMargin);
                                // This is a new contract amendment line, no previous cost
                                if (contractLineItem.Amendment_Type__c == 'I' && contractLineItem.get('Previous_Cost_' + costZone + '__c') == null) {
                                    skipApprover = false;
                                } else {
                                    skipApprover = skipApprover && (newMargin >= previousMargin);
                                }
                            }

                            // TODO: check if Start Date is changed - skipApprover if start date has not been extended and all margins are greater than their previous
                            skipApprover = skipApprover && (contractLineItem.Start_Date__c == contractLineItem.Original_Start_Date__c);

                            System.debug(LoggingLevel.FINEST, '***SkippedApprover? ' + skipApprover);                            

                            if(skipApprover){
                                // BUNDIG-18514 - Commented out - Let integration user update this field
                                // contractLineItem.Line_Status__c = 'A';
                                contractLineItem.Approver__c = userId;
                                contractLineItem.Approver_Action__c = approvalStatus;
                                contractLineItem.Approver_Action_Date__c = Datetime.now();
                                contractLineItem.Approver_Comments__c = comments;
                            }
                        }
                        else if(approvalStatus == 'R'){
                            // BUNDIG-18514 - Commented out - Let integration user update this field
                            // contractLineItem.Line_Status__c = 'A2';
                        }
                    }
                    else if(status == 'A2'){
                        contractLineItem.Approver__c = userId;
                        contractLineItem.Approver_Action__c = approvalStatus;
                        contractLineItem.Approver_Action_Date__c = Datetime.now();
                        contractLineItem.Approver_Comments__c = comments;
                        if(approvalStatus == 'A'){
                            // BUNDIG-18514 - Commented out - Let integration user update this field
                            // contractLineItem.Line_Status__c = 'A';
                        }
                        else if(approvalStatus == 'R'){
                            // BUNDIG-18514 - Commented out - Let integration user update this field
                            // contractLineItem.Line_Status__c = 'R';
                        }
                    }
                }
                if(!contractLineItems.isEmpty()){
                    update contractLineItems;
                }
                
                resp.userHasAccess = true;
            }
            return resp;
        } catch(Exception e) {
            // log
            ApplicationLogger.log('SM_ContractReview.saveContractLineItems', 'Contract__c', 'LWC Controller', e);
            // throw error
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description 
    * @author John Paul Peñaflor | 6/3/2020 
    * @param Contract__c contract 
    * @return ContractReviewWrapper 
    **/
    @AuraEnabled
    public static ContractReviewWrapper saveContract(Contract__c contract) {
        try {
            ContractReviewWrapper resp = new ContractReviewWrapper();
            System.debug(LoggingLevel.DEBUG, contract);
            // check lock status, if locked return error message, otherwise update the contract
            Contract__c c = DM_Contract.getContract(contract.Id);
            if(c.Contract_Locked__c == true) {
                resp.userHasAccess = false;
                resp.noAccessMessage = MESSAGE_LOCKED_CONTRACT;    
            } else {
                // if approver actioned, the contract approval status should be set to 'Completed'
                
                // Below condition updated to include CCRM-8664 changes
                // if(String.isNotBlank(contract.Approver_Action__c) && contract.Status__c == Constants.CONTRACT_STATUS_APPROVED) {
                if(contract.Approver_Action__c == 'A' && contract.Status__c == 'Awaiting System Response') {
                    contract.Contract_Approval_Status__c = Constants.CONTRACT_APPROVAL_STATUS_COMPLETED;
                }else if(contract.Status__c == Constants.CONTRACT_STATUS_SUBMITTED){
                    contract.Contract_Approval_Status__c = Constants.CONTRACT_APPROVED;
                }

                update contract;
                resp.userHasAccess = true;
            }
            return resp;
        } catch(Exception e) {
            // log
            ApplicationLogger.log('SM_ContractReview.saveContract', 'Contract__c', 'LWC Controller', e);
            // throw error
            throw new AuraHandledException(e.getMessage());
        }
    }

    


    private static List<Field> generateSpecialBuyLWCFields(List<Contract_Review_Field__mdt> crfs) {
        List<Field> fields = new List<Field>();
        for(Contract_Review_Field__mdt crf : crfs) {
            Field f = new Field();
            f.fieldName = crf.Field_Name__c;
            f.label = crf.Label__c;
            f.priceFieldName = crf.Price_Field_Name__c;
            f.type = crf.Field_Type__c;
            fields.add(f);
        }
        return fields;
    }

    private static ContractReviewWrapper generateContractLineLWCFields(List<Contract_Review_Field__mdt> crfs, ContractReviewWrapper resp) {
        List<Field> fields = new List<Field>();
        List<Field> fieldsWithoutRetail = new List<Field>();
        Boolean isProjectContract = resp.contract.Project__c != null;
        for(Contract_Review_Field__mdt crf : crfs) {
            if(crf.Label__c.contains('Hide Me') == false) {
                // special margin fields are hidden when it's a project contract
                if(!(isProjectContract && crf.Label__c.containsIgnoreCase('Special Buy'))) {
                    Field f = new Field();
                    f.fieldName = crf.Field_Name__c;
                    f.label = crf.Label__c;
                    f.type = crf.Field_Type__c;
                    f.editable = crf.Editable__c;
                    f.retail = crf.Is_Retail__c;
                    f.removeItem = (f.fieldName == 'Enabled__c');
                    f.additionalFieldName = crf.Additional_Field_Name__c;
                    if(resp.readOnly == true) {
                        f.readOnly = true;
                    }
                    fields.add(f);
                    if(f.retail == false) {
                        fieldsWithoutRetail.add(f);
                    }   
                }
            }
        }

        resp.itemFields = fields;
        resp.itemFieldsWithoutRetail = fieldsWithoutRetail;

        return resp;
    }

    /**
     * @description wrapper class
     */
    public class ContractReviewWrapper {
        @AuraEnabled
        public String contractType;                             // New, Renewal, Amendment
        @AuraEnabled
        public String contractCZs;                              // Not Contract__c.Cost_Zone__c but the applicable cost zone(s)
        @AuraEnabled
        public Contract__c contract;
        @AuraEnabled
        public Double underGPPercent;                           // By default 10, changed through Initialisation__mdt
        @AuraEnabled
        public List<Contract_Line_Item__c> contractLineItems;
        @AuraEnabled
        public List<Contract_Line_Item__c> contractLineItemsForSpecialBuys;
        @AuraEnabled
        public List<Field> sbFields;
        @AuraEnabled
        public List<Field> itemFields;
        @AuraEnabled
        public List<Field> itemFieldsWithoutRetail;
        @AuraEnabled
        public Boolean userHasAccess;
        @AuraEnabled
        public String noAccessMessage;
        @AuraEnabled
        public Boolean readOnly;                                // reserved for Commercial Pricing / System Admin profiles
        
    }

    /**
     * @description
     */
    public class Field {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String priceFieldName; // for special buy field only
        @AuraEnabled
        public Boolean editable;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean retail;
        @AuraEnabled
        public Map<String, String> typeAttributes;
        @AuraEnabled
        public Map<String, String> cellAttributes;
        @AuraEnabled
        public Boolean removeItem;  // dedicated for remove item column
        @AuraEnabled
        public String additionalFieldName;  // for cell that has a static display and an input
        @AuraEnabled
        public Boolean readOnly;
    }
}