/*******************************************************************************************************
* Class Name      	: SM_Contract
* Description		: Domain / Service layer for Contract__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 28/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              28/07/2020		1000				Initial version (Moved Phil's codes from SM_ContractReview)
* Yi Zhang              30/09/2020		2000				Added associateContractsWithProjects
* Simplus MS			15/02/2022		3000				Added for SFSUP-302 - Person Account Changes
* Jasper R Galapon      11/04/2023      4000                BUNDIG-17527 - Block integration user update when contract is Customer Approved
* Jasper R. Galapon     19/06/2023      5000                BUNDIG-21197 - New/Renewal Contracts - No Case Created When A1 Rejects
******************************************************************************************************/
public without sharing class SM_Contract {
    
    public static final String PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT = 'Active - On Contract';
    public static final String PROJECTPARTICIPANT_STATUS_ACTIVE_NOT_ON_CONTRACT = 'Active - Not on Contract';
    public static final String PROJECTPARTICIPANT_STATUS_REQUEST_CONTRACT_CHANGE = 'Request for Contract Change';
    public static final String PROJECTPARTICIPANT_STATUS_REQUEST_CONTRACT_ADDITION = 'Request for Contract Addition';
    public static final String CONTRACT_CUSTOMER_APPROVED = 'Customer Approved';
    public static final String CONTRACT_CUSTOMER_REJECTED = 'Customer Rejected';
    
    /**
* @description 
* @author Philip Clark | 01/07/2020 
* @param newList
**/
    public static void beforeInsert(list<Contract__c> newList) {
        try {
            newList = setReviewersApprovers(null, newList, TRUE);
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.beforeInsert', 'Contract__c', 'Trigger', e);
        }
    }
    
    /**
* @description 
* @author Philip Clark | 01/07/2020 
* @param oldMap, newList
**/
    public static void beforeUpdate(map<Id,Contract__c> oldMap, list<Contract__c> newList) {
        try {
            newList = setReviewersApprovers(oldMap, newList, TRUE);
            newList = associateContractsWithProjects(oldMap, newList);
            checkUpdatedContractNumber(oldMap, newList);
            getPreviousContractData(oldMap, newList);

            // BUNDIG-17527
            blockUpdate(oldMap, newList);
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.beforeUpdate', 'Contract__c', 'Trigger', e);
        }
    }
    
    /**
* @description 
* @author John Paul Peñaflor | 08-18-2020 
* @param map<Id Contract__c> oldMap 
* @param list<Contract__c> newList 
**/
    public static void afterUpdate(map<Id,Contract__c> oldMap, list<Contract__c> newList) {
        try {
            checkProjectUpdate(oldMap, newList);
            createCase(oldMap, newList); // BUNDIG-21197
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.afterUpdate', 'Contract__c', 'Trigger', e);
        }
    }
    
    public static List<Contract__c> associateContractsWithProjects(Map<Id,Contract__c> oldMap, List<Contract__c> newList) {
        // metadata
        List<String> contractFields = new List<String>();
        for(Project_Contract_Matching_Field__mdt cpmf : DM_ProjectContractMatchingField.matchingFields) {
            contractFields.add(cpmf.Source_Field__r.QualifiedApiName);
        }
        if(contractFields.isEmpty()) {
            return newList;
        }
        
        // scenarios where project field need to be examined:
        // - some fields are changed
        Map<Id, Contract__c> contractsAddressUpdated = new Map<Id, Contract__c>();
        for(Contract__c newContract : newList) {
            Contract__c oldContract = oldMap.get(newContract.Id);
            if(isValidToMatchProject(newContract, contractFields) || isValidToMatchProject(oldContract, contractFields)) {
                if(oldContract.Price_Estimate__c == true) {
                    contractsAddressUpdated.put(newContract.Id, newContract);
                } else {
                    for(String field : contractFields) {
                        if(oldContract.get(field) != newContract.get(field)) {
                            contractsAddressUpdated.put(newContract.Id, newContract);
                            break;
                        }
                    }
                }
            }
        }
        // System.debug(LoggingLevel.DEBUG, 'contractsAddressUpdated: ' + JSON.serialize(contractsAddressUpdated));
        if(contractsAddressUpdated.isEmpty() == false) {
            Map<Id, Contract__c> contractsWithProject = populateContractsProjects(
                DM_CustomerContract.getCustomerContracts(new Set<String>((List<String>)new List<Id>(contractsAddressUpdated.keySet()))), 
                contractsAddressUpdated);
            // System.debug(LoggingLevel.DEBUG, 'contractsWithProject: ' + JSON.serialize(contractsWithProject));
            for(Contract__c contract : newList) {
                if(contractsAddressUpdated.containsKey(contract.Id)) {
                    if(contractsWithProject.containsKey(contract.Id)) {
                        contract.Project__c = contractsWithProject.get(contract.Id).Project__c;
                    } else {
                        contract.Project__c = null;
                    }
                }
            }
        }
        return newList;
    }
    
    /**
* @description      To be used in customer contract trigger (on record creation) and contract trigger (on certain field update)
* @author Yi Zhang | 30/09/2020 
* @param customerContractList   Should contain Id, Customer__c, Contract__c fields
* @param contractsWithUpdatedAddress   Contains updated contracts when called by contract trigger (it's before update)
* @return Map<Id, Contract__c> 
**/
    public static Map<Id, Contract__c> populateContractsProjects(List<Customer_Contract__c> customerContractList, Map<Id, Contract__c> contractsWithUpdatedAddress) {
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        if(customerContractList.isEmpty()) {
            return contractsMap;
        }
        // find the contracts
        List<Id> contractIds = new List<Id>();
        List<Id> accountIds = new List<Id>();
        for(Customer_Contract__c cc : customerContractList) {
            contractIds.add(cc.Contract__c);
            accountIds.add(cc.Customer__c);
        }
        
        // query metadata
        Map<String, String> matchingFieldsMap = new Map<String, String>();  // key is the contract field, val is the project field
        for(Project_Contract_Matching_Field__mdt cpmf : DM_ProjectContractMatchingField.matchingFields) {
            matchingFieldsMap.put(cpmf.Source_Field__r.QualifiedApiName, 'Project__r.' + cpmf.Destination_Field__r.QualifiedApiName);
        }
        if(matchingFieldsMap.isEmpty()) {
            return contractsMap;
        }
        
        // query contracts
        String contractQuery = 'SELECT Id, ' + String.join(new List<String>(matchingFieldsMap.keySet()), ', ') + ', '
            + ' (SELECT Id, Customer__c FROM Customer_Contracts__r) '
            + ' FROM Contract__c '
            + ' WHERE Id IN :contractIds ';
        // if contractsWithUpdatedAddress is empty, make sure Price Estimate is false and address populated
        // if contractsWithUpdatedAddress is not empty, no need to check as it's called in Contract's beforeUpdate
        if(contractsWithUpdatedAddress.isEmpty()) {
            contractQuery+= ' AND Price_Estimate__c = false ';
            for(String field : matchingFieldsMap.keySet()) {
                contractQuery += ' AND ' + field + ' != null';
            }
        }
        List<Contract__c> contracts = Database.query(contractQuery);
        // System.debug(LoggingLevel.DEBUG, contractQuery);
        // System.debug(LoggingLevel.DEBUG, JSON.serialize(contracts));
        if(contracts.isEmpty()) {
            return contractsMap;
        }

        //Added for SFSUP-302 - Person Account Changes
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;

        // query account - project participant - project
        String accountQuery = 'SELECT Id, ' 
            + '(SELECT Id, Project__c, ' + String.join(matchingFieldsMap.values(), ',') + ' FROM Project_Groups__r) '
            + 'FROM Account '
            + 'WHERE Id IN :accountIds AND RecordTypeId != :personAccRecordTypeId';
        List<Account> accounts = Database.query(accountQuery);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);
        // System.debug(LoggingLevel.DEBUG, accountQuery);
        // System.debug(LoggingLevel.DEBUG, JSON.serialize(accountsMap));
        
        // accounts: contains project partipants (Project_Groups__r)
        // contracts: contains customer contracts (Customer_Contracts__r)
        // Logic:
        // for each contract, loop through the customer contract, find the account, loop through project participant
        // if the contract's field(s) are exact match to project participant's project field(s), set contract's project
        for(Contract__c contract : contracts) {
            if(contract.Customer_Contracts__r.isEmpty() == false) {
                for(Customer_Contract__c cc : contract.Customer_Contracts__r) {
                    if(accountsMap.containsKey(cc.Customer__c) && accountsMap.get(cc.Customer__c).Project_Groups__r.isEmpty() == false) {
                        for(Project_Participant__c pp : accountsMap.get(cc.Customer__c).Project_Groups__r) {
                            Boolean exactMatch = true;
                            // in case contractsWithUpdatedAddress is not empty, use it for comparison
                            Contract__c contractToCompare = contractsWithUpdatedAddress.containsKey(contract.Id) ? contractsWithUpdatedAddress.get(contract.Id) : contract;
                            
                            for(String contractField : matchingFieldsMap.keySet()) {
                                String projectField = matchingFieldsMap.get(contractField);
                                projectField = projectField.replace('Project__r.', '');
                                
                                if(contractToCompare.get(contractField) != pp.Project__r.get(projectField)) {
                                    exactMatch = false;
                                    System.debug('Went wrong here: ' + contractToCompare.get(contractField) + '!=' + pp.Project__r.get(projectField));
                                }
                            }
                            if(exactMatch == true) {
                                contractsMap.put(contract.Id, new Contract__c(Id = contract.Id, Project__c = pp.Project__c));
                            }
                        }
                    }
                }
            }
        }
        // System.debug(LoggingLevel.DEBUG, 'contractsMap' + JSON.serialize(contractsMap));
        return contractsMap;
    }
    
    /**
* @description      If Price_Estimate__c is false AND all fields are NOT null
* @author Yi Zhang | 30/09/2020 
* @param contract 
* @param contractFields 
* @return Boolean 
**/
    private static Boolean isValidToMatchProject(Contract__c contract, List<String> contractFields) {
        if(contract.Price_Estimate__c == true) {
            return false;
        }
        for(String field : contractFields) {
            if(contract.get(field) == null) {
                return false;
            }
        }
        return true;
    }
    
    /**
* @description 
* @author John Paul Peñaflor | 08-18-2020 
* @param map<Id Contract__c> oldMap 
* @param list<Contract__c> newList 
**/
    public static void checkProjectUpdate(map<Id,Contract__c> oldMap, list<Contract__c> newList){
        Map<String,Contract__c> projectRemovedContractMap = new Map<String,Contract__c>();
        Map<String,Contract__c> projectAddedContractMap = new Map<String,Contract__c>();
        System.debug(oldMap);
        System.debug(newList);
        for(Contract__c contract : newList){
            if(contract.Project__c == null & oldMap.get(contract.Id).Project__c != null){
                projectRemovedContractMap.put(contract.Id, oldMap.get(contract.Id));
            }
            else if(oldMap.get(contract.Id).Project__c == null && contract.Project__c != null){
                projectAddedContractMap.put(contract.Id, contract);
            }
            else if(oldMap.get(contract.Id).Project__c != null && contract.Project__c != null && oldMap.get(contract.Id).Project__c != contract.Project__c){
                projectRemovedContractMap.put(contract.Id, oldMap.get(contract.Id));
                projectAddedContractMap.put(contract.Id, contract);
            }
        }
        
        if(!projectRemovedContractMap.isEmpty()){
            deassociateProjectParticipants(projectRemovedContractMap);
        }
        
        if(!projectAddedContractMap.isEmpty()){
            associateProjectParticipants(projectAddedContractMap);
        }
    }
    
