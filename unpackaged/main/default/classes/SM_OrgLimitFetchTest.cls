/*******************************************************************************************************
* Class Name      	: SM_OrgLimitFetchTest
* Description		: Test class for SM_OrgLimitFetch
* Author          	: Simplus MS-AU
* Created On      	: 02-June-2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS-AU			02/Jun/20201	1000				Initial version
******************************************************************************************************/
@istest
private class SM_OrgLimitFetchTest {
    @istest
    static void testOne() {
        SM_OrgLimitFetch.schedule(1, 'Test Job Name ' + String.valueOf(System.currentTimeMillis()));
        
        Test.startTest();
        SM_OrgLimitFetch job = new SM_OrgLimitFetch();
        job.execute(null);
        Test.stopTest();
        
        Org_Limit__c[] oLimits = [select id from Org_Limit__c];
        System.assert(oLimits.size()>0);
    }
}