/*******************************************************************************************************
* Class Name      	: SM_PricingAssignment_Test
* Description		: Test class for SM_PricingAssignment
* Author          	: Simplus - Yi Zhang
* Created On      	: 06/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              06/10/2020		1000				Initial version
******************************************************************************************************/
@isTest
private class SM_PricingAssignment_Test {
	@isTest
    private static void testGetUmbrellaGroup() {
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(2);
        insert accounts;
        
        // create umbrella groups
        List<Umbrella_Group__c> groups = TestDataFactory.createUmbrellaGroups(1);
        insert groups;
        
        // create umbrella beneficiaries
        List<Umbrella_Beneficiary__c> beneficiaries = TestDataFactory.createUmbrellaBeneficiaries(accounts[0].Id, groups[0].Id, 1);
        insert beneficiaries;
        
        Test.startTest();
        List<List<String>> groupOwnerIds = SM_PricingAssignment.getUmbrellaGroup(new List<String>{accounts[0].Id});
        System.assertEquals(1, groupOwnerIds.size());
        try {
            SM_PricingAssignment.getUmbrellaGroup(null);
        } catch(Exception e) {}
        Test.stopTest();
    }
}