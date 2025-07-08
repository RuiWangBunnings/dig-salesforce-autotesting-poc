/**
 * @File Name          : WoOBFormOpportunityLWCController_Test.cls
 * @Description        : Covers test coverage for WoOBFormOpportunityLWCController apex class
 * @Author             : Sidney Garcia
 * @Group              : MS-AU
 * @Last Modified By   : Sidney Garcia
 * @Last Modified On   : 29/11/2021
 * @Modification Log   : 
 * Ver		Date			Author      		    Modification
 * 1.0		29/11/2021		Sidney Garcia    		Initial Version
**/
@isTest
public class WOBFormOpportunityLWCController_Test {
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
        

        OpportunityContactRole ocrRecord = new OpportunityContactRole();
        ocrRecord.ContactId = contactList[0].Id;
        ocrRecord.OpportunityId = oppList[0].Id;
        
        insert ocrRecord;            

    }
    @istest 
    public static void testGetRelatedOpportunities(){
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> relatedOppList = new List<Opportunity>();
        Test.startTest();
        try{
            relatedOppList = WOBFormOpportunityLWCController.getRelatedOpportunities(projectRecord.Id, accountRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(1, relatedOppList.size());
    }
    
    @istest 
    public static void testGetRelatedOpportunitiesCatch(){
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> oppListToDelete = [SELECT ID FROM Opportunity LIMIT 100];
        delete oppListToDelete;
        List<Opportunity> relatedOppList = new List<Opportunity>();
        Test.startTest();
        try{
            relatedOppList = WOBFormOpportunityLWCController.getRelatedOpportunities(projectRecord.Id, accountRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assertEquals(0, relatedOppList.size());
    }
    
    @istest 
    public static void testCheckExistingOpportunityContactRole(){
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        Opportunity oppRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean hasExistingOCR = false;
        Test.startTest();
        try{
            hasExistingOCR = WOBFormOpportunityLWCController.checkExistingOpportunityContactRole(oppRecord.Id, contactRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assertEquals(true, hasExistingOCR);
    }
    
    @istest 
    public static void testCheckExistingOpportunityContactRoleCatch(){
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        User userRecord = [SELECT Id FROM User LIMIT 1];
        List<Contact> contactToDelete = [SELECT Id FROM Contact LIMIT 10];
        delete contactToDelete;
        Boolean hasExistingOCR = false;
        List<Contact> contactList = TestDataFactory.createContacts(accRecord.Id, userRecord.Id, 1);
        insert contactList;
        
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        Opportunity oppRecord = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try{
            hasExistingOCR = WOBFormOpportunityLWCController.checkExistingOpportunityContactRole(oppRecord.Id, contactRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assertNotEquals(true, hasExistingOCR);
    }
    
    @istest 
    public static void testGetLoggedInUserProfileName(){
        Profile userProfile = [SELECT Id,Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String profileNameToCompare;
        String loggedInUserProfileName;
        Test.startTest();
        try{
            profileNameToCompare = userProfile.Name;
            loggedInUserProfileName = WOBFormOpportunityLWCController.getLoggedInUserProfileName();
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assertEquals(profileNameToCompare, loggedInUserProfileName);
    }
    
    @istest 
    public static void testGetEstimatedAmountOppOffer(){
        String oppOffer = 'Flooring';
        WoB_S_I_Opp_Offer_Estimate_Amount__mdt oppOfferEstimateAmount = new WoB_S_I_Opp_Offer_Estimate_Amount__mdt();
        Test.startTest();
        try{
            oppOfferEstimateAmount = WOBFormOpportunityLWCController.getEstimatedAmountOppOffer(oppOffer);
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(oppOfferEstimateAmount.Estimated_Amount__c == 4000);
    }
    
    @istest 
    public static void testGetTactileOppOfferUrl(){
        String projectState = 'NSW';
        Initialisation__mdt wobOppOfferTactile = new Initialisation__mdt();
        Test.startTest();
        try{
            wobOppOfferTactile = WOBFormOpportunityLWCController.getTactileOppOfferUrl();
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(wobOppOfferTactile != null);
    }
    
    @istest 
    public static void testGetGarageDoorOfferUrls(){
        Profile userProfile = [SELECT Id,Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String projectState = 'NSW';
        Initialisation__mdt garageDoorUrls = new Initialisation__mdt();
        Test.startTest();
        try{
            garageDoorUrls = WOBFormOpportunityLWCController.getGarageDoorOfferUrls();
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(garageDoorUrls != null);
    }
    
    @istest 
    public static void testGetOpportunityOfferVisibilityByProjectState(){
        Profile userProfile = [SELECT Id,Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String projectState = 'NSW';
        WoB_Opp_Offer_Visibility_Mapping__mdt oppOfferVisibility = new WoB_Opp_Offer_Visibility_Mapping__mdt();
        Test.startTest();
        try{
            oppOfferVisibility = WOBFormOpportunityLWCController.getOpportunityOfferVisibilityByProjectState(projectState,userProfile.Name);
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(oppOfferVisibility != null);
    }
}