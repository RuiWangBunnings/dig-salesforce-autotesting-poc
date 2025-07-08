/*******************************************************************************************************
* Class Name      	: DM_Opportunity_Test
* Description		: Test class for DM_Opportunity
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class DM_Opportunity_Test {
    @isTest
    public static void testGetOpportunities() {
        
        Test.startTest();
        System.assertEquals(0, DM_Opportunity.getOpenOpportunities('test', 'test').size(), 'no opportunity created, no opportunity retrieved');
        System.assertEquals(0, DM_Opportunity.getOpenOpportunities(new Set<Id>{null}, new Set<Id>{null}).size(), 'no opportunity created, no opportunity retrieved');
        Test.stopTest();

    }
}