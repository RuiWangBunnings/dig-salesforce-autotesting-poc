/*******************************************************************************************************
* Class Name      	: DM_FeatureToggle_Test
* Description		: Test class for DM_FeatureToggle
* Author          	: Bunnings Dev
* Created On      	: 22/10/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     6/06/2023		1000				Initial version - BUNDIG-14708
* Jasper R. Galapon     6/06/2023		1001				BUNDIG-40916 - Added test coverage for Contract Amendment Line Auto Approval
******************************************************************************************************/

@isTest
public class DM_FeatureToggle_Test {
    
    // BUNDIG-40916
    @isTest
    public static void testgetContract_AmendmentLineAutoApproval() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Contract_Amendment_Line_Auto_Approval');
            System.assertEquals(testEnabled, True);
        Test.stopTest();
    }

	@isTest
    public static void testgetOrderOpptyAssEnabled() {
        Test.startTest();       
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Order_Oppty_Association_on_Creation');
            System.assertEquals(testEnabled, True);
        Test.stopTest();
    }
    
	@isTest
    public static void testgetAUStndOpptyClosedLostBellNotificationEnabled() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('AU_Stnd_Oppty_Close_LostBellNotification');
            System.assertEquals(testEnabled, True);
        Test.stopTest();
    }
    
	@isTest
    public static void testgetAccountDomainFeedv1() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Accnt_Number_Domain_Feed_v1');
            System.assertEquals(testEnabled, true);
        Test.stopTest();
    }
    
	@isTest
    public static void testgetAccountDomainFeedv2() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Accnt_Number_Domain_Feed_v2');
            System.assertEquals(testEnabled, true);
        Test.stopTest();
    }
    
	@isTest
    public static void testgetUpdateAUOpptyFollowUpDate() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Update_AU_Opportunity_Follow_Up_Date');
            System.assertEquals(testEnabled, true);
        Test.stopTest();
    }
    
	@isTest
    public static void testgetUpdateNZOpptyFollowUpDate() {
        Test.startTest();        
            Boolean testEnabled = DM_FeatureToggle.getFeatureToggleEnabled('Update_NZ_Opportunity_Follow_Up_Date');
            System.assertEquals(testEnabled, true);
        Test.stopTest();
    }

}