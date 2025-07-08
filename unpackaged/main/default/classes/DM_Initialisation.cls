/*******************************************************************************************************
* Class Name        : DM_Initialisation
* Description       : Data Layer - Selector for Custom Metadata Type Initialisation
* Author            : Simplus - Yi Zhang
* Created On        : 2020-05-14
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-14      1000                Initial version
* Errol Yatar           19/01/2021      2000                Added new field on query for CCRM-8710
* Simplus MS            04/06/2021      3000                Added new field on query for CCRM-13829
* Simplus MS            11/11/2021      4000                Added new field on query for CCRM15-410
* Simplus MS            23/23/2021      5000                Added new field on query for CCRM15-542
* Jasper R. Galapon     17/08/2023      6000                Added new field on query for BUNDIG-24085
* Jasper R. Galapon     04/06/2024      9000                Added new field on query for BUNDIG-31597
* Deepika Pentareddy    08/09/2023      7000                Added new field on query for BUNDIG-25133
* Deepika Pentareddy    08/05/2024      8000                Change engagement/onboarding call flow MicroStrategy report to Transaction Report BUNDIG-12013 
* Jasper R. Galapon     30/07/2024      9000                Added new field on query for BUNDIG-34611
******************************************************************************************************/
public with sharing class DM_Initialisation {

    /**
    * @description 
    * @author Simplus MS | 14/05/2020 
    * @return Initialisation__mdt 
    **/
    @AuraEnabled(cacheable=true)
    public static Initialisation__mdt getCCRMInitialisation() {                                             
		Initialisation__mdt record = [SELECT Id, Account_Transfer_Profile_Exemption__c, Account_Transfer_Profile_Exemption_2__c, 
        Account_Transfer_Approval_Exemption__c, Contract_Review_Percent_GP__c, Contract_Review_Read_Only_Profile__c, COS_New_Quote_URL__c,
        Planned_Call_Start_Time__c, Planned_Call_End_Time__c, Admin_Validation_Exceptions__c,
        Call_Planner_Amber_Foreground__c, Call_Planner_Amber_Background__c, 
        Call_Planner_Green_Foreground__c, Call_Planner_Green_Background__c, 
        Call_Planner_Red_Foreground__c, Call_Planner_Red_Background__c,
        Account_Transfer_Contract_Email_AU__c, Account_Transfer_Contract_Email_NZ__c,
        Delegated_Approver_Profile_Exemption__c, COS_Powerpass_URL__c, Call_Cycle_Attempts__c,
        CCRM_Account_Default_Owner__c, Default_Onboarding_Added_Days__c, CCRM_Default_NZ_Account_Owner__c, Staging_Object_Exemption_Profile__c,
		COS_Transaction_Sales_Report_URL__c,   //BUNDIG-12013 Change engagement/onboarding call flow MicroStrategy report to Transaction Report                                      
        COS_Product_Sales_Report_URL__c,       //added 11.Nov.2020 for CCRM-554 by Aldrin Rasdas
        DefaultApprovalRequestEmailSetting__c,   //added 20.JAN.2021 for CCRM-8710 by Errol Yatar
        MicroStrategy_URL__c, //added 04.Jun.2021 for CCRM-13829 by Simplus MS
        COS_Powerpass_SignUp_URL__c, //added 11.Nove.2021 for CCRM15-410 by Simplus MS
        CCRM_Dummy_Account_Id__c,
        SyncAccount_Date_Range__c, //added 21.8.2023 for BUNDIG-24095                                      
		Pricing_Assignment_Unassign_Delay__c,
        Pricing_Assignment_Assign_Delay__c,
        Contract_Line_Item_Auto_Approval_Buffer__c, // added 30/07/2024 for BUNDIG-34611
        CLI_Auto_Approval_Batch_Limit__c // added 15/08/2024 for BUNDIG-34611
        FROM Initialisation__mdt WHERE DeveloperName = 'CCRM_Initialisation' LIMIT 1];

        return record;
    }
    
    
    /**
    * @description 
    * @author Yi Zhang | 20/07/2020
    * @return Initialisation__mdt 
    **/    
    public static Initialisation__mdt ccrmInitialisation {
        get {
            if(ccrmInitialisation == null) {
                ccrmInitialisation = getCCRMInitialisation();
            }
            return ccrmInitialisation;
        } set;
    }  
}