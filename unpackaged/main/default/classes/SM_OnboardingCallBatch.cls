/*******************************************************************************************************
* Class Name      	: SM_OnboardingCallBatch
* Description		: Batch Class to create onboarding tasks
* Author          	: Simplus - Simplus MS
* Created On      	: 23/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS			23/08/2021		1000				Initial version for SPRINT1_CCRM15-56 Changes to onboarding creation and due dates
* Simplus MS			03/09/2021		2000				Additional logic for CCRM15-149 Onboarding tasks at end of month
* Bunnings Dev          26/04/2022      3000                SFSUP-477 - Pilot of Predictive Model
* Bunnings Dev          01/09/2022      4000                SFSUP-678 - Reference the new digitally managed flag in account extension
******************************************************************************************************/
public class SM_OnboardingCallBatch implements Database.Batchable<sObject>, Schedulable
{
    Date powerPassAccountCreatedDate;
    String dateStr;
    public SM_OnboardingCallBatch(){
    //    this.powerPassAccountCreatedDate = null;
    }
    
    public SM_OnboardingCallBatch(string powerPassAccountCreatedDate) {
        
        this.powerPassAccountCreatedDate =  date.parse(powerPassAccountCreatedDate) != null ? date.parse(powerPassAccountCreatedDate) : null;
        dateStr = DateTime.newInstance(this.powerPassAccountCreatedDate.year(),this.powerPassAccountCreatedDate.month(),this.powerPassAccountCreatedDate.day()).format('yyyy-MM-dd');
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        // SFSUP-477 - Get predictive model config
        Predictive_Model__mdt pmModel;
        List<Predictive_Model__mdt> pm = [SELECT MasterLabel, QualifiedAPIName, Active__c, No_of_Days__c FROM Predictive_Model__mdt
                                     WHERE QualifiedAPIName = 'Digitally_Managed'];
        pmModel = pm[0];
        
        String accountQuery = 'SELECT Id, Account_Status__c, Home_Store__c, Country__c, Power_Pass_Account_Number__c, Do_Not_Call__c, ';
        accountQuery += 'Onboarding_Status__c, ParentId, OwnerId, Phone, CreatedDate, Type, Secondary_Segment__c, Credit_Limit__c, ';
        accountQuery += 'Secondary_Segment__r.Segment_Group__c, PowerPass_Account_Created_Date__c, Account_Extension__r.Digitally_Managed__c ';
        accountQuery += 'FROM Account ';
        accountQuery += 'WHERE Account_Status__c != \'' + 'Inactive' +'\' ';
        accountQuery += 'AND Account_Status__c != \'' + 'Terminated' +'\' ';
        accountQuery += 'AND RecordType.Name != \'' + 'Person Account' +'\'';
        accountQuery += 'AND Country__c != null AND Power_Pass_Account_Number__c != null ';
        accountQuery += 'AND Onboarding_Status__c = null AND Do_Not_Call__c = false AND ParentId = null';
        
        
        if(this.powerPassAccountCreatedDate != null) {
            accountQuery += ' AND Home_Store__c != null AND PowerPass_Account_Created_Date__c = '+dateStr;
        }
        else {
            // SFSUP-477 - Predictive Model
            System.debug('***Model Active: '+pmModel.Active__c);
            
            if (pmModel.Active__c) {
                Date dateToProcess = Date.today().addDays(-Integer.valueOf(pmModel.No_of_Days__c));
                
                System.debug('***Predictive Model On: '+pmModel.No_of_Days__c + ' / ' + dateToProcess);                
                
                // Commented for SFSUP-678
                //accountQuery += ' AND Digital_Managed__c = \'FALSE\' AND Home_Store__c != null AND PowerPass_Account_Created_Date__c <=: dateToProcess AND PowerPass_Account_Created_Date__c != null';
                // Added for SFSUP-678
                accountQuery += ' AND Account_Extension__r.Digitally_Managed__c = \'FALSE\' AND Home_Store__c != null AND PowerPass_Account_Created_Date__c <=: dateToProcess AND PowerPass_Account_Created_Date__c != null';
            } else {
                System.debug('***Predictive Model Off');
            	accountQuery += ' AND Home_Store__c != null AND PowerPass_Account_Created_Date__c = YESTERDAY AND PowerPass_Account_Created_Date__c != null';
            }
        }
        System.debug('accountQuery>> '+accountQuery);
        return Database.getQueryLocator(accountQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> accList) {
        Map<Id, Task> onboardingTasks = new Map<Id, Task>(); 
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Map<Id, Powerpass_Assignment_Rule__mdt> ruleMap = new Map<Id, Powerpass_Assignment_Rule__mdt>();
        Map<Id, Account> accountMap = new Map<Id, Account>(DM_Account.getAccountsWithSecondarySegment(accList));
        List<Id> storeIds = new List<String>();
        List<Integer> taskAdditionalDaysList = new List<Integer>();
        
        //Fetch Metadata which is use to add additional days to task due date
        List<OnBoardingCallDueDates__mdt> forDueDatesList = [SELECT DeveloperName,Add_Days__c from OnBoardingCallDueDates__mdt where DeveloperName = 'Task_Additional_Days'];
        for(OnBoardingCallDueDates__mdt days : forDueDatesList) {
            taskAdditionalDaysList.add(Integer.valueof(days.Add_Days__c));//convert string to integer
        }
        //Get All the Home Stores related to Account
        for(Account acct : accList) {
            storeIds.add(acct.Home_Store__c);
        }

        Map<Id, Store__c> storeMap = new Map<Id, Store__c>(DM_Store.getStoresWithActiveSMs(storeIds));
        System.debug('storeMap>> '+storeMap);
        for(Account acct : accList) {
            
            String storeModel = storeMap.get(acct.Home_Store__c).Engagement_Model__c;
            String accountType = storeModel == Constants.STORE_MODEL_OLD ? null : acct.Type;
            String segment = null;
            if(storeModel != Constants.STORE_MODEL_OLD && String.isNotBlank(acct.Secondary_Segment__c)) {
                segment = accountMap.get(acct.Id).Secondary_Segment__r.Segment_Group__c;
            }
            if(segment != null){
                segment = segment.toLowerCase();
            }
            String key = accountType + storeModel + segment + acct.Country__c;
            system.debug('key>> '+key);
            Double creditLimit = (acct.Credit_Limit__c == null) ? 0 : acct.Credit_Limit__c;
            if(DM_PowerpassAssignmentRule.ruleMap.containsKey(key)) {
                Powerpass_Assignment_Rule__mdt rule;
                for(Powerpass_Assignment_Rule__mdt par : DM_PowerpassAssignmentRule.ruleMap.get(key)) {
                    if(creditLimit >= par.Credit_Limit_Floor__c) {
                        system.debug('par>> '+par);
                        rule = par;
                        ruleMap.put(acct.Id, par);//ruleMap --> Test
                        break;
                    }
                }
            }
            
            if(ruleMap.containsKey(acct.Id) && ruleMap.get(acct.Id).Create_Onboarding_Task__c == true) {
                   Date powerPassAcctDate = date.newinstance(acct.PowerPass_Account_Created_Date__c.year(), acct.PowerPass_Account_Created_Date__c.month(), acct.PowerPass_Account_Created_Date__c.day());
                   Date powerPassAccountDate;
                   if(this.powerPassAccountCreatedDate != null) {
                       powerPassAccountDate = this.powerPassAccountCreatedDate;
                   }
                   else {
                       powerPassAccountDate = powerPassAcctDate;
                   }
                   onboardingTasks.put(acct.Id, new Task(
                       RecordTypeId = DM_RecordType.rtId_Task_OnboardingCall,
                       ActivityDate = powerPassAccountDate.addDays(taskAdditionalDaysList[0]),
                       IsRecurrence = false,
                       IsReminderSet = false,
                       OwnerId = acct.OwnerId,
                       Phone__c = acct.Phone,
                       Subject = 'Onboarding Call',
                       Type = 'Phone',
                       WhatId = acct.Id,
                       Sub_type__c = 'Onboarding'
                   ));
                   acct.Onboarding_Status__c = 'Onboarding Task Created';
               }
            accountsToUpdate.put(acct.Id, acct);
        }
        System.debug('Accounts Status Updating>> '+accountsToUpdate);
        System.debug('On Boarding Task Inserted>> '+onboardingTasks);
        System.debug('Rule Map>> '+ruleMap);
        
        if(accountsToUpdate.size() > 0 && onboardingTasks.size() > 0) {
            try {
                update accountsToUpdate.values();
            } catch(Exception e) {
				ApplicationLogger.log('SM_OnboardingCallBatch.Execute', 'Update Account', 'BatchClass', e);
            }
        }
        if(onboardingTasks.size() > 0) {
            try {
                insert onboardingTasks.values();
            } catch(Exception e) {
               ApplicationLogger.log('SM_OnboardingCallBatch.Execute', 'Insert Task', 'BatchClass', e);
            }
        }
    }
    public void finish(Database.BatchableContext BC) {
    }
  public void execute(SchedulableContext SC) {
      SM_OnboardingCallBatch myBatchObject = new SM_OnboardingCallBatch(); 
      Id batchId = Database.executeBatch(myBatchObject, 10);
      System.debug('batchId '+batchId);
  }
}