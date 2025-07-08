/*******************************************************************************************************
* Class Name        : SM_AccountRequestTransfer
* Description    	: Service layer for account transfer epic. 
                      Without sharing is required as related records' owner are to be changed
* Author            : Bunnings Developer
* Created On      	: 14/08/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          14/08/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/

public without sharing class SM_AccountRequestTransfer
{
    public static String STEP_APPROVAL_IN_PROCESS = 'ApprovalInProgress';
    public static String STEP_NOT_ELIGIBLE_FOR_TRANSFER = 'NotEligibleForTransfer';
    public static String STEP_UMBRELLA_GROUP_OWNERS_ONLY = 'UmbrellaGroupOwnersOnly';
    public static String STEP_SET_TRANSFER_TO = 'SetTransferTo';
    public static String STEP_TO_TS_WITH_ACTIVE = 'ToTSWithActiveContract';
    public static String STEP_TO_NON_TS_WITH_ACTIVE = 'ToNonTSWithActiveContract';
    public static String STEP_TO_SELF = 'ToSelf';
    public static String STEP_SINGLE_ACC_TRANSFER = 'SingleAccountTransfer';
    public static String STEP_BULK_ACC_TRANSFER = 'BulkAccountTransfer';
    public static String STEP_SUBMIT_FOR_APPROVAL = 'SubmitForApproval';
    public static String STEP_SKIP_APPROVAL = 'SkipApproval';
    public static List<String> PROFILE_ACCOUNT_MANAGER = new List<String>{'Account Manager', 'NZ Account Manager'};

    /**
    * @description 
    * @author Bunnings Dev | 14/08/2024 
    * @param accountId 
    * @param runningUserId 
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> init(String accountId, String runningUserId) {

        System.debug('init in Acount Request account id:' +accountId);
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
            System.debug('approvals: ' + approvals);
            /*
            Get list of Active Umbrella Beneficiaries with Owners - Added by Paul Peñaflor
            */
            Set<Id> activeUmbrellaGroupOwnerIds = getActiveUmbrellaGroupOwnerIds(accountId);
            if(activeUmbrellaGroupOwnerIds!=null){
                System.debug('activeUmbrellaGroupOwnerIds: ' + activeUmbrellaGroupOwnerIds);
            }
            //Verify Pending Approval Process on Account
            System.debug('approvals size: ' + approvals.size());
            if(approvals.size() > 0) {
                
                resp.put('step', STEP_APPROVAL_IN_PROCESS);
                resp.put('debugMsg', 'Account already in approval');
                //else if added - Paul Peñaflor to cater to NZ Account Transfer Restriction
            } 
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
            ApplicationLogger.log('Sm_AccountRequestTransfer.init', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
        
    }

