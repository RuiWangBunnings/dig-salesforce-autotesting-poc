/*******************************************************************************************************
* Class Name      	: Constants
* Description		: This class holds static variables to be used by other classes
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-06-05
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-05		1000				Initial version
* Errol Yatar           19/01/2021		2000				Added new String constants for Initialisation__mdt.DefaultApprovalRequestEmailSetting__c picklist field values.
* Simplus MS            05/02/2021      3000                CCRM-8664 - Added Contract Status Submitted
* Simplus MS 			22/09/2021		4000				CCRM15-83 and CCRM15-140 - Added Contact Record Types
* Simplus MS 			13/12/2021		5000				CCRM15-416- Added Account Manager profile names
* Simplus MS			14/02/2022		3000				SFSUP-302 - Added Person Account Record Type Name
* Jasper R Galapon      12/04/2023      6000                BUNDIG-17527 - Added Contract Status Rejected
******************************************************************************************************/
public class Constants {

    // General
    public static final String COUNTRY_AU = 'Australia';
    public static final String COUNTRY_NZ = 'New Zealand';
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_INACTIVE = 'Inactive';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_CANCELLED = 'Cancelled';

    // Contract__c
    public static final String CONTRACT_APPROVAL_STATUS_DELETED = 'Deleted';
    public static final String CONTRACT_APPROVAL_STATUS_COMPLETED = 'Completed';
    public static final String CONTRACT_APPROVAL_STATUS_PENDING = 'Pending';

    public static final String CONTRACT_STATUS_ACTIVE = 'Active';
    public static final String CONTRACT_STATUS_PENDING = 'Pending';
    public static final String CONTRACT_STATUS_REVIEWED = 'Reviewed';
    public static final String CONTRACT_STATUS_APPROVED = 'Approved';
    public static final String CONTRACT_STATUS_EXPIRED = 'Expired';
    public static final String CONTRACT_STATUS_REJECTED = 'Rejected';
    public static final String CONTRACT_STATUS_DRAFT = 'Draft';
    public static final String CONTRACT_STATUS_AWAITING_SYSTEM_RESPONSE = 'Awaiting System Response';
    
    // CCRM-8664 additions
    public static final String CONTRACT_APPROVED = 'Customer Approved';
    public static final String CONTRACT_REJECTED = 'Customer Rejected';
    public static final String CONTRACT_STATUS_SUBMITTED = 'Submitted';


    // Contract_Line_Item__c
    public static final String CLI_LINE_TYPE_CONTRACT  = 'Contract';
    public static final String CLI_LINE_TYPE_AMENDMENT = 'Amendment';

    public static final String CLI_LINE_STATUS_COMPLETED = 'C';
    public static final String CLI_LINE_STATUS_A = 'A';
    
    // Case Record Types
    public static final String AU_CONTRACT_CASE = 'AU_Contract_Requests';
    public static final String NZ_CONTRACT_CASE = 'NZ_Contract_Requests';
    
    // Profile Names
	public static final String AU_TRADE_SPECIALIST_PROFILEENAME = 'Trade Specialist';
	public static final String NZ_TRADE_SPECIALIST_PROFILEENAME = 'NZ Trade Specialist';
    public static final String AU_SALES_MANAGER_PROFILEENAME = 'Sales Manager';
    public static final String AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME = 'Light Commercial Manager';
    public static final String ORG_SALES_MANAGER_PROFILEENAME = 'Organisations Sales Manager';
    public static final String NATIONAL_MANAGER_PROFILEENAME = 'National Manager';
    public static final String AU_ACCOUNT_MANAGER_PROFILENAME = 'Account Manager';
    public static final String NZ_ACCOUNT_MANAGER_PROFILENAME = 'NZ Account Manager';
    
    // Store__c
    public static final String STORE_TYPE_WAREHOUSE = 'Warehouse';
    public static final String STORE_TYPE_STORE = 'Small Format Store';
    public static final String STORE_MODEL_NEW = 'New';
    public static final String STORE_MODEL_OLD = 'Old';

