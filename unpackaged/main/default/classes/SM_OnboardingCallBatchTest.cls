/*******************************************************************************************************
* Class Name      	: SM_OnboardingCallBatchTest
* Description		: Test class for SM_OnboardingCallBatch
* Author          	: Simplus MS
* Created On      	: 26/08/2021	
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            26/08/2021		1000				Initial version - created test class for SM_OnboardingCallBatch
* Simplus MS 			09/09/2021		2000				Added onBoardingTaskCreationBulkTest for CCRM15-170
* Bunnings Dev			05/09/2022		3000				SFSUP-678 - Updated number of Stores creation to fix CPU limit error
******************************************************************************************************/
@isTest
public class SM_OnboardingCallBatchTest {
    @testSetup static void setup() {                
        // Account Data Creation
        List<Account> acctList = TestDataFactory.createAccounts(1);
        insert acctList;
        
        // Store Data Creation        
        // SFSUP-678
        //List<Store__c> storeList = TestDataFactory.createStores(200);
        List<Store__c> storeList = TestDataFactory.createStores(20);
        insert storeList;
        
        // Segment Data Creation
        List<Segment__c> segmentList = new List<Segment__c>();
        for (Integer i = 0; i < 20; i++) {
            Segment__c segment = new Segment__c();
            segment.Name = 'Test';
            segment.Status__c = 'Active';
            segment.Segment_Group__c = 'Builders';
            segmentList.add(segment);
        }
        insert segmentList;
    }
    
    @isTest
    public static void onBoardingTaskCreationTest() {
        
        List<Integer> taskAdditionalDaysList = new List<Integer>();
        Datetime LastDate= System.today().toStartOfMonth() +date.daysInMonth(System.today().toStartOfMonth().year(), System.today().toStartOfMonth().month())-3;//4
        Date myDate = date.newinstance(LastDate.year(), LastDate.month(), LastDate.day());
        Map<Id, Powerpass_Assignment_Rule__mdt> ruleMap = new Map<Id, Powerpass_Assignment_Rule__mdt>();
        
        // Get the MetaData
        List<OnBoardingCallDueDates__mdt> forDueDatesList = [SELECT DeveloperName, Add_Days__c FROM OnBoardingCallDueDates__mdt WHERE DeveloperName = 'Task_Additional_Days'];
        for (OnBoardingCallDueDates__mdt days : forDueDatesList) {
            taskAdditionalDaysList.add(Integer.valueof(days.Add_Days__c));//Trim use to convert string to integer
        }
        
        // Store Data Updation
        Store__c stores = [SELECT Id, Engagement_Model__c, Status__c FROM Store__c LIMIT 1];
        stores.Engagement_Model__c = 'New';
        stores.Status__c = 'Active';
        update stores;
        
        // Get Segment Data
        Segment__c segments = [SELECT Id, Segment_Group__c FROM Segment__c LIMIT 1];
        
        // Account Data Updation
        Account acct = [SELECT Id, PowerPass_Account_Created_Date__c, OwnerId, Phone, Country__c, Onboarding_Status__c FROM Account LIMIT 1];
        acct.PowerPass_Account_Created_Date__c = myDate;
        acct.Type = '30Day';
        acct.Secondary_Segment__c = segments.Id;
        acct.Home_Store__c = stores.Id;
        acct.Credit_Limit__c = 10000;
        acct.Do_Not_Call__c = false;
        acct.ParentId = null;
        acct.Power_Pass_Account_Number__c = '2323232';
        acct.PowerPass_Account_Created_Date__c = System.today().addDays(-1);
        update acct;
        
        Test.startTest();        
            Database.executeBatch(new SM_OnboardingCallBatch());
            
            acct.PowerPass_Account_Created_Date__c = myDate;
            Update acct;
            String dateStr = LastDate.format('dd/MM/yyyy');
            Database.executeBatch(new SM_OnboardingCallBatch(dateStr));  
            
            SchedulableContext sc = null;
            SM_OnboardingCallBatch s = new SM_OnboardingCallBatch();
            s.execute(sc);		
        Test.stopTest();  
        
        Account accUpdated = [SELECT Id, Name, Onboarding_Status__c FROM Account LIMIT 1];
        System.assertEquals('Onboarding Task Created', accUpdated.Onboarding_Status__c);
    }
    
