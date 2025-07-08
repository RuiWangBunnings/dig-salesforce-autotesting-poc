/*******************************************************************************************************
* Class Name      	: DM_AccountPlan_Test
* Description		: Test class for DM_AccountPlan
* Author            : Bunnings Dev - Jasper R Galapon
* Created On        : 04/08/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R Galapon      04/08/2022      1000                SFSUP-898 - Initial version
******************************************************************************************************/
@isTest
public class DM_AccountPlan_Test {

    @isTest
    public static void testGetAccountPlans() {
        Test.startTest();
            System.assertEquals(0, DM_AccountPlan.getAccountPlans(null, null, null).size(), 'No Account Plan created, No Accout Plan retrieved');
        Test.stopTest();
    }
}