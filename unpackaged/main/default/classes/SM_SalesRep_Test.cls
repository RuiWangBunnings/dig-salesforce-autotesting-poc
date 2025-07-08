/*******************************************************************************************************
* Class Name      	: SM_SalesRep_Test
* Description		: Test class for SM_SalesRep
* Author          	: Simplus - Yi Zhang
* Created On      	: 25/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              25/08/2020		1000				Initial version
******************************************************************************************************/
@isTest
private class SM_SalesRep_Test {
    @isTest
    private static void testCUSalesRep() {
        // create users
        Profile profileSSM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_SALES_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileRCM = [SELECT Id FROM Profile WHERE Name = :Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
        Profile profileTS = [SELECT Id FROM Profile WHERE Name = :Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        List<User> users = TestDataFactory.createUsers(3, null);
        users[0].ProfileId = profileSSM.Id;
        users[1].ProfileId = profileRCM.Id;
        users[2].ProfileId = profileTS.Id;
        users[2].Location_Code__c = '0002';
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }

        // create stores
        List<Store__c> stores = TestDataFactory.createStores(1);
        stores[0].Location_Code__c = '0002';
        stores[0].Location_Type__c = 'Warehouse';
        insert stores;
        
        // create Sales Reps
        List<Sales_Rep__c> salesReps = new List<Sales_Rep__c>();
        salesReps.add(new Sales_Rep__c(Assigned_to_Team_Member__c = users[1].Id, Sales_Rep_Legacy_ID__c = '1213', Status__c = Constants.STATUS_ACTIVE));
        // salesReps.add(new Sales_Rep__c(Assigned_to_Store__c = stores[0].Id, Sales_Rep_Legacy_ID__c = '1214', Status__c = Constants.STATUS_ACTIVE));

        Test.startTest();
        insert salesReps;

        // try duplicate
        try {
            insert new Sales_Rep__c(Assigned_to_Store__c = stores[0].Id, Sales_Rep_Legacy_ID__c = '1214', Status__c = Constants.STATUS_ACTIVE);
        } catch(Exception e) {
            System.assert(e.getMessage().contains(SM_SalesRep.ERROR_SINGLE_ACTIVE_STORE_PER_CATEGORY), 'incorrect error message');
        }


        // try update
        salesReps.add([SELECT Id, Assigned_to_Store__c, Status__c FROM Sales_Rep__c WHERE Assigned_to_Store__c = :stores[0].Id LIMIT 1]);
        salesReps[0].Assigned_to_Team_Member__c = users[0].Id;
        salesReps[1].Status__c = Constants.STATUS_INACTIVE;
        update salesReps;

        update salesReps[1];

        salesReps[1].Status__c = Constants.STATUS_ACTIVE;
        update salesReps[1];
        salesReps[1].Sales_Rep_Legacy_ID__c = '4321';
        update salesReps[1];

        // try update to the same team member
        try {
            salesReps[1].Assigned_to_Store__c = null;
            salesReps[1].Assigned_to_Team_Member__c = users[0].Id;
            update salesReps[1];
        } catch(Exception e) {
            System.assert(e.getMessage().contains(SM_SalesRep.ERROR_SINGLE_ACTIVE_TEAM_MEMBER), 'incorrect error message');
        }



        Test.stopTest();
    }
}