    @isTest
    public static void onBoardingTaskCreationBulkTest() {
        
		Datetime LastDate= System.today().toStartOfMonth() +date.daysInMonth(System.today().toStartOfMonth().year(), System.today().toStartOfMonth().month())-3;//4
        Date myDate = date.newinstance(LastDate.year(), LastDate.month(), LastDate.day());
        List<Integer> taskAdditionalDaysList = new List<Integer>();
        Map<Id, Powerpass_Assignment_Rule__mdt> ruleMap = new Map<Id, Powerpass_Assignment_Rule__mdt>();
        
        // Get the MetaData
        List<OnBoardingCallDueDates__mdt> forDueDatesList = [SELECT DeveloperName, Add_Days__c FROM OnBoardingCallDueDates__mdt WHERE DeveloperName = 'Task_Additional_Days'];
        for (OnBoardingCallDueDates__mdt days : forDueDatesList) {
            taskAdditionalDaysList.add(Integer.valueof(days.Add_Days__c));//Trim use to convert string to integer
        }
        
        // Store Data Updation
        // SFSUP-678
        //List<Store__c> storesList = [Select Id,Engagement_Model__c,Status__c from Store__c Limit 200];
        List<Store__c> storesList = [SELECT Id, Engagement_Model__c, Status__c FROM Store__c LIMIT 20];
        List<Store__c> updateStoresList = new List<Store__c>();
        for (Store__c stores : storesList) {
            stores.Engagement_Model__c = 'New';
            stores.Status__c = 'Active';
            updateStoresList.add(stores);
        }
        
        // Get Segment Data
        // SFSUP-678
        //List<Segment__c> segmentsList = [Select Id,Segment_Group__c	from Segment__c limit 200];
        List<Segment__c> segmentsList = [SELECT Id, Segment_Group__c FROM Segment__c LIMIT 20];
        //Account Data Mapping
        List<Account> acctList = new List<Account>();
        // SFSUP-678
        //for(Integer i = 0; i < 200; i++) {
        for (Integer i = 0; i < 20; i++) {
            Account newAcc = new Account(
                Name = 'TestCompany' + i,
                BillingCity = 'Melbourne',
                BillingCountry = 'AUS',
                BillingPostalCode = '3000',
                BillingState = 'VIC',
                BillingStreet = 'Collins St',
                Country__c = 'Australia',
                Account_Status__c = 'Active',
                Type = '30Day',
                Secondary_Segment__c = segmentsList[i].Id,
                Home_Store__c = storesList[i].Id,
                Credit_Limit__c = 10000,
                Do_Not_Call__c = false,
                ParentId = null,
                Power_Pass_Account_Number__c = '2323232'+i,
                PowerPass_Account_Created_Date__c = System.today().addDays(-1)
            );
            acctList.add(newAcc);
        }
        
        Test.startTest();
            update updateStoresList;
            Insert acctList;
            
            SM_OnboardingCallBatch myBatchObject = new SM_OnboardingCallBatch();
            Database.executeBatch(myBatchObject);
            
            List<Account> acctUpdateList1 = new List<Account>();
            for (Account act1 : acctList) {
                act1.PowerPass_Account_Created_Date__c = myDate;
                acctUpdateList1.add(act1);
            }
            Update acctUpdateList1;
            
            String dateStr = LastDate.format('dd/MM/yyyy');
            SM_OnboardingCallBatch myBatchObject1 = new SM_OnboardingCallBatch(dateStr);//e.parse('24/08/2021')
            Database.executeBatch(myBatchObject1);        
        Test.stopTest();    
    }
}