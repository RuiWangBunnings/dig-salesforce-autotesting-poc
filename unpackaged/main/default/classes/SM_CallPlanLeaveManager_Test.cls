/*******************************************************************************************************
* Class Name      	: SM_CallPlanLeaveManager_Test
* Description		: Test class for SM_CallPlanLeaveManager
* Author          	: Simplus - Yi Zhang
* Created On      	: 13/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              13/07/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_CallPlanLeaveManager_Test {
    @isTest
    public static void testGetLeavesAndAMs() {
        // create AM/ASM user
        Profile amProfile = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        List<User> users = TestDataFactory.createUsers(2, amProfile.Id);
        Profile asmProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        users[1].ProfileId = asmProfile.Id;
        insert users;



        Test.startTest();
        // Sys Admin
        SM_CallPlanLeaveManager.getLeavesAndAMs(UserInfo.getUserId(), true);
        // AM
        SM_CallPlanLeaveManager.getLeavesAndAMs(users[0].Id, true);
        // ASM
        SM_CallPlanLeaveManager.getLeavesAndAMs(users[1].Id, true);
        Test.stopTest();
    }
}