/*******************************************************************************************************
* Class Name      	: DM_CustomerContract_Test
* Description		: Test class for DM_CustomerContract
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-06-15
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-06-15		1000				Initial version
* Simplus MS            2021-01-04      1001                CCRM-170 - Changes made to cover the DM_CustomerContract methods.
******************************************************************************************************/
@isTest
public class DM_CustomerContract_Test {
    
    /**
    * @description - New changes made to cover the DM_CustomerContract methods
    * @author Simplus MS | 25/01/2021 
    **/
    @isTest
    public static void testGetCustomerContracts() {

        List<Account> accounts = TestDataFactory.createAccounts(1);
        accounts[0].On_Contract__c = Label.No;
        insert accounts;
        
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Status__c = Label.Active;
        insert contracts;
        
        List<Customer_Contract__c> customerConList = TestDataFactory.createCustomerContracts(accounts[0].ID, new List<ID> {contracts[0].ID});
        insert customerConList; 

        Profile p_lcm = [SELECT Id FROM Profile WHERE Name =: Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME LIMIT 1];
		List<User> user_lcm = TestDataFactory.createUsers(1, p_lcm.Id);
		
        User thisUser_lcm = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser_lcm) {
            insert user_lcm;
        }

        Set<Id> ownerIds = new Set<Id>();
        for(User u : user_lcm){
            ownerIds.add(u.Id);
        }

        Set<Id> acctIds = new Set<Id>();
        Set<String> contractIds = new Set<String>();

        for(Account a : accounts){
            acctIds.add(a.Id);
        }

        for(Customer_Contract__c cc : customerConList){
            contractIds.add(cc.Id);
        }
        
        Test.startTest();
        System.assertEquals(0, DM_CustomerContract.getNonExpiredCustomerContracts(null).size(), 'no customer contract created, no customer contract retrieved');
        System.assertEquals(0, DM_CustomerContract.getNonExpiredCustomerContracts(new Set<Id>{null}, new Set<Id>{null}).size(), 'no customer contract created, no customer contract retrieved');
        
        DM_CustomerContract.getCustomerContracts(accounts[0].Id);
        DM_CustomerContract.getNonExpiredCustContracts(acctIds, ownerIds);
        DM_CustomerContract.getNonExpiredCustomerContracts(accounts[0].Id);
        DM_CustomerContract.getCustomerContracts(contractIds);

        Test.stopTest();

    }
}