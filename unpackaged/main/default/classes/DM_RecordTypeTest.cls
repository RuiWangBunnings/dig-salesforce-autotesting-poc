/*******************************************************************************************************
* Class Name      	: TestDataFactoryTest
* Description		: Test Class for DM_RecordType
* Author          	: Simplus - MS
* Created On      	: 28/09/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus - MS         28/09/2021		1000				Initial version
* Bunnings Dev         09/11/2022       2000                BUNDIG-12626 - New Maintaining Workflow
******************************************************************************************************/
@isTest
public class DM_RecordTypeTest {
    @isTest
    public static void test () {
        Test.startTest();        
            Id callCycleTaskRecordTypeId = DM_RecordType.rtId_Task_CallCycle;
            Id standardTaskRecordTypeId = DM_RecordType.rtId_Task_Standard;
            Id onboardingTaskRecordTypeId = DM_RecordType.rtId_Task_OnboardingCall;
            Id standardEventRecordTypeId = DM_RecordType.rtId_Event_Standard;
            Id AuCustomerAccountRecordTypeId = DM_RecordType.rtId_Account_AuCustomer;
            Id NzCustomerAccountRecordTypeId = DM_RecordType.rtId_Account_NzCustomer;
            Id AuProspectAccountRecordTypeId = DM_RecordType.rtId_Account_AuProspect;
            Id NzProspectAccountRecordTypeId = DM_RecordType.rtId_Account_NzProspect;
            Id AuApprenticeAccountRecordTypeId = DM_RecordType.rtId_Account_AuApprentice;
            Id NzApprenticeAccountRecordTypeId = DM_RecordType.rtId_Account_NzApprentice;
            Id AuArContactRecordTypeId = DM_RecordType.rtId_Contact_AuArContact;  
            Id NzArContactRecordTypeId = DM_RecordType.rtId_Contact_NzArContact;  
            Id AuSalesRepRecordTypeId = DM_RecordType.rtId_SalesRep_Au;
            Id NzSalesRepRecordTypeId = DM_RecordType.rtId_SalesRep_Nz;
            Map<String, Id> mapOpportunityRecordTypeIds = DM_RecordType.getStandardOpptyRTs();
            Id reducingLapsingRecordTypeId = DM_RecordType.rtId_Task_ReducingLapsing;
        	Id personAccountRecordTypeId = DM_RecordType.rtId_Account_PersonAccount;
            Id maintainingRecordTypeId = DM_RecordType.rtId_Task_Maintaining;        
        Test.stopTest();
    }
}