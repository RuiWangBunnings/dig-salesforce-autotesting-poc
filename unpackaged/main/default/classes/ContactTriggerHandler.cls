/**
*   =====================================================================================
*   Class Name          : ContactTriggerHandler
*   Description         : Contact trigger handler
*   Author              : Simplus - Haider Raza
*   Created On          : 15/04/2020
*   Modification Log    :
*   =====================================================================================
*   Developer       Date            Modification ID         Description
*   =====================================================================================
*   Haider Raza     15/04/2020     1000                    Initial version
*   Francis Benzon  15/06/2020     2000                    Update with beforeInsert and beforeUpdate
*	Rui Wang		20/09/2021	   3000					   CCRM15-83, 140 set Marketing flags
* 	Simplus MS 		05/11/2021	   4000					   Optimized updateAccountRecievingMarket method
*   Simplus MS		15/02/2022	   5000				       Added for SFSUP-302 - Person Account Changes
*   =====================================================================================
**/

public with sharing class ContactTriggerHandler {    
    /**
    *  Method name  :  beforeInsert
    *  Description  :  before insert logic here
    *  Author       :  Francis Benzon
    *  Parameter    :  List<Contact> allContacts                   
    **/
    public static void beforeInsert(List<Contact> lstNewContacts){
        for(Contact con : lstNewContacts) {
            if(con.FirstName != null) {
                con.FirstName = autoCapitalizeName(con.FirstName);
            }
            if(con.LastName != null) {
                con.LastName = autoCapitalizeName(con.LastName);
            }
        }
        
        //CCRM15-83
        setMarketingFlags('beforeInsert', lstNewContacts, null, null);
    }
    
    /**
    *  Method name  :  beforeUpdate
    *  Description  :  before update logic here
    *  Author       :  Francis Benzon
    *  Parameter    :  List<Contact> allContacts
    *                  Map<Id, Contact> mapNewContacts
    *                  List<Contact> lstOldContacts
    *                  Map<Id, Contact> mapOldContacts
    **/
    public static void beforeUpdate(List<Contact> lstNewContacts, Map<Id, Contact> mapNewContacts,
                               List<Contact> lstOldContacts, Map<Id, Contact> mapOldContacts)
    {
        for(Contact con : lstNewContacts) {
            if(con.FirstName != mapOldContacts.get(con.ID).FirstName) {
                con.FirstName = autoCapitalizeName(con.FirstName);
            }
            if(con.LastName != mapOldContacts.get(con.ID).LastName) {
                con.LastName = autoCapitalizeName(con.LastName);
            }
        }
        
        //CCRM15-83
        system.debug('beforeupdate');
        setMarketingFlags('beforeUpdate', lstNewContacts, mapNewContacts, mapOldContacts);
    }
        
    /**
    *  Method name  :  beforeDelete
    *  Description  :  before deletion
    *  Author       :  Haider Raza
    *  Parameter    :  List<Contact> allContacts
    *                  Map<Id, Contact> allContactsByIds
    **/
    public static void beforeDelete(List<Contact> allContacts, Map<Id, Contact> allContactsByIds, List<Contact> oldContacts){

        String profileName = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        if(!(profileName == 'System Administrator' || profileName == 'Integrations User') || Test.isRunningTest()){
            List<Contact> contactsNotToDelete = new List<Contact>([
                    SELECT Id, RecordType.DeveloperName
                    FROM Contact
                    WHERE Id IN:oldContacts
                    AND (RecordType.DeveloperName = 'AU_AR_Contact'
                    OR RecordType.DeveloperName = 'NZ_AR_Contact')
            ]);

            if (contactsNotToDelete.size() > 0) {
                ContactTriggerHandler.aviodDelete(contactsNotToDelete, allContactsByIds);
            }
        }

    }

    
    /**
    * @description 
    * @author Yi Zhang | 08/09/2020 
    * @param oldMap 
    **/
    public static void afterDelete(Map<Id, Contact> oldMap) {
        
        // prevent deletion by non system admin / integration user, but allows for merging 
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        User user = DM_User.getUser(UserInfo.getUserId());
        for(Contact contact : oldMap.values()){
            if(contact.MasterRecordId == null && !profileExemptions.contains(user.Profile.Name)){
                contact.addError('You do not have permission to delete Contacts. Please contact your system admin to delete this Contact.');
            }
        }
    }
    
    /**
    *  Method name  :  avoidDelete
    *  Description  :  Stop contacts from deletion
    *  Author       :  Haider Raza
    *  Parameter    :  List<Contact> allContacts
    *                  Map<Id, Contact> allContactsByIds
    **/
    public static void aviodDelete(List<Contact> allContacts, Map<Id, Contact> allContactsByIds){
        for(Contact item : allContacts){
            allContactsByIds.get(item.Id).addError(Label.ContactMergeMessage);
        }
    }
    
    //Auto Capitalize Name to have correct formatting
    public static String autoCapitalizeName(String name) {
        if(String.isBlank(name)) {
            return name;
        }
        String conName = name;
        List<String> nameGroup = conName.split(' '); 

        for(Integer i = 0; i < nameGroup.size(); i++) {
            if(nameGroup[i].contains('-')) {
                
                nameGroup[i] = nameGroup[i].substringBefore('-').subString(0,1).toUpperCase()
                    +  nameGroup[i].substringBefore('-').subString(1,nameGroup[i].substringBefore('-').length()).toLowerCase()
                    + '-' 
                    + nameGroup[i].substringAfter('-').subString(0,1).toUpperCase() 
                    + nameGroup[i].substringAfter('-').subString(1,nameGroup[i].substringAfter('-').length()).toLowerCase();    
            }else {
                nameGroup[i] = nameGroup[i].subString(0,1).toUpperCase() + nameGroup[i].subString(1,nameGroup[i].length()).toLowerCase();
            }   
        }
        return conName = String.join(nameGroup, ' ');
        //system.assertEquals('NAME: ' , ' ' + names);
    }
    
    //CCRM15-83,140 set marketing flags
    private static void setMarketingFlags(String operationType, List<Contact> lstNewContacts, Map<Id, Contact> mapNewContacts, Map<Id, Contact> mapOldContacts){
		Id recordTypeIdAUARContact= DM_RecordType.rtId_Contact_AuArContact;    
    	Id recordTypeIdNZARContact= DM_RecordType.rtId_Contact_NzArContact;  
        String integrationUserId = Config.Integration_User_Id__c;
        String marketingConnectUserId = Config.Marketing_Connect_User_Id__c; 
        String batchUserId = Config.Batch_User_Id__c; //CCRM15-180, needs review, added as a temporary fix to avoid error: System.AsyncException: Future method cannot be called from a future or batch method
        
        system.debug('Integration_User_Id:' + integrationUserId);
        system.debug('Marketing_Connect_User:' + marketingConnectUserId);
        system.debug('current login id:' + Userinfo.getUserId());
        
        /*
        Map<Id, String> mapUsers = New Map<Id, String> ();
        List<User> lstUser = [SELECT Id, Username FROM User WHERE Username IN (:integrationUserId,  :marketingConnectUserId)];
        if(lstUser.size() > 0){
            for(User u : lstUser){
                mapUsers.put(u.Id, u.Username);
            }
        }*/
        
        Set<Id> setAcctIds = New Set<Id>(); 
        Map<Id, Contact> mapMarketingContact = New Map<Id, Contact>();
        List<Contact> lstMarketingContact = New List<Contact>();
        Set<Id> updateAccountIds = New Set<Id>();

        //Added for SFSUP-302 - Person Account Changes
        Id personAccRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;

        for(Contact conts: lstNewContacts){
            if(
                (conts.RecordTypeId == recordTypeIdAUARContact || conts.RecordTypeId == recordTypeIdNZARContact)
                && UserInfo.getUserId() != batchUserId
              ){
                if(conts.Account.RecordTypeId != personAccRecordTypeId) {
                    setAcctIds.add(conts.AccountId);
                }

                if((operationType == 'beforeUpdate' && mapOldContacts.get(conts.Id).Marketing_Contact__c == true) || Test.isRunningTest()){
                    if(Userinfo.getUserId() == integrationUserId || Test.isRunningTest()){
                        if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == null){
                            conts.Receive_Marketing_Last_Update_By__c = Userinfo.getUserId();
                            updateAccountIds.add(conts.AccountId);
                        }
                        else if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == Userinfo.getUserId()){
                            conts.Receive_Marketing_Last_Update_By__c = Userinfo.getUserId();
                            updateAccountIds.add(conts.AccountId);
                        }
                        else if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == marketingConnectUserId){
                            if(conts.Receive_Marketing__c != mapOldContacts.get(conts.Id).Receive_Marketing__c){
                                conts.Receive_Marketing__c =  mapOldContacts.get(conts.Id).Receive_Marketing__c;
                                conts.Receive_Marketing_Last_Update_By__c =  mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c;
                                updateAccountIds.add(conts.AccountId);
                            }
                            else{
                                conts.Receive_Marketing_Last_Update_By__c =  Userinfo.getUserId();
                                updateAccountIds.add(conts.AccountId);
                            }
                        }
                    }
                    if(Userinfo.getUserId() == marketingConnectUserId || Test.isRunningTest()){
                        if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == null){
							conts.Receive_Marketing_Last_Update_By__c =  Userinfo.getUserId();
                            updateAccountIds.add(conts.AccountId);                            
                        }
                        else if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == integrationUserId){
                            if(conts.Receive_Marketing__c != mapOldContacts.get(conts.Id).Receive_Marketing__c){
								conts.Receive_Marketing_Last_Update_By__c =  Userinfo.getUserId();
                                updateAccountIds.add(conts.AccountId);
                            }
                            else{
								conts.Receive_Marketing_Last_Update_By__c =  mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c;
                                updateAccountIds.add(conts.AccountId);
                            }                            
                        }
                        else if(mapOldContacts.get(conts.Id).Receive_Marketing_Last_Update_By__c == marketingConnectUserId){
							conts.Receive_Marketing_Last_Update_By__c =  Userinfo.getUserId();
                            updateAccountIds.add(conts.AccountId);
                        }                        
                    }
                }   
            }
        }
        
        system.debug('setAcctIds:' + setAcctIds);
        if(setAcctIds.size() > 0){		       
        	lstMarketingContact = [SELECT Id, AccountId, LastName FROM Contact WHERE AccountId IN :setAcctIds AND Marketing_Contact__c = true];
            if(lstMarketingContact.size() > 0){
                for(Contact con : lstMarketingContact){
                    mapMarketingContact.put(con.AccountId, con);
                }
            }
        }

        for(Contact conts: lstNewContacts){
            System.debug('Check: '+ ((conts.Account_Type__c == 'CASH' && conts.Verified_AC_Email__c == true) || (conts.Account_Type__c == 'CREDIT' || conts.Account_Type__c == '30DAY')));
            if((conts.RecordTypeId == recordTypeIdAUARContact || conts.RecordTypeId == recordTypeIdNZARContact)
              && conts.Receive_Marketing__c == true
              && String.valueOf(conts.Email) == conts.Account_Business_Email__c
              && (conts.Account_Type__c == 'CASH' || conts.Account_Type__c == 'CREDIT' || conts.Account_Type__c == '30DAY')){//Remove conts.Verified_AC_Email__c Check for CCRM15-252
                if(operationType == 'beforeInsert' && mapMarketingContact.get(conts.AccountId) == null){
                    conts.Marketing_Contact__c = true;
                }
                if(operationType == 'beforeUpdate' && mapOldContacts.get(conts.Id).Marketing_Contact__c == false && mapMarketingContact.get(conts.AccountId) == null){
                    conts.Marketing_Contact__c = true;
                }            	  
            }            
        }
        
        if(updateAccountIds.size()>0 && !System.isFuture() && !System.isBatch()){
            updateAccountRecievingMarket(updateAccountIds);
        }
    }
    
    @future
    private static void updateAccountRecievingMarket(Set<ID> recordIds){
        system.debug('updateAccountRecievingMarket input parameter:' + recordIds);
        try{
            List<Account> acctsList = [SELECT Id, Receive_Marketing__c, (SELECT Id, Receive_Marketing__c,Marketing_Contact__c FROM Contacts WHERE Marketing_Contact__c = true) FROM Account WHERE Id IN :recordIds AND RecordTypeId != :DM_RecordType.rtId_Account_PersonAccount];
            
            for(Account acc : acctsList){
                for(Contact con : acc.contacts){
                    if(con.Marketing_Contact__c){
                        if (acc.Receive_Marketing__c != con.Receive_Marketing__c){
                            acc.Receive_Marketing__c = con.Receive_Marketing__c;
                            system.debug('account to update:' + acc.Id);
                            system.debug('account to update Receive_Marketing__c:' + con.Receive_Marketing__c);
                            break;
                        }
                    }
                }
            }
            system.debug('acctsList:' + acctsList);
            
            if(acctsList.size() > 0) {
                update acctsList;
            }
            
        }catch(Exception e){
            ApplicationLogger.log('ContactTriggerHandler.updateAccountRecievingMarket', 'Contact', 'Trigger', e);
        }        
    }
    
    private static SM_Configs__c config {
        get {
            if (config==null) config = SM_Configs__c.getInstance();
            return config;
        }
        private set;
    } 
}