/**
    * @description 
    * @author Bunnings Dev | 14/08/2024 
    * @param accountId 
    * @param runningUserId 
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Account_Request__c accTransferDetailsinit(String accountId) {
	
        Account_Request__c resp = new Account_Request__c();

        try {


            List<Account_Request__c> accReqListSingle = DM_AccountRequest.getPendingSingleAccountTransferRequest(accountId);
            return (accReqListSingle.isEmpty()) ? null : accReqListSingle[0];
           
                     
            
        } catch(Exception e) {
            // TODO log exception
            ApplicationLogger.log('SM_AccountRequestTransfer.init', 'AccountRequest', 'LWC Controller', e); 
            throw new AuraHandledException(e.getMessage());
        }
        
    }


    /**
    * @description 
    * @author Sowjanya | 14/08/2024 
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
    * @author Sowjanya | 14/08/2024 
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
            ApplicationLogger.log('Sm_AccountRequestTransfer.updateAccountAMToTSTransfer', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Sowjanya | 14/08/2024 
    * @param accountId 
    * @param runningUserId 
    * @param transferToUserId 
    * @param transferComments 
    * @param bypassChecks ,callBulkCheck
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> checkContracts(String accountId, String runningUserId, 
    String transferToUserId, String transferComments, Boolean bypassChecks,Boolean callBulkCheck) {
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

            if(accountId!=null && transferToUserId !=null){
                List<Account_Request__c> accReqListSingle = DM_AccountRequest.getSingleAccountTransferRequests(accountId,transferToUserId);
                if(accReqListSingle.size()>0){
                    resp.put('step', STEP_SINGLE_ACC_TRANSFER);
                    resp.put('debugMsg', 'Single Acount Transfer Request is already submitted and pending for approval');
                    return resp;
                }
                if(callBulkCheck == true){
                    List<Account_Request__c> accReqListBulk = DM_AccountRequest.getBulkAccountTransferRequests(accountId,transferToUserId);
                    if(accReqListBulk.size()>0){
                        resp.put('step', STEP_BULK_ACC_TRANSFER);
                        resp.put('debugMsg', 'Bulk Acount Transfer Request is already submitted');
                        return resp;
                    }
                }
                

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
                resp = updateAccountRequestForApproval(account, transferComments, accountReceiver, accountOriginalOwner, transferInitiator);
                resp.put('debugMsg', resp.get('debugMsg') +' & bypass....');
            } else {
              

                List<Customer_Contract__c> allContracts = DM_CustomerContract.getCustomerContracts(accountId);
                System.debug('***allContracts: '+allContracts);

                Integer nonExpiredCount = SM_CustomerContract.countNonExpiredContracts(allContracts);
                Integer nonExpiredOwnerIsReviewerCount = SM_CustomerContract.countNonExpiredContractsWithOriginalReviewerSameAsAccountOwner(allContracts, accountOriginalOwner.Id);
                if(nonExpiredCount == 0 || nonExpiredOwnerIsReviewerCount == 0) {
                    // send to approval
                    resp = updateAccountRequestForApproval(account, transferComments, accountReceiver, accountOriginalOwner, transferInitiator);
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
            ApplicationLogger.log('SM_AccountRequestTransfer.checkContracts', 'AccountRequest', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Bunnings Developer
    * @param accountId 
    * @param transferComments 
    * @param accountReceiver 
    * @param accountOriginalOwner 
    * @return String 
    **/
    public static Map<String, String> updateAccountRequestForApproval(Account accRec, String transferComments, User accountReceiver, User accountOriginalOwner, User transferInitiator) {
        
        try {
            Account_Request__c a = new Account_Request__c(
                Account__c           = accRec.Id, 
                Transfer_comments__c = transferComments, 
                Transfer_to__c       = accountReceiver.Id,
                New_Owner__c       = accountReceiver.Id,
                TransferInitiator__c= transferInitiator.Id,
                Non_TS_Manager__c    = accountReceiver.ManagerId,
                PowerPass_Account_Number__c =accRec.Power_Pass_Account_Number__c,
                Account_Owner_Sales_Id__c=accountReceiver.Sales_Rep_ID__c,
                Type__c         = 'Single Account Transfer'      // default to original owner's line manager
            );
           insert a;
           System.debug('Account Request inserted :'+a.id);
           Account_Request__c b = new Account_Request__c(
                Id          = a.Id
                
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
              /*  || (accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == false && (accountOriginalOwner.ManagerId == transferInitiator.Id 
               || transferInitiator.Profile.Name == 'Sales Manager' // Fix for UAT_CCRM-13675
               || transferInitiator.Profile.Name == 'National Manager' 
               || transferInitiator.Profile.Name == 'NZ Sales Manager')) // Fix for UAT_CCRM-13675)
               || transferInitiator.Profile.Name == 'Sales Person BDM - Insurance')) //BUNDIG-23466
               || transferInitiator.Profile.Name == 'System Administrator'  */
               || (accRec.Country__c == 'New Zealand' && activeUmbrellaGroupOwnerIds.size() > 0 && activeUmbrellaGroupOwnerIds.contains(transferInitiator.Id))
               || accountOriginalOwner.IsActive == false
              ) {
                
                  // change owner & approval status from null to approved
                  //a.OwnerId = accountReceiver.Id;
                  b.AM_to_TS_Transfer__c = PROFILE_ACCOUNT_MANAGER.contains(accountOriginalOwner.Profile.Name) && accountReceiver.IS_TS__c;
                  b.Transfer_approval_status__c = 'Approved';
                  update b;
                  
                     System.debug('debug Update Acc Req:'+b.id);
                  resp.put('step', STEP_SKIP_APPROVAL);
                  resp.put('debugMsg', 'TS to TS or exempt profile');
                  
              } else {
                
                  // Otherwise specify the Non-TS manager and go through approval process
                  b.Transfer_approval_status__c = 'In progress';
                  
                  // If a transfer was requested from an non-TS to a TS, then the non-TS line manager will receive an approval request
                  // If a transfer was requested from a TS to an Non-TS, then the Non-TS line manager will receive an approval request
                  // If a transfer was requested from a non-TS to another non-TS, then the line manager associated with the original owner will receive an approval request
                  if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == true) {
                      b.Non_TS_Manager__c = accountOriginalOwner.ManagerId;
                  } else if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == true) {
                      b.Non_TS_Manager__c = accountReceiver.ManagerId;
                  } else if(accountOriginalOwner.IS_TS__c == false && accountReceiver.IS_TS__c == false) {
                      b.Non_TS_Manager__c = accountOriginalOwner.ManagerId;
                  }
                  update b;
                  
                  resp.put('step', STEP_SUBMIT_FOR_APPROVAL);
                  resp.put('debugMsg', 'Account Request to be updated: ' + String.valueOf(a));
                  
              }
            
            return resp;
            
        } catch(Exception e) {
            // TODO log exception
            ApplicationLogger.log('Sm_AccountRequestTransfer.updateAccountForApproval', 'Account', 'LWC Controller', e); //Added 04.Jun.2021
            throw new AuraHandledException(e.getMessage());
        }
    }

        /**
    * @description  transferAccountAndRelatedRecords
    * @param accountIdSet, newOwnerIdset,oldOwnerIdset
    * @param updateAccReq 
    * @return void 
    **/
    public static void transferAccountAndRelatedRecords(Set<Id> accountIdSet, Set<Id> newOwnerIdset,Set<Id> oldOwnerIdset,List<Account_Request__c> updateAccReq) {
       
        system.debug('transferAccountAndRelatedRecords');
        Set<Id> accountIds = accountIdSet;
        Set<Id> oldOwnerIds = oldOwnerIdset;
        Set<Id> newOwnerIds = newOwnerIdset;
        Id newownid = new List<Id> (newOwnerIds).get(0);
        String arid = updateAccReq[0].id;
        //accounts

        List<Account> accounts= DM_Account.getAccountsBySet(accountIds);
        if(accounts.isEmpty() == false) {
            for(Account a : accounts) {
                a.OwnerId = newownid;
            }
            
            
            try {
                update accounts;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.accErrorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedAccount', 'Account', 'Trigger', e, arid); //Added 04.Jun.2021
                return;
            }
        }
        // tasks
        List<Task> tasks = DM_Task.getOpenTasksWithWhatIds(accountIds, oldOwnerIds);
        if(tasks.isEmpty() == false) {
            for(Task t : tasks) {
                t.OwnerId = newownid;
            }
            try {
                update tasks;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.errorFlag = true;
               ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedTask', 'Task', 'Trigger', e, arid); //Added 04.Jun.2021
                
            }
        }
        // events
        List<Event> events = DM_Event.getOpenEventsWithWhatIds(accountIds, oldOwnerIds);
        if(events.isEmpty() == false) {
            for(Event e : events) {
                e.OwnerId = newownid;
            }
            try {
                update events;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedEvent', 'Event', 'Trigger', e, arid); //Added 04.Jun.2021
                           
            }
        }
        // opportunities
        List<Opportunity> opportunities = DM_Opportunity.getOpenOpportunities(accountIds, oldOwnerIds).values();
        if(opportunities.isEmpty() == false) {
            for(Opportunity o : opportunities) {
                o.OwnerId = newownid;
            }
            try {
                update opportunities;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedOpportunity', 'Opportunity', 'Trigger', e, arid); //Added 04.Jun.2021
                             
            }
        }
        
        // contacts
        List<Contact> contacts = DM_Contact.getContacts(accountIds, oldOwnerIds).values();
        if(contacts.isEmpty() == false) {
            for(Contact c : contacts) {
                c.OwnerId = newownid;
            }
            try {
                update contacts;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedContact', 'Contact', 'Trigger', e, arid); //Added 04.Jun.2021
                
            }   
        }
        // cases
        List<Case> cases = DM_Case.getOpenCases(accountIds, oldOwnerIds).values();
        if(cases.isEmpty() == false) {
            for(Case c : cases) {
                c.OwnerId = newownid;
            }
            try {
                update cases;
            } catch(Exception e) {
                // TODO log exception
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedCase', 'Case', 'Trigger', e, arid); //Added 04.Jun.2021
                
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
                    sbr.Level_1_Approver__c = newownid;
                    sbr.OwnerId = sbr.Level_1_Approver__c;
                    // update level 2 approver
                    sbr.Level_2_Approver__c = newOwners.get(sbr.Level_1_Approver__c).ManagerId;
                    reviewList.add(sbr);
                }
                try {
                    update reviewList;
                } catch(Exception e) {
                    // TODO log exception
                    AccountRequestTriggerHandler.errorFlag = true;
                    ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedSBR', 'Spend_Band_Review__c', 'Trigger', e, arid); //Added 04.Jun.2021
                        
                }
                // recall existing approval requests
                // issue new approval requests
                Map<Id, Spend_Band_Review__c> reviewMap = new Map<Id, Spend_Band_Review__c>(reviewList);
                List<Approval.ProcessWorkitemRequest> pwrs = new List<Approval.ProcessWorkitemRequest>();
                List<Approval.ProcessSubmitRequest> psrs = new List<Approval.ProcessSubmitRequest>();
                List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>(DM_ProcessInstanceWorkitem.getProcessInstanceWorkItems(reviewIdsWithPendingApproval));
                for(ProcessInstanceWorkitem wi : workItems) {
                    wi.ActorId = (reviewMap.get(wi.ProcessInstance.TargetObjectId).OwnerId);
                 
                }
                if(workItems.isEmpty() == false) {
                    
                    try {
                        update workItems;
                    }
                    catch(Exception e) {
                        // TODO log exception
                        AccountRequestTriggerHandler.errorFlag = true;
                        ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedSBRApprovalProcessInstance', 'ProcessInstanceWorkitem', 'Trigger', e, arid); //Added 04.Jun.2021
                             
                    
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
                    if (mapNewOwnerProfile.get(newownid).Profile.Name ==  Constants.AU_ACCOUNT_MANAGER_PROFILENAME) {
                        if (ap.Status__c == 'Active') {
                            ap.OwnerId = newownid;
                        }
                        if (ap.Status__c == 'Draft') {
                            ap.End_Date__c = Date.today();
                            ap.Status__c = 'Inactive';
                        }
                    }
                    if (mapNewOwnerProfile.containsKey(newownid) && mapNewOwnerProfile.get(newownid).Profile.Name == Constants.PROFILE_TRADE_SPECIALIST) {
                        ap.End_Date__c = Date.today();
                        ap.Status__c = 'Inactive';
                    }
                }                
            }
            System.debug('***acctPlans (UPDATE): ' + acctPlans);
            try {
                update acctPlans;
            } catch(Exception e) {            
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedAccountPlan', 'Account_Plan__c', 'Trigger', e, arid); //Added 04.Jun.2021
         
            }
        }


        //NonExpiredContracts
        List<Contract__c> contractList = new List<Contract__c>();
        if(accountIds.isEmpty() == false) {
            List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(accountIds, oldOwnerIds);
            User managerIdUser = DM_User.getUser(String.valueof(newownid)); //Get Manager list
            if(contracts.isEmpty() == false) {
                
                for(Customer_Contract__c cc : contracts) {
                    if(cc.Customer__r.Account_Transferrable__c == 'Yes'){
                        Contract__c contract = new Contract__c();
                        contract.Id = cc.Contract__r.Id;
                        contract.OwnerId = newownid;
                        contract.New_Reviewer__c = newownid;
                        contract.New_Approver__c = managerIdUser.ManagerId;
                        contractList.add(contract);
                    }
                }
                   
                
            }
        }
        
        if(contractList!=null && !contractList.isEmpty()){
            try {
                
                system.debug('contractList here :: '+contractList);
                update contractList;
                 
            } catch (Exception e) {
               
                AccountRequestTriggerHandler.errorFlag = true;
                ApplicationLogger.logException('SM_AccountRequestTransfer.transferAccountAndRelatedRecords.UpdateRelatedContract', 'Contract__c', 'Trigger', e, arid); //Added 04.Jun.2021
             }
        }


        
       

        
       
    }

    /**
    * @description : transferAccountRelatedRecords
    * @author Bunnigs dev
    * @param updateAccList 
    * @param oldOwnerId,  newOwnerId , lUpdateAccountRequests
    * @return void 
    **/
    public static void transferAccountRelatedRecords(List<Account> updateAccList, String oldOwnerId, String newOwnerId,List<Account_Request__c> lUpdateAccountRequests,Map<id,id> accReqMap) {
        System.debug('inside transferAccountRelatedRecords');
        system.debug('lUpdateAccountRequests transfer :: '+lUpdateAccountRequests);
        system.debug('accReqMap :: '+accReqMap);
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oldOwnerIds = new Set<Id>();
        Set<Id> newOwnerIds = new Set<Id>();
        Map<String, Id> acctOwnersMap = new Map<String, Id>(); // key = account Id + old Owner Id, val = new Owner Id
        
        for(Account a : updateAccList) {
            oldOwnerIds.add(oldOwnerId);
            newOwnerIds.add(newOwnerId);
            accountIds.add(a.Id);
            acctOwnersMap.put(a.Id + '' + oldOwnerId, newOwnerId);
        }
        
        
        // tasks
        List<Task> tasks = DM_Task.getOpenTasksWithWhatIds(accountIds, oldOwnerIds);
        if(tasks.isEmpty() == false) {
            for(Task t : tasks) {
                t.OwnerId = acctOwnersMap.get(t.WhatId + '' + t.OwnerId);
            }
           
            if(tasks.size() != 0){
                List<Database.SaveResult> taskResults = Database.update(tasks, false);
                for (Database.SaveResult result : taskResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedTasks', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            }
        }
        
        // events
        List<Event> events = DM_Event.getOpenEventsWithWhatIds(accountIds, oldOwnerIds);
        if(events.isEmpty() == false) {
            for(Event e : events) {
                e.OwnerId = acctOwnersMap.get(e.WhatId + '' + e.OwnerId);
            }
           
            if(events.size() != 0){
                List<Database.SaveResult> eventResults = Database.update(events, false);
                for (Database.SaveResult result : eventResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedEvents', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                    System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            } 
        }
        
        // opportunities
        List<Opportunity> opportunities = DM_Opportunity.getOpenOpportunities(accountIds, oldOwnerIds).values();
        if(opportunities.isEmpty() == false) {
            for(Opportunity o : opportunities) {
                o.OwnerId = acctOwnersMap.get(o.AccountId + '' + o.OwnerId);
            }
            
            if(opportunities.size() != 0){
                List<Database.SaveResult> opptyResults = Database.update(opportunities, false);
                for (Database.SaveResult result : opptyResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                      ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedOpportunities', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                        System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            } 
        }
        
        // contacts
        List<Contact> contacts = DM_Contact.getContacts(accountIds, oldOwnerIds).values();
        if(contacts.isEmpty() == false) {
            for(Contact c : contacts) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            

            if(contacts.size() != 0){
                List<Database.SaveResult> conResults = Database.update(contacts, false);
                for (Database.SaveResult result : conResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                     ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedContacts', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                    System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            } 
        }
        
        // cases
        List<Case> cases = DM_Case.getOpenCases(accountIds, oldOwnerIds).values();
        if(cases.isEmpty() == false) {
            for(Case c : cases) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            
            if(cases.size() != 0){
                List<Database.SaveResult> openResults = Database.update(cases, false);
                for (Database.SaveResult result : openResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedCases', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                        System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
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
                
                if(reviewList.size() != 0){
                    List<Database.SaveResult> reviewResults = Database.update(reviewList, false);
                    for (Database.SaveResult result : reviewResults) {
                    if (!result.isSuccess()){
                        for (Database.Error err : result.getErrors()){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedSpendBandReview', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                            System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                        }
                    }
                    }
                } 
                
                // recall existing approval requests
                // issue new approval requests
                Map<Id, Spend_Band_Review__c> reviewMap = new Map<Id, Spend_Band_Review__c>(reviewList);
                List<Approval.ProcessWorkitemRequest> pwrs = new List<Approval.ProcessWorkitemRequest>();
                List<Approval.ProcessSubmitRequest> psrs = new List<Approval.ProcessSubmitRequest>();
                
                List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>(DM_ProcessInstanceWorkitem.getProcessInstanceWorkItems(reviewIdsWithPendingApproval));
                for(ProcessInstanceWorkitem wi : workItems) {
                    wi.ActorId = (reviewMap.get(wi.ProcessInstance.TargetObjectId).OwnerId);
                    
                }
                if(workItems.isEmpty() == false) {
                    update workItems;
                }
                System.debug(LoggingLevel.DEBUG, 'pwrs: ' + pwrs);
                System.debug(LoggingLevel.DEBUG, 'psrs: ' + psrs);
                if(pwrs.isEmpty() == false) {
                    Approval.ProcessResult[] results = Approval.process(pwrs);
                    results.addAll(Approval.process(psrs));
                }
                
                
            }
        }

        // SFSUP-898 - Account Plan
        List<Account_Plan__c> acctPlanToUpdate = new List<Account_Plan__c>();

        Map<Id, String> mapCurrentOwnerProfile = new Map<Id, String>();
        Map<Id, Account> mapNewOwnerProfile = new Map<Id, Account>();

        System.debug('***oldOwnerIds: '+oldOwnerIds);
        System.debug('***newOwnerIds: '+newOwnerIds);

        for (Account_Plan__c acct : [SELECT Id, Account__c, Owner.Profile.Name FROM Account_Plan__c WHERE Account__c IN :accountIds AND OwnerId IN :oldOwnerIds]) {
            mapCurrentOwnerProfile.put(acct.Account__c, acct.Owner.Profile.Name);
        }

        for (Account acct : [SELECT Id, OwnerId, Owner.Profile.Name FROM Account WHERE Id IN :accountIds AND OwnerId IN :newOwnerIds]) {
            mapNewOwnerProfile.put(acct.Id, acct);
        }
        System.debug('***mapCurrentOwnerProfile: '+mapCurrentOwnerProfile);
        System.debug('***mapNewOwnerProfile: '+mapNewOwnerProfile);
                
        Id buildersAccountPlanRecTypeId = Schema.SObjectType.Account_Plan__c.getRecordTypeInfosByDeveloperName().get('Builders').getRecordTypeId();
        List<Account_Plan__c> acctPlans = DM_AccountPlan.getAccountPlans(accountIds, oldOwnerIds, buildersAccountPlanRecTypeId);
        System.debug('***acctPlans: '+acctPlans);

        /*if (acctPlans.isEmpty()) {
            return;
        }*/
      if(!acctPlans.isEmpty()){
            Map<Id, Account_Plan__c> mapAccountPlan = new Map<Id, Account_Plan__c>(acctPlans);

            for (Account_Plan__c acctPlan : mapAccountPlan.values()) {
                if (mapCurrentOwnerProfile.get(acctPlan.Account__c) == Constants.AU_ACCOUNT_MANAGER_PROFILENAME) {                                        
                    if (mapNewOwnerProfile.get(acctPlan.Account__c).Owner.Profile.Name == Constants.AU_ACCOUNT_MANAGER_PROFILENAME) {
                        if (acctPlan.Status__c == 'Active')
                            acctPlanToUpdate.add(new Account_Plan__c(Id = acctPlan.Id, OwnerId = mapNewOwnerProfile.get(acctPlan.Account__c).OwnerId));

                        if (acctPlan.Status__c == 'Draft')
                            acctPlanToUpdate.add(new Account_Plan__c(Id = acctPlan.Id, End_Date__c = Date.today(), Status__c = 'Inactive'));
                        
                    } 
                    if (mapNewOwnerProfile.get(acctPlan.Account__c).Owner.Profile.Name == Constants.PROFILE_TRADE_SPECIALIST && acctPlan.Status__c == 'Draft') {                    
                        acctPlanToUpdate.add(new Account_Plan__c(Id = acctPlan.Id, End_Date__c = Date.today(), Status__c = 'Inactive'));
                    }
                }
            }
            System.debug('***acctPlanToUpdate: '+acctPlanToUpdate);        
            
            if(acctPlanToUpdate.size() != 0){
                List<Database.SaveResult> accplanResults = Database.update(acctPlanToUpdate, false);
                for (Database.SaveResult result : accplanResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                     ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedAccountPlans', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 

                        System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            } 

        }
        
        
        List<Account_Request__c> accReqUpd = new List<Account_Request__c>();
        List<id> accReqList = new List<id>();
        if (!lUpdateAccountRequests.isEmpty()) {
            
                for(Account_Request__c a : lUpdateAccountRequests) {
                    System.debug('account request:'+a.id);
                    try{
                    if(accReqMap.containsKey(a.id)){
                        a.Status__c='Completed';  
                        a.Transfer_to__c = acctOwnersMap.get(accReqMap.get(a.id) + '' + a.Previous_Owner__c);
                        system.debug('Transfer to :'+acctOwnersMap.get(accReqMap.get(a.id) + '' + a.Previous_Owner__c));
                    }else{
                        a.Status__c='Failed'; 
                        a.Failed_Reason__c = 'Account Transfer Failed';
                    }
                    
    
                     
                }
                catch(Exception e){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedAccountRequest', 'AccountRequest', 'BulkBatch', e.getMessage()); 
                    a.Status__c='Failed'; 
                    a.Failed_Reason__c = e.getMessage();
                    System.debug('Error: '+ e.getMessage()); 
                }
                accReqUpd.add(a); 
            }
            
            if(accReqUpd.size() != 0){
                List<Database.SaveResult> accReqResults = Database.update(accReqUpd, false);
                for (Database.SaveResult result : accReqResults) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                    ApplicationLogger.log('SM_AccountRequestTransfer.transferAccountRelatedRecords.UpdateRelatedAccountRequests', 'AccountRequest', 'BulkBatch', result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
 
                        System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                }
                }
            } 

        }

    }

     /**
    * @description - Send Transfer Notification to Current Account Owner
    * @author Bunnings dev 
    * @param transferFromUserId
    * @return Map<String,String>
    **/
    public static void sendBulkAccountTransferErrorNotification(String transferFromUserId) {
        Map<String, Object> flowInput = new Map<String, Object>();
        flowInput.put('customNotificationTypeName', 'Account Transfer Notification');
        flowInput.put('targetId', transferFromUserId);
        flowInput.put('recipientIds', new List<String>{transferFromUserId});
        flowInput.put('notificationTitle', 'Bulk Account Transfer Notification');
        flowInput.put('notificationBody', 'Error occurred while transferring accounts. Please contact administrator to resolve the issue');
        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
        sendCustomNotifiFlow.start();
    }
    
    /**
    * @description - Send Transfer Notification to Current Account Owner
    * @author Bunnings dev 
    * @param transferFromUserId
    * @return Map<String,String>
    **/
    public static void sendBulkAccountTransferNotification(String transferToUserId) {
        Map<String, Object> flowInput = new Map<String, Object>();
        flowInput.put('customNotificationTypeName', 'Account Transfer Notification');
        flowInput.put('targetId', transferToUserId);
        flowInput.put('recipientIds', new List<String>{transferToUserId});
        flowInput.put('notificationTitle', 'Bulk Account Notification');
        flowInput.put('notificationBody', 'Multiple accounts have been transferred to you. Remember to review the open tasks and events in your calendar.');
        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
        sendCustomNotifiFlow.start();
    }
    
}