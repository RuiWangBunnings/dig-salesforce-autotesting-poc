/**
 * @File Name          : WOBFormAuraController_Test.cls
 * @Description        : Covers test coverage for WobFormAuraController apex class
 * @Author             : Sidney Garcia
 * @Group              : MS-AU
 * @Last Modified By   : Sidney Garcia
 * @Last Modified On   : 29/11/2021
 * @Modification Log   : 
 * Ver		Date			Author      		    Modification
 * 1.0		29/11/2021		Sidney Garcia    		Initial Version
**/
@isTest
public class WOBFormAuraController_Test {
	@testSetup static void setupmethod() {
        // create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        User u = TestDataFactory.createUsers(1, p.Id)[0];

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {        
        	insert u;
        }        
        
		List<Account> accountList = TestDataFactory.createAccounts(1);
        insert accountList;
        
        List<Contact> contactList = TestDataFactory.createContacts(accountList[0].Id, u.Id, 1);
        insert contactList;
        
        List<Project__c> projectList = TestDataFactory.createProject(1);
        for(Project__c pro : projectList){
            pro.Main_Account__c = accountList[0].Id;
            pro.Selected_Account__c = accountList[0].Id;
            pro.Selected_Contact__c = contactList[0].Id;
        }
        insert projectList;
        
        
    }
    
    @istest 
    public static void testGetInitialAccountId(){
        Account accountRecord = [SELECT ID FROM Account LIMIT 1];
        Contact contactRecord = [SELECT ID FROM Contact LIMIT 1];
        Project__c projectRecord = [SELECT Id, Selected_Contact__c, Selected_Account__c FROM Project__c LIMIT 1];
        Project__c projectToAssert = new Project__c();
        Test.startTest();
        try{
            projectToAssert = WobFormAuraController.getInitialAccountId(projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assertEquals(accountRecord.Id, projectToAssert.Selected_Account__c);
        System.assertEquals(contactRecord.Id, projectToAssert.Selected_Contact__c);
        
        
    }
}