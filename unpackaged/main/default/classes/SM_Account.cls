/*******************************************************************************************************
* Class Name      	: SM_Account
* Description		: Domain / Service layer for Account
* Author          	: Simplus - Yi Zhang
* Created On      	: 12/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              	12/08/2020		1000				Initial version
* Simplus MS - RLugpatan	23/08/2021 		2000				Modifications for CCRM15-109 (Assigned_Store__c = Store with Owner's Location_code__c)
******************************************************************************************************/
public class SM_Account {
    
    /**
    * @description 
    * @author Yi Zhang | 13/08/2020 
    * @param accountsToUpdate 
    **/
    public static void updateScheduledEngagementCall(Map<Id, Account> accountsToUpdate) {
        // query account's Scheduled Engagement Call (date) and compare with proposed new date
        // if new date is greater than existing SEC, update the account, otherwise don't
        if(accountsToUpdate.size() > 0) {
            Map<Id, Account> oldMap = DM_Account.getAccountsWithScheduledEngagementCall(accountsToUpdate.keySet());
            for(Id accountId : accountsToUpdate.keySet()) {
                if(oldMap.get(accountId).Scheduled_Engagement_Call__c >= accountsToUpdate.get(accountId).Scheduled_Engagement_Call__c) {
                    accountsToUpdate.remove(accountId);
                }
            }
        }
        if(accountsToUpdate.size() > 0) {
            update accountsToUpdate.values();
        }
    }
    
    /**
    * @description  Business logic before account insert and update to map Assigned Store for TS (Moved from AccountTriggerHandler)
    * @author       Francis Benzon| 29/06/2020 
    * @param assignedStoreAcctList 
    * @param acctID_ownerIDMap 
    * @return Map<ID, ID> 
    **/
    public static Map<ID,ID> mapAssignedStore(List<Account> assignedStoreAcctList, Map<ID, ID> acctID_ownerIDMap) {
		
        //Map<ID, String> userID_locNameMap = new Map<ID, String>(); //commented for CCRM15-109 
        Map<ID, String> userID_locCodeMap = new Map<ID, String>();
        //Map<String, ID> locName_strIDMap = new Map<String, ID>(); //commented for CCRM15-109 
        Map<String, ID> locCode_strIDMap = new Map<String, ID>();
        Map<ID,ID> acctID_storeIDMap = new Map<ID, ID>();
        
        
        //loop on query of Users where ID in Map.values (acct.ownerIDs)
        for(User us : [SELECT ID, Location_Code__c, Location_Name__c FROM USER WHERE ID IN :acctID_ownerIDMap.values()]) {
            /** CCRM15-109
            if(us.Location_Name__c != null)
                userID_locNameMap.put(us.ID, us.Location_Name__c);
			**/
            //The assigned store needs to be based on the location code from the User as location code will always be unique
            if(us.Location_Code__c != null)
                userID_locCodeMap.put(us.ID, us.Location_Code__c);
        }
        
        //Simplus.MS 23/08/2021 - Removed any logic related to Location_Name__c for CCRM15-109
        //if(!userID_locNameMap.isEmpty() || !userID_locCodeMap.isEmpty()) {
        if(!userID_locCodeMap.isEmpty()) {
            for(Store__c str : [SELECT ID, Name, Location_Code__c FROM Store__c 
                                WHERE Location_Code__c IN :userID_locCodeMap.values()]) {
                /** CCRM15-109
                if(str.Name != null)
                    locName_strIDMap.put(str.Name, str.ID); 
				**/
                if(str.Location_Code__c != null)
                    locCode_strIDMap.put(str.Location_Code__c, str.ID);
            }
            
            for(Account acct : assignedStoreAcctList) {
                /** CCRM15-109
                if(userID_locNameMap.containsKey(acct.OwnerID) && 
                   locName_strIDMap.containsKey(userID_locNameMap.get(acct.OwnerID))) 
                {   
                    
                    if(locName_strIDMap.get(userID_locNameMap.get(acct.OwnerID)) != null){
                        acct.Assigned_Store__c = locName_strIDMap.get(userID_locNameMap.get(acct.OwnerID));
                        acctID_storeIDMap.put(acct.ID, acct.Assigned_Store__c);
                    }                                             
                    
                }
                **/
                if(userID_locCodeMap.containsKey(acct.OwnerID) && locCode_strIDMap.containsKey(userID_locCodeMap.get(acct.OwnerID))) { 
                    if(locCode_strIDMap.get(userID_locCodeMap.get(acct.OwnerID)) != null) {
                        acct.Assigned_Store__c = locCode_strIDMap.get(userID_locCodeMap.get(acct.OwnerID));
                        acctID_storeIDMap.put(acct.ID, acct.Assigned_Store__c);
                    }                                                          
                }
            }                        
        }
        
        if(!acctID_storeIDMap.isEmpty()) {
            return acctID_storeIDMap;
        }else {
            return acctID_storeIDMap = new Map<ID, ID>();
        }        
    }

