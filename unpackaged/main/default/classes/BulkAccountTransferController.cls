/*******************************************************************************************************
* Class Name      	: BulkAccountTransferController
* Description		: Controller for LWC Component
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS           29/12/2020		1000				Initial version - CCRM-170
* Simplus MS           29/01/2021       1001                Validation added to check logged-in user's profile
* Simplus MS           04/02/2021       1002                Transfer comments added, Logic to check if Account is transferrable
* Simplus MS           08/02/2021       1003                Logic for defaulting Current Account Owner field added in checkProfile method
* Simplus MS           26/02/2021       1004                Added new method transferAccountRelatedRecords to update all Account related records on successful transfer
* Simplus MS           23/04/2021       1005                Added logic to query records using date range filter on CreatedDate
* Simplus MS 		   03/05/2021		1006				Added logic for additional filters
* Simplus MS 		   28/06/2021		1007 				Added Added logic to add an additional layer of validation that prevent TS users to transfer accounts 
															      that they do not own incase they are not defaulted in current Account owner field - fix for INC0978332
* Simplus MS           18/11/2021       1008                CCRM15-55: Bulk Account Transfer additional filters.
* Simplus MS           22/12/2021       1009                CCRM15-421 Bulk Account Transfer confirmation prompt.
* Simplus MS 		   19/01/2022		1010			    CCRM15-594 Bulk Account Transfer Not Functioning
******************************************************************************************************/
public with sharing class BulkAccountTransferController {
    private static final Integer QUERY_LIMIT = 25;
    public static final String STEP_TO_SELF = 'ToSelf';
    public static final String MESSAGE_UNAUTHORISED    = 'You do not have access to this page';

    /**
    * @description - On load fetch account data
    * @author Simplus MS | 29/12/2020 
    * @param objectApiName 
    * @param transferFromUserId 
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static CustomSearchWrapper init(String objectApiName, String transferFromUserId, String createdDate, String createdDateOperator, String filters, String sortBy, String sortDirection) {
        CustomSearchWrapper response = new CustomSearchWrapper();

        system.debug('filters =>'+filters);
        response.queryLimit = QUERY_LIMIT;
        
       // Updated by Simplus MS 28.Jun.2021
       // Added logic to add an additional layer of validation that prevent TS users to transfer accounts that they do not own incase they are not defaulted in current Account owner field - fix for INC0978332
        Set<String> tradeSpecialistProfiles = new Set<String>{Constants.AU_TRADE_SPECIALIST_PROFILEENAME, Constants.NZ_TRADE_SPECIALIST_PROFILEENAME};
        Map<String,Id> tsIdMap = new Map<String,Id>();
        for (Profile p : DM_Profile.getProfilebyName(tradeSpecialistProfiles)) {
            tsIdMap.put(p.Name,p.Id);
        }

        Boolean allowTransfer = FALSE;
        if ((UserInfo.getProfileId() == tsIdMap.get(Constants.AU_TRADE_SPECIALIST_PROFILEENAME)) || (UserInfo.getProfileId() == tsIdMap.get(Constants.NZ_TRADE_SPECIALIST_PROFILEENAME)) || Test.isRunningTest()){
            system.debug('Running user is a trade specialist.');
            if (transferFromUserId == UserInfo.getUserId()){
                allowTransfer = TRUE;
            } else {
                allowTransfer = FALSE;
                response.tsUserAccess = true;
                response.data = new List<Account>();
            }
        } else {
            system.debug('Running user is a not trade specialist.');
            allowTransfer = TRUE;
        }
		
        if (allowTransfer){
            // set label & pural labels
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if(gd.containsKey(objectApiName)) {
                Schema.DescribeSObjectResult dsr = gd.get(objectApiName).getDescribe();
                response.objectLabel = dsr.getLabel();
                response.objectLabelPlural = dsr.getLabelPlural();
            }
            
            // get display fields
            List<Bulk_Account_Transfer_Field__mdt> fieldData = customSearchFieldDataByObject(objectApiName);
            response.displayFields = new List<Field>();
            for(Bulk_Account_Transfer_Field__mdt csf : fieldData) {
                // display fields
                if(csf.Display_Field__c == true) {
                    Field f = new Field();
                    if(csf.Field__r.Label == 'On Contract'){
                        f.label = 'Non-Expired Contract Exists?';
                    }else{
                        f.label = csf.Field__r.Label;
                    }
                    
                    if(csf.Field__r.QualifiedApiName == 'Assigned_Store__c'){
                        f.fieldName = 'Assigned_Store__r.Name';
                    }
                    else if(csf.Field__r.QualifiedApiName == 'Secondary_Segment__c'){
                        f.fieldName = 'Secondary_Segment__r.Name';
                    }else{
                        f.fieldName = csf.Field__r.QualifiedApiName;
                    } 
                    
                    f.sortable = true;
                    
                    response.displayFields.add(f);
                }
            }
            
            
            
            List<Field> filterArr = (List<Field>)JSON.deserialize(filters, List<Field>.class);
            // add initial data
            response.data = getAccounts(response.displayFields, transferFromUserId, 0, QUERY_LIMIT, sortBy, sortDirection, createdDate, createdDateOperator, filterArr);
        }
        return response;
    }

    /**
    * @description - fetch account data
    * @author Simplus MS | 29/12/2020 
    * @param fields,transferToUserId 
    * @return List<Account> 
    **/
    @AuraEnabled
    public static List<Account> getAccounts(List<Field> fields, String transferFromUserId, Integer offset, Integer recordLimit, String sortBy, String sortDirection, String createdDate, String createdDateOperator, List<Field> filters){
        System.debug(LoggingLevel.DEBUG, fields);
        System.debug(LoggingLevel.DEBUG, filters);
        System.debug(LoggingLevel.DEBUG, transferFromUserId);
        
        String sorting = (sortBy != null && sortDirection != null) ? (' ORDER BY ' + sortBy + ' ' + sortDirection + ' ') : '';
        if(sortDirection == 'desc') {
            sorting += '  NULLS last';
        }

        String query = '';

		system.debug('filters'+filters);
		//system.debug('filtersToWhereClauses'+filtersToWhereClauses(filters));  
        
        if(createdDate != '' && createdDateOperator != ''){
            // Datetime dt = Date.valueOf(createdDate);
            // String dateFormat = dt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');
            query = 'SELECT ' + fieldsToQueryFields(fields) 
            + ' FROM Account ' 
            + ' WHERE OwnerId =: transferFromUserId '
			+ ' AND (PowerPass_Account_Created_Date__c ' +createdDateOperator+ ' ' +createdDate+ ''
            + ' OR (CreatedDate ' +createdDateOperator+ ' ' +createdDate+ 'T00:00:00Z '
            + ' AND (PowerPass_Account_Created_Date__c = null)))' 
            + filtersToWhereClauses(filters)
            + sorting
			+ ' LIMIT 50000'
           ;
            //+ ' AND PowerPass_Account_Created_Date__c ' +createdDateOperator+ ' ' +createdDate+ ''
            // + ' LIMIT :recordLimit OFFSET :offset' 
        }
        System.debug('Query-->' +query);
        System.debug(LoggingLevel.DEBUG, query);
        List<Account> results = Database.query(query);
        return results;
    }

    /**
    * @description - Fetch Column Names from Custom Metadata
    * @author Simplus MS | 29/12/2020 
    * @param objectApiName 
    * @return List<Bulk_Account_Transfer_Field__mdt>
    **/
    public static List<Bulk_Account_Transfer_Field__mdt> customSearchFieldDataByObject(String objectApiName) {
        return new List<Bulk_Account_Transfer_Field__mdt>([
            SELECT Id,
            Object__r.QualifiedApiName, 
            Field__r.QualifiedApiName, 
            Field__r.Label, Display_Field__c, Column_Order__c
            FROM Bulk_Account_Transfer_Field__mdt
            WHERE Object__r.QualifiedApiName = :objectApiName
            ORDER BY Column_Order__c
        ]);
    }

    /**
    * @description - query field names
    * @author Simplus MS | 29/12/2020 
    * @param fields
    * @return String
    **/
    private static String fieldsToQueryFields(List<Field> fields) {
        List<String> fs = new List<String>{'Id'};
        for(Field f : fields) {
            if(String.isNotBlank(f.fieldName)) {
                if(f.fieldName == 'Assigned_Store__c'){
                    fs.add('Assigned_Store__r.Name');
                }else if(f.fieldName == 'Secondary_Segment__c'){
                    fs.add('Secondary_Segment__r.Name');
                }else{
                    fs.add(f.fieldName);
                }
            }
        }
        return String.join(fs, ',');
    }

    /**
    * @description - Fetch Account data based on UserId
    * @author Simplus MS | 29/12/2020 
    * @param userId 
    * @return List<Account>
    **/
    @AuraEnabled
    public static List<Account> getAccountData(Id transferFromUserId){
        List<Account> acctList = [SELECT Id, Name, Power_Pass_Account_Number__c, PowerPass_Account_Created_Date__c, On_Contract__c,
                                         Account_State__c, BillingAddress, Assigned_Store__r.Name, Primary_Segment__c, 
                                         Secondary_Segment__r.Name, Account_Transferrable__c
                                  FROM  Account
                                  WHERE OwnerId =: transferFromUserId
                                  LIMIT 50000];
        return acctList;
    }

    /**
    * @description - Check if contracts available for all accounts
    * @author Simplus MS | 05/01/2021
    * @param transferFromUserId,transferToUserId 
    * @return Map<String,String>
    **/
    @AuraEnabled
    public static Map<String, String> checkContractsForAllAccounts(Id transferFromUserId, Id transferToUserId){
        Map<String, String> resp = new Map<String, String>();
        try{
            
            if(transferFromUserId == transferToUserId) {
                resp.put('debugMsg', 'Attempting to transfer to self');
                return resp;
            }else{
                List<Account> acctList = getAccountData(transferFromUserId);
                Set<Id> acctIds = new Set<Id>();
                for(Account a : acctList){
                    acctIds.add(a.Id);
                }

                System.debug(acctIds);

                Set<Id> ownerIds = new Set<Id>();
                ownerIds.add(transferFromUserId);

                System.debug(ownerIds);
                List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
                System.debug('contracts::' +contracts);
                //Integer nonExpiredCount = SM_CustomerContract.countNonExpiredContracts(contracts);
                
                if(contracts!=null && !contracts.isEmpty()) {
                    resp.put('NewContractOwner', 'true');
                } else {
                    resp.put('NewContractOwner', 'false');
                }
            }
        }catch(Exception ex){

        }
        return resp;
    }

    /**
    * @description - Check if contracts available for selected accounts
    * @author Simplus MS | 05/01/2021
    * @param transferFromUserId,transferToUserId 
    * @return Map<String,String>
    **/
    @AuraEnabled
    public static Map<String, String> checkContractsForSelectedAccounts(List<Account> acctList, Id transferFromUserId, Id transferToUserId){
        Map<String, String> resp = new Map<String, String>();
        List<Id> acctIdList = new List<Id>();
        try{
            
            if(transferFromUserId == transferToUserId) {
                resp.put('step', STEP_TO_SELF);
                resp.put('debugMsg', 'Attempting to transfer to self');
                return resp;
            }else{
                Set<Id> acctIds = new Set<Id>();
                for(Account a : acctList){
                    acctIds.add(a.Id);
                }

                Set<Id> ownerIds = new Set<Id>();
                ownerIds.add(transferFromUserId);

                List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
                
                Integer nonExpiredCount = SM_CustomerContract.countNonExpiredContracts(contracts);
                if(nonExpiredCount == 0) {
                    resp.put('NewContractOwner', 'false');
                    resp.put('msg', 'No Contract Owner Available');
                } else {
                    resp.put('NewContractOwner', 'true');
                }
            }
        }catch(Exception ex){

        }
        return resp;
    }

    /**
    * @description - Transfer All accounts
    * @author Simplus MS | 08/01/2021
    * @param transferFromUserId,transferToUserId,newContractOwner
    * @return Map<String,String>
    * @modification CCRM15-594
    **/
    @AuraEnabled
    public static String transferAccounts(String selectedOption, List<Account> lSelectedAccounts, Id transferFromUserId, Id transferToUserId, String newContractOwner, String comments,  String createdDate, String createdDateOperator, String filters){

        System.debug('selectedOption-->' +selectedOption);
        System.debug('transferFromId-->' +transferFromUserId);
        System.debug('transferToUserId-->' +transferToUserId);
        System.debug('newContractOwner-->' +newContractOwner);
        System.debug('comments-->' +comments);
        
        SM_BulkAccountTransferBatch bulkTransferBatch = new SM_BulkAccountTransferBatch(selectedOption, lSelectedAccounts, transferFromUserId, transferToUserId, newContractOwner, comments, createdDate, createdDateOperator, filters);
        Id batchJobId = Database.executeBatch(bulkTransferBatch, 50);
        
        String response = (batchJobId != null ? 'Success' : 'Failure');
        return response;
        
    }

    /**
    * @description - Transfer Selected accounts
    * @author Simplus MS | 08/01/2021
    * @param transferFromUserId,transferToUserId,newContractOwner
    * @return Map<String,String>
    **/
    /** Commented for CCRM15-594 - transfer of selected accounts will now be in SM_BulkAccountTransferBatch
    @AuraEnabled
    public static Map<String, String> transferSelectedAccounts(List<Account> accList, Id transferFromUserId, Id transferToUserId, 
                                                                Id newContractOwner, String comments){
        System.debug('inside transferSelectedAccounts acctList::' +accList);
        Map<String, String> resultMap = new Map<String, String>{'Status' => 'Failure'};
        List<Account> updateAcctList = new List<Account>();
        List<Customer_Contract__c> customerContractList = new List<Customer_Contract__c>();
        List<Contract__c> contractList = new List<Contract__c>();
        Set<Id> acctIds = new Set<Id>();
        for(Account a : accList){
            if(a.Account_Transferrable__c == 'Yes'){
                Account acc = new Account();
                acc.Id = a.Id;
                acc.OwnerId = transferToUserId;
                acc.Bulk_Account_Transfer__c = true;
                acc.Transfer_comments__c = comments;
                updateAcctList.add(acc);
    
                acctIds.add(a.Id);
            }
        }

        Set<Id> ownerIds = new Set<Id>();
        ownerIds.add(transferFromUserId);

        if(acctIds!=null){
            List<Customer_Contract__c> contracts = DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
            System.debug('contracts:: '+contracts);
            List<User> managerIdList = getManagerId(newContractOwner);

            if(contracts!=null && !contracts.isEmpty()){
                for(Customer_Contract__c cusContract : contracts){
                    if(cusContract.Customer__r.Account_Transferrable__c == 'Yes'){
                        Contract__c contract = new Contract__c();
                        contract.Id = cusContract.Contract__r.Id;
                        contract.OwnerId = newContractOwner;
                        contract.New_Reviewer__c = newContractOwner;
                        contract.New_Approver__c = managerIdList[0].ManagerId;
                        contractList.add(contract);
                    }
                }
            }
        }
        System.debug('updateAcctList::' +updateAcctList);
        
        if(updateAcctList!=null && !updateAcctList.isEmpty()){
            try {
                update updateAcctList;
                resultMap.put('Status', 'Success');
                transferAccountRelatedRecords(updateAcctList, transferFromUserId, transferToUserId);
                sendBulkAccountTransferNotification(transferToUserId);
                
            } catch (Exception ex) {
                System.debug('Inside update acct exception');
                System.debug(ex.getStackTraceString());
                System.debug(ex.getMessage());
                ApplicationLogger.log('BulkAccountTransferController.transferSelectedAccounts', '', 'LWC controller', ex);
            }
        }
        if(contractList!=null && !contractList.isEmpty()){
            try {
                update contractList;
                resultMap.put('Status', 'Success');
                
            } catch (Exception ex) {
                System.debug(ex.getStackTraceString());
                ApplicationLogger.log('BulkAccountTransferController.transferSelectedAccounts', '', 'LWC controller', ex);
            }
        }
        
        return resultMap;
    }
	**/

    /**
    * @description - Send Transfer Notification to New Account Owner
    * @author Simplus MS | 11/01/2021
    * @param transferFromUserId,transferToUserId,newContractOwner
    * @return Map<String,String>
    **/
    public static void sendBulkAccountTransferNotification(String transferToUserId) {
        String addressTest = 
            '' +
            '{' +
            '       type: \'standard__objectPage\',' +
            '       attributes: {' +
            '           objectApiName: \'Account\',' +
            '           actionName: \'list\',' +
            '       },' +
            ' 		state: {' +
            '       	filterName: \'MyAccounts\'' +
            '       }' +
            '}';
        
        system.debug('addressTest'+addressTest);
        Map<String, Object> flowInput = new Map<String, Object>();
        flowInput.put('customNotificationTypeName', 'Account Transfer Notification');
        flowInput.put('targetId', transferToUserId);
        flowInput.put('recipientIds', new List<String>{transferToUserId});
        flowInput.put('notificationTitle', 'Bulk Account Transfer Notification');
        flowInput.put('notificationBody', 'Multiple have been transferred to you. Remember to review the open tasks and events in your calendar.');
        flowInput.put('setTargetPageRef',addressTest);
        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
        sendCustomNotifiFlow.start();
    }

    /**
    * @description - On load validate if user is allowed to view the Bulk Account Transfer Page
    * @author Simplus MS | 29/01/2021
    * @param runningUserId 
    * @return CustomSearchWrapper 
    **/
    @AuraEnabled(cacheable=true)
    public static CustomSearchWrapper checkUserProfile(String runningUserId){
        CustomSearchWrapper resp = new CustomSearchWrapper();

        User runningUser = DM_User.getUser(runningUserId);

        List<Bulk_Account_Transfer_Profile__mdt> profileList = [SELECT Label, Default_Current_Account_Owner__c
                                                                FROM Bulk_Account_Transfer_Profile__mdt
                                                                WHERE Label =: runningUser.Profile.Name];

        if(profileList!=null && !profileList.isEmpty()){
            resp.userHasAccess = true;
            if(profileList[0].Default_Current_Account_Owner__c == true){
                resp.defaultInitiator = true;
            }
        }else{
            resp.userHasAccess = false;
            resp.noAccessMessage = MESSAGE_UNAUTHORISED;
        }

        List<Initialisation__mdt> filterUMProfileList = [SELECT Id, BulkAccTrans_UmGroup_Filter_Profiles__c FROM Initialisation__mdt];

        System.debug('profileList: '+filterUMProfileList[0].BulkAccTrans_UmGroup_Filter_Profiles__c);
        System.debug('runningUser.Profile.Name: '+runningUser.Profile.Name);
        if(filterUMProfileList!=null && !filterUMProfileList.isEmpty() && 
            filterUMProfileList[0].BulkAccTrans_UmGroup_Filter_Profiles__c.contains(runningUser.Profile.Name)){
            resp.showUmbrellaGroupFilter = true;
        }else{
            resp.showUmbrellaGroupFilter = false;
        }
        
        return resp;                 
    }

    /**
    * @description - To fetch managerId of the user
    * @author Simplus MS | 02/02/2021
    * @param userId 
    * @return Id 
    **/
    public static List<User> getManagerId(String userId){
        return [SELECT ManagerId 
                FROM User
                WHERE Id =: userId];
    }


    /**
    * @description 
    * @author Yi Zhang | 18/05/2020 
    * @param oldMap 
    * @param newMap 
    * @return void 
    **/
    /** Commented for CCRM15-594 - transfer of selected accounts will now be in SM_BulkAccountTransferBatch
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
        if(reviews.keySet().isEmpty() == false) {
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
    }
	**/
    
    /**
    * @description - Method is invoked from lookup component to fetch records
    * @author Simplus MS | 30/04/2021 
    * @param searchKey 
    * @param objectName
    * @return List of sObjects 
    **/
    @AuraEnabled(cacheable=true)  
    public static List<sobject> findRecords(String searchKey, String objectName) {  
        string searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';  
        string query = 'SELECT Id, Name FROM ' +objectName+ ' WHERE Name LIKE '+searchText+' LIMIT 5';  
        return Database.query('SELECT Id, Name FROM ' +objectName+ ' WHERE Name LIKE '+searchText+' LIMIT 5');  
    } 

    /**
    * @description - Fetch Primary values from Segments
    * @author Simplus MS | 03/05/2021
    * @return List<String>
    **/
    @AuraEnabled(cacheable=true)  
    public static List<String> fetchPrimarySegment () {
        List<String> primarySegmentValues = new List<String>();
        List<AggregateResult> primaries = new List<AggregateResult>([SELECT Primary__c FROM Segment__c WHERE Primary__c != null GROUP BY Primary__c ORDER BY Primary__c ASC LIMIT 49999]);
        system.debug('primaries'+primaries);
        if(primaries.size() > 0) {
            for(AggregateResult ar : primaries) {
                system.debug('value'+(String)ar.get('Primary__c'));
                primarySegmentValues.add((String)ar.get('Primary__c'));
            }
        }
        system.debug('primarySegmentValues'+primarySegmentValues);
        //get Primary Segment values
		return primarySegmentValues;
    }

    /**
    * @description - construct Where clause
    * @author Simplus MS | 03/05/2021
    * @return String
    **/
    private static String filtersToWhereClauses(List<Field> filters) {
        List<String> fs = new List<String>();
        try{
            for(Field f : filters) {
                if(String.isNotBlank(f.fieldName) && (String.isNotBlank(f.value)) && (String.isNotBlank(f.operator))) {
                    // override for primary segment / operations region
                    if((f.fieldName == 'Primary_Segment__c' ) && String.isNotBlank(f.value)) {
                        f.type = 'picklist';
                    }
                    if ((f.fieldName == 'Secondary_Segment__c' ) && String.isNotBlank(f.value)){
                        f.fieldName = 'Secondary_Segment__r.Name';
                    }
                    if ((f.fieldName == 'Assigned_Store__c' ) && String.isNotBlank(f.value)){
                        f.fieldName = 'Assigned_Store__r.Name';
                    }
                    if ((f.fieldName == 'R12_Top_Spend_Location_1__c' ) && String.isNotBlank(f.value)){
                        f.fieldName = 'R12_Top_Spend_Location_1__r.Name';
                    }
                    if ((f.fieldName == 'R12_Top_Spend_Location_2__c' ) && String.isNotBlank(f.value)){
                        f.fieldName = 'R12_Top_Spend_Location_2__r.Name';
                    }

                    if(f.value == null){
                        f.value = '';
                    }
                    else {
                        if(f.type == 'boolean' || f.type == 'currency' || f.type == 'date' || f.type == 'number') {
                            // boolean, currency or date, no quote
                            fs.add(f.fieldName + ' ' + f.operator + f.value);
                        } else if((f.fieldName == 'BillingCity' ) && String.isNotBlank(f.value) && f.operator == '%%') {
                            fs.add(f.fieldName + ' LIKE \'%' + f.value +'%\'');
                        } else if((f.fieldName == 'Previous_Owner__c' ) && String.isNotBlank(f.value) && f.operator == '%%') {
                            fs.add(f.fieldName + ' LIKE \'%' + f.value +'%\'');
                        } else if ((f.fieldName == 'Umbrella_Group__c' ) && String.isNotBlank(f.value)){
                            fs.add('Id IN (Select Account__c From Umbrella_Beneficiary__c Where Umbrella_Group__c = \'' + f.value + '\')');
                        } else if(f.type == 'picklist') {
                            // picklist, use IN
                            String fieldValue = f.value.replaceAll(', ', '\', \'');
                            fieldValue = fieldValue.replace('[','(');
                            fieldValue = fieldValue.replace(']',')');
                            fieldValue = fieldValue.replaceAll('"','\'');
                            fs.add(f.fieldName + ' IN ' + fieldValue);
                        }else {
                            fs.add(f.fieldName + ' ' + f.operator + ' \'' + f.value + '\'');
                        }
                    }
                }
            }
            if(fs.size() > 0) {
                System.debug('filtersToWhereClauses: '+ String.join(fs, ' AND '));
                return ' AND ' + String.join(fs, ' AND ');
            }
            return '';
        }catch (System.NullPointerException e){
            system.debug(e);
            return '';
        }

    }

    /**
    * @description - Find Segment Records By NameKey
    * @author Simplus MS | 22/11/2021
    * @return List<sObject>
    **/
    @AuraEnabled (cacheable = true)
    public static List<sObject> findRecordsByNameKey(String searchKey, List<Id> excludeIds){
        String searchNameKey = '%' + searchKey + '%';
        return [SELECT Id, Name FROM Segment__c WHERE Name LIKE :searchNameKey AND Id NOT IN :excludeIds ORDER BY Name ASC LIMIT 5];
    }

    /**
    * @description - Get New Account Owner Name By Id
    * @author Simplus MS | 22/12/2021
    * @return String
    **/
    @AuraEnabled
    public static String getNewAccountOwnerName(Id newOwnerId){
        return [SELECT Id, Name FROM User WHERE Id =: newOwnerId].Name;
    }
	
    /**
     * @description Wrapper class for dynamic column creation
     */
    public class CustomSearchWrapper {
        @AuraEnabled
        public List<Field> displayFields;
        @AuraEnabled
        public List<Field> filterFields;
        @AuraEnabled
        public List<Account> data;
        @AuraEnabled
        public List<String> primarySegmentValues;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String objectLabelPlural;
        @AuraEnabled
        public Integer queryLimit;
        @AuraEnabled
        public Boolean tsUserAccess;
        @AuraEnabled
        public Boolean userHasAccess;
        @AuraEnabled
        public String noAccessMessage;
        @AuraEnabled
        public Boolean defaultInitiator;
        @AuraEnabled
        public Boolean showUmbrellaGroupFilter;
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