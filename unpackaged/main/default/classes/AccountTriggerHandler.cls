/*******************************************************************************************************
* Class Name        : AccountTriggerHandler
* Description       : Account trigger handler
* Author            : Simplus - Haider Raza
* Created On        : 15/04/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           15/04/2020      1000                Initial version
* Yi Zhang              20/05/2020      2000                Added beforeUpdate & afterUpdate
* Francis Benzon        29/06/2020      3000                Added beforeInsert
* Yi Zhang              20/07/2020      2000                Added GST Number validation for NZ Prospect
* Purba Ghosh           31/08/2020      4000                Added apprentice to customer convert
* Yi Zhang              28/09/2020      5000                Added handling of terminated/inactive accounts
* Yi Zhang              26/10/2020      6000                Converted powerpass account flows (match, conversion, assignment)
* Simplus MS            9/04/2021       7000                Added updateCustomerPriceList
* Simplus MS            21/05/2021      8000                CCRM 13819 : Added logic for onboarding calls creation to check  NOT to create for both parent and child and when Do not Call is TRUE
* Simplus MS            24/05/2021      9000                CCRM 13836 : Added logic for onboarding calls creation to check  NOT to create for accounts with  inactive and terminated status
                                                                         Added logic for onboarding calls deletion when accounts are changed to inactive / terminated status
* Simplus MS            18/06/2021      10000               INC0956629/INC0975202: Added logic for assigning the account to Default User when it doesn't fall to any criteria in powerpass assignment
* Simplus MS            18/07/2021      11000               Added logic in createCallCycleTasksForCreditLimitIncrease for INC0982513
* Simplus MS            09/08/2021      12000               Added logic for CCRM-13943 - when PowerPass Account Manager field is not blank, And the Home Store has no ASM, Then Account Owner is the Default Trade Specialist
* Simplus MS            23/08/2021      13000               Fix for CCRM15-110
* Simplus MS            23/08/2021      14000               CCRM15-56 (AC1) - Commented logic for Onboarding Call creation during account creation 
* Bunnings              20/09/2021      15000               CCRM15-83, 140 : Set marketing account flag before insert AND before update
* Bunnings              29/09/2021      16000               CCRM15-242 : hotfix
* Simplus MS            18/10/2021                          CCRM15-252 : Remove Verified_Email__c check When Marketing_Account__c or Marketing_Contact__c are populated
* Simplus MS            28/10/2021      18000               Added Logic for CCRM15-79, CCRM15-80 & CCRM15-180
* Simplus MS            05/11/2021      19000               Optimized updateContactMarketingFlag method
* Simplus MS            14/11/2021      20000               Added logic for CCRM15-275 and CCRM15-227 - Account Owner and Powerpass Account Created Date when the Account has no home store
* Simplus MS            16/11/2021      21000               CCRM15-407 - Automatically transfer accounts when TS moves store/leaves business/changes role
* Simplus MS            21/12/2021      22000               CCRM15-541 - More Errors in Upserting Customer Price List using DataLoader
* Simplus MS            14/02/2022      23000               Added for SFSUP-302 - Person Account Changes
* Simplus MS            09/03/2022      24000               Added for SFSUP-246 - No credit limit increase call should be created
* Simplus MS            11/03/2022      25000               Added for SFSUP-400 - No Platform Events generated when account owner updated
* Simplus MS            28/03/2022      26000               Added for SFSUP-368 - Credit limit increase call should be created on parent only
* Simplus MS            20/04/2022      27000               Added for SFSUP-433 - Assigned store not updating when accounts are transferred
* Simplus MS            20/05/2022      27000               Added for SFSUP-745 - Incorrect Account Owner Sales Id in Account
* Bunnings Dev			13/07/2022		28000				SFSUP-745 - Incorrect Account Owner Sales Id in Account
* Bunnings Dev			19/07/2022		29000				SFSUP-876 - Owner Sales Id not updated when Account is manually transferred from TS to an AM
* Bunnings Dev          08/08/2022      30000               SFSUP-877 - Assigned Store Not Populating for NZ Trade Specialist.
* Bunnings Dev			01/09/2022      31000				SFSUP-910 - Incorrect Account Owner Sales Rep Id after SFSUP-745 and data fix
* Bunnings Dev			26/10/2022      32000				BUNDIG-11663 - Stop replication of customer price list on Contract Group accounts
* Bunnings Dev          07/02/2023      33000               BUNDIG-16248 - Stop Replication of Customer Contracts for Contract Group Associations
* Bunnings Dev          27/06/2023      34000               BUNDIG-22457 - comment out calling checkNZGSTNumber
* Bunnings Dev          22/10/2024      35000               CRMS-226 - New Account Number Fields on Account Object for V1 Integration Feed
* Jasper R. Galapon     03/04/2024      35000               BUNDIG-31597 - Convert Account Update Action Process Builder to Apex Trigger
******************************************************************************************************/
public without sharing class AccountTriggerHandler {
    public static Map<Id, Task> manualCallCycleTasks = new Map<Id, Task>();     // to store tasks to be inserted
    public static Set<Account> creditIncreasedAccounts = new Set<Account>();    // to store accounts of which credit limit increased
    public static Boolean triggerInProgress = false;                            // to prevent trigger from running recursively
    public static Boolean manulCallCycleTasksInserted = false;                  // to prevent double up on manual call cycle task creation
    public static final String ERROR_INVALID_GST_NUMBER = 'Please enter a valid GST Number';
    public static final String QUARANTINE_ERROR = 'New call cycle task cannot be created because a task is existing within the quarantine months.';
    public static boolean runOnce = true;

    /**
    * @description  Business logic before account insert
    * @author       Francis Benzon| 29/06/2020 
    * @param trigger.new 
    **/
    public static void beforeInsert(List<Account> lstNewAccount) { 
        
        List<Account> lstNewBusinessAcc = new List<Account>();
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;
        for(Account acc : lstNewAccount) {
            if(acc.RecordTypeId != personAccRecordTypeId) {
                System.debug('Business Account'+acc);
                lstNewBusinessAcc.add(acc);
            }
        }
        
        if(!lstNewBusinessAcc.isEmpty()){
        
            Map<ID, ID> acctID_ownerIDMap = new Map<ID, ID>();
            Map<ID, ID> acctID_storeIDMap = new Map<ID, ID>();
            List<Account> assignedStoreAcctList =  new List<Account>();
            
            for(Account acct : [SELECT ID, OwnerID, Owner.Profile.Name, Assigned_Store__c, Account_Owner_Sales_Id__c, Owner.Sales_Rep_ID__c FROM Account
                                WHERE ID IN :lstNewBusinessAcc]) 
            {
                
                //Added by Simplus MS 07.Dec.2021 - Original logic from 'Changed Owner with Sales Id' node in Account Update Actions PB, to avoid 'Apex CPU time limit exceeded'
                acct.Account_Owner_Sales_Id__c = acct.Owner.Sales_Rep_ID__c; 
                
                if(acct.Owner.Profile.Name.contains(Label.Trade_Specialist)) {
                    assignedStoreAcctList.add(acct);
                    acctID_ownerIDMap.put(acct.ID, acct.OwnerID);
                }
            }
            
            if(!assignedStoreAcctList.isEmpty())
                acctID_storeIDMap = SM_Account.mapAssignedStore(assignedStoreAcctList, acctID_ownerIDMap);
            
            for(Account acct : lstNewBusinessAcc) {
                if(!acctID_storeIDMap.isEmpty() && acctID_storeIDMap.containsKey(acct.ID)) {
                    acct.Assigned_Store__c = acctID_storeIDMap.get(acct.ID);
                }
                if(acct.ABN__c != null) {
                    acct.ABN__c = SM_StringFormatter.abnFormat(acct.ABN__c);
                }
                if(acct.ACN__c != null) {
                    acct.ACN__c = SM_StringFormatter.acnFormat(acct.ACN__c);
                }
                if(acct.GST_Number__c != null) {
                    acct.GST_Number__c = SM_StringFormatter.gstFormat(acct.GST_Number__c);
                }
                // beforeInsert part of Powerpass Account Match flow
                if(powerpassMatchRequired(acct)) {
                    acct = updatePowerpassAccountRecordType(acct);
                }
                //Simplus.MS 14.Nov.21 - Added for CCRM15-275 and CCRM15-227 when Powerpass Account has no Home Store 
                if (acct.Home_Store__c == null){
                    assignmentsWhenNoHomeStore(acct);
                }
            }
            
            // validate GST Number
            // comment out for BUNDIG-22457
            //checkNZGSTNumber(lstNewBusinessAcc);
            
            //CCRM15-83 setting marketing flags
            setMarketingFlags(null, null, lstNewBusinessAcc, 'beforeInsert');

            //CRMS-226 - New Account Number Fields on Account Object for V1 Integration Feed
            if(DM_FeatureToggle.getFeatureToggleEnabled('Accnt_Number_Domain_Feed_v1')){
                updateAccountNumberandAccountIdentificaton(lstNewBusinessAcc);
            }
           
        }
    }
    
    /**
* @description  Business logic before account update
* @author       Yi Zhang | 20/05/2020 
* @param oldMap 
* @param newMap 
**/
    public static void beforeUpdate(Map<Id, Account> oldMap, Map<Id, Account> newMap, List<Account> lstNewAccount) {
        
        Map<Id, Account> oldMapBusinessAcc = new Map<Id, Account>();
        Map<Id, Account> newMapBusinessAcc = new Map<Id, Account>();
        List<Account> lstNewBusinessAcc = new List<Account>();
        List<Account> lAccounstToSetAssignedStore =  new List<Account>();
        Map<Id, String> accMapToSalesRepId = new Map<Id, String>(); //Added for SFSUP-745 
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;
        for(Account acc : lstNewAccount) {
            if(acc.RecordTypeId != personAccRecordTypeId) {
                System.debug('Business Account'+acc);
                system.debug('433 Debug ::: Owner Id >>> '+acc.OwnerId);
                lstNewBusinessAcc.add(acc);

                Account oldAccount = oldMap.get(acc.Id);
                oldMapBusinessAcc.put(oldAccount.ID, oldAccount);
                System.debug('Business oldAccount Account'+oldAccount);

                Account newAccount = newMap.get(acc.Id);
                newMapBusinessAcc.put(newAccount.ID, newAccount);
                System.debug('Business newAccount Account'+newAccount);
                
                //SFSUP-433 - Assigned store not updating when accounts are transferred
                lAccounstToSetAssignedStore.add(acc);
            }
        }

        // Start - Added 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account
        Map<Id, String> mapAcctOwner = new Map<Id, String>();
		Map<Id, String> mapAcctUser = new Map<Id, String>();
        
        for (Account acct : newMap.values()) {         
            mapAcctOwner.put(acct.Id, acct.OwnerId);
        }
        // End - Added 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account
        
        // Commented - 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account
        //Added by Simplus MS 20.May.2022 for SFSUP-745 - Incorrect Account Owner Sales Id in Account
        /*for(Account acct : [SELECT ID, OwnerId, Account_Owner_Sales_Id__c, Owner.Sales_Rep_ID__c FROM Account WHERE ID IN :lstNewBusinessAcc]) 
        {
            accMapToSalesRepId.put(acct.Id, acct.Owner.Sales_Rep_ID__c);
        }*/
        
        // Start - Added 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account
        Map<String, String> mapOwnerSalesRep = new Map<String, String>();
        Map<String, String> mapAccountSalesRep = new Map<String, String>();
        
        for (User u : [SELECT Id, Sales_Rep_ID__c FROM User WHERE Id IN :mapAcctOwner.values()]) {
			mapOwnerSalesRep.put(u.Id, u.Sales_Rep_ID__c);
        }
        
        for (Id ids : mapAcctOwner.keySet()) {            
            if (mapOwnerSalesRep.containsKey(mapAcctOwner.get(ids))) {
                mapAccountSalesRep.put(ids, mapOwnerSalesRep.get(mapAcctOwner.get(ids)));
            }
        }
                        
        for (Account acc : newMap.values()) {
            if (mapAccountSalesRep.containsKey(acc.Id)) {
                acc.Account_Owner_Sales_Id__c = mapAccountSalesRep.get(acc.Id);
            }               
        }
        // End - Added 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account

        if(!lstNewBusinessAcc.isEmpty()){
            for(Account acct : lstNewBusinessAcc) {
                
                // Commented - 13/07/2022 - SFSUP-745 - Incorrect Account Owner Sales Id in Account
                //Added by Simplus MS 20.May.2022 for SFSUP-745 - Incorrect Account Owner Sales Id in Account
                //if (accMapToSalesRepId.containsKey(acct.Id)){
                //    acct.Account_Owner_Sales_Id__c = accMapToSalesRepId.get(acct.Id);
                //}
                
                if(acct.ABN__c != null && acct.ABN__c != oldMapBusinessAcc.get(acct.ID).ABN__c) {
                    acct.ABN__c = SM_StringFormatter.abnFormat(acct.ABN__c);
                }
                if(acct.ACN__c != null && acct.ACN__c != oldMapBusinessAcc.get(acct.ID).ACN__c) {
                    acct.ACN__c = SM_StringFormatter.acnFormat(acct.ACN__c);
                }
                if(acct.GST_Number__c != null && acct.GST_Number__c != oldMapBusinessAcc.get(acct.ID).GST_Number__c) {
                    acct.GST_Number__c = SM_StringFormatter.gstFormat(acct.GST_Number__c);
                }
                
            }
        }
                
        if(!oldMapBusinessAcc.isEmpty() && !newMapBusinessAcc.isEmpty()){
            
            updateOwnerForTransferApprovedAccounts(oldMapBusinessAcc, newMapBusinessAcc);
            
            prepareCallCycleTasks(oldMapBusinessAcc, newMapBusinessAcc);
            
            // validate GST Number
            // comment out for BUNDIG-22457
            // checkNZGSTNumber(oldMapBusinessAcc, newMapBusinessAcc);
            
            //check Approval Process for Rejection
            checkForApprovalRejectionComment(oldMapBusinessAcc, newMapBusinessAcc);
            
            // Convert an existing apprentice account to customer account
            convertApprenticeToCustomer(oldMapBusinessAcc, newMapBusinessAcc);
            // inactiveChildAccCustomerContract(oldMapBusinessAcc, newMapBusinessAcc); - BUNDIG-16248 - Commented out
            
            //CCRM15-83 setting marketing flags
            setMarketingFlags(oldMapBusinessAcc, newMapBusinessAcc, null, 'beforeUpdate');
            
            //SFSUP-433 - Assigned store not updating when accounts are transferred
            if (!lAccounstToSetAssignedStore.isEmpty()){
                system.debug('433 Debug ::: Account eligible 2');
                setAssignedStore(lAccounstToSetAssignedStore, oldMapBusinessAcc);
            }
        }
    }

    /**
    *  Method name  :  beforeDelete
    *  Description  :  Before deletion
    *  Author       :  Haider Raza
    *  Parameter    :  List<Account> allAccounts
    *                  Map<Id, Account> allAccountsByIds
    *                  List<Account> oldAccounts
    **/
    public static void beforeDelete(List<Account> allAccounts, Map<Id, Account> oldMap, List<Account> oldAccounts){
        
        Map<Id, Account> oldMapBusinessAcc = new Map<Id, Account>();
        List<Account> lstOldBusinessAcc = new List<Account>();
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;
        for(Account acc : oldAccounts) {
            if(acc.RecordTypeId != personAccRecordTypeId) {
                System.debug('Business Account'+acc);
                lstOldBusinessAcc.add(acc);

                Account oldAccount = oldMap.get(acc.Id);
                oldMapBusinessAcc.put(oldAccount.ID, oldAccount);
                System.debug('Business oldAccount Account'+oldAccount);

            }
        }
        
        String profileName = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        System.debug('profileName: ' + profileName);
        if(!(profileName == Constants.PROFILE_SYSTEM_ADMIN || profileName == Constants.PROFILE_INTEGRATIONS_USER || Test.isRunningTest())){
            List<Account> accountsNotToDelete = new List<Account>([
                SELECT Id, RecordType.DeveloperName
                FROM Account
                WHERE Id IN:lstOldBusinessAcc
                AND (
                    RecordType.DeveloperName = 'AU_Customer'
                    OR  RecordType.DeveloperName = 'NZ_Customer'
                    OR  RecordType.DeveloperName = 'AU_Apprentice'
                    OR  RecordType.DeveloperName = 'NZ_Apprentice')
            ]);
            
            if(!accountsNotToDelete.isEmpty() && !oldMapBusinessAcc.isEmpty()){
                AccountTriggerHandler.avoidDelete(accountsNotToDelete, oldMapBusinessAcc);
            }
        }
    }
    
    
    /**
    * @description 
    * @author Yi Zhang | 27/08/2020 
    * @param newList 
    **/
    public static void afterInsert(List<Account> newList) {
        
        List<Account> lstNewBusinessAcc = new List<Account>();
        List<Account> accountsAddParentId = new List<Account>();
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;
        for(Account acc : newList) {
            if(acc.RecordTypeId != personAccRecordTypeId) {
                System.debug('Business Account'+acc);
                lstNewBusinessAcc.add(acc);
                if(String.isNotBlank(acc.ParentId) && !isTerminatedOrInactive(acc)) {
                    accountsAddParentId.add(acc);
                }
            }
        }
        
        if(!accountsAddParentId.isEmpty()){
            updateHasChildAccountFlag(accountsAddParentId, new List<Account>());
        }

        if(!lstNewBusinessAcc.isEmpty()){
            // afterInsert part of Powerpass Account Match flow
            matchPowerpassAccountsAfterInsert(lstNewBusinessAcc);
            
            // for CCRM-13792
            // createChildAccCustomerContract(null, lstNewBusinessAcc); - BUNDIG-16248 - Commented out
            // customerPriceListsFromContractGroup(null, lstNewBusinessAcc); BUNDIG-11663 - Commented out
        }
    }
    
    /**
    * @description  Business logic post account update
    * @author       Yi Zhang | 15/05/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        
        Map<Id, Account> oldMapBusinessAcc = new Map<Id, Account>();
        Map<Id, Account> newMapBusinessAcc = new Map<Id, Account>();
        //List<Account> lstNewBusinessAcc = new List<Account>();
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;

        for(Account acc : newMap.values()) {
            system.debug('Sales ID after Update :: '+acc.Account_Owner_Sales_Id__c);
            if(acc.RecordTypeId != personAccRecordTypeId) {
                //System.debug('Business Account'+acc);
                //lstNewBusinessAcc.add(acc);

                Account oldAccount = oldMap.get(acc.Id);
                oldMapBusinessAcc.put(oldAccount.ID, oldAccount);
                System.debug('Business oldAccount Account'+oldAccount);

                Account newAccount = newMap.get(acc.Id);
                newMapBusinessAcc.put(newAccount.ID, newAccount);
                System.debug('Business newAccount Account'+newAccount);
            }
        }
        
        if(!oldMapBusinessAcc.isEmpty() && !newMapBusinessAcc.isEmpty()){
                // transfer account
                transferAccount(oldMapBusinessAcc, newMapBusinessAcc);
        }
        
        // insert manual cc tasks if any
        insertManualCallCycleTasks();
        
        // create credit increase cc tasks if any
        // System.debug(LoggingLevel.DEBUG, creditIncreasedAccounts);
        
        // Added for SFSUP-246 - To avoid Credit Limit Increased Task duplication,  Account trigger recursion due to Task trigger  
        if(runOnce) {
            runOnce = false;
            SM_CallCycle.createCallCycleTasksForCreditLimitIncrease(creditIncreasedAccounts);
        }
        
        creditIncreasedAccounts.clear();
        
        // update has child flag
        List<Account> accountsAddParentId = new List<Account>();
        List<Account> accountsRemoveParentId = new List<Account>();
        
        // remove Onboarding Call 
        List<Account> accountsRemoveOnboardingCall = new List<Account>();
        
        if(!oldMapBusinessAcc.isEmpty() && !newMapBusinessAcc.isEmpty()){
            for(Account newAccount : newMapBusinessAcc.values()) {
                Account oldAccount = oldMapBusinessAcc.get(newAccount.Id);
                // scenario: parent account is changed when status remains active/referred
                if(oldAccount.ParentId != newAccount.ParentId && !isTerminatedOrInactive(oldAccount) && !isTerminatedOrInactive(newAccount)) {
                    if(String.isNotBlank(oldAccount.ParentId)) {
                        accountsRemoveParentId.add(oldAccount);
                    }
                    if(String.isNotBlank(newAccount.ParentId)) {
                        accountsAddParentId.add(newAccount);
                    }
                    // scenario: become terminated or inactive, only concerned about old parent
                } else if(becomeTerminatedOrInactive(oldAccount, newAccount)) {
                    if(String.isNotBlank(oldAccount.ParentId)) {
                        accountsRemoveParentId.add(oldAccount);
                    }
                    accountsRemoveOnboardingCall.add(newAccount); //Added for CCRM-13836
                    // scenario: become NOT terminated or inactive, only concerned about new parent
                } else if(becomeNotTerminatedOrInactive(oldAccount, newAccount)) {
                    if(String.isNotBlank(newAccount.ParentId)) {
                        accountsAddParentId.add(newAccount);
                    }
                }
            }
        }
        
        updateHasChildAccountFlag(accountsAddParentId, accountsRemoveParentId);
        //updateCustomerPriceList(newMapBusinessAcc);
        
        //delete onboarding calls for terminate / inactive accounts - CCRM-13836
        deleteOnboardingCallsTerminateInactiveAccounts (accountsRemoveOnboardingCall);
        
        if(!oldMapBusinessAcc.isEmpty() && !newMapBusinessAcc.isEmpty()){

            // terminate / inactivate accounts
            terminateInactivateAccounts(oldMapBusinessAcc, newMapBusinessAcc);    
            
            // for CCRM-13792
            System.debug('Test1');
            // createChildAccCustomerContract(oldMapBusinessAcc, newMapBusinessAcc.values()); - BUNDIG-16248 - Commented out
            //customerPriceListsFromContractGroup(oldMapBusinessAcc, newMapBusinessAcc.values()); BUNDIG-11663 - Commented out
        }

        // BUNDIG-31597
        managerActionedPricingAssignmentStatus(newMap.values(), oldMap);
        
    }
    
    /**
    * @description 
    * @author Yi Zhang | 08/09/2020 
    * @param oldMap 
    **/
    public static void afterDelete(Map<Id, Account> oldMap) {
        
        Map<Id, Account> oldMapBusinessAcc = new Map<Id, Account>();
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;

        for(Account acc : oldMap.values()) {
            if(acc.RecordTypeId != personAccRecordTypeId) {
                oldMapBusinessAcc.put(acc.ID, acc);
                System.debug('Business oldAccount Account'+acc);
            }
        }
        
        // prevent deletion by non system admin / integration user, but allows for merging 
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        User user = DM_User.getUser(UserInfo.getUserId());
        for(Account account : oldMapBusinessAcc.values()){
            if(account.MasterRecordId == null && !profileExemptions.contains(user.Profile.Name)){
                account.addError('You do not have permission to delete Accounts. Please contact your system admin to delete this Account.');
            }
        }
    }
    
    
    /**
    * @description      Actions to be taken when an account becomes Terminated / Inactive
    * @author Yi Zhang | 25/09/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void terminateInactivateAccounts(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Account> terminatedOrInactiveAccounts = new List<Account>();
        for(Account oldAccount : oldMap.values()) {
            Account newAccount = newMap.get(oldAccount.Id);
            // only accounts which become terminated or inactive
            if(becomeTerminatedOrInactive(oldAccount, newAccount))  {
                terminatedOrInactiveAccounts.add(newAccount);
            }
        }
        if(terminatedOrInactiveAccounts.isEmpty()) {
            return;
        }
        
        
        try {
            // find all un-inactive umbrella beneficiaries, future tasks, future events:
            // inactivate beneficiaries
            // cancel tasks
            // delete events
            List<Umbrella_Beneficiary__c> beneficiaries = new List<Umbrella_Beneficiary__c>();
            List<Task> tasks = new List<Task>();
            List<Event> events = new List<Event>();
            for(Account a : DM_Account.getAccountsWithUmbBeneficiariesAndFutureActivities(terminatedOrInactiveAccounts)) {
                for(Umbrella_Beneficiary__c ub : a.Umbrella_Beneficiaries__r) {
                    beneficiaries.add(new Umbrella_Beneficiary__c(Id = ub.Id, Status__c = Constants.STATUS_INACTIVE));
                }
                for(Task task : a.Tasks) {
                    tasks.add(new Task(Id = task.Id, Status = Constants.STATUS_CANCELLED));
                }
                events.addAll(a.Events);
            }
            
            if(beneficiaries.size() > 0) {
                update beneficiaries;
            }
            if(tasks.size() > 0) {
                update tasks;
            }
            if(events.size() > 0) {
                delete events;
            }
        } catch(Exception e) {
            ApplicationLogger.log('AccountTriggerHandler.terminateInactivateAccounts', 'Account', 'Trigger', e);
        }
    }
    
    /**
    * @description 
    * @author John Paul Peñaflor | 07-27-2020 
    * @param Map<Id Account> oldMap 
    * @param Map<Id Account> newMap 
    **/
    public static void checkForApprovalRejectionComment(Map<Id, Account> oldMap, Map<Id, Account> newMap){
        Set<Id> accForRejectionIds = new Set<Id>();
        for(Account accRec : newMap.values()){
            Account oldAccRec = oldMap.get(accRec.Id);
            if(accRec.Pricing_Assignment_Status__c == 'Rejected' && oldAccRec.Pricing_Assignment_Status__c == 'Pending Approval'){
                accForRejectionIds.add(accRec.Id);
            }
        }
        
        List<ProcessInstance> piList = new List<ProcessInstance>([SELECT Id, TargetObjectId,Status, (SELECT Id, StepStatus, Comments 
                                                                                                     FROM Steps
                                                                                                     WHERE StepStatus = 'Rejected'
                                                                                                     ORDER BY CreatedDate DESC
                                                                                                     LIMIT 1 
                                                                                                    )
                                                                  FROM ProcessInstance
                                                                  WHERE TargetObjectId IN: accForRejectionIds
                                                                  ORDER BY CreatedDate DESC]);
        System.debug(piList);
        if(piList.isEmpty()){
            return;
        }
        
        Map<Id, ProcessInstance> accProcessMap = new Map<Id, ProcessInstance>();
        for(ProcessInstance piRec : piList){
            if(!accProcessMap.containsKey(piRec.TargetObjectId)){
                accProcessMap.put(piRec.TargetObjectId, piRec);
            }
        }
        
        for(ProcessInstance piRec : accProcessMap.values()){
            if(piRec.Steps.size() > 0 && (piRec.Steps[0].Comments == null || piRec.Steps[0].Comments.trim().length() == 0)){
                //System.debug('Rejected');
                newMap.get(piRec.TargetObjectId).addError('Please enter a rejection comment.');
            }
            else{
                newMap.get(piRec.TargetObjectId).Temp_Comments__c = piRec.Steps[0].Comments;
            }
        }
    }
    
    /**
    * @description      Check if inserted GST Number is valid (for NZ Prospect Account only)
    * @author           Yi Zhang | 17/07/2020 
    * @param            newList 
    **/
    public static void checkNZGSTNumber(List<Account> newList) {
        for(Account a : newList) {
            if(a.RecordTypeId == DM_RecordType.rtId_Account_NzProspect && String.isNotBlank(a.GST_Number__c)) {
                // remove all whitespaces
                a.GST_Number__c = a.GST_Number__c.trim().replaceAll( '\\s+', '');
                // validate
                if(SM_Validator.isValidNZGSTNumber(a.GST_Number__c) == false) {
                    a.addError(ERROR_INVALID_GST_NUMBER);
                }
            }
        }
    }
    /**
    * @description      Check if updated GST Number is valid (for NZ Prospect Account only)
    * @author           Yi Zhang | 17/07/2020 
    * @param            oldMap 
    * @param            newMap 
    **/
    public static void checkNZGSTNumber(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        
        for(Account oldAccount : oldMap.values()) {
            Account newAccount = newMap.get(oldAccount.Id);
            
            if(newAccount.RecordTypeId == DM_RecordType.rtId_Account_NzProspect && oldAccount.GST_Number__c != newAccount.GST_Number__c && String.isNotBlank(newAccount.GST_Number__c)) {
                // remove all whitespaces
                newAccount.GST_Number__c = newAccount.GST_Number__c.trim().replaceAll( '\\s+', '');
                // validate
                if(SM_Validator.isValidNZGSTNumber(newAccount.GST_Number__c) == false) {
                    newAccount.addError(ERROR_INVALID_GST_NUMBER);
                }
            }
        }
    }
    
    /**
    * @description      Used in before update to prepare a list of call cycle tasks
    * @author           Yi Zhang | 16/07/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void prepareCallCycleTasks(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        
        if(triggerInProgress == false) {
            triggerInProgress = true;

            //CCRM15-79, 80, 180 - New call cycle task cannot be created when a task is existing within the quarantine months.
            // AU
            Map<Id,Account> AUOldAccountMap = new Map<Id,Account>();
            // NZ
            Map<Id,Account> NZOldAccountMap = new Map<Id,Account>();
            for(Account acc : oldMap.values()) {
                if(acc.Country__c == 'Australia')
                    AUOldAccountMap.put(acc.Id, acc);
                else if(acc.Country__c == 'New Zealand')
                    NZOldAccountMap.put(acc.Id, acc);
            }
            
            Id callCycleRecType = DM_RecordType.rtId_Task_CallCycle;
            Integer qtnMonthsAU = SM_CallCycle.getQuarantineMonthValue('Australia');
            Integer qtnMonthsNZ = SM_CallCycle.getQuarantineMonthValue('New Zealand');
            Boolean hasQuarantineMdtAU = qtnMonthsAU != 0 ? true : false;
            Boolean hasQuarantineMdtNZ = qtnMonthsNZ != 0 ? true : false;

            Set<Id> accSet = AUOldAccountMap.keySet();
            String queryAU = 'SELECT Id, Country__c, ' +
            ' (SELECT Id ' +
               ' FROM Tasks ' +
                ' WHERE RecordTypeId = :callCycleRecType ' +
                ' AND ActivityDate >= LAST_N_MONTHS:' + qtnMonthsAU + ' ' +
                ' AND ActivityDate <= THIS_MONTH LIMIT 1) ' +
            ' FROM Account WHERE Id IN :accSet  ';
            List<Account> accountWithTaskListAU = Database.query(queryAU);

            accSet = NZOldAccountMap.keySet();
            String queryNZ = 'SELECT Id, Country__c, ' +
            ' (SELECT Id ' +
               ' FROM Tasks ' +
                ' WHERE RecordTypeId = :callCycleRecType ' +
                ' AND ActivityDate >= LAST_N_MONTHS:' + qtnMonthsNZ + ' ' +
                ' AND ActivityDate <= THIS_MONTH LIMIT 1) ' +
            ' FROM Account WHERE Id IN :accSet  ';
            List<Account> accountWithTaskListNZ = Database.query(queryNZ);

            for(Account acc : accountWithTaskListAU) {
                AUOldAccountMap.put(acc.Id, acc);
            }
            for(Account acc : accountWithTaskListNZ) {
                NZOldAccountMap.put(acc.Id, acc);
            }
            Map<Id, Account> allOldAccountsWithTaskMap = new Map<Id, Account>();
            allOldAccountsWithTaskMap.putAll(AUOldAccountMap);
            allOldAccountsWithTaskMap.putAll(NZOldAccountMap);

            Map<Id,List<Task>> accIdToListTaskMap = new Map<Id,List<Task>>();
            for(Account acc : allOldAccountsWithTaskMap.values()) {
                accIdToListTaskMap.put(acc.Id, acc.Tasks);
            }
            //End of CCRM15-79, 80, 180
            
            for(Account oldAccount : oldMap.values()) {
                Account newAccount = newMap.get(oldAccount.Id);
                
                // CCRM-85 TS Accepts a Business Determined Call Reason (entered by RCM/LCM)
                if(oldAccount.Include_in_Call_Cycle__c == null && newAccount.Include_in_Call_Cycle__c != null) {
                    if(newAccount.Include_in_Call_Cycle__c == 'Accept') {
                        //CCRM15-79, 80, 180 - New call cycle task cannot be created when a task is existing within the quarantine months.
                        if(newAccount.Country__c == 'Australia' && hasQuarantineMdtAU)
                        if(accIdToListTaskMap.get(oldAccount.Id).size() > 0) {
                            newAccount.Business_Determined_Call_Reason__c.addError(QUARANTINE_ERROR);
                            newAccount.Include_in_Call_Cycle__c.addError(QUARANTINE_ERROR);
                        }
                        if(newAccount.Country__c == 'New Zealand' && hasQuarantineMdtNZ)
                        if(accIdToListTaskMap.get(oldAccount.Id).size() > 0) {
                            newAccount.Business_Determined_Call_Reason__c.addError(QUARANTINE_ERROR);
                            newAccount.Include_in_Call_Cycle__c.addError(QUARANTINE_ERROR);
                        }
                        //End of CCRM15-79, 80, 180
                        // create task
                        manualCallCycleTasks.put(oldAccount.Id, SM_Task.createManualCallCycleTask(
                            newAccount.Id, 
                            newAccount.OwnerId,
                            newAccount.Business_Determined_Call_Reason__c,
                            DM_RecordType.rtId_Task_CallCycle));
                    } 
                    newAccount.Business_Determined_Call_Reason__c = null;
                    newAccount.Include_in_Call_Cycle__c = null;
                }
                
                System.debug('prepareCallCycleTasks: '+newMap);
                // CCRM-82 Credit Limit Increase 
                if((oldAccount.Credit_Limit__c == null && newAccount.Credit_Limit__c > 0)
                   || (oldAccount.Credit_Limit__c < newAccount.Credit_Limit__c)
                   || (oldAccount.Type == Constants.ACCOUNT_TYPE_CASH && newAccount.Type == Constants.ACCOUNT_TYPE_30DAY)
                   || (oldAccount.Type == Constants.ACCOUNT_TYPE_CASH && newAccount.Type == Constants.ACCOUNT_TYPE_CREDIT)
                   || (oldAccount.Type == Constants.ACCOUNT_TYPE_CREDIT && newAccount.Type == Constants.ACCOUNT_TYPE_30DAY)) {
                    // Added for SFSUP-246 - No credit limit increase call should be created
                    if(!(oldAccount.Type == Constants.ACCOUNT_TYPE_CASH && newAccount.Type == Constants.ACCOUNT_TYPE_CASH && oldAccount.Credit_Limit__c !=    newAccount.Credit_Limit__c) 
                    && !((newAccount.Type == Constants.ACCOUNT_TYPE_CREDIT || newAccount.Type == Constants.ACCOUNT_TYPE_30DAY)
                    && (oldAccount.Credit_Limit__c == 0 && newAccount.Credit_Limit__c == 1))
                    // Added for SFSUP-368 - Credit limit increase call should be created on parent only
                    && (newAccount.ParentId == null || newAccount.ParentId == newAccount.Id)) {
                            
                            newAccount.Credit_Limit_Increased_Check__c = true;//Flag for task creation when limit increased - Added 18/07/2021 for INC0982513
                            creditIncreasedAccounts.add(newAccount);
                            System.debug('creditIncreasedAccounts: '+creditIncreasedAccounts);

                        }
                   }
            }
        }
    }
    
    /**
    * @description      Used in after update to insert tasks if any
    * @author           Yi Zhang | 16/07/2020 
    **/
    public static void insertManualCallCycleTasks() {
        // CCRM-85
        if(manualCallCycleTasks.size() > 0) {
            if(manulCallCycleTasksInserted == false) {
                manulCallCycleTasksInserted = true;
                System.debug(LoggingLevel.DEBUG, 'inserting manualCallCycleTasks');
                try {
                    insert manualCallCycleTasks.values();
                    manualCallCycleTasks.clear();
                } catch(Exception e) {
                    // exception handling
                    ApplicationLogger.log('insertManualCallCycleTasks', 'Task', 'Trigger', e);
                }
            }
        }
    }
    
    /**
    * @description 
    * @author Yi Zhang | 20/05/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void updateOwnerForTransferApprovedAccounts(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
                                
        //SFSUP-876
        Map<Id, String> mapAcctOwner = new Map<Id, String>();
        Map<String, String> mapOwnerSalesRep = new Map<String, String>();
        Map<String, String> mapAccountSalesRep = new Map<String, String>();
        
        for (Account acct : newMap.values()) {  
            //commented for //SFSUP-910
            //mapAcctOwner.put(acct.Id, acct.OwnerId);
            //added for SFSUP-910
            if(acct.Transfer_to__c != null){ 
                mapAcctOwner.put(acct.Id, acct.Transfer_to__c);
            }
            
        }
        
        // Get Sales Rep Id from User record
        for (User u : [SELECT Id, Sales_Rep_ID__c FROM User WHERE Id IN :mapAcctOwner.values()]) {
			mapOwnerSalesRep.put(u.Id, u.Sales_Rep_ID__c);
        }
        
        // Populate map with Account Id and Sales Rep Id
        for (Id ids : mapAcctOwner.keySet()) {            
            if (mapOwnerSalesRep.containsKey(mapAcctOwner.get(ids))) {
                mapAccountSalesRep.put(ids, mapOwnerSalesRep.get(mapAcctOwner.get(ids)));
            }
        }

        // For debugging       
        for (String str : mapAccountSalesRep.keySet())
            System.debug('***Account New Owner: ' + str + ' / Rep Id: ' + mapAccountSalesRep.get(str));
            
        for (Account newAccount : newMap.values()) {
            Account oldAccount = oldMap.get(newAccount.Id);
            
            // When account's transfer approval status is changed from Submitted for approval to Approved and Transfer_to__c is not empty
            // Set new owner to Transfer_to__c and reset Transfer_to__c
            if(oldAccount.Transfer_approval_status__c == 'Submitted for approval' 
               && newAccount.Transfer_approval_status__c == 'Approved' 
               && newAccount.Transfer_to__c != null) {

                   newAccount.OwnerId = newAccount.Transfer_to__c;
                   newAccount.Transfer_to__c = null;
                   newAccount.Account_Owner_Sales_Id__c = mapAccountSalesRep?.get(newAccount.Id); //SFSUP-876
               }
        }
    }
    
    /**
    * @description 
    * @author Simplus MS | 29/04/20201 
    * @param oldMap 
    * @param newMap 
    **/
    /**
    public static void updateCustomerPriceList(Map<Id, Account> newMap) {
        List<Customer_Price_List__c> cplToUpdate = new List<Customer_Price_List__c>();
        try{
            for (Account newAccount : newMap.values()){
                // When account's Pricing Assignment Status is changed  to Approved 
                // Set Pricing Assignment Status of related Customer Price List to Submitted to CPS
                if(newAccount.Pricing_Assignment_Status__c == 'Approved') {
                    List<Customer_Price_List__c> customerPriceLists = new List<Customer_Price_List__c>(CustomerPriceListHelper.getRelatedCustomerPriceLists(newAccount.Id));
                    System.debug('customerPriceLists::' +customerPriceLists);
                    
                    for(Customer_Price_List__c customerPriceList : customerPriceLists){
                        if(customerPriceList.Status__c == 'Active'){
                            customerPriceList.Pricing_Assignment_Status__c = 'Submitted to CPS';
                            //customerPriceList.Action__c = 'Removal';
                            cplToUpdate.add(customerPriceList);
                        }
                    }
                }
            }
            
            if(!cplToUpdate.isEmpty()){
                update cplToUpdate;
            } 
        } catch(Exception e) {
            // exception handling
            ApplicationLogger.log('updateCustomerPriceList', 'Customer_Price_List__c', 'Trigger', e);
        }
    }
    **/
    /**
    *  Method name  :  avoidDelete
    *  Description  :  Stop accounts from deletion
    *  Author       :  Haider Raza
    *  Parameter    :  List<Account> allAccounts
    *                  Map<Id, Account> allAccountsByIds
    **/
    public static void avoidDelete(List<Account> allAccounts, Map<Id, Account> allAccountsByIds){
        for(Account item : allAccounts){
            allAccountsByIds.get(item.Id).addError(Label.AccountMergeMessage);
        }
    }
    
    
    /**
    * @description  Find accounts of which ownership is changed and carry out transfer of related records
    * @author       Yi Zhang | 15/05/2020 
    * @param oldMap 
    * @param newMap 
    * @modification : CCRM15-407 - to transfer related contacts when account ownership changes
    **/
    public static void transferAccount(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        
        // find accounts of which owner is changed through approval process
        Map<Id, Account> oldTransferMap = new Map<Id, Account>();
        Map<Id, Account> newTransferMap = new Map<Id, Account>();
        
        Set<Id> accountIds = new Set<Id>(); //Added for CCRM15-407
        
        for(Account newAccount : newMap.values()) {
            Account oldAccount = oldMap.get(newAccount.Id);
            if (newAccount.OwnerId != oldAccount.OwnerId){
                if (oldAccount.Transfer_approval_status__c != 'Approved' 
                    && newAccount.Transfer_approval_status__c == 'Approved'){
                        oldTransferMap.put(oldAccount.Id, oldAccount);
                        newTransferMap.put(newAccount.Id, newAccount);
                    } else {
                        //Added by Simplus MS - 08.Dec.2021 - Original logic from 'Ownership Updated' node in Account Update Actions PB, to avoid 'Apex CPU time limit exceeded'
                        accountIds.add(newAccount.Id);
                    }
            }
        }
        if(oldTransferMap.isEmpty() == false) {
            SM_AccountTransfer.transferAccountRelatedRecords(oldTransferMap, newTransferMap);
        }
        
        //Added for 407
        if(accountIds.isEmpty() == false) {
            SM_AccountTransfer.transferAccountRelatedContactRecordsOnly(accountIds);
        }        
    }
    
    /**
    * @description 
    * @author Yi Zhang | 27/08/2020 
    * @param accountsAddParentId 
    * @param accountsRemoveParentId 
    **/
    public static void updateHasChildAccountFlag(List<Account> accountsAddParentId, List<Account> accountsRemoveParentId) {
        if(accountsAddParentId.isEmpty() && accountsRemoveParentId.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        // set parent account's flag to true
        List<Id> parentIds = new List<Id>();
        for(Account a : accountsAddParentId) {
            parentIds.add(a.ParentId);
        }
        if(parentIds.size() > 0) {
            for(Account a : DM_Account.getAccountsWithoutChild(parentIds)) {
                accountsToUpdate.put(a.Id, new Account(Id = a.Id, Has_Child_Accounts__c = true));
            }
        }
        // set parent account's flag to false
        parentIds.clear();
        for(Account a : accountsRemoveParentId) {
            parentIds.add(a.ParentId);
        }
        List<Id> stillHasChildAccountIds = new List<Id>();
        if(parentIds.size() > 0) {
            for(AggregateResult ar : DM_Account.getAccountsGroupedByParent(parentIds)) {
                stillHasChildAccountIds.add((Id)ar.get('ParentId'));
            }
            for(Id accountId : parentIds) {
                if(stillHasChildAccountIds.contains(accountId) == false) {
                    accountsToUpdate.put(accountId, new Account(Id = accountId, Has_Child_Accounts__c = false));
                }
            }
        }
        
        if(accountsToUpdate.size() > 0) {
            try {
                update accountsToUpdate.values();
            } catch(Exception e) {
                ApplicationLogger.log('AccountTriggerHandler.updateHasChildAccountFlag', 'Account', 'Trigger', e);
            }
        }
        
    }
    
    /**
    * @description 
    * @author Simplus MS | 24/05/2021
    * @param accountsRemoveOnboardingCall 
    **/
    public static void deleteOnboardingCallsTerminateInactiveAccounts(List<Account> accountsRemoveOnboardingCall) {
        system.debug('inside deleteOnboardingCallsTerminateInactiveAccounts');
        if(accountsRemoveOnboardingCall.isEmpty()) {
            return;
        }
        
        List<Task> removeOnboardingTasks = new List<Task>();
        Set <Id> accountIdsRemoveOnboardingCall = new Set<Id>();
        try{
            for (Account acc : accountsRemoveOnboardingCall){
                accountIdsRemoveOnboardingCall.add(acc.Id);  
            }
            removeOnboardingTasks = [Select Id From Task Where Subject = 'Onboarding Call' And WhatId In :accountIdsRemoveOnboardingCall];
            
            if(removeOnboardingTasks.size() > 0) {
                delete removeOnboardingTasks;
            }
        }catch(Exception e) {
            ApplicationLogger.log('AccountTriggerHandler.deleteOnboardingCallsTerminateInactiveAccounts', 'Account', 'Trigger', e);
        }
            
    }
    
    /**
    * @description      Converting an existing apprentice account to customer account
    * @author           Purba Ghosh | 31/08/2020 
    * @param            oldMap 
    * @param            newMap 
    **/
    public static void convertApprenticeToCustomer(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        for(Account oldAccount : oldMap.values()) {
            Account newAccount = newMap.get(oldAccount.Id);
            
            // If an account that was previously marked as an apprentice is now being unmarked, 
            // the intention is to convert the account to a customer type. There is no need for 
            // checking assignment rules for ownership or create any onboarding task at this
            // point. The account is intended to stay with who ever owns it and carry on as normal,
            // just the type changes over as a customer.
            
            // It is expected that the source system will underatke the validation and responsibilty
            // of ensuring the segments, type and other details are updated while they switch over 
            // an account from apprentice to customer.
            
            if((!(newAccount.Apprentice__c) && oldAccount.Apprentice__c && newAccount.Power_Pass_Account_Number__c != null)
               || (newAccount.Power_Pass_Account_Number__c != oldAccount.Power_Pass_Account_Number__c)) {
                   // Assign customer record type based on country
                   //newAccount.RecordTypeId = newAccount.Country__c == Constants.COUNTRY_AU ? DM_RecordType.rtId_Account_AuCustomer : DM_RecordType.rtId_Account_NzCustomer;
                   updatePowerpassAccountRecordType(newAccount);
               }
        }
    }
    
    /**
    * @description      Converted from Powerpass Account Match flow, only invoked in afterInsert
    * @author Yi Zhang | 22/10/2020 
    * @param newList 
    **/
    public static void matchPowerpassAccountsAfterInsert(List<Account> newList) {
        system.debug('inside matchPowerpassAccountsAfterInsert'+newList.size());
        List<Account> accountsWithHomeStore = new List<Account>();
        List<Account> accountsWithoutHomeStore = new List<Account>(); //Added for CCRM15-275 and CCRM15-227
        List<String> accountNamesWithHomeStore = new List<String>();
        List<Id> accountIdsWithHomeStore = new List<Id>();
        
        Map<Id, Account> accountsWithTempUmbrellaGroup = new Map<Id, Account>();
        Map<Id, Umbrella_Beneficiary__c> beneficiaries = new Map<Id, Umbrella_Beneficiary__c>();
        for(Account account : newList) {
            if(powerpassMatchRequired(account)) {
                system.debug('inside powerpassMatchRequired');
                // subflow Organisation Lead Conversion - Umbrella Group Association
                // note that for new account, no umbrella beneficiaries
                if(String.isNotBlank(account.Temporary_Umbrella_Group__c)) {
                    beneficiaries.put(account.Id, new Umbrella_Beneficiary__c(
                        Account__c = account.Id,
                        Umbrella_Group__c = account.Temporary_Umbrella_Group__c,
                        Status__c = Constants.STATUS_ACTIVE
                    ));
                    accountsWithTempUmbrellaGroup.put(account.Id, new Account(
                        Id = account.Id,
                        Temporary_Umbrella_Group__c = null
                    ));
                }                
                
                if(String.isNotBlank(account.Home_Store__c)) {
                    accountsWithHomeStore.add(account);
                    accountNamesWithHomeStore.add(account.Name);
                    accountIdsWithHomeStore.add(account.Id);
                } 
            }
        }
        
        if(accountsWithHomeStore.isEmpty() == false) {
            system.debug('inside accountsWithHomeStore');
            // assignment flow
            assignPowerpassAccount(accountsWithHomeStore);
            // find all existing prospect accounts with the same name
            Map<String, List<Account>> existingAccountsMap = new Map<String, List<Account>>();  // key = account name
            for(Account a : DM_Account.getProspectAccountsByName(accountNamesWithHomeStore, accountIdsWithHomeStore)) {
                if(existingAccountsMap.containsKey(a.Name) == false) {
                    existingAccountsMap.put(a.Name, new List<Account>());
                }
                existingAccountsMap.get(a.Name).add(a);
            }
            
            // if a matched account is found (all key fields matched), clone all fields to existing account and abandon newly created account
            if(existingAccountsMap.isEmpty() == false) {
                Map<Id, Account> existingAccountsToUpdate = new Map<Id, Account>(); // matched existing accounts to be updated
                Map<Id, Account> newAccountsToDelete = new Map<Id, Account>(); // newly created accounts to be deleted
                for(Account newAccount : accountsWithHomeStore) {
                    if(existingAccountsMap.containsKey(newAccount.Name)) {
                        for(Account existingAccount : existingAccountsMap.get(newAccount.Name)) {
                            if(twoAccountsMatch(newAccount, existingAccount)) {
                                Account mergedAccount = newAccount.clone(false, true, false, false);
                                mergedAccount.Id = existingAccount.Id;
                                mergedAccount.RecordTypeId = existingAccount.RecordTypeId;
                                mergedAccount.PowerPass_Account_Created_Date__c = System.today(); //Added for CCRM-13372
                                // in case existing account is of AU/NZ prospect record type, update record type
                                // AU prospect -> AU apprentice / customer
                                // NZ prospect -> NZ apprentice / customer
                                if(mergedAccount.RecordTypeId == DM_RecordType.rtId_Account_AuProspect) {
                                    mergedAccount.RecordTypeId = (mergedAccount.Apprentice__c == true) ? DM_RecordType.rtId_Account_AuApprentice :DM_RecordType.rtId_Account_AuCustomer;
                                } else if(mergedAccount.RecordTypeId == DM_RecordType.rtId_Account_NzProspect) {
                                    mergedAccount.RecordTypeId = (mergedAccount.Apprentice__c == true) ? DM_RecordType.rtId_Account_NzApprentice :DM_RecordType.rtId_Account_NzCustomer;
                                }
                                mergedAccount.OwnerId = existingAccount.OwnerId;
                                existingAccountsToUpdate.put(mergedAccount.Id, mergedAccount);
                                
                                // add newly created account to map to be deleted
                                newAccountsToDelete.put(newAccount.Id, new Account(Id = newAccount.Id));
                                // remove account from beneficiary list as well (to avoid DML error)
                                if(beneficiaries.containsKey(newAccount.Id)) {
                                    beneficiaries.remove(newAccount.Id);
                                    accountsWithTempUmbrellaGroup.remove(newAccount.Id);
                                }
                                break;  // when the first one is found, break from loop to avoid unforseeable error
                            }
                        }
                    }
                }
                if(newAccountsToDelete.isEmpty() == false) {
                    delete newAccountsToDelete.values();
                }
                if(existingAccountsToUpdate.isEmpty() == false) {
                    update existingAccountsToUpdate.values();
                }
            }
            
        }
        
        if(beneficiaries.isEmpty() == false) {
            insert beneficiaries.values();
            update accountsWithTempUmbrellaGroup.values();
        }
    }
    
    /**
    * @description      Converted from Powerpass Account Assignment flow 
    * @author Yi Zhang | 22/10/2020 
    * @param accounts   accounts of which Home_Store__c populated
    **/
    public static void assignPowerpassAccount(List<Account> accounts) {
        if(accounts == null || accounts.isEmpty()) {
            return;
        }
        
        List<String> accountManagerNames = new List<String>();
        List<Id> storeIds = new List<String>();
        Map<Id, Task> onboardingTasks = new Map<Id, Task>();            // key = account Id
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();     // key = account Id
        // preparation, collect all required data for querying
        for(Account account : accounts) {
            storeIds.add(account.Home_Store__c);
            // has account manager
            if(String.isNotBlank(account.Powerpass_Account_Manager__c)) {
                accountManagerNames.add(account.Powerpass_Account_Manager__c);
            }
        }
        
        // query additional data for business logic
        // key = account manager name
        Map<String, List<User>> accountManagerMap = new Map<String, List<User>>();
        for(User user : DM_User.getUsersByName(accountManagerNames)) {
            if(accountManagerMap.containsKey(user.Name) == false) {
                accountManagerMap.put(user.Name, new List<User>());
            }
            accountManagerMap.get(user.Name).add(user);
        }
        Map<Id, Store__c> storeMap = new Map<Id, Store__c>(DM_Store.getStoresWithActiveSMs(storeIds));
        Map<Id, Account> accountMap = new Map<Id, Account>(DM_Account.getAccountsWithSecondarySegment(accounts));
        Map<Id, Powerpass_Assignment_Rule__mdt> ruleMap = new Map<Id, Powerpass_Assignment_Rule__mdt>();
        
        // business logic
        for(Account accountOriginal : accounts) {
            Account account = accountOriginal.clone(true, false, false, false);
            // set owner id - account manager field populated
            if(String.isNotBlank(account.Powerpass_Account_Manager__c)) {
                List<User> managers = accountManagerMap.get(account.Powerpass_Account_Manager__c);
                if(managers == null) {
                    Boolean availableASM = FALSE;
                    Id defaultTSId = null; //09-August-2021 CCRM-13941 Added variable to Default Trade Specialist Id
                    // no user with the name found, use store's ASM
                    for(Store_Member__c sm : storeMap.get(account.Home_Store__c).User_Stores__r) {
                        system.debug('sm.Role__c =>' + sm.Role__c);
                        if(sm.Role__c == Constants.STOREMEMBER_ASM_ROLENAME) {
                            account.OwnerId = sm.Team_Member__c;
                            availableASM = TRUE;
                            break;
                        } else if (sm.Default_Trade_Specialist__c == true) { //09-August-2021 CCRM-13941 Added else if statement to set value of variable.
                            defaultTSId = sm.Team_Member__c;
                        } 
                    }
                    //Added by Simplus MS - 18.Jun.2021
                    //if no available ASM in home store, assign to default user
                    if (!availableASM){
                        //09-August-2021 CCRM-13941 added if else statement that sets OwnerId as Default Trade Specialist or Default User
                        if (defaultTSId != null) {
                            account.OwnerId = defaultTSId;
                        } else {
                            assignToDefaultUser(account);
                        }
                    }
                } else if(managers.size() == 1) {
                    // one user with the name found, use this user
                    account.OwnerId = managers[0].Id;
                } else {
                    // more than one user with the name found
                    // compare the name with home store's members
                    Boolean availableSM = FALSE;
                    for(Store_Member__c sm : storeMap.get(account.Home_Store__c).User_Stores__r) {
                        if(sm.Team_Member__r.Name == account.Powerpass_Account_Manager__c) {
                            account.OwnerId = sm.Team_Member__c;
                            availableSM = TRUE;
                            break;
                        }
                    }
                    //Added by Simplus MS - 18.Jun.2021
                    //if no available home store member with manager's name, assign to default user
                    if (!availableSM){
                        assignToDefaultUser(account);
                    }
                }
                // set owner id - account manager field NOT populated
                // determine account owner based on Powerpass Assignment Rule CMT
            } else {
                String storeModel = storeMap.get(account.Home_Store__c).Engagement_Model__c;
                String accountType = storeModel == Constants.STORE_MODEL_OLD ? null : account.Type;
                String segment = null;
                if(storeModel != Constants.STORE_MODEL_OLD && String.isNotBlank(account.Secondary_Segment__c)) {
                    segment = accountMap.get(account.Id).Secondary_Segment__r.Segment_Group__c;
                }
                if(segment != null){
                    segment = segment.toLowerCase();
                }
                String key = accountType + storeModel + segment + account.Country__c;
                system.debug('key '+key);
                Double creditLimit = (account.Credit_Limit__c == null) ? 0 : account.Credit_Limit__c;
                if(DM_PowerpassAssignmentRule.ruleMap.containsKey(key)) {
                    Powerpass_Assignment_Rule__mdt rule;
                    for(Powerpass_Assignment_Rule__mdt par : DM_PowerpassAssignmentRule.ruleMap.get(key)) {
                        if(creditLimit >= par.Credit_Limit_Floor__c) {
                            system.debug('par '+par);
                            rule = par;
                            ruleMap.put(account.Id, par);
                            break;
                        }
                    }
                    
                    // find store member of the same role defined in the rule (if any)
                    Store_Member__c storeMember;    // owner of account
                    if(rule != null) {
                        for(Store_Member__c sm : storeMap.get(account.Home_Store__c).User_Stores__r) {
                            if(sm.Role__c == rule.Assign_to_Store_Member__c) {
                                if((sm.Role__c == Constants.STOREMEMBER_TS_ROLENAME && sm.Default_Trade_Specialist__c == true) || sm.Role__c != Constants.STOREMEMBER_TS_ROLENAME) {
                                    storeMember = sm;
                                    break;
                                }
                            }
                        }
                    }
                    // store member found, use it
                    if(storeMember != null) {
                        account.OwnerId = storeMember.Team_Member__c;
                        // store member not found, use default owner
                    } else {
                        assignToDefaultUser(account);
                    }
                } else {
                    assignToDefaultUser(account);
                }
            }
            
            // set record type
            account = updatePowerpassAccountRecordType(account);
            // set digitally managed            
            account.Digitally_Managed__c = ruleMap.containsKey(account.Id) ? ruleMap.get(account.Id).Set_Digitally_Managed_Flag__c : false;            
            account.PowerPass_Account_Created_Date__c = Date.today(); //Added for CCRM-13372
            // onboarding task
            System.debug('ruleMap '+ruleMap);
            
            //Comment task insertion for CCRM15-56 Changes to onboarding creation and due dates
          /*  if(String.isBlank(account.Onboarding_Status__c) 
               && ruleMap.containsKey(account.Id) 
               && ruleMap.get(account.Id).Create_Onboarding_Task__c == true
               && (account.Do_Not_Call__c == false && account.ParentId == null)
               && (account.Account_Status__c != 'Inactive' && account.Account_Status__c != 'Terminated')){
                   //CCRM-13819 - Added logic for onboarding calls creation to check  NOT to create for both parent and child and when Do not Call is TRUE
                   //CCRM-13836 - Added logic for onboarding calls creation to check  NOT to create for accounts with  inactive and terminated status
                   system.debug('inside onboardingTasks creation');
                   
                   Decimal addedDays = ruleMap.get(account.Id).Days_from_Account_Creation__c;
                   addedDays = addedDays == null ? DM_Initialisation.ccrmInitialisation.Default_Onboarding_Added_Days__c : addedDays;
                   // converted from subflow Create Onboarding Task
                   onboardingTasks.put(account.Id, new Task(
                       RecordTypeId = DM_RecordType.rtId_Task_OnboardingCall,
                       ActivityDate = Date.today().addDays(Integer.valueOf(addedDays)),
                       IsRecurrence = false,
                       IsReminderSet = false,
                       OwnerId = account.OwnerId,
                       Phone__c = account.Phone,
                       Subject = 'Onboarding Call',
                       Type = 'Phone',
                       WhatId = account.Id,
                       Sub_type__c = 'Onboarding'
                   ));
                   account.Onboarding_Status__c = 'Onboarding Task Created';
               }*/
            
            accountsToUpdate.put(account.Id, account);
        }
        
        //DML 
        update accountsToUpdate.values();
       /* removed for CCRM15-56
        if(onboardingTasks.size() > 0) {
            System.debug('onboardingTasks '+onboardingTasks);
            insert onboardingTasks.values();
        }*/
    }
    
    /**
    * @description      Converted from Powerpass Account Conversion flow
    * @author Yi Zhang | 22/10/2020 
    * @param account 
    * @return Account 
    **/
    public static Account updatePowerpassAccountRecordType(Account account) {
        if(account.Apprentice__c == true) {
            if(account.Country__c == Constants.COUNTRY_AU) {
                account.RecordTypeId = DM_RecordType.rtId_Account_AuApprentice;
            } else {
                account.RecordTypeId = DM_RecordType.rtId_Account_NzApprentice;
            }
        } else {
            if(account.Country__c == Constants.COUNTRY_AU) {
                account.RecordTypeId = DM_RecordType.rtId_Account_AuCustomer;
            } else {
                account.RecordTypeId = DM_RecordType.rtId_Account_NzCustomer;
            }
        }
        return account;
    }
    
    private static Boolean defaultOwnerQueried = false;
    public static Id defaultOwnerIdAU {
        get {
            if(defaultOwnerQueried == false) {
                defaultOwnerQueried = true;
                List<User> users = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c});
                if(users.isEmpty() == false) {
                    defaultOwnerIdAU = users[0].Id;
                }
            }
            return defaultOwnerIdAU;
        } set;
    }
    public static Id defaultOwnerIdNZ {
        get {
            if(defaultOwnerQueried == false) {
                defaultOwnerQueried = true;
                List<User> users = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Default_NZ_Account_Owner__c});
                if(users.isEmpty() == false) {
                    defaultOwnerIdNZ = users[0].Id;
                }
            }
            return defaultOwnerIdNZ;
        } set;
    }
    
    private static Boolean twoAccountsMatch(Account n, Account o) {
        // follow what's in CCRM-192
        // tweaked to always check name
        // added Country comparison to mimic the sharing rule as the class is without sharing
        return n.Name == o.Name 
            && n.Country__c == o.Country__c
            && (
                ((n.BillingStreet != null && n.BillingStreet == o.BillingStreet) && ((n.BillingCity != null || n.BillingPostalCode != null) && n.BillingCity == o.BillingCity || n.BillingPostalCode == o.BillingPostalCode))
                || ((n.BillingCity != null && n.BillingState != null) && (n.BillingCity == o.BillingCity && n.BillingState == o.BillingState))
                || (n.BillingPostalCode != null && n.BillingPostalCode == o.BillingPostalCode)
                || (n.Phone != null && n.Phone == o.Phone)
                || (n.Website != null && n.Phone != null && (n.Website == o.Website && n.Phone == o.Phone))
                || (n.Website != null && n.BillingStreet != null && (n.Website == o.Website && n.BillingStreet == o.BillingStreet))
                || (n.ABN__c != null && n.ABN__c == o.ABN__c)
                || (n.GST_Number__c != null && n.GST_Number__c == o.GST_Number__c)
            );
        // return newAccount.Name == oldAccount.Name 
        // && newAccount.BillingStreet == oldAccount.BillingStreet
        // && newAccount.BillingCity == oldAccount.BillingCity
        // && newAccount.BillingState == oldAccount.BillingState
        // && newAccount.BillingPostalCode == oldAccount.BillingPostalCode
        // && newAccount.Phone == oldAccount.Phone
        // && newAccount.Website == oldAccount.Website
        // && newAccount.ABN__c == oldAccount.ABN__c
        // && newAccount.GST_Number__c == oldAccount.GST_Number__c;
    }
    
    private static Boolean powerpassMatchRequired(Account account) {
        return String.isNotBlank(account.Country__c) && String.isNotBlank(account.Power_Pass_Account_Number__c);
    }
    
    private static Boolean becomeTerminatedOrInactive(Account oldAccount, Account newAccount) {
        return oldAccount.Account_Status__c != newAccount.Account_Status__c
            && oldAccount.Account_Status__c != Constants.ACCOUNT_STATUS_INACTIVE
            && oldAccount.Account_Status__c != Constants.ACCOUNT_STATUS_TERMINATED
            && (newAccount.Account_Status__c == Constants.ACCOUNT_STATUS_INACTIVE 
                || newAccount.Account_Status__c == Constants.ACCOUNT_STATUS_TERMINATED);
    }
    
    private static Boolean becomeNotTerminatedOrInactive(Account oldAccount, Account newAccount) {
        return oldAccount.Account_Status__c != newAccount.Account_Status__c
            && newAccount.Account_Status__c != Constants.ACCOUNT_STATUS_INACTIVE
            && newAccount.Account_Status__c != Constants.ACCOUNT_STATUS_TERMINATED
            && (oldAccount.Account_Status__c == Constants.ACCOUNT_STATUS_INACTIVE 
                || oldAccount.Account_Status__c == Constants.ACCOUNT_STATUS_TERMINATED);
    }
    
    private static Boolean isTerminatedOrInactive(Account account) {
        return account.Account_Status__c == Constants.ACCOUNT_STATUS_INACTIVE 
            || account.Account_Status__c == Constants.ACCOUNT_STATUS_TERMINATED;
    }
    
    //Added by Simplus MS - 14.Nov.2021
    private static void assignmentsWhenNoHomeStore (Account account){
        if ((account.RecordTypeId == DM_RecordType.rtId_Account_AuCustomer || account.RecordTypeId == DM_RecordType.rtId_Account_NzCustomer
             || account.RecordTypeId == DM_RecordType.rtId_Account_AuApprentice || account.RecordTypeId == DM_RecordType.rtId_Account_NzApprentice)
             && account.PowerPass_Account_Created_Date__c == null && account.Country__c != null){
                //CCRM15-275
                if (account.PowerPass_Account_Created_Date__c == null){
                    account.PowerPass_Account_Created_Date__c = System.today();
                }
                //CCRM15-227
                if (account.Country__c != null){
                    assignToDefaultUser(account);
                }
            }
    }
    
    //Added by Simplus MS - 18.Jun.2021 
    private static void assignToDefaultUser (Account account){
        if(account.Country__c == 'Australia'){
            if(defaultOwnerIdAU != null) {
                account.OwnerId = defaultOwnerIdAU;
            }
        }
        else if(account.Country__c == 'New Zealand'){
            if(defaultOwnerIdNZ != null){
                account.OwnerId = defaultOwnerIdNZ;
            }
        }
    } 

    /*
        public static void createCustomerContract (Map<Id, Account> oldMap, Map<Id, Account> newMap) {
    
        List<Account> updatedAccounts  = new List<Account>();
        Map<Id, List<Customer_Contract__c>> parentToCustomerMap = new Map<Id, List<Customer_Contract__c>>();
        Set<Id> parentAccounts = new Set<Id>();
    
        for(Account newAccount : newMap.values()) {
        List<Customer_Contract__c> customerContactLlist = new List<Customer_Contract__c>();
            
        if(newAccount.Contract_Group__c  != null
        && newAccount.Contract_Group__c  != oldMap.get(newAccount.id).Contract_Group__c ){
        parentAccounts.add(newAccount.Contract_Group__c);
        }
        }
    
        for(Customer_Contract__c  con : [Select id,Contract__c  from Customer_Contract__c where Contract__c in : parentAccounts]){
        if(parentToCustomerMap.containsKey(con.Contract__c) && parentToCustomerMap.get(con.Contract__c) != null){
        List<Customer_Contract__c> lst = parentToCustomerMap.get(con.Contract__c);
    
        lst.add(con);
        parentToCustomerMap.put(con.Contract__c, lst);
    
        }else{
        parentToCustomerMap.put(con.Contract__c , new List<Customer_Contract__c> {con});
        }
        }
        }
    */
    /**
    * @description CCRM-13792 AC2: Create Child Account Customer Contract When there are accounts 
    *                               linked via the Contract Group Association
    * @author Simplus MS | 24/06/20201
    * @param oldMap 
    * @param newMap 
    * @modifications: BUNDIG-16248 - Commented out
    **/
    /* public static void createChildAccCustomerContract(Map<Id, Account> oldMap, List<Account> newList) {

        Set<Id> parentAccounts = new Set<Id>();
        Set<Id> childAccounts = new Set<Id>();

        if(oldMap == null){
            for(Account newAcc : newList) {
                if(newAcc.Contract_Group__c  != null) {
                    parentAccounts.add(newAcc.Contract_Group__c );
                    childAccounts.add(newAcc.Id);
                }
            }
        }else{
            for(Account newAcc : newList) {
                if(newAcc.Contract_Group__c  != null 
                    && newAcc.Contract_Group__c  != oldMap.get(newAcc.id).Contract_Group__c){
                    parentAccounts.add(newAcc.Contract_Group__c );
                    childAccounts.add(newAcc.Id);
                }
            }
        }
        System.debug('Test2.1 '+parentAccounts.size()+' '+childAccounts.size());
        if(parentAccounts.isEmpty()) {
            return;
        }
        
        Map<Id, Account> parentAccWithCustContractsMap = DM_Account.getParentAccWithCustContracts(parentAccounts);
        Map<Id, Account> childAccWithCustContractsMap = DM_Account.getChildAccWithCustContracts(childAccounts);
        List<Customer_Contract__c> toInsertCloneCustContract  = new List<Customer_Contract__c>();
        List<Customer_Contract__c> toDeleteOldCustContract  = new List<Customer_Contract__c>();
        
        System.debug('(Test2.2 '+parentAccWithCustContractsMap.size()+' '+childAccWithCustContractsMap.size());
        
        for(Account newAcc : childAccWithCustContractsMap.values()) {
            for(Customer_Contract__c custContract : newAcc.Customer_Contracts__r){
                toDeleteOldCustContract.add(custContract);
            }
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for(Account newAcc : newList) {
            Account parentAccWithCustContracts = parentAccWithCustContractsMap.get(newAcc.Contract_Group__c);
            System.debug('Test2.3 '+parentAccWithCustContracts+' '+parentAccWithCustContracts.Customer_Contracts__r.size());
            if(parentAccWithCustContracts != null && parentAccWithCustContracts.Customer_Contracts__r.size() > 0){
                for(Customer_Contract__c custContract : parentAccWithCustContracts.Customer_Contracts__r){
                        Customer_Contract__c custContractClone = custContract.clone(false, false, false, false);
                        custContractClone.Customer__c = newAcc.Id;
                        toInsertCloneCustContract.add(custContractClone);
                }
                System.debug('Test3');
                accountsToUpdate.add(new Account(Id = newAcc.Id, On_Contract__c = 'Yes'));
            }
        }
        System.debug('Test4 '+accountsToUpdate.size()+' '+accountsToUpdate);
        if(accountsToUpdate.size() > 0) {
            try {
                Update accountsToUpdate;
            } catch(Exception e) {
                ApplicationLogger.log('AccountTriggerHandler.createChildAccCustomerContract', 'Account', 'Trigger', e);
            }
        }

        if(toDeleteOldCustContract.size() > 0) {
            try {
                Delete toDeleteOldCustContract;
            } catch(Exception e) {
                ApplicationLogger.log('AccountTriggerHandler.createChildAccCustomerContract', 'Account', 'Trigger', e);
            }
        }
        
        if(toInsertCloneCustContract.size() > 0) {
            try {

                Insert toInsertCloneCustContract;
            } catch(Exception e) {
                ApplicationLogger.log('AccountTriggerHandler.createChildAccCustomerContract', 'Account', 'Trigger', e);
            }
        }
    } */

    /**
    * @description CCRM-13792: When Contract_Group__c == null then make customer contract End Date = Today
    * @author Simplus MS | 24/06/20201
    * @param oldMap 
    * @param newMap 
    * @modification: BUNDIG-16248 - Commented out
    **/
    /* public static void inactiveChildAccCustomerContract(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        Set<Id> childAccounts = new Set<Id>();
        for(Account newAcc : newMap.values()) {
            if(oldMap.get(newAcc.id).Contract_Group__c != null && newAcc.Contract_Group__c  == null){
                childAccounts.add(newAcc.Id);
            }
        }
        
        if(childAccounts.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsWithCustContractsMap = DM_Account.getChildAccWithCustContracts(childAccounts);
        List<Customer_Contract__c> toDeleteCustContractList  = new List<Customer_Contract__c>();
        for(Account newAcc : newMap.values()) {
            Account accWithCustContracts = accountsWithCustContractsMap.get(newAcc.Id);
            if(accWithCustContracts != null && accWithCustContracts.Customer_Contracts__r.size() > 0){
                for(Customer_Contract__c custContract : accWithCustContracts.Customer_Contracts__r){
                    toDeleteCustContractList.add(custContract);
                }
                newAcc.On_Contract__c = 'No';
            }
        }

        if(toDeleteCustContractList.size() > 0) {
            try {
                    Delete toDeleteCustContractList;       
            } catch(Exception e) {
                    ApplicationLogger.log('AccountTriggerHandler.createChildAccCustomerContract', 'Account', 'Trigger', e);
            }
        }
    } */
    
    /**
    * @description Create/Deactivate CPL in account for CCRM-13792
    * @author Simplus - Karlo De Leon | 29/06/2021 
    * @param oldList 
    * @param newList 
    **/
    // BUNDIG-11663 - Commented out
    /* public static void customerPriceListsFromContractGroup(Map<Id,Account> oldList, List<Account> newList) {
        
        Map<Id, List<Customer_Price_List__c>> retrievedAcctCurrentCPL = new Map<Id, List<Customer_Price_List__c>>(); //account's current CPL
        Map<Id, List<Customer_Price_List__c>> retrievedCPL = new Map<Id, List<Customer_Price_List__c>>(); //contract group's CPL
        List<Customer_Price_List__c> lstOldCPL = new List<Customer_Price_List__c>(); //account's current CPL to be deactivated
        List<Customer_Price_List__c> lstFutureCPL = new List<Customer_Price_List__c>(); // account's futured dated CPL to be deleted
        List<Customer_Price_List__c> lstNewCPL = new List<Customer_Price_List__c>(); // account's new CPL to be created
        Map<Id,Id> acctIds = new Map<Id,Id>();
        Date startDate = System.today();
        if (oldList == null) { //FOR NEW ACCOUNTS
            for (Account acct : newList) {
                if (acct.Contract_Group__c != null) {
                    acctIds.put(acct.Id, acct.Contract_Group__c);    
                }                
            }
            if (acctIds.size() > 0) {
                retrievedCPL = retrieveContractGroupCPL(acctIds.values());
                for (Id keyId : acctIds.keySet()) {
                    List<Customer_Price_List__c> cpl = new List<Customer_Price_List__c>(retrievedCPL.get(acctIds.get(keyId)));
                    for (Customer_Price_List__c row : cpl) {
                        lstNewCPL.add(setNewCPL(row, keyId, startDate));
                    }
                }
            }
        } else { //FOR UPDATED ACCOUNTS
            
            for (Account acct : newList) {
                Account oldAcctData = oldList.get(acct.Id);
                
                if (oldAcctData.Contract_Group__c != acct.Contract_Group__c) {
                    acctIds.put(acct.Id, acct.Contract_Group__c);
                }
            }
            
            if (acctIds.size() > 0) {
                retrievedAcctCurrentCPL = retrieveContractGroupCPL(new List<Id>(acctIds.keySet()));
                retrievedCPL = retrieveContractGroupCPL(acctIds.values());
                
                
                for (Id keyId : acctIds.keySet()) {
                    startDate = System.today();
                    if (retrievedAcctCurrentCPL.containsKey(keyId)) { //Deactivates all active and future dated CPL's per account
                        List<Customer_Price_List__c> cpl = new List<Customer_Price_List__c>(retrievedAcctCurrentCPL.get(keyId));
                        for (Customer_Price_List__c row : cpl) {
                            if (row.Status__c == 'Active' && row.Start_Date__c <= System.today()) {
                                row.End_Date__c = System.today(); 
                                row.Status__c = 'Inactive';
                                row.Pricing_Assignment_Status__c = 'Submitted to CPS'; //for clarification
                                lstOldCPL.add(row);
                                startDate = System.today().addDays(1);
                            } else {
                                lstFutureCPL.add(row);
                            }
                        }
                    }
                    
                    if (acctIds.get(keyId) != null) { //Add to list all new CPL's per account
                        List<Customer_Price_List__c> cpl = new List<Customer_Price_List__c>(retrievedCPL.get(acctIds.get(keyId)));
                        for (Customer_Price_List__c row : cpl) {
                            lstNewCPL.add(setNewCPL(row, keyId, startDate));
                        }
                    }
                }
            }
        }
        
        if (lstOldCPL.size() > 0) {
            UPDATE lstOldCPL;
        }
        
        if (lstFutureCPL.size() > 0) {
            DELETE lstFutureCPL;
        }
            
        if (lstNewCPL.size() > 0) {
            INSERT lstNewCPL;
        }
    } */
    
    /**
    * @description Retrieves all CPL per account
    * @author Simplus - Karlo De Leon | 29/06/2021 
    * @param acctIds
    **/
    // BUNDIG-11663 - Commented out
    /* public static Map<Id, List<Customer_Price_List__c>> retrieveContractGroupCPL(List<Id> acctIds) {
        Map<Id, List<Customer_Price_List__c>> mapCPL = new Map<Id, List<Customer_Price_List__c>>();
        List<Customer_Price_List__c> lstCPL = new List<Customer_Price_List__c>([SELECT Id, Account__r.Id, Action__c, Change_Requested_On__c, 
                                                                                CreatedById, End_Date__c, 
                                                                                LastModifiedById, Name, Price_List__c, Pricing_Assignment_Status__c, 
                                                                                Start_Date__c, Status__c
                                                                                FROM Customer_Price_List__c
                                                                                WHERE Account__r.Id IN : acctIds AND 
                                                                               (Status__c = 'Active' OR Start_Date__c > TODAY)]);
        for (Customer_Price_List__c row : lstCPL) {
            if (!mapCPL.containsKey(row.Account__r.Id)) {
                mapCPL.put(row.Account__r.Id, new List<Customer_Price_List__c>());
            }
            mapCPL.get(row.Account__r.Id).add(row);
        }
        return mapCPL;
    } */
    
    /**
    * @description Set new CPL record
    * @author Simplus - Karlo De Leon | 30/06/2021 
    * @param acctIds
    **/
    public static Customer_Price_List__c setNewCPL(Customer_Price_List__c row, Id acctId, Date startDate) {
        return new Customer_Price_List__c(Account__c = acctId,
                                          Action__c = row.Action__c,
                                          Change_Requested_On__c = row.Change_Requested_On__c,
                                          CreatedById = row.CreatedById,
                                          Customer_Price_List_ID__c = null, //row.Customer_Price_List_ID__c,
                                          End_Date__c = row.End_Date__c,
                                          LastModifiedById = row.LastModifiedById,
                                          Price_List__c = row.Price_List__c,
                                          Pricing_Assignment_Status__c = row.Pricing_Assignment_Status__c,
                                          Start_Date__c = row.Status__c == 'Active' ? startDate : row.Start_Date__c,
                                          Status__c = row.Status__c,
                                          Parent_CPL__c = row.Id);//Parent_CPL__c is added for CCRM 15-541
    }
    
    /**
    * @description Set Marketing Cloud flags for CCRM15-83
    * @author Bunnings - Rui Wang | 20/09/2021 
    * @param oldMap,newMap
    **/
    private static void setMarketingFlags(Map<Id, Account> oldMap, Map<Id, Account> newMap, List<Account> lstNewAccount, String operationType){
        Id recordTypeIdAUApprentice = DM_RecordType.rtId_Account_AuApprentice;
        Id recordTypeIdAUCustomer = DM_RecordType.rtId_Account_AuCustomer;
        Id recordTypeIdNZApprentice = DM_RecordType.rtId_Account_NzApprentice;
        Id recordTypeIdNZCustomer = DM_RecordType.rtId_Account_NzCustomer;
        
        String integrationUserId = Config.Integration_User_Id__c;
        String marketingConnectUserId = Config.Marketing_Connect_User_Id__c; 
        String batchUserId = Config.Batch_User_Id__c; //CCRM15-180
        Set<Id> setAcctIds = New Set<Id>(); //CCRM15-242   
        
        if (operationType == 'beforeInsert'){
            for(Account acct : lstNewAccount){
                if(acct.Receive_Marketing__c 
                   && (acct.Type == 'CASH' || acct.Type == 'CREDIT' || acct.Type == '30DAY')//Remove Verified_Email__c check for CCRM15-252
                   && (acct.RecordTypeId == recordTypeIdAUApprentice
                      || acct.RecordTypeId == recordTypeIdAUCustomer
                      || acct.RecordTypeId == recordTypeIdNZApprentice
                      || acct.RecordTypeId == recordTypeIdNZCustomer)){
                    acct.Marketing_Account__c = true;         
                }
            }
        }
        if(operationType == 'beforeUpdate'){
            /*
            Map<Id, String> mapUsers = New Map<Id, String> ();
            List<User> lstUser = [SELECT Id, Username FROM User WHERE Username IN (:integrationUserId,  :marketingConnectUserId)];
            if(lstUser.size() > 0){
                for(User u : lstUser){
                    mapUsers.put(u.Id, u.Username);
                }
            }*/
            
            for(Account newAccount : newMap.values()) {
                System.debug('newAccount****** '+newAccount.Assigned_Store__c);
                Account oldAccount = oldMap.get(newAccount.Id);
                System.debug('oldAccount********* '+oldAccount.Assigned_Store__c);
                if(oldAccount.Marketing_Account__c == false 
                   && newAccount.Receive_Marketing__c == true
                   && (newAccount.Type == 'CASH' || newAccount.Type == 'CREDIT' || newAccount.Type == '30DAY')//Remove Verified_Email__c check for CCRM15-252
                   && (newAccount.RecordTypeId == recordTypeIdAUApprentice
                      || newAccount.RecordTypeId == recordTypeIdAUCustomer
                      || newAccount.RecordTypeId == recordTypeIdNZApprentice
                      || newAccount.RecordTypeId == recordTypeIdNZCustomer) 
                   && !(UserInfo.getUserId() == batchUserId)) { //CCRM15-180 Exclude batch user from running updateContactMarketingFlag future method            
                       newAccount.Marketing_Account__c = true; 
                       setAcctIds.add(newAccount.Id);//CCRM15-242
                }
                
                if((newAccount.RecordTypeId == recordTypeIdAUApprentice
                      || newAccount.RecordTypeId == recordTypeIdAUCustomer
                      || newAccount.RecordTypeId == recordTypeIdNZApprentice
                      || newAccount.RecordTypeId == recordTypeIdNZCustomer)
                  && oldAccount.Marketing_Account__c == true){
                      
                    if(Userinfo.getUserId() == integrationUserId || Test.isRunningTest()){
                        if(oldAccount.Receive_Marketing_Last_Update_By__c == null || Test.isRunningTest()){
                            newAccount.Receive_Marketing_Last_Update_By__c = integrationUserId;
                        }
                        else if(oldAccount.Receive_Marketing_Last_Update_By__c == integrationUserId || Test.isRunningTest()){
                            newAccount.Receive_Marketing_Last_Update_By__c =  integrationUserId;
                        }
                        else if(oldAccount.Receive_Marketing_Last_Update_By__c == marketingConnectUserId || Test.isRunningTest()){
                            if(newAccount.Receive_Marketing__c != oldaccount.Receive_Marketing__c){
                                newAccount.Receive_Marketing__c =  oldAccount.Receive_Marketing__c;
                                newAccount.Receive_Marketing_Last_Update_By__c =  oldAccount.Receive_Marketing_Last_Update_By__c;
                            }
                            else{
                                newAccount.Receive_Marketing_Last_Update_By__c =  integrationUserId;
                            }
                        }
                    }
                    
                    if(Userinfo.getUserId() == marketingConnectUserId || Test.isRunningTest()){
                        if(oldAccount.Receive_Marketing_Last_Update_By__c == null || Test.isRunningTest()){
                            if(newAccount.Receive_Marketing__c != oldAccount.Receive_Marketing__c){
                                newAccount.Receive_Marketing_Last_Update_By__c =  marketingConnectUserId;
                            }
                            else{
                                newAccount.Receive_Marketing_Last_Update_By__c =  oldAccount.Receive_Marketing_Last_Update_By__c;
                            }                            
                        }
                        else if(oldAccount.Receive_Marketing_Last_Update_By__c == integrationUserId || Test.isRunningTest()) {
                            if(newAccount.Receive_Marketing__c != oldAccount.Receive_Marketing__c){
                                newAccount.Receive_Marketing_Last_Update_By__c =  marketingConnectUserId;
                            }
                            else{
                                newAccount.Receive_Marketing_Last_Update_By__c =  oldAccount.Receive_Marketing_Last_Update_By__c;
                            }                            
                        }
                        else if(oldAccount.Receive_Marketing_Last_Update_By__c == marketingConnectUserId || Test.isRunningTest()){
                            newAccount.Receive_Marketing_Last_Update_By__c =  marketingConnectUserId;
                        }                        
                    }                                  
                }
            }
         } 
        //CCRM15-242
        if(setAcctIds.size() > 0 && !System.isFuture() && !System.isBatch()){
            updateContactMarketingFlag(setAcctIds);    
        }
    }
    
    private static SM_Configs__c config {
        get {
            if (config==null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    }   
    
    //CCRM15-242
    @future
    private static void updateContactMarketingFlag(Set<ID> recordIds){
        system.debug('updateContactMarketingFlag input parameter:' + recordIds);
        try{
            Id recordTypeIdAUARContact= DM_RecordType.rtId_Contact_AuArContact;    
            Id recordTypeIdNZARContact= DM_RecordType.rtId_Contact_NzArContact; 
            
            List<Contact> contList = [SELECT Id, Email,RecordTypeId, Marketing_Contact__c, Account.Business_Email_Address__c, Account.Marketing_Account__c,  Account.Verified_Email__c FROM Contact WHERE AccountId IN :recordIds];
            
            for(Contact con : contList){//Remove Verified_Email__c check for CCRM15-252
                if(con.account.Business_Email_Address__c == con.Email 
                   && con.account.Marketing_Account__c 
                   && (con.RecordTypeId == recordTypeIdAUARContact || con.RecordTypeId == recordTypeIdNZARContact)
                   && !con.Marketing_Contact__c){
                    con.Marketing_Contact__c = true;
                }               
            }
            system.debug('contList:' + contList);
            
            if(contList.size() > 0) {
                update contList;
            }
       
        }catch(Exception e){
             ApplicationLogger.log('AccountTriggerHandler.updateContactMarketingFlag', 'Account', 'Trigger', e);
        }        
    }  
    
    //SFSUP-433 - Assigned store not updating when accounts are transferred
    private static void setAssignedStore(List <Account> lAccounstToSetAssignedStore, Map<Id, Account> oldMapAccountsToSetAssignedStore){

        Map<ID, ID> acctID_ownerIDMap = new Map<ID, ID>();
        Map<ID, ID> acctID_storeIDMap = new Map<ID, ID>();
        Map<ID, String> oldAcctID_storeIDMap = new Map<ID, String>();
        Map<Id,String> previousOwnerIdsMap = new Map<Id,String>();
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        Map<ID, Boolean> acctID_isTSMap = new Map<ID, Boolean>();
        List<User> auDefaultUser = new List<User>();
        List<User> nzDefaultUser = new List<User>();
        List<Account> assignedStoreAcctList =  new List<Account>();       
        List<Account> oldAcctList = new List<Account>();
        
        for (Account acct : lAccounstToSetAssignedStore){
            acctID_ownerIDMap.put(acct.Id, acct.OwnerId);
            system.debug('433 Debug ::: acctID_ownerIDMap '+acctID_ownerIDMap);
        }
        
        Map<Id, User> mapOwnerIdToUser = new Map<Id, User>([Select Id, Name, Profile.Name From User Where Id IN :acctID_ownerIDMap.values()]);
        system.debug('433 Debug ::: mapOwnerIdToUser '+mapOwnerIdToUser);
        
        auDefaultUser = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c});
        nzDefaultUser = DM_User.getUsersByName(new List<String>{DM_Initialisation.ccrmInitialisation.CCRM_Default_NZ_Account_Owner__c}); 
        
        Boolean auDefaultUserIsNotEmpty = (!auDefaultUser.isEmpty()) ? true : false;
        Boolean nzDefaultUserIsNotEmpty = (!nzDefaultUser.isEmpty()) ? true : false;
        
        system.debug('433 Debug ::: auDefaultUser '+auDefaultUser);
        system.debug('433 Debug ::: nzDefaultUser '+nzDefaultUser);
        
        for(Account acct : lAccounstToSetAssignedStore){
           //SFSUP-877 - Assigned Store Not Populating for NZ Trade Specialist.
            if((mapOwnerIdToUser.get(acct.OwnerId).Profile.Name.contains(Label.Trade_Specialist) && mapOwnerIdToUser.get(acct.OwnerId).Profile.Name != null)
              || ((auDefaultUserIsNotEmpty && oldMapAccountsToSetAssignedStore.get(acct.Id).OwnerId == auDefaultUser[0].Id) || 
                  (nzDefaultUserIsNotEmpty && oldMapAccountsToSetAssignedStore.get(acct.Id).OwnerId == nzDefaultUser[0].Id))) {
                system.debug('433 Debug ::: Owner Name'+mapOwnerIdToUser.get(acct.OwnerId).Name);
                acctID_isTSMap.put(acct.ID, true);
                assignedStoreAcctList.add(acct);
            }else {
                acctID_isTSMap.put(acct.ID, false);
            }
        }
        
        if(!assignedStoreAcctList.isEmpty()) {
            system.debug('433 Debug ::: assignedStoreAcctList '+assignedStoreAcctList);
            acctID_storeIDMap = SM_Account.mapAssignedStore(assignedStoreAcctList, acctID_ownerIDMap);
        }
        
        oldAcctList = [Select Id, Assigned_Store__r.Name, Account_Owner__c, Account_Owner_Sales_Id__c, Owner.Name, Owner.Team_Member_ID__c, Owner.Profile.Name, Owner.Sales_Rep_ID__c From Account Where Id In: oldMapAccountsToSetAssignedStore.values()];
        for(Account oldAcc: oldAcctList) {
            oldAcctID_storeIDMap.put(oldAcc.Id, oldMapAccountsToSetAssignedStore.get(oldAcc.Id).Assigned_Store__c);
            previousOwnerIdsMap.put(oldAcc.Id, oldAcc.Owner.Name+' - '+oldAcc.Owner.Team_Member_ID__c);
			oldAccountMap.put(oldAcc.Id, oldAcc);
        }
        Map<Id,Store__c> assignedStoresMap = new Map<Id,Store__c>([Select Id, Name from Store__c Where Id In: oldAcctID_storeIDMap.values()]);
        system.debug('433 Debug ::: assignedStoresMap '+assignedStoresMap);
        
        for(Account acct : lAccounstToSetAssignedStore){
            //For TS-owned accounts
            if(!acctID_isTSMap.isEmpty() && acctID_isTSMap.get(acct.ID) && 
               (auDefaultUserIsNotEmpty && acct.OwnerId != auDefaultUser[0].Id) 
               && (nzDefaultUserIsNotEmpty && acct.OwnerId != nzDefaultUser[0].Id)) {
                acct.Assigned_Store__c = acctID_storeIDMap.get(acct.ID); 
                if (assignedStoresMap.containsKey(oldAcctID_storeIDMap.get(acct.ID))){
                    acct.Previous_Assigned_Store__c = assignedStoresMap.get(oldAcctID_storeIDMap.get(acct.ID)).Name; 
                }
                acct.Previous_Owner__c = previousOwnerIdsMap.get(acct.Id);
                acct.Last_Owner_Transfer_Date__c = System.today();
            }
            //For Default User-owned accounts
            if(!acctID_isTSMap.isEmpty() && ((auDefaultUserIsNotEmpty && acct.OwnerId == auDefaultUser[0].Id) || (nzDefaultUserIsNotEmpty && acct.OwnerId == nzDefaultUser[0].Id))){
                if (assignedStoresMap.containsKey(oldAcctID_storeIDMap.get(acct.ID))){
                    acct.Assigned_Store__c = oldAcctID_storeIDMap.get(acct.Id);
                    acct.Previous_Assigned_Store__c = assignedStoresMap.get(oldAcctID_storeIDMap.get(acct.ID)).Name; 
                }
                acct.Previous_Owner__c = previousOwnerIdsMap.get(acct.Id);
                acct.Last_Owner_Transfer_Date__c = System.today();
            }
            //For Non-TS-owned accounts
            if (!mapOwnerIdToUser.get(acct.OwnerId).Profile.Name.contains(Label.Trade_Specialist) && //SFSUP-877 - Assigned Store Not Populating for NZ Trade Specialist.
                (auDefaultUserIsNotEmpty && acct.OwnerId != auDefaultUser[0].Id) && (nzDefaultUserIsNotEmpty && acct.OwnerId != nzDefaultUser[0].Id)){
                acct.Assigned_Store__c = null; 
                acct.Previous_Owner__c = previousOwnerIdsMap.get(acct.Id);
                acct.Last_Owner_Transfer_Date__c = System.today();
            }
 
        }
        
    }

    // BUNDIG-31597 - Check if Manager Actioned Pricing Assignment Status
    private static void managerActionedPricingAssignmentStatus(List<Account> lstNewAccount, Map<Id, Account> oldMap) {
        System.debug(LoggingLevel.FINEST, '***managerActionedPricingAssignmentStatus');
        Set<Id> acctIds = new Set<Id>();
        List<Customer_Price_List__c> cplToUpdate = new List<Customer_Price_List__c>();
        List<Customer_Family_Tree_Discount__c> cftdToUpdate = new List<Customer_Family_Tree_Discount__c>();
        Map<Id, Account> acctToUpdate = new Map<Id, Account>();

        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;

        for (Account acct : lstNewAccount) {            
            Account oldAccount = oldMap.get(acct.Id);
            if (acct.Pricing_Assignment_Status__c != oldAccount.Pricing_Assignment_Status__c && acct.Pricing_Assignment_Status__c == 'Manager Actioned' && acct.RecordTypeId != personAccRecordTypeId) {
                acctIds.add(acct.Id);
            }
        }

        System.debug(LoggingLevel.FINEST, '***acctIds: ' + acctIds);

        List<Customer_Price_List__c> lstCPL = [SELECT Id, Account__c, Customer_Price_List_ID__c, Pricing_Assignment_Status__c, Status__c FROM Customer_Price_List__c WHERE Account__c IN :acctIds];
        
        Map<Id, Map<Id, Customer_Price_List__c>> mapAcctCPL = new Map<Id, Map<Id, Customer_Price_List__c>>();        

        if (!lstCPL.isEmpty()) {
            for (Customer_Price_List__c cpl : lstCPL) {
                if(mapAcctCPL.containsKey(cpl.Account__c)) {                
                    mapAcctCPL.get(cpl.Account__c).put(cpl.Id, cpl);
                } else {
                    Map<Id, Customer_Price_List__c> innerCPLMap = new Map<Id, Customer_Price_List__c>();
                    innerCPLMap.put(cpl.Id, cpl);                
                    mapAcctCPL.put(cpl.Account__c, innerCPLMap);
                }
            }
        }

        System.debug(LoggingLevel.FINEST, '***mapAcctCPL: ' + mapAcctCPL);

        List<Customer_Family_Tree_Discount__c> lstCFTD = [SELECT Id, Account__c, Customer_Family_Tree_External_ID__c, Pricing_Assignment_Status__c, Status__c 
            FROM Customer_Family_Tree_Discount__c WHERE Account__c IN :acctIds];
            
        Map<Id, Map<Id, Customer_Family_Tree_Discount__c>> mapAcctCFTD = new Map<Id, Map<Id, Customer_Family_Tree_Discount__c>>();

        if (!lstCFTD.isEmpty()) {
            for (Customer_Family_Tree_Discount__c cftd : lstCFTD) {
                if(mapAcctCFTD.containsKey(cftd.Account__c)) {                
                    mapAcctCFTD.get(cftd.Account__c).put(cftd.Id, cftd);
                } else {
                    Map<Id, Customer_Family_Tree_Discount__c> innerCFTDMap = new Map<Id, Customer_Family_Tree_Discount__c>();
                    innerCFTDMap.put(cftd.Id, cftd);                
                    mapAcctCFTD.put(cftd.Account__c, innerCFTDMap);
                }
            }
        }

        System.debug(LoggingLevel.FINEST, '***mapAcctCFTD: ' + mapAcctCFTD);
        
        for (Account acct : [SELECT Id, RecordTypeId, Family_Tree_Discount_Approval__c, Family_Tree_Discount_Changed__c, Price_List_Changed__c, Pricing_Assignment_Approval_Submitter__c, Pricing_Assignment_Approver__c,
            Updated_Price_Lists__c, Proposed_Spend_Band__c, Spend_Band__c FROM Account WHERE Id IN :acctIds]) {

                if (mapAcctCPL.get(acct.Id) != null && !mapAcctCPL.get(acct.Id).isEmpty()) {                    
                    for (Customer_Price_List__c cpl : mapAcctCPL.get(acct.Id).values()) {
                        System.debug(LoggingLevel.FINEST, '***CPL: ' + cpl);
                        // Update Active CPL
                        if (cpl.Customer_Price_List_ID__c != null && cpl.Pricing_Assignment_Status__c == 'Pending Removal Approval') {
                            System.debug(LoggingLevel.FINEST, '***Update Active CPL');
                            cplToUpdate.add(new Customer_Price_List__c(Id = cpl.Id, Action__c = 'Removal', Pricing_Assignment_Status__c = 'Submitted to CPS'));
                        }
                        
                        // Update Inactive CPL
                        if (cpl.Customer_Price_List_ID__c == null && cpl.Pricing_Assignment_Status__c == 'Pending Assignment Approval'&& cpl.Status__c == 'Inactive') {
                            System.debug(LoggingLevel.FINEST, '***Update Inactive CPL');
                            cplToUpdate.add(new Customer_Price_List__c(Id = cpl.Id, Action__c = 'Assignment', Pricing_Assignment_Status__c = 'Submitted to CPS'));
                        }
                    }
                }

                if (mapAcctCFTD.get(acct.Id) != null && !mapAcctCFTD.get(acct.Id).isEmpty()) {                    
                    for (Customer_Family_Tree_Discount__c cftd : mapAcctCFTD.get(acct.Id).values()) {
                        System.debug(LoggingLevel.FINEST, '***CFTD: ' + cftd);
                        // Update Active CFTD
                        if (cftd.Customer_Family_Tree_External_ID__c != null && cftd.Pricing_Assignment_Status__c == 'Pending Removal Approval') {
                            System.debug(LoggingLevel.FINEST, '***Update Active CPL');
                            cftdToUpdate.add(new Customer_Family_Tree_Discount__c(Id = cftd.Id, Action__c = 'Removal', Pricing_Assignment_Status__c = 'Submitted to CPS'));
                        }

                        // Update Inactive CFTD
                        if (cftd.Customer_Family_Tree_External_ID__c == null && cftd.Pricing_Assignment_Status__c == 'Pending Assignment Approval'&& cftd.Status__c == 'Inactive') {
                            System.debug(LoggingLevel.FINEST, '***Update Inactive CPL');
                            cftdToUpdate.add(new Customer_Family_Tree_Discount__c(Id = cftd.Id, Action__c = 'Assignment', Pricing_Assignment_Status__c = 'Submitted to CPS'));
                        }
                    }
                }
                
                // Reset Approval fields
                acctToUpdate.put(acct.Id, new Account(Id = acct.Id, Family_Tree_Discount_Approval__c = false, Family_Tree_Discount_Changed__c = false, Price_List_Changed__c = false,
                    Updated_Price_Lists__c = false));

                // Reset Proposed Spend Band
                if (acct.Proposed_Spend_Band__c == acct.Spend_Band__c) {
                    acctToUpdate.put(acct.Id, new Account(Id = acct.Id, Proposed_Spend_Band__c = null));
                }

                // Uncheck NZ Prospect Fields
                if (acct.RecordTypeId == DM_RecordType.rtId_Account_NzProspect) {
                    acctToUpdate.put(acct.Id, new Account(Id = acct.Id, Send_Data_to_CPS__c = false));
                }
        }

        System.debug(LoggingLevel.FINEST, '***acctToUpdate: ' + acctToUpdate.values());
        System.debug(LoggingLevel.FINEST, '***cplToUpdate: ' + cplToUpdate);
        System.debug(LoggingLevel.FINEST, '***cftdToUpdate: ' + cftdToUpdate);

        if (!acctToUpdate.isEmpty())
            update acctToUpdate.values();

        if (!cplToUpdate.isEmpty())
            update cplToUpdate;

        if (!cftdToUpdate.isEmpty())
            update cftdToUpdate;
    }
    
     /**
    * @description CRMS-226 - New Account Number Fields on Account Object for V1 Integration Feed
    * @author Bunnings - Dev | 22/10/2024
    * @param lstNewBusinessAcc
    **/
    public static void updateAccountNumberandAccountIdentificaton(List<Account> lstNewBusinessAcc){

        for(Account acct : lstNewBusinessAcc){
            
            if(String.isNotBlank(acct.Power_Pass_Account_Number__c) ){
                String powerPassNumber = acct.Power_Pass_Account_Number__c;
                Integer length = powerPassNumber.length();
                String accNumber;
                if(powerPassNumber.contains('AU') || powerPassNumber.contains('NZ') ){
                    List<String> parts = powerPassNumber.splitByCharacterType();
                    System.debug(parts.size());
                    accNumber = parts[0].length() <= 6 ? parts[0].leftpad(6,'0'):parts[0].leftpad(9,'0');
                    acct.Account_Number__c = accNumber;
                    acct.Account_Identification__c = accNumber + '-' + parts[1];
                 }else{
                    String countryCode = acct.Country__c == 'Australia' ? 'AU' : 'NZ';
                    accNumber = powerPassNumber.length() <= 6 ? powerPassNumber.leftpad(6,'0'):powerPassNumber.leftpad(9,'0');
                    acct.Account_Number__c = accNumber;
                    acct.Account_Identification__c = accNumber + '-' + countryCode;
                }

                

            }

        }
        

    }
        
}