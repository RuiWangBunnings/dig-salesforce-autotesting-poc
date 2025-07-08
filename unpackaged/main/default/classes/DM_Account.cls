/*******************************************************************************************************
* Class Name        : DM_Account
* Description       : Data Layer - Selector for Sobject Account
* Author            : Simplus - Yi Zhang
* Created On        : 2020-05-14
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-14      1000                Initial version
* Simplus MS            02/07/2021      2000                CCRM-13792: Get Parent/Child Account With Customer Contracts
* Simplus MS            09/08/2021      3000                Added sorting in getSupplierAccountsByRegion
* Simplus MS            25/08/2021      4000                CCRM15-107: Update legacy accounts for CCRM15-103
* Simplus MS			04/11/2021		5000				Added Account_Owner_Sales_Id__c field in method getAccountsOwnedBy
* Simplus MS 			02/02/2022      6000 				SFSUP-302 Added Record Type != Person Account to queries
* Bunnings Dev          01/06/2022      7000                SFSUP-623 / SFSUP-764 - LifeCycle Calls
* Bunnings Dev          01/08/2022      8000                SFSUP-932 - Remove sub query to fetch "Events" for LifeCycle Calls
* Bunnings Dev          25/10/2022      9000                BUNDIG-12626 - New Maintaining customer form
* Bunnings Dev          28/08/2024      9100                CRMS-17 - Single Account Transfer
* Bunnings Dev 			07/10/2024		9200				Get Accounts Map
* Bunnings Dev          24/01/2025      9300                BUNDIG-35626 - PB Account Create Action Conversation - New Sub Account Notification
* Juan Cutrera			21/03/2025		10000				Consent get PersonAccounts that match Email or Phone 					
******************************************************************************************************/
public with sharing class DM_Account {
    
    /**
    * @description  Used by AccountController
    * @author Purba Ghosh | 01/03/2020 
    * @param accountId 
    * @return Account 
    **/
    public static Account getAccountDetails(String accountId) {      
        Account ObjAccount = new Account();
        if(accountId != null) {
            try {
                ObjAccount = [SELECT Id, Name, Country__c, Pricing_Assignment_Status__c, Pricing_Assignment_Requested_On__c, Spend_Band__c, 
                                    Spend_Band__r.Name, Proposed_Spend_Band__c, Proposed_Spend_Band__r.Name
                                    From Account 
                                    WHERE Id = :accountId
									AND RecordType.Name != 'Person Account']; //Added Feb.02.2022 to seperate it from Person Accounts
            } catch (exception e) {
                // Error or Application log handler (Reminder - A new object for logging needs to be created)
                ApplicationLogger.log('DM_Account.getAccountDetails', 'Account', 'SOQL', e);
            }
        }
        return ObjAccount;
    }

    /**
    * @description  Used by SM_AccountTransfer
    * @author       Yi Zhang | 14/05/2020 
    * @param        accountId 
    * @return       Account 
    **/
    public static Account getAccount(String accountId) {
        if(accountId == null) {
            return null;
        }
        List<Account> accts = [SELECT Id, OwnerId, ParentId,Transfer_approval_status__c, Country__c, Assigned_Store__c, Power_Pass_Account_Number__c,Account_Owner_Sales_Id__c
        FROM Account
        WHERE Id = :accountId
		AND RecordType.Name != 'Person Account'];
        return (accts.isEmpty()) ? null : accts[0];
    }

    /**
    * @description  Used by SM_AccountRequestTransfer
    * @author      Bunnings Dev 
    * @param        accountId 
    * @return       Account 
    **/
    public static Account getAccountRec(String accountId) {
        if(accountId == null) {
            return null;
        }
        List<Account> accts = [SELECT Id, OwnerId, Transfer_approval_status__c, Country__c, Assigned_Store__c, Power_Pass_Account_Number__c,Account_Owner_Sales_Id__c
        FROM Account
        WHERE Id = :accountId];
        return (accts.isEmpty()) ? null : accts[0];
    }

    /**
    * @description Used by SM_CallPlanner
    * @author Yi Zhang | 01/07/2020 
    * @param accountIds 
    * @return List<Account> 
    **/
    public static List<Account> getAccounts(List<String> accountIds) {
        return new List<Account>([
            SELECT Id, Name, OwnerId, Transfer_approval_status__c, Country__c, Parent.ownerid, Parent.Owner.IsActive, Power_Pass_Account_Number__c, Parent.Name //BUNDIG-35626 PB Account Create Action Conversation - New Sub Account Notification
            FROM Account
            WHERE Id IN :accountIds AND RecordType.Name != 'Person Account'
        ]);
    }
/**
    * @description : getAccountsBySet
    * @author Sowjanya 
    * @param accountIds 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsBySet(Set<Id> accountIds) {
        return new List<Account>([
            SELECT Id, Name, OwnerId, Transfer_approval_status__c, Country__c 
            FROM Account
            WHERE Id IN :accountIds AND RecordType.Name != 'Person Account'
        ]);
    }
    /**
    * @description Used by SM_Account
    * @author Yi Zhang | 13/08/2020 
    * @param accountIds 
    * @return Map<Id, Account> 
    **/
    public static Map<Id, Account> getAccountsWithScheduledEngagementCall(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Scheduled_Engagement_Call__c
            FROM Account
            WHERE Id IN :accountIds AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description Used by SM_SupplierQuoteSelection
    * @author Philip Clark | 10/07/2020 
    * @param region 
    * @return List<Account> 
    **/
    public static List<Account> getSupplierAccountsByRegion(String region) {
        return new List<Account>([
            SELECT Id, Name, OwnerId, Business_Email_Address__c, Supplier_Region__c, Supplier_Categories__c 
            FROM Account
            WHERE Supplier_Region__c =:region
            AND RecordType.DeveloperName = 'NZ_Supplier'
            ORDER BY Name ASC
        ]);
    }


    /**
    * @description Used by SM_ContractReview
    * @author Yi Zhang | 07/07/2020 
    * @param contractId 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsWithCustomerSpecialBuys(String contractId) {
        return new List<Account>([
            SELECT Id, (SELECT Id, Special_Buy__c FROM Customer_Special_Buys__r) 
            FROM Account 
            WHERE Id IN (SELECT Customer__c FROM Customer_Contract__c WHERE Contract__c = :contractId)
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description Used by SM_CallPlanner
    * @author Yi Zhang | 07/07/2020 
    * @param ownerId 
    * @return List<Account> 
    **/
    public static List<Account> getCustomerAndProspectAccountsOwnedBy(String ownerId) {
        return new List<Account>([
            SELECT Id,
            Power_Pass_Account_Number__c,
            Name,
            R12_Sales__c, 
            Last_3_Month_Sales__c, 
            Share_of_Wallet__c, 
            Reason_for_Share__c
            //Tactic__c //Commented for CCRM-8162 // Aldrin Rasdas 13.Nov.2020
            FROM Account
            WHERE OwnerId = :ownerId
            AND RecordType.DeveloperName IN ('AU_Customer', 'NZ_Customer', 'AU_Prospect', 'NZ_Prospect')
            AND Account_Status__c IN ('Active', 'Referred')
            ORDER BY Name ASC
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 23/07/2020 
    * @param accountIds 
    * @return List<Account> 
    **/
    // public static List<Account> getAccountsWithComingCallCycleTaskThisMonth(List<Id> accountIds) {
    //     return new List<Account>([
    //         SELECT Id, OwnerId, 
    //         (SELECT Id FROM Tasks WHERE RecordTypeId = :DM_RecordType.rtId_Task_CallCycle AND ActivityDate >= TODAY AND ActivityDate <= THIS_MONTH LIMIT 1)
    //         FROM Account
    //         WHERE Id IN :accountIds
    //         AND Owner.IS_TS__c = true
    //     ]);
    // }

    /**
    * @description Used by SM_CallCycle
    * @author Yi Zhang | 26/10/2020 
    * @param accountIds 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsWithCustomerEngagementCallThisMonth(List<Id> accountIds) {
        return new List<Account>([
            SELECT Id, OwnerId, 
            (SELECT Id FROM Tasks WHERE Sub_type__c = 'Engagement Call' AND ActivityDate = THIS_MONTH LIMIT 1),
            (SELECT Id FROM Events WHERE Sub_type__c = 'Engagement Call' AND ActivityDate = THIS_MONTH LIMIT 1)
            FROM Account
            WHERE Id IN :accountIds
            AND Owner.IS_TS__c = true
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description Used by SM_User 
    * @author Yi Zhang | 21/08/2020 
    * @param ownerIds 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsOwnedBy(List<Id> ownerIds) {
        return new List<Account>([
            SELECT Id, OwnerId, Account_Owner_Sales_Id__c, Assigned_Store__c, Owner.Profile.Name,RecordType.Name,
            Owner.isActive, Owner.Name, Assigned_Store__r.Location_Code__c, Owner.Team_Member_ID__c, Owner.UserRole.Name
            FROM Account WHERE OwnerId IN :ownerIds AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description Used by AccountTriggerHandler
    * @author Yi Zhang | 27/08/2020 
    * @param accountIds 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsWithoutChild(List<Id> accountIds) {
        return new List<Account>([
            SELECT Id 
            FROM Account 
            WHERE Id IN :accountIds 
            AND Has_Child_Accounts__c = false AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description      Only accounts with any status other than Terminated or Inactive, Used by AccountTriggerHandler
    * @author Yi Zhang | 28/09/2020
    * @param parentIds 
    * @return List<AggregateResult> 
    **/
    public static List<AggregateResult> getAccountsGroupedByParent(List<Id> parentIds) {
        return new List<AggregateResult>([
            SELECT ParentId, COUNT(Id) 
            FROM Account
            WHERE ParentId IN :parentIds 
            AND Account_Status__c != :Constants.ACCOUNT_STATUS_TERMINATED
            AND Account_Status__c != :Constants.ACCOUNT_STATUS_INACTIVE
            AND RecordType.Name != 'Person Account'
			GROUP BY ParentId]);
    }

    /**
    * @description Used by SM_CallCycle
    * @author Yi Zhang | 24/09/2020 
    * @param accountId 
    * @return Account 
    **/
    public static Account getAccountWithContactsEngagementCallActivities(String accountId) {
        
        return [
            SELECT Id, Name, Description__c, Power_Pass_Account_Number__c, Primary_Segment__c,
            Secondary_Segment__r.Name, R12_Sales__c, toLabel(Type), Credit_Limit__c, 
            BillingCity, PowerPass_Account_Created_Date__c,
            Assigned_Store__c, Phone, Business_Mobile__c, Country__c, 
            OwnerId, Business_Email_Address__c, Home_Store__c, R12_Top_Spend_Location_1__r.Name, R12_Top_Spend_Location_2__r.Name, Preferred_Contact_Method__pc,
            (
                SELECT Id, Subject, Objectives__c, Call_Cycle_Attempt__c, Opportunity__c, WhatId, OwnerId, ActivityDate, Call_Research_Notes__c, Main_Reason__c,
                Main_Reason_Other__c
                FROM Tasks 
                WHERE Sub_type__c = 'Engagement Call'
                AND IsClosed = false
                AND ((NOT Reason_Group__c LIKE 'Growing%') AND (NOT Reason_Group__c LIKE 'Maintaining%')) // BUNDIG-12626 - Exclude Maintaining
                ORDER BY ActivityDate ASC
            ),
            (
                SELECT Id, StartDateTime, Objectives__c 
                FROM Events 
                WHERE Sub_type__c = 'Engagement Call'                
                AND Status__c != 'Completed' 
                AND IsChild = false
                ORDER BY StartDateTime ASC LIMIT 1),
            (
                SELECT Id, Name, Phone, Email 
                FROM Contacts
            )
            FROM Account
            WHERE Id = :accountId
        ];
    }

    /**
    * @description Used by SM_CallCycle - LifeCycle Call Cycle
    * @author Bunnings Dev | 15/06/2022
    * @param accountId, taskSubType 
    * @return Account     
    **/
    public static Account getAccountWithContactsCallActivities(String accountId, String taskSubType, String reasonGroup) {
        
        return [
            SELECT Id, Name, Description__c, Power_Pass_Account_Number__c, Primary_Segment__c,
            Secondary_Segment__r.Name, R12_Sales__c, toLabel(Type), Credit_Limit__c, 
            BillingCity, PowerPass_Account_Created_Date__c,
            Assigned_Store__c, Phone, Business_Mobile__c, Country__c, 
            OwnerId, Business_Email_Address__c, Home_Store__c, R12_Top_Spend_Location_1__c, R12_Top_Spend_Location_1__r.Name, R12_Top_Spend_Location_2__c, R12_Top_Spend_Location_2__r.Name, 
            Preferred_Contact_Method__pc, PowerPass_App_Registered__c, Transacted_on_PowerPass_App__c, LifeCycle_Call_Reason__c,
            (
                SELECT Id, RecordTypeId, Subject, Objectives__c, Call_Cycle_Attempt__c, Opportunity__c, WhatId, OwnerId, ActivityDate, Call_Research_Notes__c, Main_Reason__c,
                Main_Reason_Other__c
                FROM Tasks 
                WHERE Sub_type__c =:taskSubType
                AND Reason_Group__c =:reasonGroup
                AND IsClosed = false
                ORDER BY ActivityDate ASC
            ),
            // SFSUP-932 - Commented out - LifeCycle Calls only creates Task
            /*(
                SELECT Id, StartDateTime, Objectives__c 
                FROM Events 
                WHERE Sub_type__c =:taskSubType
                AND Status__c != 'Completed' 
                AND IsChild = false
                ORDER BY StartDateTime ASC LIMIT 1),*/
            (
                SELECT Id, Name, Phone, MobilePhone, Email, Preferred_Contact_Time__c, Preferred_Contact_Method__c 
                FROM Contacts
            )
            FROM Account
            WHERE Id = :accountId
        ];
    }
        
    /**
    * @description Used by AccountTriggerHandler
    * @author Yi Zhang | 28/09/2020 
    * @param accounts 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsWithUmbBeneficiariesAndFutureActivities(List<Account> accounts) {
        return new List<Account>([
            SELECT Id,
            (SELECT Id FROM Umbrella_Beneficiaries__r WHERE Status__c != :Constants.STATUS_INACTIVE),
            (SELECT Id FROM Tasks WHERE IsClosed = false),
            (SELECT Id FROM Events WHERE Status__c != :Constants.STATUS_COMPLETED)
            FROM Account
            WHERE Id IN :accounts
        ]);
    }

    /**
    * @description Used by AccountTriggerHandler
    * @author Yi Zhang | 28/10/2020 
    * @param names 
    * @param excludeIds 
    * @return List<Account> 
    **/
    public static List<Account> getProspectAccountsByName(List<String> names, List<Id> excludeIds) {
        return new List<Account>([
            SELECT Id, RecordTypeId, OwnerId, Name, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, 
            Phone, Website, ABN__c, GST_Number__c, Country__c 
            FROM Account 
            WHERE RecordType.DeveloperName IN ('AU_Prospect', 'NZ_Prospect') 
            AND Name IN :names AND 
            Id NOT IN :excludeIds
        ]);
    }

    /**
    * @description Used by AccountTriggerHandler, SM_OnboardingCallBatch
    * @author Yi Zhang | 28/10/2020 
    * @param accounts 
    * @return List<Account> 
    **/
    public static List<Account> getAccountsWithSecondarySegment(List<Account> accounts) {
        return new List<Account>([
            SELECT Id, Secondary_Segment__c, Secondary_Segment__r.Segment_Group__c
            FROM Account
            WHERE Id IN :accounts
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description CCRM-13792: Get Parent Account With Customer Contracts 
    * @author Simplus MS | 24/06/2021
    * @param accountIds 
    * @return Map<Id, Account> 
    **/
    public static Map<Id, Account> getParentAccWithCustContracts(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Contract_Group__c,
            (SELECT Customer__c, Contract__c, Contract__r.Status__c, Contract__r.Start_Date__c, Contract__r.End_Date__c 
            FROM Customer_Contracts__r 
            WHERE Contract__r.Status__c = :Constants.CONTRACT_STATUS_ACTIVE OR Start_Date__c >= TODAY)
            FROM Account
            WHERE Id IN :accountIds
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description CCRM-13792: Get Child Account With Customer Contracts, Used by AccountTriggerHandler, TEMP_SM_ContractGroupBatch
    * @author Simplus MS | 24/06/2021
    * @param accountIds 
    * @return Map<Id, Account> 
    **/
    public static Map<Id, Account> getChildAccWithCustContracts(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Contract_Group__c,
            (SELECT Customer__c, Contract__c, Contract__r.Status__c, Contract__r.Start_Date__c, Contract__r.End_Date__c FROM Customer_Contracts__r) 
            FROM Account
            WHERE Id IN :accountIds
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description CCRM15-107: Update legacy accounts for CCRM15-103, Used by TEMP_SM_ContractGroupBatch
    * @author Simplus MS | 25/08/2021
    * @param accountIds 
    * @return Map<Id, Account> 
    **/
    public static Map<Id, Account> getParentAccWithCustContractsAndCPL(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Contract_Group__c,
            (SELECT Customer__c, Contract__c, Contract__r.Status__c, Contract__r.Start_Date__c, Contract__r.End_Date__c 
            FROM Customer_Contracts__r 
            WHERE Contract__r.Status__c = :Constants.CONTRACT_STATUS_ACTIVE OR Start_Date__c >= TODAY),
            (SELECT Id, Account__c, Action__c, Change_Requested_On__c, CreatedById, End_Date__c, LastModifiedById, Price_List__c,
            Pricing_Assignment_Status__c, Start_Date__c, Status__c 
            FROM Customer_Price_Lists__r
            WHERE Status__c = 'Active' OR Start_Date__c > TODAY)
            FROM Account
            WHERE Id IN :accountIds
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    * @description CRMS -202 Get Account Map
    * @author Simplus MS | 25/08/2021
    * @param accountIds
    * @return Map<Id, Account>
    **/
    public static Map<Id, Account> getAccountMap(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, RecordTypeId, OwnerId, Name, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, 
            Phone, Website, ABN__c, GST_Number__c, Country__c 
            FROM Account 
            WHERE Id IN :accountIds
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
    *  Method name  :  CRMS 203 - Get Oppportunities with Details
    *  Description  :  Retrieve all the accounts with power pass numbers
    *  Author       :  Sowjanya   
    * @param        :  power pass set 
    **/
    public static Map<String,Id> getAccountIDByPowerPassNumbers(Set<String> powerpassNumberSet) {
        Map<String,id> powerpassAccIDMap = new Map<String,id>();
        
        //Query Account details using powerpass numbers
        List<Account> accList= [
            SELECT ID,Power_Pass_Account_Number__c 
            FROM Account 
            WHERE Power_Pass_Account_Number__c in :powerpassNumberSet];
          
        //Retrieve Account id and update them in a  map
        if(!accList.IsEmpty()){
            for (Account acc : accList) {
                powerpassAccIDMap.put(acc.Power_Pass_Account_Number__c,acc.id);
                
            }
        }
        
        return powerpassAccIDMap;
    }

    /**
    *  Method name  :  getAccountsByPowerPassNumbers
    *  Description  :  Retrieve all the accounts with power pass numbers
    *  Author       :  Sowjanya   
    * @param        :  power pass set 
    **/
    public static Map<String,Account> getAccountsByPowerPassNumbers(Set<String> powerpassNumberSet) {
        Map<String,Account> powerpassAccMap = new Map<String,Account>();
        system.debug('powerpassNumberSet:'+powerpassNumberSet);
        //Query Account details using powerpass numbers
        List<Account> accList= [
            SELECT ID,Power_Pass_Account_Number__c,OwnerId,Account_Owner_Sales_Id__c
            FROM Account 
            WHERE Power_Pass_Account_Number__c in :powerpassNumberSet];
          
        //Retrieve Account id and update them in a  map
        if(!accList.IsEmpty()){
            for (Account acc : accList) {
                powerpassAccMap.put(acc.Power_Pass_Account_Number__c,acc);
                
            }
        }
        
        return powerpassAccMap;
    }

    /**
    * @description CCRM15-107: Update legacy accounts for CCRM15-103, Used by TEMP_SM_ContractGroupBatch
    * @author Simplus MS | 25/08/2021
    * @param accountIds
    * @return Map<Id, Account>
    **/
    public static Map<Id, Account> getChildAccWithCustContractsAndCPL(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Contract_Group__c,
            (SELECT Customer__c, Contract__c, Contract__r.Status__c, Contract__r.Start_Date__c, Contract__r.End_Date__c 
            FROM Customer_Contracts__r),
            (SELECT Id, Account__c, Action__c, Change_Requested_On__c, CreatedById, End_Date__c, LastModifiedById, Price_List__c,
            Pricing_Assignment_Status__c, Start_Date__c, Status__c 
            FROM Customer_Price_Lists__r) 
            FROM Account
            WHERE Id IN :accountIds
			AND RecordType.Name != 'Person Account'
        ]);
    }

    /**
     * @description getPersonAccountsBasedOnEmailOrMobile getPerson Accounts Based On Email Or Mobile
     * @author Juan M. Cutrera | 09/04/2025
     * @param  matchingEmail       matchingEmail
     * @param  matchingMobilePhone matchingMobilePhone
     * @return List<Account         
     */
    public static List<Account> getPersonAccountsBasedOnEmailOrMobile(String matchingEmail, String matchingMobilePhone){
        List<Account> personAccountMatchList = new List<Account>();
        List<String> soqlCondition = new List<String>();
 
        String soqlQuery;
        String selectClause = 'SELECT Id, Name, FirstName, LastName, PersonIndividualId, PersonIndividual.LastModifiedDate, PersonEmail, PersonMobilePhone ';
        String fromClause = ' FROM Account ';
        String whereClause;
        String endingClause = ' WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC';
        
        
        //Look at where clause
        String sanitizedEmail = String.isNotBlank(matchingEmail) ? String.escapeSingleQuotes(matchingEmail) : null;
        String sanitizedMobile = String.isNotBlank(matchingMobilePhone) ? String.escapeSingleQuotes(matchingMobilePhone) : null;
        //TODO use where clause to add the email to and phone to it
        if(sanitizedEmail != null){
            soqlCondition.add('PersonEmail = :sanitizedEmail ');
        }
        if(sanitizedMobile != null){
            soqlCondition.add('PersonMobilePhone = :sanitizedMobile ');
        }
        //create the whereClause
        if(soqlCondition.size() > 0){
             whereClause = ' WHERE (';
            for(Integer i = 0; i < soqlCondition.size(); i++){
                if(i == 0){
                    whereClause += soqlCondition[i];
                }else{
                    whereClause += ' OR ' + soqlCondition[i];
                }
            }
            whereClause += ') ';
            whereClause += ' AND isPersonAccount = TRUE';
            soqlQuery = selectClause + fromClause + whereClause + endingClause;
            System.debug('### soqlQuery: ' + soqlQuery);
            personAccountMatchList = Database.query(soqlQuery);
        }else{}
        return personAccountMatchList;
 
    }
 
}