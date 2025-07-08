/*******************************************************************************************************
* Class Name      	: TaskTriggerHandlerTest
* Description		: Test class for TaskTriggerHandler
* Author          	: Simplus MS
* Created On      	: 31/05/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            31/05/2021		1000				Initial version - created separate test class for the task trigger
******************************************************************************************************/
@isTest
private class TaskTriggerHandlerTest {
    
    @isTest
    private static void testAfterUpdate() {
        Test.startTest();
        List<Account> accts = TestDataFactory.createAccounts(1); 
        Account account = accts[0];
        account.OwnerId = UserInfo.getUserId();
        account.Power_Pass_Account_Number__c = '23232';
        account.PowerPass_Account_Created_Date__c = System.today().addDays(-1);
        insert account;
        
        Account newAcc = new Account(
            Name = 'Test Company 1' ,
            BillingCity='Melbourne',
            BillingCountry='AUS',
            BillingPostalCode='3000',
            BillingState='VIC',
            BillingStreet='Collins St',
            Country__c='Australia',
            Account_Status__c = 'Active',
            OwnerId = UserInfo.getUserId(),
            Power_Pass_Account_Number__c = '23232666',
            PowerPass_Account_Created_Date__c = System.today().addDays(-1)
        );
        insert newAcc;
        
		Date LastDate= account.PowerPass_Account_Created_Date__c.toStartOfMonth() +date.daysInMonth(account.PowerPass_Account_Created_Date__c.toStartOfMonth().year(), account.PowerPass_Account_Created_Date__c.toStartOfMonth().month())-4;//4

        Task onboardingTask = new Task(
            RecordTypeId = DM_RecordType.rtId_Task_OnboardingCall,
            ActivityDate = Date.today().addDays(1),
            IsRecurrence = false,
            IsReminderSet = false,
            OwnerId = account.OwnerId,
            Phone__c = account.Phone,
            Subject = 'ON BOARDING',
            Type = 'Phone',
            WhatId = account.Id,
            Sub_type__c = 'Onboarding'
        );
        
        insert onboardingTask;
        onboardingTask.Description = 'Test';
        update onboardingTask;
        
         Task onboardingTask1 = new Task(
            RecordTypeId = DM_RecordType.rtId_Task_OnboardingCall,
            ActivityDate = LastDate,
            IsRecurrence = false,
            IsReminderSet = false,
            OwnerId = newAcc.OwnerId,
            Phone__c = newAcc.Phone,
            Subject = 'ON BOARDING',
            Type = 'Phone',
            WhatId = newAcc.Id,
            Sub_type__c = 'Onboarding'
        );
        insert onboardingTask1;
        onboardingTask1.Description = 'Test1';
        update onboardingTask1;
        
        Test.stopTest();
        
        Account acct = [Select Id, Onboarding_Status__c From Account Where Id =: onboardingTask.WhatId limit 1];
        System.assertEquals('Onboarding Task Created', acct.Onboarding_Status__c, 'Onboarding task not created.');
        
        
    }
    
}