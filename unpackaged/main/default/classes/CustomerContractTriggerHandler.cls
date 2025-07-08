/*******************************************************************************************************
* Class Name      	: CustomerContractTriggerHandler
* Description		: Customer Contract Trigger Handler
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 17/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    17/08/2020		1000				Initial version
* Yi Zhang              30/09/2020		2000				Added associateContractsWithProjects
* Simplus MS            02/07/2021      3000                Added updateChildAccCustomerContract for CCRM-13792
* Bunnings Dev          07/03/2022      4000                SFSUP-373 - new method added to replace PB Customer Contract Update Actions
* Simplus MS            13/04/2022      5000                Added to avoid trigger recursion for SFSUP-379
* Bunnings Dev          07/02/2023      33000               BUNDIG-16248 - Stop Replication of Customer Contracts for Contract Group Associations
******************************************************************************************************/
public class CustomerContractTriggerHandler {


    public static boolean runOnce = true;

    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020 
    * @param newMap 
    **/
    public static void afterInsert(Map<Id, Customer_Contract__c> newMap){
        try {
            updateProjectParticipants(newMap, 'Insert');
            associateContractsWithProjects(newMap.values());

            // Added for SFSUP-379 - To avoid trigger recursion
            if(runOnce) {
                runOnce = false;
                // updateChildAccCustomerContract(null, newMap.values()); //Added for CCRM-13792 - BUNDIG-16248 - Commented out
            }

            checkAccountContracts(newMap.values());
        } catch (Exception e) {
            ApplicationLogger.log('beforeInsert', 'Customer_Contract__c', 'Trigger', e); 
        }
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020 
    * @param Map<Id Customer_Contract__c> contractMap 
    **/
    public static void beforeDelete(Map<Id, Customer_Contract__c> customerContractMap){
        try {
            updateProjectParticipants(customerContractMap, 'Delete');
        } catch (Exception e) {
            ApplicationLogger.log('beforeDelete', 'Customer_Contract__c', 'Trigger', e); 
        }
    }

       /**
    * @description After update event
    * @author Bunnings Dev | 07/03/2022 
    * @param newMap
    **/
    public static void afterUpdate(Map<Id, Customer_Contract__c> oldMap, Map<Id, Customer_Contract__c> newMap) {
        try {
            checkAccountContracts(newMap.values());
        } catch (Exception e) {
            ApplicationLogger.log('afterUpdate', 'Customer_Contract__c', 'Trigger', e);
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 30/09/2020 
    * @param newList 
    **/
    public static void associateContractsWithProjects(List<Customer_Contract__c> newList) {
        Map<Id, Contract__c> contractsMap = SM_Contract.populateContractsProjects(newList, new Map<Id, Contract__c>());
        if(contractsMap.isEmpty() == false) {
                update contractsMap.values();
        }
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020 
    * @param Map<Id Customer_Contract__c> customerContractMap 
    * @param String dmlAction 
    **/
    public static void updateProjectParticipants(Map<Id, Customer_Contract__c> customerContractMap, String dmlAction){
        Set<String> contractIds = new Set<String>();
        Set<String> accountIds = new Set<String>();
        
        for(Customer_Contract__c customerContract : customerContractMap.values()){
            contractIds.add(customerContract.Contract__c);
            accountIds.add(customerContract.Customer__c);
        }
        
        if(contractIds.isEmpty() || accountIds.isEmpty()){
            return;
        }
        
        Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>(DM_Contract.getContracts(new List<String>(contractIds)));
        
        Set<String> projectIds = new Set<String>();

        for(Contract__c contract : contractMap.values()){
            if(contract.Project__c != null){
                projectIds.add(contract.Project__c);
            }
        }

        if(projectIds.isEmpty()){
            return;
        }

        Map<Id, Project_Participant__c> projParticipantMap = new Map<Id, Project_Participant__c>(DM_ProjectParticipant.getProjectParticipants(projectIds, accountIds));
       
        List<Project_Participant__c> projParticipantToUpsert = new List<Project_Participant__c>();
        
        for(Customer_Contract__c customerContract : customerContractMap.values()){
            if(contractMap.get(customerContract.Contract__c).Project__c != null){
                Boolean isParticipantFound = false;
                for(Project_Participant__c projectParticipant : projParticipantMap.values()){
                    
                    if(customerContract.Customer__c == projectParticipant.Account__c && contractMap.get(customerContract.Contract__c).Project__c == projectParticipant.Project__c){
                        if(dmlAction == 'Insert'){
                            if(projectParticipant.Contract__c == null){
                                projectParticipant.Status__c = SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT;
                                projectParticipant.Contract__c = customerContract.Contract__c;
                                isParticipantFound = true;
                            }
                            else if(projectParticipant.Contract__c == customerContract.Contract__c){
                                projectParticipant.Status__c = SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT;
                                isParticipantFound = true;
                            }
                            
                        }
                        else if(dmlAction == 'Delete'){
                            if(projectParticipant.Contract__c == customerContract.Contract__c){
                                projectParticipant.Status__c = SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_NOT_ON_CONTRACT;
                                projectParticipant.Contract__c = null;
                                isParticipantFound = true;
                            }
                        }
                        
                        projParticipantToUpsert.add(projectParticipant);
                    }
                    
                }

                if(!isParticipantFound){
                    Project_Participant__c newProjectParticipant = new Project_Participant__c();
                    newProjectParticipant.Project__c = contractMap.get(customerContract.Contract__c).Project__c;
                    newProjectParticipant.Contract__c = customerContract.Contract__c;
                    newProjectParticipant.Account__c = customerContract.Customer__c;
                    newProjectParticipant.Status__c = SM_Contract.PROJECTPARTICIPANT_STATUS_ACTIVE_ON_CONTRACT;

                    projParticipantToUpsert.add(newProjectParticipant);
                }
            }
            
        }

        if(!projParticipantToUpsert.isEmpty()){
            try {
                upsert projParticipantToUpsert;
            } catch (Exception e) {
                ApplicationLogger.log('updateProjectParticipantStatus', 'Customer_Contract__c', 'Trigger', e);
            }
        }
    }

    /**
    * @description CCRM-13792: Any updates to the master account customer contract are 
    *                           also updated on the child account customer contract.
    * @author Simplus MS | 02/07/2021
    * @param oldMap 
    * @param newList 
    * @modification BUNDIG-16248 - Commented out
    **/
    // public static void updateChildAccCustomerContract(Map<Id,Customer_Contract__c> oldMap, List<Customer_Contract__c> newList) {
        
    //     Map<Id,List<Customer_Contract__c>> acctIds = new Map<Id,List<Customer_Contract__c>>(); //FOR UPDATE: oldMap GROUPED BY ACCOUNT || FOR INSERT: SET OF PARENT ACCOUNTS
    //     List<Customer_Contract__c> lstCC = new List<Customer_Contract__c>(); //CC FOR UPDATE OR INSERT

    //     if (oldMap == null || oldMap.isEmpty()) { //FOR NEW CPLs

    //         Set<Id> custContractIds =  new Set<Id>();
    //         for (Customer_Contract__c row : newList) {
    //                 custContractIds.add(row.Id);
    //                 acctIds.put(row.Customer__c, null);
    //         }
            
    //         List<Customer_Contract__c> custContractList = retrieveNewCustContracts(custContractIds);            
    //         System.debug('custContractList '+custContractList);
            
    //         //CCRM15-493: map to correctly seggregate customer contracts per account - start
    //         Map<Id, Customer_Contract__c[]> cgCustToccMap = new Map<Id, Customer_Contract__c[]>();
    //         for (Customer_Contract__c rowCC : custContractList) {
    //             Customer_Contract__c[] ccList = cgCustToccMap.containsKey(rowCC.Customer__c) ? 
    //                 cgCustToccMap.get(rowCC.Customer__c) : new List<Customer_Contract__c>();
                
    //             ccList.add(rowCC);
    //             cgCustToccMap.put(rowCC.Customer__c, ccList);
    //         }
    //         //CCRM15-493: map to correctly seggregate customer contracts per account - ends
            
    //         if (custContractList.size() > 0) {
	// 				for (Account rowAcct : retrieveChildAccounts(new List<Id>(acctIds.keySet()))) {
    //                     System.debug('rowAcct '+rowAcct);
    //                     /*CCRM15-493: this is a flawed logic hence being commented
	// 					for (Customer_Contract__c rowCC : custContractList) {
    //                         Customer_Contract__c custContractClone = rowCC.clone(false, false, false, false);
    //                         custContractClone.Customer_Contract_ID__c = '';
    //                         custContractClone.Customer__c = rowAcct.Id;
    //                         lstCC.add(custContractClone);
    //                     }*/
                        
    //                     //CCRM15-493: corrected logic - that only CCs from parent contract group should be 
    //                     //cloned/copied to related to related account
    //                     Id cgKey = rowAcct.Contract_Group__c;
    //                     Customer_Contract__c[] ccList = cgCustToccMap.containsKey(cgKey) ? 
    //                         cgCustToccMap.get(cgKey) : new List<Customer_Contract__c>();
                        
    //                     for (Customer_Contract__c rowCC : ccList) {
    //                         Customer_Contract__c custContractClone = rowCC.clone(false, false, false, false);
    //                         custContractClone.Customer_Contract_ID__c = '';
    //                         custContractClone.Customer__c = rowAcct.Id;
    //                         lstCC.add(custContractClone);                            
    //                     }
    //                     //CCRM15-493: corrected logic - ends
    //             }
    //         }
    //         System.debug('lstCC '+lstCC);
    //         if(lstCC.size() > 0) {
    //             try {
    //                     Insert lstCC;       
    //             } catch(Exception e) {
    //                     ApplicationLogger.log('CustomerContractTriggerHandler.updateChildAccCustomerContract', 'Customer_Contract__c', 'Trigger', e);
    //             }
    //         }
    //     }
    // }
    
    /**
    * @description Retrieves all child account
    * @author Simplus MS | 02/07/2021 
    * @param acctIds
    **/
    public static List<Account> retrieveChildAccounts(List<Id> acctIds) {
        //CCRM15-493: added Contract_Group__c
        return [SELECT Id, Contract_Group__c FROM Account WHERE Contract_Group__c IN : acctIds];
    }

    /**
    * @description Retrieves all new Customer Contract with Status and Start Date
    * @author Simplus MS | 06/07/2021 
    * @param acctIds
    **/
    public static List<Customer_Contract__c> retrieveNewCustContracts(Set<Id> custContractIds) {
        return [SELECT Customer__c, Contract__c, Contract__r.Status__c, Contract__r.Start_Date__c, Contract__r.End_Date__c 
                FROM Customer_Contract__c 
                WHERE Id IN : custContractIds 
                AND (Contract__r.Status__c = :Constants.CONTRACT_STATUS_ACTIVE OR Start_Date__c >= TODAY)];
    }

    /**
    * @description Update account On Contract to 'Yes' - Replacing process builder Customer Contract Update Actions
    * @author Bunnings Dev | SFSUP-373 | 07/03/2022
    * @param newList
    **/
    @testVisible
    private static void checkAccountContracts(List<Customer_Contract__c> newList) {
        Set<Id> acctIds = new Set<Id>();
        List<Account> accToUpdate = new List<Account>();

        if (newList.isEmpty()) {
            return;
        }

        for (Customer_Contract__c cc : newList) {
            if (cc.Customer__c != null && cc.Contract__c != null && cc.Contract__r.Status__c == Label.Active)
                accToUpdate.add(new Account(Id = cc.Customer__c, On_Contract__c = Label.Yes));   
        }

        System.debug('***accToUpdate: '+accToUpdate);
        if (!accToUpdate.isEmpty()) {
            try {
                UPDATE accToUpdate;
            } catch (Exception e) {
                ApplicationLogger.log('CustomerContractTriggerHandler.checkAccountContracts', 'Customer Contract', 'Trigger', e);
            } 
        }
    }
}