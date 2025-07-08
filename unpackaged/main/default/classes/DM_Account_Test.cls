/*******************************************************************************************************
* Class Name        : DM_Account_Test
* Description       : Data Layer - Selector for Sobject Account
* Author            : Bunnings dev
* Created On        : 2024-10-14
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev              2024-10-14      1000                Initial version
******************************************************************************************************/
@isTest
public class DM_Account_Test {
	@testSetup 
    public static void testDataSetup() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        Profile p1 = [SELECT Id FROM Profile WHERE Name = :Constants.AU_ACCOUNT_MANAGER_PROFILENAME LIMIT 1];
        List<User> usersAccManger = TestDataFactory.createUsers(2, p1.Id);
        insert usersAccManger;
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[0].isActive=true;
        users[0].FirstName='Test Transfer';
        users[1].ManagerId = users[2].Id;
        users[1].isActive=true;
        users[2].ManagerId = users[3].Id;
        users[2].isActive=true;
        update users;
        
        User u = users[0];
        User u1 =usersAccManger[0];
        User newOwner = users[2];
        
        System.runAs(users[0]) {
            List<Account> accts = TestDataFactory.createAccounts(5);
            accts[0].Power_Pass_Account_Number__c ='657';
           // accts[0].Account_Transferrable__c = 'Yes';
            //accts[0].Transfer_approval_status__c = 'Submitted for approval';
            accts[1].Power_Pass_Account_Number__c ='6577';
            accts[1].Transfer_approval_status__c = 'Submitted for approval';
            accts[2].Power_Pass_Account_Number__c ='6579';
            accts[2].Transfer_approval_status__c = 'Submitted for approval';
            accts[3].Power_Pass_Account_Number__c ='65795';
            accts[3].Transfer_approval_status__c = 'Submitted for approval';
            accts[3].Country__c = 'New Zealand';
            accts[4].Power_Pass_Account_Number__c ='65799';
            accts[4].Transfer_approval_status__c = 'Submitted for approval';
            accts[4].Country__c = 'New Zealand';
            insert accts;
            
           
            

        }
            
    }
    
    @isTest
    private static void testgetAccountDetails() {
	
        Test.startTest();
      
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
		DM_Account.getAccountDetails(a.id);
		Test.stopTest();
    }
    
 @isTest
    private static void testgetAccount() {
	
        Test.startTest();
      
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
		DM_Account.getAccount(a.id);
		Test.stopTest();
    }    
    
    @isTest
    private static void testgetAccounts() {
	
        Test.startTest();
      List<String> accs = new List<String>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccounts(accs);
		Test.stopTest();
    }    
    
    
    @isTest
    private static void testgetAccountsBySet() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsBySet(accs);
		Test.stopTest();
    }    
    
    
     @isTest
    private static void testgetAccountsWithScheduledEngagementCall() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsWithScheduledEngagementCall(accs);
		Test.stopTest();
    }   
    
    @isTest
    private static void testgetSupplierAccountsByRegion() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getSupplierAccountsByRegion('Australia');
		Test.stopTest();
    }  
       @isTest
    private static void testgetAccountsWithoutChild() {
	
        Test.startTest();
      List<String> accs = new List<String>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsWithoutChild(accs);
		Test.stopTest();
    }     
    
     @isTest
    private static void testgetAccountsGroupedByParent() {
	
        Test.startTest();
      List<id> accs = new List<id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsGroupedByParent(accs);
		Test.stopTest();
    }    
    
     @isTest
    private static void testgetAccountWithContactsEngagementCallActivities() {
	
        Test.startTest();
      List<id> accs = new List<id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountWithContactsEngagementCallActivities(a.id);
		Test.stopTest();
    }   
    
         @isTest
    private static void testgetAccountsWithUmbBeneficiariesAndFutureActivities() {
	
        Test.startTest();
      List<Account> accs = new List<Account>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a);
		DM_Account.getAccountsWithUmbBeneficiariesAndFutureActivities(accs);
		Test.stopTest();
    }   
    
     @isTest
    private static void testgetAccountsWithSecondarySegment() {
	
        Test.startTest();
      List<Account> accs = new List<Account>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a);
		DM_Account.getAccountsWithSecondarySegment(accs);
		Test.stopTest();
    }  
    
    @isTest
    private static void testgetParentAccWithCustContracts() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getParentAccWithCustContracts(accs);
		Test.stopTest();
    }  
    
    @isTest
    private static void testgetChildAccWithCustContracts() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getChildAccWithCustContracts(accs);
		Test.stopTest();
    }  
    
    @isTest
    private static void testgetParentAccWithCustContractsAndCPL() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getParentAccWithCustContractsAndCPL(accs);
		Test.stopTest();
    } 
    
     @isTest
    private static void testgetChildAccWithCustContractsAndCPL() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getChildAccWithCustContractsAndCPL(accs);
		Test.stopTest();
    } 
    
     @isTest
    private static void testgetAccountsWithCustomerSpecialBuys() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsWithCustomerSpecialBuys(a.id);
		Test.stopTest();
    } 
    
    @isTest
    private static void testgetCustomerAndProspectAccountsOwnedBy() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getCustomerAndProspectAccountsOwnedBy(a.id);
		Test.stopTest();
    } 
    
     @isTest
    private static void testgetAccountsWithCustomerEngagementCallThisMonth() {
	
        Test.startTest();
      List<Id> accs = new List<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsWithCustomerEngagementCallThisMonth(accs);
		Test.stopTest();
    } 
    
     @isTest
    private static void testgetAccountsOwnedBy() {
	
        Test.startTest();
      List<Id> accs = new List<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountsOwnedBy(accs);
		Test.stopTest();
    } 
    
    
     @isTest
    private static void testgetAccountWithContactsCallActivities() {
	
        Test.startTest();
      Set<Id> accs = new Set<Id>();
        Account a = [SELECT id,Name,Power_Pass_Account_Number__c FROM Account Limit 1];
		System.debug('Account a:'+a);
        accs.add(a.id);
		DM_Account.getAccountWithContactsCallActivities(a.id,'type','reason');
		Test.stopTest();
    } 
    
    @isTest
    private static void testgetAccountIDByPowerPassNumbers() {
	
        Test.startTest();
      Set<string> accs = new Set<String>();
        
        accs.add('657');
		DM_Account.getAccountIDByPowerPassNumbers(accs);
		Test.stopTest();
    } 
    
    @isTest
    private static void testgetAccountsByPowerPassNumbers() {
	
        Test.startTest();
      Set<string> accs = new Set<String>();
        
        accs.add('657');
		DM_Account.getAccountsByPowerPassNumbers(accs);
		Test.stopTest();
    } 

    @isTest
    static void testGetPersonAccountsBasedOnEmailOrMobile(){

        Test.startTest();
         DM_Account.getPersonAccountsBasedOnEmailOrMobile('matchingEmail', 'matchingMobilePhone');
        Test.stopTest();
    }
}