    /**
    * @description      To be used by User trigger or any method requires a different context/transaction
    * @author Yi Zhang | 21/08/2020 
    * @param accountListJson 
    **/
    @future
    public static void updateAccountList (String accountListJson) {
        List<Account> accounts = (List<Account>) JSON.deserialize(accountListJson, List<Account>.class);
        try {
            update accounts;
        } catch(Exception e) {
            ApplicationLogger.log('SM_Account.updateAccountList', 'Account', 'Trigger', e);
        }    
    }

    /**
     * @description upsertAccountList Upsert AccountList
     * @author Juan M. Cutrera
     * @param  accountList accountList description
     */
    public static void upsertAccountList(List<Account> accountList){
        try {
            Database.upsert(accountList, true);
        } catch (Exception e) {
            throw new SM_AccountException('Accounts could not be created or updated: ' + e.getMessage() ); 
        }
    }
    
    /**
    * @description  createNewAccount - Build a new PersonAccount
    * @author Juan M.Cutrera | 02/04/2025
    * @param currentEntity
    * @return Account
    **/
    public static Account buildNewAccount(Consent_ConsentManagerPayload.Entity currentEntity){
            SM_PersonBuilder personAccountBuilder = new SM_PersonBuilder();
            
            //Check that Person is not null
            if(currentEntity.getPerson()!= null){
                Consent_ConsentManagerPayload.Person currentPerson = currentEntity.getPerson();
                //Use the First and last name if they're not null ELSE use the FullName
                if(String.isNotBlank(currentPerson.getFirstName()) && String.isNotBlank(currentPerson.getLastName())){
                    personAccountBuilder.setFirstName(currentPerson.getFirstName());
                    personAccountBuilder.setLastName(currentPerson.getLastName());
                }else if(String.isNotBlank(currentPerson.getFullName())){
                    personAccountBuilder.setLastName(currentPerson.getFullName());
                }
                personAccountBuilder.setAccountOwner(UserInfo.getUserId());
                personAccountBuilder.setEmail(currentPerson.getContactPoint('Email')?.getEmail());
                //Check if its mobile or not
                if(currentPerson.getContactPoint('Phone')?.getPhone() != null){
                    if(currentPerson.getContactPoint('Phone').getPhone().isMobile()){
                        personAccountBuilder.setPersonMobilePhone(currentPerson.getContactPoint('Phone').getPhone().getPhoneNumber());
                    }else{
                        // personAccountBuilder.setPersonOtherPhone(currentPerson.getContactPoint('Phone').getPhone().getPhoneNumber());
                    }
                }
                
                //Address section
                Consent_ConsentManagerPayload.Address currentMailingAddress = currentPerson.getContactPoint('Mailing Address')?.getAddress();
                if(currentMailingAddress != null){
                    personAccountBuilder.setAccountState(currentMailingAddress.getStateCode());
                    personAccountBuilder.setMailingAddress(currentMailingAddress.getStreetAddress(),
                                                           currentMailingAddress.getLocality(),
                                                           currentMailingAddress.getStateCode(),
                                                           currentMailingAddress.getPostCode(),
                                                           currentMailingAddress.getCountryCode()
                                                          );
                    //TODO Confirm if its the same or its going to be different?
                    personAccountBuilder.setBillingAddress(currentMailingAddress.getStreetAddress(),
                                                           currentMailingAddress.getLocality(),
                                                           currentMailingAddress.getStateCode(),
                                                           currentMailingAddress.getPostCode(),
                                                           currentMailingAddress.getCountryCode()
                                                          );
                }
                
                //Capture Section
                Consent_ConsentManagerPayload.Capture currentCapture = currentEntity.getCapture();
                if(currentCapture != null){
                    personAccountBuilder.setSourceSystem(currentCapture.getSource());
                    personAccountBuilder.setSourceSystemModule(currentCapture.getSourceModule());
                }
                
            }
            return personAccountBuilder.build();
        }


    private class SM_AccountException extends Exception {}    
}