/*******************************************************************************************************
* Class Name      	: SM_OperationsRegion_Test
* Description		: Test class for SM_OperationsRegion
* Author          	: Simplus - Philip Clark
* Created On      	: 22/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          22/06/2020		1000				Initial version
* Yi Zhang          	19/08/2020		2000				Revamp all resulted from requirement change
******************************************************************************************************/
@isTest
private class SM_OperationsRegion_Test {
    
    @isTest
    private static void testCUDOperationsRegions() {
        // create users
        Profile profileSSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileAreaBDM = [SELECT Id FROM Profile WHERE Name = :Constants.ORG_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileCCSManager = [SELECT Id FROM Profile WHERE Name = :Constants.NATIONAL_MANAGER_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(4, null);
        users[0].ProfileId = profileSSM.Id;
        users[1].ProfileId = profileRCM.Id;
        users[2].ProfileId = profileAreaBDM.Id;
        users[3].ProfileId = profileCCSManager.Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        // create store
        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';
        insert storeList;

        
        // add operations regions
        List<Operations_Region__c> opRegs = new List<Operations_Region__c>();
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'SSM', Team_Member__c = users[0].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'RCM', Team_Member__c = users[1].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'Area BDM', Team_Member__c = users[2].Id));
        opRegs.add(new Operations_Region__c(Name = 'NSW', Role__c = 'CCS Manager', Team_Member__c = users[3].Id));

        Test.startTest();
        insert opRegs;

        opRegs[0].Team_Member__c = users[1].Id;
        try {
            update opRegs[0];
        } catch(Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            System.assert(e.getMessage().contains('SSM'), 'Incorrect validation error');
        }

        delete opRegs[3];

        opRegs[0].Role__c = 'CCS Manager';
        opRegs[0].Team_Member__c = users[3].Id;
        update opRegs[0];

        Test.stopTest();
    }
}