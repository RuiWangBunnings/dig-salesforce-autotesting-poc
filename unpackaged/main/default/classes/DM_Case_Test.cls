/*******************************************************************************************************
* Class Name      	: DM_Case_Test
* Description		: Test class for DM_Case
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-06-15
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-15		1000				Initial version
******************************************************************************************************/
@isTest
public class DM_Case_Test {
    @isTest
    public static void testGetCases() {
        
        Test.startTest();
        System.assertEquals(0, DM_Case.getCases('test', 'test').size(), 'no case created, no case retrieved');
        System.assertEquals(0, DM_Case.getCases(new Set<Id>{null}, new Set<Id>{null}).size(), 'no case created, no case retrieved');
        System.assertEquals(0, DM_Case.getOpenCases(new Set<Id>{null}, new Set<Id>{null}).size(), 'no case created, no case retrieved');
        Test.stopTest();

    }
}