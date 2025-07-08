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
public class WOBFormSummaryLWCController_Test {
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
        
        
        ContentVersion file=new ContentVersion(); 
        file.Title='test file'; 
        file.PathOnClient= file.Title + '.txt'; 
        Blob bodyBlob=Blob.valueOf('test file content'); 
        file.VersionData=bodyBlob; 
        file.origin = 'H';
        insert file;
        
        ContentDocumentLink link=new ContentDocumentLink();
        link.contentdocumentid=[select contentdocumentid from contentversion where id =: file.id].contentdocumentid;
        link.ShareType = 'I';
        link.Visibility = 'AllUsers';  
        link.LinkedEntityId = projectList[0].id;
        insert link;   
        
        
        List<Opportunity> oppList = TestDataFactory.createOpenOpportunities(accountList[0].Id, u.Id, 1);
        Id beaumontOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Beaumont Tiles Opportunity').getRecordTypeId();
        for(Integer i = 0; i < oppList.size(); i++){
            oppList[i].Project__c = projectList[i].Id;
            oppList[i].Current_Supplier__c = 'Test Supplier';
            oppList[i].Builder_Type__c = 'Medium';
            oppList[i].Dwelling_Type__c = 'House';
            oppList[i].Quality__c = 'Best';
            oppList[i].Site_Address__c = 'Test Site Address';
            oppList[i].Other__c = 'Test';
            oppList[i].Additional_Notes__c = 'Test';
            oppList[i].Created_from_WOB__c = true;
            oppList[i].Quote_Email_Sent__c = false;
            oppList[i].RecordTypeId = beaumontOppId;
        }
        insert oppList;
        
        List<Opportunity> oppListFrameTruss = TestDataFactory.createOpenOpportunities(accountList[0].Id, u.Id, 1);
        Id frameTrussId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Frame & Truss Opportunity').getRecordTypeId();
        for(Integer i = 0; i < oppListFrameTruss.size(); i++){
            oppListFrameTruss[i].Project__c = projectList[i].Id;
            oppListFrameTruss[i].Name = 'Test Frame Truss Opp';
            oppListFrameTruss[i].Site_Address__c = 'Test Site Address';
            oppListFrameTruss[i].Created_from_WOB__c = true;
            oppListFrameTruss[i].Quote_Email_Sent__c = false;
            oppListFrameTruss[i].RecordTypeId = frameTrussId;
        }
        insert oppListFrameTruss;
        System.debug('sid oppListFrameTruss ' + oppListFrameTruss);

        List<Opportunity> supplyInstallOppList = TestDataFactory.createOpenOpportunities(accountList[0].Id, u.Id, 18);
        Id supplyInstallOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Supply & Install Opportunity').getRecordTypeId();
        for(Integer i = 0; i < supplyInstallOppList.size(); i++){
            supplyInstallOppList[i].Project__c = projectList[0].Id;
            supplyInstallOppList[i].Name = 'Test Supply & Install Opp'+i;
            supplyInstallOppList[i].Site_Address__c = 'Test Site Address'+i;
            supplyInstallOppList[i].Created_from_WOB__c = true;
            supplyInstallOppList[i].Quote_Email_Sent__c = false;
            supplyInstallOppList[i].RecordTypeId = supplyInstallOppId;
            supplyInstallOppList[i].Estimated_Amount__c = 50000;

            if(i == 0){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Plasterboard & Insulation';
            }else if(i == 1){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Insulation Only';
            }else if(i == 2){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Staircases';
            }else if(i == 3){
                supplyInstallOppList[i].State__c = 'VIC';
                supplyInstallOppList[i].Offer__c = 'HVAC';
            }else if(i == 4){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Balustrading';
            }else if(i == 5){
                supplyInstallOppList[i].State__c = 'VIC';
                supplyInstallOppList[i].Offer__c = 'Cladding';
            }else if(i == 6){
                supplyInstallOppList[i].State__c = 'VIC';
                supplyInstallOppList[i].Offer__c = 'Flooring';
            }else if(i == 7){
                supplyInstallOppList[i].State__c = 'VIC';
                supplyInstallOppList[i].Offer__c = 'Garage Door';
            }else if(i == 8){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Joinery';
            }else if(i == 9){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Render & Texture';
            }else if(i == 10){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Residential Lifts';
            }else if(i == 11){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Shower Screens';
            }else if(i == 12){
                supplyInstallOppList[i].State__c = 'QLD';
                supplyInstallOppList[i].Offer__c = 'Tactile';
            }else if(i == 13){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Wardrobe';
            }else if(i == 14){
                supplyInstallOppList[i].State__c = 'WA';
                supplyInstallOppList[i].Offer__c = 'Waterproofing/Sealing';
            }else if(i == 15){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Window Furnishing';
            }else if(i == 16){
                supplyInstallOppList[i].State__c = 'NSW';
                supplyInstallOppList[i].Offer__c = 'Windows';
            }else if(i == 17){
                supplyInstallOppList[i].State__c = 'VIC';
                supplyInstallOppList[i].Offer__c = 'AAC - Nasahi Panel';
            }
        }
        insert supplyInstallOppList;
        System.debug('supplyInstallOppList: ' + supplyInstallOppList);

