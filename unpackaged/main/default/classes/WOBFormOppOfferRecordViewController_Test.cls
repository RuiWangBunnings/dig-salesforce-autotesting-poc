@isTest
public class WOBFormOppOfferRecordViewController_Test {
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
        
        Opportunity_Offer__c oppOffer = new Opportunity_Offer__c();
        oppOffer.Project__c = projectList[0].Id;
        oppOffer.Opportunity__c = oppList[0].Id;
        
        insert oppOffer;

    }
    
    @isTest
    private static void getOpportunityOfferId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity_Offer__c oppOffer = [SELECT Id FROM Opportunity_Offer__c LIMIT 1];
        String oppOfferId;
        Test.startTest();
           oppOfferId = WOBFormOppOfferRecordViewController.getOpportunityOfferId(opp.Id);
        Test.stopTest();
        
        System.assert(oppOfferId == oppOffer.Id);

    }
}