/*******************************************************************************************************
* Class Name        : SM_AccountTransfer
* Description    	: Service layer for account transfer epic. 
                      Without sharing is required as related records' owner are to be changed
* Author            : Simplus - Yi Zhang
* Created On        : 14/05/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer        Date      Modification ID    Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              14/05/2020    1000        Initial version
* Simplus MS            17/02/2021    1001        Added NZ Sales Person Contact Centre check as part of CCRM 9376
* Simplus MS            22/04/2021    1002        Fix for UAT_CCRM-13675 - Added the Sales Manager, National Manager, NZ Sales Manager changes
* Simplus MS            04/06/2021    1003        Added ApplicationLogs to exception catch blocks
* Simplus MS            11/06/2021    1004        Added fix for inactive account owner users on updateAccountForApproval method
* Simplus MS            29/07/2021    1005        Added fix for exception message for pending spend band review on transferAccountRelatedRecords method   
* Simplus MS			04/11/2021	  1006		  Added fix for CCRM15-182 - Account Owner Transfers - Umbrella Groups [PRB0048508]
* Simplus MS			08/12/2021	  1007		  Added fix for CCRM15-407
* Bunnings Dev          08/08/2022    1008        SFSUP-898 - Transfer Account Plan
* Deepika Pentareddy    31/08/2023    1009        BUNDIG-23624 Convert Hard coded profile in SM_AccountTransfer
* Deepika Pentareddy    08/09/2023    1010        BUNDIG-25133 Create the new field on Initialisation (Custom Metadata)
******************************************************************************************************/
public without sharing class SM_AccountTransfer {
    public static final String STEP_APPROVAL_IN_PROCESS = 'ApprovalInProgress';
    public static final String STEP_NOT_ELIGIBLE_FOR_TRANSFER = 'NotEligibleForTransfer';
    public static final String STEP_UMBRELLA_GROUP_OWNERS_ONLY = 'UmbrellaGroupOwnersOnly';
    public static final String STEP_SET_TRANSFER_TO = 'SetTransferTo';
    public static final String STEP_TO_TS_WITH_ACTIVE = 'ToTSWithActiveContract';
    public static final String STEP_TO_NON_TS_WITH_ACTIVE = 'ToNonTSWithActiveContract';
    public static final String STEP_TO_SELF = 'ToSelf';
    public static final String STEP_SUBMIT_FOR_APPROVAL = 'SubmitForApproval';
    public static final String STEP_SKIP_APPROVAL = 'SkipApproval';
    public static final List<String> PROFILE_ACCOUNT_MANAGER = new List<String>{'Account Manager', 'NZ Account Manager'};

    /**
    * @description 
    * @author Yi Zhang | 14/05/2020 
    * @param accountId 
    * @param runningUserId 
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> init(String accountId, String runningUserId) {

        // List<String> steps = new List<String>{'NotEligibleForTransfer', 'SubmitForApproval', 
        // 'SkipApproval', 'ApprovalInProgress',
        // 'SetTransferTo', 'ToTSWithActiveContract', 
        // 'ToNonTSWithActiveContract', 'Exception'};

        // String step = steps[Integer.valueOf(Math.floor(steps.size() * Math.random()))];
        // if(step == 'Exception') {
        //     throw new AuraHandledException('Exception message here');
        // }

        Map<String, String> resp = new Map<String, String>();

        try {
            // get account details, e.g. ownerId
            Account account = DM_Account.getAccount(accountId);
            // get running user details, e.g. profile
            User user = DM_User.getUser(runningUserId);
            // get allowed profiles
            List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Account_Transfer_Profile_Exemption__c.split(', ');
            List<String> profileExemption = DM_Initialisation.getCCRMInitialisation().Account_Transfer_Profile_Exemption_2__c.split(', '); //BUNDIG-25133
            System.debug('profileExemptions: ' + profileExemptions);
            system.debug('profileExemption: ' + profileExemption);
            /* 
            System Administrator, Integrations User, Light Commercial Manager, National Manager, 
            NZ Light Commercial Manager, NZ Sales Manager, NZ Support - National, Sales Manager, Support Manager - Trade PA
            */
            List<ProcessInstance> approvals = DM_ProcessInstance.getPendingProcessInstances(new Set<Id>{accountId});
            /*
            Get list of Active Umbrella Beneficiaries with Owners - Added by Paul Peñaflor
            */
            Set<Id> activeUmbrellaGroupOwnerIds = getActiveUmbrellaGroupOwnerIds(accountId);
            System.debug('activeUmbrellaGroupOwnerIds: ' + activeUmbrellaGroupOwnerIds);
            if(account.Transfer_approval_status__c == 'In progress' || account.Transfer_approval_status__c == 'Submitted for approval' || approvals.size() > 0) {
                
                resp.put('step', STEP_APPROVAL_IN_PROCESS);
                resp.put('debugMsg', 'Account approval status = ' + account.Transfer_approval_status__c);
                //else if added - Paul Peñaflor to cater to NZ Account Transfer Restriction
            } 
            //Commented below logic for CCRM15-182
            /** else if(account.Country__c == 'New Zealand' && activeUmbrellaGroupOwnerIds.size() > 0 && activeUmbrellaGroupOwnerIds.contains(user.Id) == false){
                resp.put('step', STEP_UMBRELLA_GROUP_OWNERS_ONLY);
                resp.put('debugMsg', account.OwnerId + '==' + user.Id + ', and ' + user.Profile.Name + ' not in related active umbrella group owner ' + String.valueOf(activeUmbrellaGroupOwnerIds));
            } **/
            else if(account.OwnerId != user.Id && profileExemptions.contains(user.Profile.Name) == false && profileExemption.contains(user.Profile.Name) == false) { //BUNDIG-25133

                resp.put('step', STEP_NOT_ELIGIBLE_FOR_TRANSFER);
                resp.put('debugMsg', account.OwnerId + '!=' + user.Id + ', and ' + user.Profile.Name + ' not in ' + String.valueOf(profileExemptions));
                resp.put('debugMsg', account.OwnerId + '!=' + user.Id + ', and ' + user.Profile.Name + ' not in ' + String.valueOf(profileExemption)); //BUNDIG-25133

            } else {

                resp.put('step', STEP_SET_TRANSFER_TO);

            }
            
            // national trade contracts email based on account's country
            resp.put('nationalTradeContractsEmail', (account.Country__c == Constants.COUNTRY_NZ) 
                ? DM_Initialisation.ccrmInitialisation.Account_Transfer_Contract_Email_NZ__c
                : DM_Initialisation.ccrmInitialisation.Account_Transfer_Contract_Email_AU__c);

            return resp;
        } catch(Exception e) {
            // TODO log exception
            ApplicationLogger.log('SM_AccountTransfer.init', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 6/24/2020 
    * @param String accountId 
    * @return Set<Id> 
    **/
    public static Set<Id> getActiveUmbrellaGroupOwnerIds(String accountId){

        Set<Id> ownerIds = new Set<Id>();
        List<Umbrella_Beneficiary__c> activeUmbrellaBeneficiaries = DM_UmbrellaBeneficiary.getActiveUmbrellaBeneficiariesWithGroupOwners(accountId);

        for(Umbrella_Beneficiary__c umbrellaBeneficiaryRecord : activeUmbrellaBeneficiaries){
            ownerIds.add(umbrellaBeneficiaryRecord.Umbrella_Group__r.OwnerId);
        }

        return ownerIds;
    }

    
    /**
    * @description 
    * @author John Paul Peñaflor | 7/2/2020 
    * @param List<List<String>> idList 
    * @return void 
    **/
    @InvocableMethod
    public static void updateAccountAMToTSTransfer(List<List<String>> idList) {

        List<Customer_Price_List__c> cplToDelete = new List<Customer_Price_List__c>();
        List<Customer_Price_List__c> cplToUpdate = new List<Customer_Price_List__c>();
        List<Customer_Family_Tree_Discount__c> cftdToDelete = new List<Customer_Family_Tree_Discount__c>();
        List<Customer_Family_Tree_Discount__c> cftdToUpdate = new List<Customer_Family_Tree_Discount__c>();

        try {
            Account accRec = DM_Account.getAccount(idList[0][0]); // first array element should contain the account id

            if(accRec.Country__c == 'New Zealand'){
                String powerPassSpendBandId = idList[0][1];//second array element should contain the Powerpass Spend Band Id
                System.debug('powerPassSpendBandId::' +powerPassSpendBandId);
                List<Customer_Price_List__c> customerPriceLists = new List<Customer_Price_List__c>(CustomerPriceListHelper.getRelatedCustomerPriceLists(accRec.Id));
                System.debug('customerPriceLists::' +customerPriceLists);
                List<Customer_Family_Tree_Discount__c> customerFamilyTreeDiscounts = new List<Customer_Family_Tree_Discount__c>(CustomerFamilyTreeDiscountsHelper.getRelatedCustomerFamilyTreeDiscount(accRec.Id));
                System.debug('customerFamilyTreeDiscounts::' +customerFamilyTreeDiscounts);

                for(Customer_Price_List__c customerPriceList : customerPriceLists){
                    if(customerPriceList.Status__c == 'Active'){
                        customerPriceList.Pricing_Assignment_Status__c = 'Submitted to CPS';
                        customerPriceList.Action__c = 'Removal';
                        cplToUpdate.add(customerPriceList);
                    }
                    else{
                        cplToDelete.add(customerPriceList);
                    }
                }

                for(Customer_Family_Tree_Discount__c customerFamilyTreeDiscount : customerFamilyTreeDiscounts){
                    if(customerFamilyTreeDiscount.Status__c == 'Active'){
                        customerFamilyTreeDiscount.Pricing_Assignment_Status__c = 'Submitted to CPS';
                        customerFamilyTreeDiscount.Action__c = 'Removal';
                        cftdToUpdate.add(customerFamilyTreeDiscount);
                    }
                    else{
                        cftdToDelete.add(customerFamilyTreeDiscount);
                    }
                }

                if(!cplToUpdate.isEmpty()){
                    update cplToUpdate;
                }

                if(!cftdToUpdate.isEmpty()){
                    update cftdToUpdate;
                }

                if(!cplToDelete.isEmpty()){
                    delete cplToDelete;
                }

                if(!cftdToDelete.isEmpty()){
                    delete cftdToDelete;
                }
                
                accRec.Spend_Band__c = powerPassSpendBandId;
            }
            

            accRec.AM_to_TS_Transfer__c = false;
            accRec.Send_Data_to_CPS__c  = true;
            accRec.Transfer_comments__c = null;
            accRec.Transfer_to__c       = null;
            accRec.Transfer_Initiator__c= null;
            accRec.Non_TS_Manager__c    = null;
            

            update accRec;
        } catch (Exception e) {
            ApplicationLogger.log('SM_AccountTransfer.updateAccountAMToTSTransfer', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param accountId 
    * @param runningUserId 
    * @param transferToUserId 
    * @param transferComments 
    * @param bypassChecks 
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> checkContracts(String accountId, String runningUserId, 
    String transferToUserId, String transferComments, Boolean bypassChecks) {
        try {
            Map<String, String> resp = new Map<String, String>();
            // get account details, e.g. ownerId
            Account account = DM_Account.getAccount(accountId);
            System.debug('account.OwnerId: ' + account.OwnerId);
            System.debug('transferToUserId: ' + transferToUserId);
            if(account.OwnerId == transferToUserId) {
                resp.put('step', STEP_TO_SELF);
                resp.put('debugMsg', 'Attempting to transfer to self');
                return resp;
            }

            // get transfer to user (account receiver) details, e.g. profile, TS or not
            Map<Id, User> userMap = DM_User.getUsers(new List<String>{runningUserId, transferToUserId, account.OwnerId});
            User accountReceiver = userMap.get(transferToUserId);
            User transferInitiator = userMap.get(runningUserId);
            User accountOriginalOwner = userMap.get(account.OwnerId);
            
            // provide meaningful exception message in case user visibility is not set properly?
            if(accountReceiver == null || accountOriginalOwner == null) {
                AuraHandledException auraEx = new AuraHandledException('Either original owner or new owner is invisible, please check owner\'s country');
                auraEx.setMessage('Either original owner or new owner is invisible, please check owner\'s country');
                throw auraEx;
            }
            
            if(bypassChecks == true) {
                // send to approval
                resp = updateAccountForApproval(account, transferComments, accountReceiver, accountOriginalOwner, transferInitiator);
                resp.put('debugMsg', resp.get('debugMsg') +' & bypass....');
            } else {
                // get non-expiry contracts
                // logic refined per CCRM-6776
                // List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustomerContracts(accountId);
                // Integer activeContractsWithAcctOwner = SM_CustomerContract.getNumberOfContractsBelongTo(contracts, account.OwnerId);

                // if(activeContractsWithAcctOwner > 0) {

                //     if(accountReceiver.IS_TS__c == true) {

                //         resp.put('step', STEP_TO_TS_WITH_ACTIVE);
                //         resp.put('debugMsg', 'Receiver ' + String.valueOf(accountReceiver) + ' is a TS');

                //     } else {

                //         resp.put('step', STEP_TO_NON_TS_WITH_ACTIVE);
                //         resp.put('debugMsg', 'Receiver is not a TS. Among ' + activeContractsWithAcctOwner + ' non-expired contracts, ' + activeContractsWithAcctOwner + ' owned by the current account owner');

                //     }
                // } else {
                //     // send to approval
                //     resp = updateAccountForApproval(account, transferComments, accountReceiver, accountOriginalOwner, transferInitiator);
                // }

                // new logic CCRM-6955 overrides CCRM-178 & CCRM-6776
                List<Customer_Contract__c> allContracts = DM_CustomerContract.getCustomerContracts(accountId);
                System.debug('***allContracts: '+allContracts);

                Integer nonExpiredCount = SM_CustomerContract.countNonExpiredContracts(allContracts);
                Integer nonExpiredOwnerIsReviewerCount = SM_CustomerContract.countNonExpiredContractsWithOriginalReviewerSameAsAccountOwner(allContracts, accountOriginalOwner.Id);
                if(nonExpiredCount == 0 || nonExpiredOwnerIsReviewerCount == 0) {
                    // send to approval
                    resp = updateAccountForApproval(account, transferComments, accountReceiver, accountOriginalOwner, transferInitiator);
                } else {
                    if(accountReceiver.IS_TS__c == true) {

                        resp.put('step', STEP_TO_TS_WITH_ACTIVE);
                        resp.put('debugMsg', 'Receiver ' + String.valueOf(accountReceiver) + ' is a TS');

                    } else {

                        resp.put('step', STEP_TO_NON_TS_WITH_ACTIVE);
                        resp.put('debugMsg', 'Receiver is not a TS');

                    }
                }
            }
            
            return resp;
        } catch(Exception e) {
            // TODO log exception
            ApplicationLogger.log('SM_AccountTransfer.checkContracts', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 15/05/2020 
    * @param accountId 
    * @param transferComments 
    * @param accountReceiver 
    * @param accountOriginalOwner 
    * @return String 
    **/
    public static Map<String, String> updateAccountForApproval(Account accRec, String transferComments, User accountReceiver, User accountOriginalOwner, User transferInitiator) {
        
        try {
            Account a = new Account(
                Id                   = accRec.Id, 
                Transfer_comments__c = transferComments, 
                Transfer_to__c       = accountReceiver.Id,
                Transfer_Initiator__c= transferInitiator.Id,
                Non_TS_Manager__c    = accountReceiver.ManagerId        // default to original owner's line manager
            );
            
            // get exempt profiles for approval
            List<String> approvalExemptions = DM_Initialisation.getCCRMInitialisation().Account_Transfer_Approval_Exemption__c.split(', ');
            Set<Id> activeUmbrellaGroupOwnerIds = getActiveUmbrellaGroupOwnerIds(accRec.Id);
            
            Map<String, String> resp = new Map<String, String>();
            
            // Exemptions:
            //  TS to TS
            //  CCS to TS
            //  non-TS to TS, skip approval if requesting user is a Sales Manager or National Manager or NZ Sales Manager
            //  TS to non-TS, skip approval if requesting user is a Sales Manager or National Manager or NZ Sales Manager
            //  non-TS to non-TS, skip approval if requesting user is the manager of original owner
            //  Initiator is System Administrator
            System.debug('accountOriginalOwner.IS_TS__c::' +accountOriginalOwner.IS_TS__c);
            System.debug('accountReceiver.IS_TS__c::' +accountReceiver.IS_TS__c);
            System.debug('accountOriginalOwner.ManagerId::' +accountOriginalOwner.ManagerId);
            System.debug('transferInitiator.Id::' +transferInitiator.Id);
            System.debug('transferInitiator.Profile.Name::' +transferInitiator.Profile.Name);
            if((accountOriginalOwner.IS_TS__c == true && accountReceiver.IS_TS__c == true) 
               || (accountOriginalOwner.Profile.Name == 'Sales Person Contact Centre' && accountReceiver.IS_TS__c == true)
               || (accountOriginalOwner.Profile.Name == 'NZ Sales Person Contact Centre' && accountReceiver.IS_TS__c == true)  // Added for CCRM 9376
               || (accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == true && approvalExemptions.contains(transferInitiator.Profile.Name))
               || (accountOriginalOwner.IS_TS__c == true && accountReceiver.IS_TS__c == false && approvalExemptions.contains(transferInitiator.Profile.Name))
               || (accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == false && approvalExemptions.contains(transferInitiator.Profile.Name)) //BUNDIG-23624 
               /*|| (accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == false && (accountOriginalOwner.ManagerId == transferInitiator.Id 
               || transferInitiator.Profile.Name == 'Sales Manager' // Fix for UAT_CCRM-13675
               || transferInitiator.Profile.Name == 'National Manager' 
               || transferInitiator.Profile.Name == 'NZ Sales Manager')) // Fix for UAT_CCRM-13675)
               || transferInitiator.Profile.Name == 'Sales Person BDM - Insurance')) //BUNDIG-23466
               || transferInitiator.Profile.Name == 'System Administrator' */
               || (accRec.Country__c == 'New Zealand' && activeUmbrellaGroupOwnerIds.size() > 0 && activeUmbrellaGroupOwnerIds.contains(transferInitiator.Id))
               || accountOriginalOwner.IsActive == false // Fix for PROD_INC0968062
              ) {
                  a.Transfer_approval_status__c = '';
                  update a;
                  
                  // change owner & approval status from null to approved
                  a.OwnerId = accountReceiver.Id;
                  a.AM_to_TS_Transfer__c = PROFILE_ACCOUNT_MANAGER.contains(accountOriginalOwner.Profile.Name) && accountReceiver.IS_TS__c;
                  a.Transfer_approval_status__c = 'Approved';
                  update a;
                  
                  // Map<Id, Account> oldMap = new Map<Id, Account>();
                  // oldMap.put(accRec.Id, new Account(Id = accRec.Id, OwnerId = accountOriginalOwner.Id));
                  // Map<Id, Account> newMap = new Map<Id, Account>();
                  // newMap.put(accRec.Id, new Account(Id = accRec.Id, OwnerId = accountReceiver.Id));
                  // transferAccountRelatedRecords(oldMap, newMap);
                  
                  resp.put('step', STEP_SKIP_APPROVAL);
                  resp.put('debugMsg', 'TS to TS or exempt profile');
                  
              } else {
                  // Otherwise specify the Non-TS manager and go through approval process
                  a.Transfer_approval_status__c = 'In progress';
                  
                  // If a transfer was requested from an non-TS to a TS, then the non-TS line manager will receive an approval request
                  // If a transfer was requested from a TS to an Non-TS, then the Non-TS line manager will receive an approval request
                  // If a transfer was requested from a non-TS to another non-TS, then the line manager associated with the original owner will receive an approval request
                  if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == true) {
                      a.Non_TS_Manager__c = accountOriginalOwner.ManagerId;
                  } else if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == true) {
                      a.Non_TS_Manager__c = accountReceiver.ManagerId;
                  } else if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == false) {
                      a.Non_TS_Manager__c = accountOriginalOwner.ManagerId;
                  }
                  update a;
                  
                  resp.put('step', STEP_SUBMIT_FOR_APPROVAL);
                  resp.put('debugMsg', 'Account to be updated: ' + String.valueOf(a));
                  
              }
            
            return resp;
            
        } catch(Exception e) {
            // TODO log exception
            ApplicationLogger.log('SM_AccountTransfer.updateAccountForApproval', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param oldMap 
    * @param newMap 
    * @return void 
    **/
    public static void transferAccountRelatedRecords(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        Set<Id> accountIds = oldMap.keySet();
        Set<Id> oldOwnerIds = new Set<Id>();
        Set<Id> newOwnerIds = new Set<Id>();
        Map<String, Id> acctOwnersMap = new Map<String, Id>(); // key = account Id + old Owner Id, val = new Owner Id
        
        for(Account a : oldMap.values()) {
            Id newOwnerId = newMap.get(a.Id).OwnerId;
            oldOwnerIds.add(a.OwnerId);
            newOwnerIds.add(newOwnerId);
            acctOwnersMap.put(a.Id + '' + a.OwnerId, newOwnerId);
        }

        
        // contracts (through joint object)
        // List<Customer_Contract__c> customerContracts = DM_CustomerContract.getNonExpiredCustomerContracts(accountIds, oldOwnerIds);
        // if(customerContracts.isEmpty() == false) {
        //     Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
        //     for(Customer_Contract__c cc : customerContracts) {
        //         contracts.put(cc.Contract__c, new Contract__c(Id = cc.Contract__c, OwnerId = acctOwnersMap.get(cc.Customer__c + '' + cc.Contract__r.OwnerId)));
        //     }
        //     update contracts.values();
        // }
        
        // tasks
        List<Task> tasks = DM_Task.getOpenTasksWithWhatIds(accountIds, oldOwnerIds);
        if(tasks.isEmpty() == false) {
            for(Task t : tasks) {
                t.OwnerId = acctOwnersMap.get(t.WhatId + '' + t.OwnerId);
            }
            try {
                update tasks;
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedTasks', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                throw new AuraHandledException(e.getMessage());
            }
        }

        // events
        List<Event> events = DM_Event.getOpenEventsWithWhatIds(accountIds, oldOwnerIds);
        if(events.isEmpty() == false) {
            for(Event e : events) {
                e.OwnerId = acctOwnersMap.get(e.WhatId + '' + e.OwnerId);
            }
            try {
                update events;
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedEvents', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                throw new AuraHandledException(e.getMessage());
            }
        }

        // opportunities
        List<Opportunity> opportunities = DM_Opportunity.getOpenOpportunities(accountIds, oldOwnerIds).values();
        if(opportunities.isEmpty() == false) {
            for(Opportunity o : opportunities) {
                o.OwnerId = acctOwnersMap.get(o.AccountId + '' + o.OwnerId);
            }
            try {
                update opportunities;
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedOpportunities', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        // contacts
        List<Contact> contacts = DM_Contact.getContacts(accountIds, oldOwnerIds).values();
        if(contacts.isEmpty() == false) {
            for(Contact c : contacts) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            try {
                update contacts;
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedContacts', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                throw new AuraHandledException(e.getMessage());
            }   
        }

        // cases
        List<Case> cases = DM_Case.getOpenCases(accountIds, oldOwnerIds).values();
        if(cases.isEmpty() == false) {
            for(Case c : cases) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            try {
                update cases;
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedCases', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        // spend band review
        Map<Id, Spend_Band_Review__c> reviews = DM_SpendBandReview.getSpendBandReviewsForApprover1(accountIds, oldOwnerIds);
        if(reviews.isEmpty() == false) {
            // process instances
            List<ProcessInstance> pendingApprovals = DM_ProcessInstance.getPendingProcessInstances(reviews.keySet());
            if(pendingApprovals.isEmpty() == false) {
                // need details of new owners
                Map<Id, User> newOwners = DM_User.getUsers(new List<Id>(newOwnerIds));
                
                Set<Id> reviewIdsWithPendingApproval = new Set<Id>();
                for(ProcessInstance pi : pendingApprovals) {
                    reviewIdsWithPendingApproval.add(pi.TargetObjectId);
                }

                // update all reviews with pending approval
                List<Spend_Band_Review__c> reviewList = new List<Spend_Band_Review__c>();
                for(Id reviewId : reviewIdsWithPendingApproval) {
                    Spend_Band_Review__c sbr = reviews.get(reviewId);
                    // update level 1 approver
                    sbr.Level_1_Approver__c = acctOwnersMap.get(sbr.Account__c + '' + sbr.Level_1_Approver__c);
                    sbr.OwnerId = sbr.Level_1_Approver__c;
                    // update level 2 approver
                    sbr.Level_2_Approver__c = newOwners.get(sbr.Level_1_Approver__c).ManagerId;
                    reviewList.add(sbr);
                }
                try {
                    update reviewList;
                } catch(Exception e) {
                    // TODO log exception
                    ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedSBR', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                    throw new AuraHandledException(e.getMessage());
                }
                // recall existing approval requests
                // issue new approval requests
                Map<Id, Spend_Band_Review__c> reviewMap = new Map<Id, Spend_Band_Review__c>(reviewList);
                List<Approval.ProcessWorkitemRequest> pwrs = new List<Approval.ProcessWorkitemRequest>();
                List<Approval.ProcessSubmitRequest> psrs = new List<Approval.ProcessSubmitRequest>();

                List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>(DM_ProcessInstanceWorkitem.getProcessInstanceWorkItems(reviewIdsWithPendingApproval));
                for(ProcessInstanceWorkitem wi : workItems) {
                    wi.ActorId = (reviewMap.get(wi.ProcessInstance.TargetObjectId).OwnerId);
                    /*
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                    pwr.setAction('Removed');
                    pwr.setWorkItemId(wi.Id);
                    pwr.setComments('Account Transfer');
                    pwrs.add(pwr);

                    Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
                    psr.setComments('A Spend Band Review requires your attention');
                    psr.setObjectId(wi.ProcessInstance.TargetObjectId);
                    psr.setSubmitterId(reviewMap.get(wi.ProcessInstance.TargetObjectId).OwnerId);
                    psrs.add(psr);
                    */
                }
                if(workItems.isEmpty() == false) {
                    
                    try {
                        update workItems;
                    }
                    catch(Exception e) {
                        // TODO log exception
                        ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedApproval', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
                        //throw new AuraHandledException(e.getMessage());
                        
                        AuraHandledException ex = new AuraHandledException(Label.Error_PendingSpendBandReview);
                        ex.setMessage(Label.Error_PendingSpendBandReview);
                        throw ex;
                    }
                }
                System.debug(LoggingLevel.DEBUG, 'pwrs: ' + pwrs);
                System.debug(LoggingLevel.DEBUG, 'psrs: ' + psrs);
                if(pwrs.isEmpty() == false) {
                    Approval.ProcessResult[] results = Approval.process(pwrs);
                    results.addAll(Approval.process(psrs));
                }
            }
        }

        // SFSUP-898 - Account Plans     
        Id buildersAccountPlanRecTypeId = Schema.SObjectType.Account_Plan__c.getRecordTypeInfosByDeveloperName().get('Builders').getRecordTypeId();
        
        Map<Id, String> mapOldOwnerProfile = new Map<Id, String>();
        Map<Id, User> mapNewOwnerProfile = new Map<Id, User>();

        System.debug('***oldOwnerIds: '+oldOwnerIds);
        System.debug('***newOwnerIds: '+newOwnerIds);
        
        for (User user : [SELECT Id, Profile.Name FROM User WHERE Id IN :oldOwnerIds])
            mapOldOwnerProfile.put(user.Id, user.Profile.Name);

        for (User user : [SELECT Id, Profile.Name FROM User WHERE Id IN :newOwnerIds])
            mapNewOwnerProfile.put(user.Id, user);

        System.debug('***mapOldOwnerProfile: '+mapOldOwnerProfile);
        System.debug('***mapNewOwnerProfile: '+mapNewOwnerProfile);

        List<Account_Plan__c> acctPlans = DM_AccountPlan.getAccountPlans(accountIds, oldOwnerIds, buildersAccountPlanRecTypeId);
        System.debug('***acctPlans: '+acctPlans);

        if (!acctPlans.isEmpty()) {
            for (Account_Plan__c ap : acctPlans) {
                if (mapOldOwnerProfile.get(ap.OwnerId) == Constants.AU_ACCOUNT_MANAGER_PROFILENAME) {
                    if (mapNewOwnerProfile.get(acctOwnersMap.get(ap.Account__c + '' + ap.OwnerId)).Profile.Name ==  Constants.AU_ACCOUNT_MANAGER_PROFILENAME) {
                        if (ap.Status__c == 'Active') {
                            ap.OwnerId = acctOwnersMap.get(ap.Account__c + '' + ap.OwnerId);
                        }

                        if (ap.Status__c == 'Draft') {
                            ap.End_Date__c = Date.today();
                            ap.Status__c = 'Inactive';
                        }
                    }
                    if (mapNewOwnerProfile.containsKey(acctOwnersMap.get(ap.Account__c + '' + ap.OwnerId)) && mapNewOwnerProfile.get(acctOwnersMap.get(ap.Account__c + '' + ap.OwnerId)).Profile.Name == Constants.PROFILE_TRADE_SPECIALIST) {
                        ap.End_Date__c = Date.today();
                        ap.Status__c = 'Inactive';
                    }
                }                
            }
            System.debug('***acctPlans (UPDATE): ' + acctPlans);

            try {
                update acctPlans;
            } catch(Exception e) {            
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedAccountPlan', 'Account_Plan__c', 'LWC Controller', e);
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    
    
     /**
    * @description added for CCRM15-407, to transfer related contacts when account owneship changes
    * @author Simplus MS | 08/12/2021 
    * @param oldMap 
    * @param newMap 
    * @return void 
    **/
    public static void transferAccountRelatedContactRecordsOnly(Set <Id> accountIds) {
        List<Account> lAccountsWithContacts = new List<Account>();
		lAccountsWithContacts = [SELECT Id, OwnerId, (SELECT AccountId, OwnerId FROM Contacts) FROM Account WHERE Id IN: accountIds];
        List<Contact> lContactsToUpdate = new List<Contact>();
        for(Account a : lAccountsWithContacts) {
            for (Contact c : a.Contacts){
                c.OwnerId = a.OwnerId;
                lContactsToUpdate.add(c);
            }
        }
        
        if(lContactsToUpdate.isEmpty() == false) {
            try {
                //update contacts;
                System.enqueueJob(new SM_UpdateSObjectsQueueable(lContactsToUpdate, 'SM_AccountTraansfer.transferAccountRelatedContactRecordsOnly', TRUE, 'Contact'));
            } catch(Exception e) {
                // TODO log exception
                ApplicationLogger.log('SM_AccountTransfer.transferAccountRelatedRecords.UpdateRelatedContacts', 'Account', 'Trigger', e);
            }   
        }
        
    }
    
}