    // Store_Member__c
	public static final String STOREMEMBER_TS_ROLENAME = 'Trade Specialist';
	public static final String STOREMEMBER_RCM_ROLENAME = 'RCM';
	public static final String STOREMEMBER_SSM_ROLENAME = 'SSM';
	public static final String STOREMEMBER_ASM_ROLENAME = 'ASM';
	public static final String STOREMEMBER_AREA_BDM_ROLENAME = 'Area BDM';
	public static final String STOREMEMBER_CCS_MANAGER_ROLENAME = 'CCS Manager';
	public static final String STOREMEMBER_ACTIVE_STATUS = 'Active';
    public static final String STOREMEMBER_INACTIVE_STATUS = 'Inactive';
    
    // Event
    public static final String EVENT_STATUS_OPEN = 'Open';
    public static final String EVENT_STATUS_COMPLETED = 'Completed';
    public static final String EVENT_OUTCOME_ON_LEAVE = 'On Leave';
    public static final String EVENT_PURPOSE_ENGAGEMENT_CALL = 'Engagement Call';
    public static final String EVENT_RT_STANDARD = 'Standard_Event';

    // Account
    public static final String ACCOUNT_TYPE_CASH = 'CASH';
    public static final String ACCOUNT_TYPE_CREDIT = 'CREDIT';
    public static final String ACCOUNT_TYPE_30DAY = '30DAY';
    public static final String ACCOUNT_STATUS_TERMINATED = 'Terminated';
    public static final String ACCOUNT_STATUS_INACTIVE = 'Inactive';
     

    // Account Record Type Developer Names
    public static final String ACCOUNT_RT_AU_CUSTOMER = 'AU_Customer';
    public static final String ACCOUNT_RT_AU_PROSPECT = 'AU_Prospect';
    public static final String ACCOUNT_RT_AU_APPRENTICE = 'AU_Apprentice';
    public static final String ACCOUNT_RT_NZ_CUSTOMER = 'NZ_Customer';
    public static final String ACCOUNT_RT_NZ_PROSPECT = 'NZ_Prospect';
    public static final String ACCOUNT_RT_NZ_APPRENTICE = 'NZ_Apprentice';
    public static final String ACCOUNT_RT_PERSON_ACCOUNT = 'PersonAccount';
    
    // Contact Record Type Developer Names
    public static final String CONTACT_RT_AU_AR_CONTACT = 'AU_AR_Contact';
    public static final String CONTACT_RT_NZ_AR_CONTACT = 'NZ_AR_Contact';

    // OpportunityD
    public static final String OPPTY_STAGE_CLOSED_WON = 'Closed Won';
    public static final String OPPTY_STAGE_CLOSED_LOST = 'Closed Lost';
    // Opportunity Record Type Developer Names
    public static final String OPPTY_RT_AU_STANDARD = 'AU_Standard_Opportunity';
    public static final String OPPTY_RT_NZ_STANDARD = 'NZ_Standard_Opportunity';

    // Quote
    public static final String QUOTE_STATUS_ENQUIRY = 'Enquiry';
    public static final String QUOTE_STATUS_QUOTE = 'Quote';
    public static final String QUOTE_STATUS_CANCELLED = 'Cancelled';
    public static final String QUOTE_STATUS_SUBMITTED = 'Submitted';
    public static final String QUOTE_STATUS_PRICING_ONLY = 'Pricing Only Quote';

    // Profile
    public static final String PROFILE_INTEGRATIONS_USER = 'Integrations User';
    public static final String PROFILE_SYSTEM_ADMIN = 'System Administrator';
    public static final String PROFILE_TRADE_SPECIALIST = 'Trade Specialist';

    // Sales Rep
    public static final String SALES_REP_RT_AU = 'AU_Sales_Rep';
    public static final String SALES_REP_RT_NZ = 'NZ_Sales_Rep';

    // Initialisation__mdt.DefaultApprovalRequestEmailSetting__c
    public static final String INIT_APPRVEMAIL_NO_EMAILS = 'Never';
    public static final String INIT_APPRVEMAIL_APPROVER_ONLY = 'Only if I am an approver';
    public static final String INIT_APPRVEMAIL_DELEGATE_ONLY = 'Only if I am a delegated approver';
    public static final String INIT_APPRVEMAIL_ALL = 'If I am an approver or delegated approver';
}