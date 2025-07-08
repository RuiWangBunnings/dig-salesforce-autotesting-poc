/*******************************************************************************************************
* Class Name      	: DM_RecordType
* Description		: Data Layer - Selector for RecordType sobject / Schema Describe.
* Author          	: Simplus - Yi Zhang
* Created On      	: 21/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              21/07/2020		1000				Initial version
* Simplus MS			22/09/2021		2000				CCRM15-83 and CCRM15-140 - Added Contact Record Types
* Simplus MS			14/02/2022		3000				Added for SFSUP-302 - Person Account Changes
* Bunnings Dev          31/10/2022      4000                BUNDIG-12626 - New Maintaining Workflow - Use a specific guide flow for Maintaining calls
******************************************************************************************************/
public class DM_RecordType {

    /**
    * @description 
    * @author Bunnings Dev | 10/06/2022
    * @return Id 
    **/
    public static Id rtId_Task_ReducingLapsing {
        get {
            if(rtId_Task_ReducingLapsing == null) {
                rtId_Task_ReducingLapsing = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Reducing and Lapsing Call').getRecordTypeId();
            }
            return rtId_Task_ReducingLapsing;
        } set;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @return Id 
    **/
    public static Id rtId_Task_CallCycle {
        get {
            if(rtId_Task_CallCycle == null) {
                rtId_Task_CallCycle = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Cycle Call').getRecordTypeId();
            }
            return rtId_Task_CallCycle;
        } set;
    }

    /**
    * @description 
    * @author Bunnings Dev | 31/10/2022
    * @return Id 
    **/
    public static Id rtId_Task_Maintaining {
        get {
            if(rtId_Task_Maintaining == null) {
                rtId_Task_Maintaining = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Maintaining Call').getRecordTypeId();
            }
            return rtId_Task_Maintaining;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @return Id 
    **/
    public static Id rtId_Task_Standard {
        get {
            if(rtId_Task_Standard == null) {
                rtId_Task_Standard = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
            }
            return rtId_Task_Standard;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 22/10/2020 
    * @return Id 
    **/
    public static Id rtId_Task_OnboardingCall {
        get {
            if(rtId_Task_OnboardingCall == null) {
                rtId_Task_OnboardingCall = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Onboarding_Call').getRecordTypeId();
            }
            return rtId_Task_OnboardingCall;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @return Id 
    **/
    public static Id rtId_Account_AuCustomer {
        get {
            if(rtId_Account_AuCustomer == null) {
                rtId_Account_AuCustomer = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_AU_CUSTOMER).getRecordTypeId();
            }
            return rtId_Account_AuCustomer;
        } set;
    }

    /**
    * @description : NZ Customer account record type ID
    * @author Purba Ghosh | 31/08/2020 
    * @return Id 
    **/
    public static Id rtId_Account_NzCustomer {
        get {
            if(rtId_Account_NzCustomer == null) {
                rtId_Account_NzCustomer = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_NZ_CUSTOMER).getRecordTypeId();
            }
            return rtId_Account_NzCustomer;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 22/10/2020 
    * @return Id 
    **/
    public static Id rtId_Account_AuProspect {
        get {
            if(rtId_Account_AuProspect == null) {
                rtId_Account_AuProspect = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_AU_PROSPECT).getRecordTypeId();
            }
            return rtId_Account_AuProspect;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 12/08/2020 
    * @return Id 
    **/
    public static Id rtId_Account_NzProspect {
        get {
            if(rtId_Account_NzProspect == null) {
                rtId_Account_NzProspect = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_NZ_PROSPECT).getRecordTypeId();
            }
            return rtId_Account_NzProspect;
        } set;
    }

    /**
    * @description 
    * @author Simplus MS | 14/02/2022
    * @return Id 
    **/
    public static Id rtId_Account_PersonAccount {
        get {
            if(rtId_Account_PersonAccount == null) {
                rtId_Account_PersonAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_PERSON_ACCOUNT).getRecordTypeId();
            }
            return rtId_Account_PersonAccount;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 26/10/2020 
    * @return Id 
    **/
    public static Id rtId_Account_AuApprentice {
        get {
            if(rtId_Account_AuApprentice == null) {
                rtId_Account_AuApprentice = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_AU_APPRENTICE).getRecordTypeId();
            }
            return rtId_Account_AuApprentice;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 26/10/2020 
    * @return Id 
    **/
    public static Id rtId_Account_NzApprentice {
        get {
            if(rtId_Account_NzApprentice == null) {
                rtId_Account_NzApprentice = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.ACCOUNT_RT_NZ_APPRENTICE).getRecordTypeId();
            }
            return rtId_Account_NzApprentice;
        } set;
    }
    
    /**
    * @description 
    * @author Simplus MS | 22/09/2021 
    * @return Id 
    **/
    public static Id rtId_Contact_AuArContact {
        get {
            if(rtId_Contact_AuArContact == null) {
                rtId_Contact_AuArContact = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Constants.CONTACT_RT_AU_AR_CONTACT).getRecordTypeId();
            }
            return rtId_Contact_AuArContact;
        } set;
    }
    
    /**
    * @description 
    * @author Simplus MS | 22/09/2021 
    * @return Id 
    **/
    public static Id rtId_Contact_NzArContact {
        get {
            if(rtId_Contact_NzArContact == null) {
                rtId_Contact_NzArContact = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Constants.CONTACT_RT_NZ_AR_CONTACT).getRecordTypeId();
            }
            return rtId_Contact_NzArContact;
        } set;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 12/08/2020 
    * @return Id 
    **/
    public static Id rtId_Event_Standard {
        get {
            if(rtId_Event_Standard == null) {
                rtId_Event_Standard = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get(Constants.EVENT_RT_STANDARD).getRecordTypeId();
            }
            return rtId_Event_Standard;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @return Id 
    **/
    public static Id rtId_SalesRep_Au {
        get {
            if(rtId_SalesRep_Au == null) {
                rtId_SalesRep_Au = Schema.SObjectType.Sales_Rep__c.getRecordTypeInfosByDeveloperName().get(Constants.SALES_REP_RT_AU).getRecordTypeId();
            }
            return rtId_SalesRep_Au;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 24/08/2020 
    * @return Id 
    **/
    public static Id rtId_SalesRep_Nz {
        get {
            if(rtId_SalesRep_Nz == null) {
                rtId_SalesRep_Nz = Schema.SObjectType.Sales_Rep__c.getRecordTypeInfosByDeveloperName().get(Constants.SALES_REP_RT_NZ).getRecordTypeId();
            }
            return rtId_SalesRep_Nz;
        } set;
    }

    /**
    * @description 
    * @author Yi Zhang | 24/07/2020 
    * @return Map<String, Id> 
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getStandardOpptyRTs(){
        Map<String, Id> rtMap = new Map<String, Id>();
        rtMap.put('Australia', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_AU_STANDARD).getRecordTypeId());
        rtMap.put('New Zealand', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_NZ_STANDARD).getRecordTypeId());
        return rtMap;
    }
}