/**
* @description 
* @author John Paul Peñaflor | 08-18-2020 
* @param Map<String Contract__c> contractMap 
**/
    public static void deassociateProjectParticipants(Map<String, Contract__c> contractMap){
        List<Project_Participant__c> projParticipantList = DM_ProjectParticipant.getProjectParticipants(contractMap.keySet());
        
        if(projParticipantList.isEmpty()){
            return;
        }
        
        for(Project_Participant__c projectParticipant : projParticipantList){
            if(projectParticipant.Project__c == contractMap.get(projectParticipant.Contract__c).Project__c){
                projectParticipant.Status__c = SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_NOT_ON_CONTRACT;
                projectParticipant.Contract__c = null;
            }
        }
        
        try {
            update projParticipantList;
        } catch (Exception e) {
            ApplicationLogger.log('deassociateProjectParticipants', 'Project_Participant__c', 'Trigger', e);
        }
        
    }
    
    /**
* @description 
* @author John Paul Peñaflor | 08-18-2020 
* @param Map<String Contract__c> contractMap 
**/
    public static void associateProjectParticipants(Map<String, Contract__c> contractMap){
        Map<Id, Customer_Contract__c> customerContractMap = new Map<Id, Customer_Contract__c>(DM_CustomerContract.getCustomerContracts(contractMap.keySet()));
        
        if(customerContractMap.isEmpty()){
            return;
        }
        
        try {
            CustomerContractTriggerHandler.updateProjectParticipants(customerContractMap, 'Insert');
        } catch (Exception e) {
            ApplicationLogger.log('associateProjectParticipants', 'Contract__c', 'Trigger', e);
        }
        
    }
    
    
    /**
* @description Check for updates in Contract Number
* @author John Paul Peñaflor | 08-17-2020 
* @param map<Id Contract__c> oldMap 
* @param list<Contract__c> newList 
**/
    public static void checkUpdatedContractNumber(map<Id,Contract__c> oldMap, list<Contract__c> newList){
        
        Set<String> contractIds = new Set<String>();
        
        for(Contract__c contractRec : newList){
            Contract__c oldContract = oldMap.get(contractRec.Id);
            if(contractRec.Name != oldContract.Name){
                contractIds.add(contractRec.Id);
            }
        }
        
        if(!contractIds.isEmpty()){
            updateProjectParticipantStatus(contractIds);
        }
    }
    
    /**
* @description Process list of Changed Contract Numbers to updated related Project Participants
* @author John Paul Peñaflor | 08-17-2020 
* @param Set<String> contractIds 
**/
    public static void updateProjectParticipantStatus(Set<String> contractIds){
        List<Project_Participant__c> projectParticipantList = DM_ProjectParticipant.getProjectParticipants(contractIds);
        
        if(projectParticipantList.isEmpty()){
            return;
        }
        
        List<Project_Participant__c> projectParticipantForUpdate = new List<Project_Participant__c>();
        
        for(Project_Participant__c projectParticipant : projectParticipantList){
            if(projectParticipant.Status__c == PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT){
                projectParticipant.Status__c = PROJECTPARTICIPANT_STATUS_REQUEST_CONTRACT_CHANGE;
            }
            else{
                projectParticipant.Status__c = PROJECTPARTICIPANT_STATUS_REQUEST_CONTRACT_ADDITION;
            }
            
            projectParticipantForUpdate.add(projectParticipant);
        }
        
        if(!projectParticipantForUpdate.isEmpty()){
            try {
                update projectParticipantForUpdate;
            } catch (Exception e) {
                ApplicationLogger.log('updateProjectParticipantStatus', 'Project_Participant__c', 'Trigger', e);
            }
        }
    }
    
    /**
* @description 
* @author Philip Clark | 1/7/2020 
* @param oldMap
* @param contractList
* @param boolean fromContract
* @return list<Contract__c>
**/
    public static list<Contract__c> setReviewersApprovers(map<Id,Contract__c> oldMap, list<Contract__c> contractList, boolean fromContract) {
        // system.debug('[SM_Contract.setReviewersApprovers] entering method');
        list<Contract__c> retContractList = new list<Contract__c>();
        try {
            map<Id,User> activeUserMap = DM_User.getActiveUsers();
            for (Contract__c c : contractList) {
                if (c.Status__c!=Constants.CONTRACT_STATUS_EXPIRED) {
                    if (fromContract) {
                        if (c.Original_Approver__c!=null && (oldMap==null || oldMap.get(c.Id).Original_Approver__c != c.Original_Approver__c))
                            c.Approver__c = findUltimateDelegate(c.Original_Approver__c,activeUserMap);
                        if (c.Original_Reviewer__c!=null && (oldMap==null || oldMap.get(c.Id).Original_Reviewer__c != c.Original_Reviewer__c))
                            c.Reviewer__c = findUltimateDelegate(c.Original_Reviewer__c,activeUserMap);
                        retContractList.add(c);
                    } else {
                        Id approverId = c.Approver__c;
                        Id reviewerId = c.Reviewer__c;
                        if (c.Status__c!=Constants.CONTRACT_STATUS_EXPIRED) {
                            if (c.Approver__c!=null && (oldMap==null || oldMap.get(c.Id).Approver__c != c.Approver__c))
                                approverId = findUltimateDelegate(c.Approver__c,activeUserMap);
                            if (c.Reviewer__c!=null && (oldMap==null || oldMap.get(c.Id).Reviewer__c != c.Reviewer__c))
                                reviewerId = findUltimateDelegate(c.Reviewer__c,activeUserMap);
                        }
                        if (approverId != c.Approver__c || reviewerId != c.Reviewer__c) {
                            c.Approver__c = approverId; 
                            c.Reviewer__c = reviewerId;
                            retContractList.add(c);
                        }
                    }
                }
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.setReviewersApprovers', 'Contract__c', 'trigger', e);
        }
        return retContractList;
    }
    
    
    /**
* @description 
* @author Philip Clark | 1/7/2020 
* @param Id
* @param map<Id,User>
* @return Id
**/
    public static Id findUltimateDelegate(Id userId, map<Id,User> activeUserMap) {
        // system.debug('[SM_Contract.findUltimateDelegate] entering method');
        Id delegateUserId = userId;
        try {
            boolean isTopDelegate = FALSE;
            // cycle through chain of delegates and check if present and active user
            while (!isTopDelegate) {
                if (activeUserMap.get(delegateUserId).DelegatedApproverId!=null
                    && activeUserMap.containsKey(activeUserMap.get(delegateUserId).DelegatedApproverId)) {
                        delegateUserId = activeUserMap.get(delegateUserId).DelegatedApproverId;
                    } else {
                        isTopDelegate = TRUE;
                    }
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.findUltimateDelegate', 'Contract__c', 'trigger', e);
        }
        return delegateUserId;
    }
    
    
    /**
* @description 
* @author Philip Clark | 1/7/2020 
* @param set<Id>
**/
    public static void resetReviewersApprovers(set<Id> userIdSet) {
        // system.debug('[SM_Contract.resetReviewersApprovers] entering method');
        try {
            map<Id,Contract__c> updateContractMap = new map<Id,Contract__c>();
            for (Contract__c c : DM_Contract.getContractsbyOrigReviewerApprover(userIdSet)) {
                if (c.Status__c!=Constants.CONTRACT_STATUS_EXPIRED) {
                    if (userIdSet.contains(c.Original_Approver__c) && c.Approver__c!=c.Original_Approver__c) {
                        c.Approver__c = c.Original_Approver__c;
                        updateContractMap.put(c.Id,c);
                    }
                    if (userIdSet.contains(c.Original_Reviewer__c) && c.Reviewer__c!=c.Original_Reviewer__c) {
                        c.Reviewer__c = c.Original_Reviewer__c;
                        updateContractMap.put(c.Id,c);
                    }
                }
            }
            if (!updateContractMap.isEmpty()) {
                String contractListJson = JSON.serialize(updateContractMap.values());
                updateContractsAsync(contractListJson);
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_Contract.resetReviewersApprovers', 'Contract__c', 'trigger', e);
        }
    }
    
    /**
    * @description : Populate the previous approver and reviewer field
    * @param : oldMap, newList
    **/
    public static void getPreviousContractData(map<Id,Contract__c> oldMap, list<Contract__c> newList) {
        
        String approverAction, reviewerAction;
        Map<Id,Id> approverIdMap = new Map<Id,Id>();
        Map<Id,String> approverContractMap = new Map<Id,String>();
        Map<Id,Id> reviewerIdMap = new Map<Id,Id>();
        Map<Id,String> reviewerContractMap = new Map<Id,String>();
        
        for(Contract__c oldCont : oldMap.values()) {
            approverIdMap.put(oldCont.Approver__c, oldCont.Id);
            reviewerIdMap.put(oldCont.Reviewer__c, oldCont.Id);
        }
        System.debug('approverIdMap '+approverIdMap);
        System.debug('reviewerIdMap '+reviewerIdMap);
        
        List<User> users = [Select Id, Name From User where Id =: approverIdMap.KeySet()];
        System.debug('users '+users);
        for(User u : users) {
            if(approverIdMap.containsKey(u.Id)) {
                Id contractId = approverIdMap.get(u.Id);
                approverContractMap.put(u.Id, u.Name);
            }
        }
        
        List<User> usersL = [Select Id, Name From User where Id =: reviewerIdMap.KeySet()];
        System.debug('usersL* '+usersL);
        for(User u : usersL) {
            if(reviewerIdMap.containsKey(u.Id)) {
                Id contractId = reviewerIdMap.get(u.Id);
                reviewerContractMap.put(u.Id, u.Name);
            }
        }
        User runningUser = DM_User.getUser(UserInfo.getUserId());
        System.debug('runningUser '+runningUser);
        System.debug('approverContractMap>> '+approverContractMap);
        System.debug('reviewerContractMap>> '+reviewerContractMap);
        
        for(Contract__c contractRec : newList){
            Contract__c oldContract = oldMap.get(contractRec.Id);
            if(oldContract.Approver_Action__c == 'A') {
                approverAction = 'Approved';
            } else if(oldContract.Approver_Action__c == 'R') {
                approverAction = 'Rejected';
            }
            if(oldContract.Reviewer_Action__c == 'A') {
                reviewerAction = 'Approved';
            } else if(oldContract.Reviewer_Action__c == 'R') {
                reviewerAction = 'Rejected';
            }
            
            if(runningUser.Id == contractRec.Reviewer__c) {//If Reviewer made the Changes
                System.debug('Inside If');
                if(contractRec.Reviewer_Comments__c != oldContract.Reviewer_Comments__c ){
                  //   || contractRec.Reviewer_Action__c != oldContract.Reviewer_Action__c || contractRec.Reviewer_Action_Date__c != oldContract.Reviewer_Action_Date__c || contractRec.Reviewer__c != oldContract.Reviewer__c) {
                contractRec.Previous_Approver_Record__c = oldContract.Approver_Action_Date__c+'.000Z' + '@'+  approverContractMap.get(oldContract.Approver__c) + '@'+  approverAction + '@'+  oldContract.Approver_Comments__c;
                System.debug(' oldContract.Approver_Comments__c** '+ oldContract.Approver_Comments__c);
                
                contractRec.Previous_Reviewer_Record__c = oldContract.Reviewer_Action_Date__c+'.000Z' + '@'+  reviewerContractMap.get(oldContract.Reviewer__c) + '@'+ reviewerAction + '@'+  oldContract.Reviewer_Comments__c;
                System.debug(' oldContract.Reviewer_Comments__c** '+ oldContract.Reviewer_Comments__c);
                
                contractRec.Approver_Comments__c = null;
                contractRec.Approver_Action__c = null;
                contractRec.Approver_Action_Date__c = null;
                    }
            }
            else if(contractRec.Reviewer_Comments__c != oldContract.Reviewer_Comments__c && oldContract.Reviewer_Comments__c != null) {
                contractRec.Previous_Reviewer_Record__c = oldContract.Reviewer_Action_Date__c+'.000Z' + '@'+  reviewerContractMap.get(oldContract.Reviewer__c) + '@'+ 
                    + reviewerAction + '@'+  oldContract.Reviewer_Comments__c;
                System.debug(' Else .Reviewer_Comments__c** '+ oldContract.Reviewer_Comments__c);
            }
            else if(contractRec.Approver_Comments__c != oldContract.Approver_Comments__c && oldContract.Approver_Comments__c != null) {
                contractRec.Previous_Approver_Record__c = oldContract.Approver_Action_Date__c+'.000Z' + '@'+ approverContractMap.get(oldContract.Approver__c) + '@'
                    + approverAction + '@' + oldContract.Approver_Comments__c;
                System.debug(' Else.Approver_Comments__c** '+ oldContract.Approver_Comments__c+' '+(datetime)oldContract.Approver_Action_Date__c);
            }
            
            System.debug('contractRec.Previous_Approver_Record__c '+contractRec.Previous_Approver_Record__c);
            System.debug('contractRec.Previous_Reviewer_Record__c '+contractRec.Previous_Reviewer_Record__c);
        }
    }
    /**
* @description 
* @author 	Philip Clark | 1/07/2020 
* @param 	String
**/
    @future
    public static void updateContractsAsync (String contractListJson) {
        // system.debug('[SM_Contract.updateContractsAsync] entering method');
        List<Contract__c> contractList = (List<Contract__c>) JSON.deserialize(contractListJson, List<Contract__c>.class);
        upsert contractList;
    }

    // BUNDIG-17527 - Start
    // Block updates from Integration user
    private static void blockUpdate(Map<Id, Contract__c> oldMap, List<Contract__c> newList) {
        Map<Id, Contract__c> newMap = new Map<Id, Contract__c>(newList);

        String integrationUserId = Config.Integration_User_Id__c;
                
        for (Contract__c newCon : newMap.values()) {
            Contract__c oldCon = oldMap.get(newCon.Id);
            System.debug('***Contract Approval Status: '+oldCon.Contract_Approval_Status__c + ' - ' + newCon.Contract_Approval_Status__c);                

            if (UserInfo.getUserId() == integrationUserId) {
                if ((oldCon.Contract_Approval_Status__c == CONTRACT_CUSTOMER_APPROVED || oldCon.Contract_Approval_Status__c == CONTRACT_CUSTOMER_REJECTED) && (oldCon.Contract_Approval_Status__c != newCon.Contract_Approval_Status__c)) {
                    newCon.Contract_Approval_Status__c = oldCon.Contract_Approval_Status__c;
                }            
                if (oldCon.Reviewer_Action__c != newCon.Reviewer_Action__c) {
                    newCon.Reviewer_Action__c = oldCon.Reviewer_Action__c;
                }
                if (oldCon.Approver_Action__c != newCon.Approver_Action__c) {
                    newCon.Approver_Action__c = oldCon.Approver_Action__c;
                }
                if (oldCon.Reviewer_Action_Date__c != newCon.Reviewer_Action_Date__c) {
                    newCon.Reviewer_Action_Date__c = oldCon.Reviewer_Action_Date__c;
                }
                if (oldCon.Approver_Action_Date__c != newCon.Approver_Action_Date__c) {
                    newCon.Approver_Action_Date__c = oldCon.Approver_Action_Date__c;
                }
                if (oldCon.Reviewer_Comments__c != newCon.Reviewer_Comments__c) {
                    newCon.Reviewer_Comments__c = oldCon.Reviewer_Comments__c;
                }
                if (oldCon.Approver_Comments__c != newCon.Approver_Comments__c) {
                    newCon.Approver_Comments__c = oldCon.Approver_Comments__c;
                }
            }            
        }            
    }

    private static SM_Configs__c config {
        get {
            if (config == null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    }
    // BUNDIG-17527 - End

    /**
    * @description 
    * @author Jasper R. Galapon | 19/06/2023 | BUNDIG-21197
    * @param List of Contract
    **/
    public static void createCase(Map<Id, Contract__c> oldMap, List<Contract__c> newList) {
        for (Contract__c con : newList) {
            Contract__c oldContract = oldMap.get(con.Id);
            if (oldContract.Status__c != con.Status__c) {
                if (con.Status__c == 'Rejected') {
                    SM_Case.createCase(con, con.Reviewer_Comments__c);
                }
            }
        }
    }
}