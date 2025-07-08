/*******************************************************************************************************
* Class Name      	: SM_BulkAccountTransferBatch
* Description		: Batch class for transfer bulk accounts
* Author          	: Simplus - MS
* Created On      	: 26/04/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            26/04/2021		1000				Initial version
* Simplus MS 		    03/05/2021		1001				Added logic for additional filters
* Simplus MS 			19/01/2022		1002			    CCRM15-594 - Bulk Account Transfer Not Functioning
* Simplus MS            19/05/2022      1003                SFSUP-451 - Bulk account transfer not working for system admin
* Bunnings Dev          05/08/2022      1008                SFSUP-898 - Transfer Account Plan
******************************************************************************************************/
public class SM_BulkAccountTransferBatch implements Database.Batchable<sObject>{
    String query;
    String transferFromId;
    String transferToId;
    String newContractOwnerId;
    String comments;
    String selectedOption;
    List<Account> lSelectedAccounts = new List<Account>();
    
    public SM_BulkAccountTransferBatch(String selectedOption, List<Account> lSelectedAccounts, Id transferFromUserId, Id transferToUserId, String newContractOwner, String comments, String createdDate, String createdDateOperator, String filters) {
        
        selectedOption = selectedOption;
        transferFromId = transferFromUserId;
        transferToId = transferToUserId;
        newContractOwnerId = newContractOwner;
        comments = comments;
        lSelectedAccounts = lSelectedAccounts;
        
        System.debug('selectedOption-->' +selectedOption);
        System.debug('transferFromId-->' +transferFromId);
        System.debug('transferToUserId-->' +transferToUserId);
        System.debug('this.newContractOwner-->' +newContractOwnerId);
        System.debug('newContractOwner-->' +newContractOwnerId);
        
        //Modified for CCRM15-594 - transfer ALL and SELECTED accounts
        if (selectedOption == 'transferAllAccounts'){
            List<Field> filterArr = (List<Field>)JSON.deserialize(filters, List<Field>.class);
            System.debug('filterArr '+filterArr);
            query = 'SELECT Id, Name, Power_Pass_Account_Number__c, PowerPass_Account_Created_Date__c, On_Contract__c, '
                + ' Account_State__c, BillingAddress, Assigned_Store__r.Name, Primary_Segment__c, '
                + ' Secondary_Segment__r.Name, Account_Transferrable__c '
                + ' FROM  Account '
                + ' WHERE OwnerId =: transferFromId '
                + ' AND (PowerPass_Account_Created_Date__c ' +createdDateOperator+ ' ' +createdDate+ ''
                + ' OR (CreatedDate ' +createdDateOperator+ ' ' +createdDate+ 'T00:00:00Z '
                + ' AND (PowerPass_Account_Created_Date__c = null)))' 
                +  filtersToWhereClauses(filterArr);
        } else if (selectedOption == 'transferSelectedAccounts'){
            List<Id> sAccountIds = new List<Id>();
            for (Account acc : lSelectedAccounts){
                sAccountIds.add(acc.Id);
            }
            String idString= '\''+String.join(sAccountIds,'\',\'')+'\'';
            system.debug('sAccountIds ' +sAccountIds);
            query = 'SELECT Id, Name, Power_Pass_Account_Number__c, PowerPass_Account_Created_Date__c, On_Contract__c, '
                + ' Account_State__c, BillingAddress, Assigned_Store__r.Name, Primary_Segment__c, '
                + ' Secondary_Segment__r.Name, Account_Transferrable__c '
                + ' FROM Account'
                + ' WHERE Id IN (' +idString+ ')';
        }
        
        System.debug('Query-->' +query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // execute code
        System.debug('Scope ::' +scope);
        try {
            List<Account> updateAcctList = new List<Account>();
            List<Contract__c> contractList = new List<Contract__c>();
            Set<Id> acctIds = new Set<Id>();
            for(Account a : scope){
                if(a.Account_Transferrable__c == 'Yes'){
                    Account acc = new Account();
                    acc.Id = a.Id;
                    acc.OwnerId = transferToId;
                    acc.Bulk_Account_Transfer__c = true;
                    acc.Transfer_comments__c = comments;
                    updateAcctList.add(acc);
                    
                    acctIds.add(a.Id);    
                }
                
            }
            System.debug('AccountList::' +updateAcctList);
            System.debug('Account List Size::' +updateAcctList.size());
            Set<Id> ownerIds = new Set<Id>();
            ownerIds.add(transferFromId);
            
            if(acctIds!=null){
                List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
                System.debug('newContractOwnerId::' +newContractOwnerId);
                List<User> managerIdList = getManagerId(newContractOwnerId);
                System.debug('ManagerIdList-->' +managerIdList);
                if(contracts!=null && !contracts.isEmpty()){
                    for(Customer_Contract__c cusContract : contracts){
                        if(cusContract.Customer__r.Account_Transferrable__c == 'Yes'){
                            Contract__c contract = new Contract__c();
                            contract.Id = cusContract.Contract__r.Id;
                            contract.OwnerId = newContractOwnerId;
                            contract.New_Reviewer__c = newContractOwnerId;
                            contract.New_Approver__c = managerIdList[0].ManagerId;
                            contractList.add(contract);
                        }
                    }
                }
            }
            
            if(updateAcctList!=null && !updateAcctList.isEmpty()){
                try {
                    update updateAcctList;
                    transferAccountRelatedRecords(updateAcctList, transferFromId, transferToId);
                    if(contractList!=null && !contractList.isEmpty()){
                        system.debug('contractList here :: '+contractList);
                        update contractList;
                    }  
                } catch (Exception ex) {
                    System.debug(ex.getStackTraceString());
                    sendBulkAccountTransferErrorNotification(transferFromId);
                }
            }
            
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // finish code
        sendBulkAccountTransferNotification(transferToId);
    }
    
    public static List<User> getManagerId(String userId){
        return [SELECT ManagerId 
                FROM User
                WHERE Id =: userId];
    }
    
    public static void transferAccountRelatedRecords(List<Account> updateAccList, String oldOwnerId, String newOwnerId) {
        System.debug('inside transferAccountRelatedRecords');
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
            update tasks;
        }
        
        // events
        List<Event> events = DM_Event.getOpenEventsWithWhatIds(accountIds, oldOwnerIds);
        if(events.isEmpty() == false) {
            for(Event e : events) {
                e.OwnerId = acctOwnersMap.get(e.WhatId + '' + e.OwnerId);
            }
            update events;
        }
        
        // opportunities
        List<Opportunity> opportunities = DM_Opportunity.getOpenOpportunities(accountIds, oldOwnerIds).values();
        if(opportunities.isEmpty() == false) {
            for(Opportunity o : opportunities) {
                o.OwnerId = acctOwnersMap.get(o.AccountId + '' + o.OwnerId);
            }
            update opportunities;
        }
        
        // contacts
        List<Contact> contacts = DM_Contact.getContacts(accountIds, oldOwnerIds).values();
        if(contacts.isEmpty() == false) {
            for(Contact c : contacts) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            update contacts;
        }
        
        // cases
        List<Case> cases = DM_Case.getOpenCases(accountIds, oldOwnerIds).values();
        if(cases.isEmpty() == false) {
            for(Case c : cases) {
                c.OwnerId = acctOwnersMap.get(c.AccountId + '' + c.OwnerId);
            }
            update cases;
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
                update reviewList;
                
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

        if (acctPlans.isEmpty()) {
            return;
        }
        
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
        
        if (!acctPlanToUpdate.isEmpty()) {
            try {
                update acctPlanToUpdate;    
            } catch (Exception e) {
                ApplicationLogger.log('Account Plan transfer', 'Account_Plan__c', 'Batch', e);
            }            
        }

    }
    
    /**
    * @description - construct Where clause
    * @author Simplus MS | 03/05/2021
    * @return String
    **/
    private static String filtersToWhereClauses(List<Field> filters) {
        if (!Test.isRunningTest()){
            List<String> fs = new List<String>();
            try{
                for(Field f : filters) {
                    System.debug('f.fieldName '+f.fieldName);
                    if(String.isNotBlank(f.fieldName) && (String.isNotBlank(f.value)) && (String.isNotBlank(f.operator))) {
                        // override for primary segment / operations region
                        if((f.fieldName == 'Primary_Segment__c' ) && String.isNotBlank(f.value)) {
                            f.type = 'picklist';
                        }
                        if ((f.fieldName == 'Secondary_Segment__c' ) && String.isNotBlank(f.value)){
                            f.fieldName = 'Secondary_Segment__r.Name';
                        }
                        if(f.value == null){
                            f.value = '';
                        }
                        //SFSUP-451 - Added to fix the error regarding % character in Account Name
                        if(f.fieldName == 'Previous_Owner__c' && String.isNotBlank(f.value)) {
                            System.debug('f.operator '+f.operator);
                            f.operator = ' ';
                        }
                        else {
                            if(f.type == 'boolean' || f.type == 'currency' || f.type == 'date' || f.type == 'number') {
                                // boolean, currency or date, no quote
                                fs.add(f.fieldName + ' ' + f.operator + ' ' + f.value);
                            } else if(f.type == 'picklist') {
                                // picklist, use IN
                                String fieldValue = f.value.replaceAll(', ', '\', \'');
                                fieldValue = fieldValue.replace('[','(');
                                fieldValue = fieldValue.replace(']',')');
                                fieldValue = fieldValue.replaceAll('"','\'');
                                fs.add(f.fieldName + ' IN ' + fieldValue);
                            } else {
                                fs.add(f.fieldName + ' ' + f.operator + ' \'' + f.value + '\'');
                            }
                        }
                    }
                }
                if(fs.size() > 0) {
                    return ' AND ' + String.join(fs, ' AND ');
                }
                return '';
            }catch (System.NullPointerException e){
                system.debug(e);
                return '';
            }
            
        } else{
            return '';
        }
        
    }
    
    /**
    * @description - Send Transfer Notification to Current Account Owner
    * @author Simplus MS 
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
    
    /**
* @description
*/
    public class Field {
        @AuraEnabled
        public Integer key;         // used in multipicklist
        @AuraEnabled
        public Integer index;         // used in filter
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public Boolean editable;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String operator;
        @AuraEnabled
        public String operators;
        @AuraEnabled
        public List<Field> picklistOptions;
        @AuraEnabled
        public Boolean sortable;
        @AuraEnabled
        public Map<String, String> typeAttributes;
    }
}