        List<Opportunity_Offer__c> oppOfferList = new List<Opportunity_Offer__c>();
        for(Integer i = 0; i < supplyInstallOppList.size(); i++){
            oppOfferList.add(new Opportunity_Offer__c(Name = 'Test Supply & Install Opp Offer'+i, Opportunity__c = supplyInstallOppList[i].Id));
        }
        insert oppOfferList;

        OpportunityContactRole ocrRecord = new OpportunityContactRole();
        ocrRecord.ContactId = contactList[0].Id;
        ocrRecord.OpportunityId = oppList[0].Id;
        
        insert ocrRecord;
    }
    
    @istest 
    public static void testUpdateWobOppStagesAndSendEmail(){
        List<String> oppIdList = new List<String>();
        List<Opportunity> oppList = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Beaumont Tiles Opportunity' LIMIT 100];
        for(Opportunity opp : oppList){
            oppIdList.add(opp.Id);
        }
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(oppIdList, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        List<Opportunity> oppListUpdated = [SELECT Id, RecordType.Name, Quote_Email_Sent__c FROM Opportunity WHERE RecordType.Name = 'Beaumont Tiles Opportunity' LIMIT 100];
        
        for(Opportunity opp : oppListUpdated){
            System.assertEquals(true, opp.Quote_Email_Sent__c);
        }
    }
    
    @istest 
    public static void testFrameTrussOpp(){
        List<String> oppIdList = new List<String>();
        List<Opportunity> oppList = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Frame & Truss Opportunity' LIMIT 100];
        System.debug('Sid oppList ' + oppList);
        for(Opportunity opp : oppList){
            oppIdList.add(opp.Id);
        }
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(oppIdList, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        List<Opportunity> oppListUpdated = [SELECT Id, StageName, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Frame & Truss Opportunity' LIMIT 100];
        
        for(Opportunity opp : oppListUpdated){
            System.assertEquals('Qualifying', opp.StageName);
        }
    }

    @istest 
    public static void testSupplyInstallOpp(){
        /*List<String> oppIdList = new List<String>();
        List<Opportunity> oppList = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' LIMIT 100];
        System.debug('oppList ' + oppList);
        for(Opportunity opp : oppList){
            oppIdList.add(opp.Id);
        }*/
        List<Opportunity> oppPlasterboardAndInsulation = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Plasterboard & Insulation' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppPlasterboardAndInsulation[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
        /*List<Opportunity> oppListUpdated = [SELECT Id, StageName, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' LIMIT 100];
        
        for(Opportunity opp : oppListUpdated){
            System.assertEquals('Submitted to S&I', opp.StageName);
        }*/
    }

    @istest 
    public static void testInsulationOnlyOpp(){
        List<Opportunity> oppInsulationOnly = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Insulation Only' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppInsulationOnly[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testStaircasesOpp(){
        List<Opportunity> oppStaircases = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Staircases' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppStaircases[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testHVACOpp(){
        List<Opportunity> oppHVAC = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'HVAC' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppHVAC[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testBalustradingOpp(){
        List<Opportunity> oppBalustrading = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Balustrading' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppBalustrading[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testCladdingOpp(){
        List<Opportunity> oppCladding = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Cladding' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppCladding[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testFlooringOpp(){
        List<Opportunity> oppFlooring = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Flooring' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppFlooring[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testGarageDoorOpp(){
        List<Opportunity> oppGarageDoor = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Garage Door' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppGarageDoor[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testJoineryOpp(){
        List<Opportunity> oppJoinery = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Joinery' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppJoinery[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testRenderAndTextureOpp(){
        List<Opportunity> oppRenderTexture = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Render & Texture' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppRenderTexture[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testResidentialLiftsOpp(){
        List<Opportunity> oppResidentialLifts = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Residential Lifts' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppResidentialLifts[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testShowerScreensOpp(){
        List<Opportunity> oppShowerScreens = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Shower Screens' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppShowerScreens[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testTactileOpp(){
        List<Opportunity> oppTactile = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Tactile' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppTactile[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testWardrobeOpp(){
        List<Opportunity> oppWardrobe = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Wardrobe' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppWardrobe[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testWaterproofingSealingOpp(){
        List<Opportunity> oppWaterproofingSealing = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Waterproofing/Sealing' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppWaterproofingSealing[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testWindowFurnishingOpp(){
        List<Opportunity> oppWindowFurnishing = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Window Furnishing' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppWindowFurnishing[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @istest 
    public static void testWindowsOpp(){
        Opportunity oppInsulationOnly = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'Windows' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppInsulationOnly.Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
    }

    @istest 
    public static void testAACNasahiPanelOpp(){
        List<Opportunity> oppAACNasahiPanel = [SELECT ID FROM Opportunity WHERE RecordType.Name = 'Supply & Install Opportunity' AND Offer__c = 'AAC - Nasahi Panel' LIMIT 100];

        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        try{
            WOBFormSummaryLWCController.updateWobOppStagesAndSendEmail(new List<String>{oppAACNasahiPanel[0].Id}, projectRecord.Id);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }
    
}