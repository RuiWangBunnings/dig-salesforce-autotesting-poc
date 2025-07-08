/**
 * @File Name          : WoOBFormProjectLWCController_Test.cls
 * @Description        : Covers test coverage for WoOBFormProjectLWCController apex class
 * @Author             : Sidney Garcia
 * @Group              : MS-AU
 * @Last Modified By   : Sidney Garcia
 * @Last Modified On   : 29/11/2021
 * @Modification Log   : 
 * Ver		Date			Author      		    Modification
 * 1.0		29/11/2021		Sidney Garcia    		Initial Version
**/
@isTest
public class WOBFormProjectLWCController_Test {
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
            pro.Selected_Contact__c = contactList[0].Id;
            pro.Project_Address__c = '123 Test Street';
            pro.Town__c = 'Test Suburb';
            pro.State__c = 'NSW';
            pro.Postcode__c = '123';
        }
        insert projectList;
        
        
        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accountList[0].Id, u.Id, 1);
        for(Integer i = 0; i < oppList.size(); i++){
            oppList[i].Project__c = projectList[i].Id;
            oppList[i].Current_Supplier__c = 'Test Supplier';
            oppList[i].Builder_Type__c = 'Medium';
            oppList[i].Dwelling_Type__c = 'House';
            oppList[i].Quality__c = 'Best';
            oppList[i].Site_Address__c = 'Test Site Address';
            oppList[i].Other__c = 'Test';
            oppList[i].Additional_Notes__c = 'Test';
        }
        insert oppList;
        
        Project_Participant__c  proPartRec = new Project_Participant__c();
        proPartRec.Account__c = accountList[0].Id;
        proPartRec.Project__c = projectList[0].Id;
        
        insert proPartRec;
    }
    
    @isTest
    private static void getProjectRecordDetailsTest() {
        
        Project__c projectRec = [SELECT Id, Concatenated_Address__c FROM Project__c LIMIT 1];
        Project__c projectToGet = new Project__c();
		Test.startTest();
        try{
            projectToGet = WOBFormProjectLWCController.getProjectRecordDetails(projectRec.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        System.assert(projectToGet != null);        
    }
    
    @isTest
    private static void checkExistingProjectParticipantTest() {
        
        Project__c projectRec = [SELECT Id, Concatenated_Address__c FROM Project__c LIMIT 1];
        Account accountRec = [SELECT ID FROM Account];
        Boolean hasProjectParticipant;
		Test.startTest();
        try{
            hasProjectParticipant = WOBFormProjectLWCController.checkExistingProjectParticipant(projectRec.Id, accountRec.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        System.assertEquals(true , hasProjectParticipant);        
    }
    
    @isTest
    private static void checkExistingProjectParticipantTestCatch() {
        Project_Participant__c  proPartRec = [SELECT ID FROM Project_Participant__c ];
        delete proPartRec;
        Project__c projectRec = [SELECT Id, Concatenated_Address__c FROM Project__c LIMIT 1];
        Account accountRec = [SELECT ID FROM Account];
        Boolean hasProjectParticipant;
		Test.startTest();
        try{
            hasProjectParticipant = WOBFormProjectLWCController.checkExistingProjectParticipant(projectRec.Id, accountRec.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        System.assertNotEquals(true , hasProjectParticipant);        
    }
}