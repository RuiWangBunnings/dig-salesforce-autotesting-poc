/*******************************************************************************************************
* Class Name      	: TaskTriggerHandler
* Description		: Trigger Handler for Task object
* Author          	: Simplus - John Paul Penaflor
* Created On      	: 21/02/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Penaflor    21/02/2020		1000				Initial version
* Yi Zhang              21/10/2020		2000				Removed inactive contact check
* Simplus MS			31/05/2021		3000				Added logic for CCRM-13853 - capture tasks with subject "ON BOARDING" and update Onboarding Status
* Simplus MS			30/07/2021		4000				Added logic for INC1005426 - Onboarding Tasks - Due dates
* Simplus MS			20/08/2021		5000				Added logic for SPRINT1_CCRM15-56 Changes to onboarding creation and due dates
* Simplus MS			03/09/2021		6000				Additional logic for CCRM15-149 Onboarding tasks at end of month
******************************************************************************************************/
public class TaskTriggerHandler {
    /**
* @description  Business logic before task insert
* @author       Simplus MS| 30/07/2021 
* @param trigger.new 
**/
    public static void beforeInsert(List<Task> lstNewTask) {
        List<Task> onboardingCallTaskList = new List<Task>();
        for(Task taskObj : lstNewTask){
            if(taskObj.RecordTypeId == DM_RecordType.rtId_Task_OnboardingCall)
            {
                onboardingCallTaskList.add(taskObj);
            }
        }
        if(onboardingCallTaskList.size() > 0) {
            onboardingTasksDueDates(onboardingCallTaskList);
        }
    }
    
    /**
* @description  Business logic before task update
* @author       Simplus MS| 30/07/2021 
* @param oldMap 
* @param newMap 
**/
    public static void beforeUpdate(Map<Id, Task> oldMap, Map<Id, Task> newMap, List<Task> lstNewTask) {
        List<Task> onboardingCallTaskList = new List<Task>();
        for(Task taskObj : lstNewTask){
            if(taskObj.RecordTypeId == DM_RecordType.rtId_Task_OnboardingCall)
            {
                onboardingCallTaskList.add(taskObj);
            }
        }
        if(onboardingCallTaskList.size() > 0) {
            //onboardingTasksDueDates(onboardingCallTaskList); -> due date changes should not be applicable to rescheduling of tasks
        }
    }
    
    /**
* @description 
* @author Yi Zhang | 12/08/2020 
* @param newMap 
**/
    public static void afterInsert(Map<Id, Task> newMap) {
        
        updateRelatedAccountScheduledEngagementCall(newMap);
        updateRelatedAccountOnboardingStatus(newMap);
        
    }
    
    /**
* @description  Business logic for INC1005426 - Onboarding Tasks - Due dates
* @author       Simplus MS| 30/07/2021
* @description	Business logic for SPRINT1_CCRM15-56 Changes to onboarding creation and due dates
* @author       Simplus MS| 20/08/2021
* description   Business logic for CCRM15-149 Onboarding tasks at end of month
* @author       Simplus MS| 03/09/2021
* @param        lstNewTask 
**/
    public static void onboardingTasksDueDates(List<Task> lstNewTask) {
        
        Datetime taskDueDateValue, nextWorkingDate;
        Date powerPassCreatedDate;
        Integer daysCount = Date.daysInMonth(System.today().year(), System.today().month()), dueDatesCount; //dynamically call the total days of the month
        List<Integer> taskAdditionalDaysList = new List<Integer>();
        List<Integer> lastWorkingDaysofaMonth = new List<Integer>();
        List<Id> acctIdsList = new  List<Id>();
        List<String> WEEKEND = new List<String>{'Saturday', 'Sunday'};
        List<Date> dueDatesList = new List<Date>();
        Set<Datetime> lastWorkingDatesofMonth = new Set<Datetime>();
        Map<String,Integer> daysMap = new Map<String,Integer>();
        
        
        //Getting Metadata uses to fetch dates required for task
        List<OnBoardingCallDueDates__mdt> forDueDatesList = [SELECT DeveloperName,Add_Days__c from OnBoardingCallDueDates__mdt];
        for(OnBoardingCallDueDates__mdt days : forDueDatesList) {
            daysMap.put(days.DeveloperName, Integer.valueof(days.Add_Days__c));//convert decimal to integer
            if(days.DeveloperName == 'Last_Working_Days_of_a_Month') {
                lastWorkingDaysofaMonth.add(Integer.valueof(days.Add_Days__c));//convert decimal to integer
                dueDatesCount = lastWorkingDaysofaMonth[0];
            }
            if(days.DeveloperName == 'Task_Additional_Days') {
                taskAdditionalDaysList.add(Integer.valueof(days.Add_Days__c));//convert decimal to integer
            }
        }
        
        //Get Account Ids and Task Due Date Value
        for(Task tasks : lstNewTask) {
            acctIdsList.add(tasks.WhatId);
            if(tasks.ActivityDate != null){
                taskDueDateValue = tasks.ActivityDate;
            }
        }
        //Get Power Pass Account Created Date
        for(Account acct : [Select id, CreatedDate, PowerPass_Account_Created_Date__c from Account where Id in :acctIdsList]){
            if(acct.PowerPass_Account_Created_Date__c != null) {
                powerPassCreatedDate = acct.PowerPass_Account_Created_Date__c;
            }
        }
        
        
        //LastDate store the last date of a month
        if (powerPassCreatedDate == null){
            powerPassCreatedDate = System.Today();
        }
        Datetime LastDate= powerPassCreatedDate.toStartOfMonth() +date.daysInMonth(powerPassCreatedDate.toStartOfMonth().year(), powerPassCreatedDate.toStartOfMonth().month())-1;//4
        
        //Datetime firstDate = powerPassCreatedDate.toStartOfMonth();
        
        //Fetch last working dates of a month 
        for(Integer i=0; i<=daysCount; i++) {
            Datetime LastDateofWeek = LastDate.addDays(-i);
            String LastDayofWeek = LastDateofWeek.format('EEEE');
            if(LastDayofWeek != WEEKEND[0] && LastDayofWeek != WEEKEND[1] && lastWorkingDatesofMonth.size() <  lastWorkingDaysofaMonth[0]) {
                lastWorkingDatesofMonth.add(LastDateofWeek);
            }
            //Increase the count if Last working days are not added in the list so that loop continues to run
            if(lastWorkingDatesofMonth.size() != lastWorkingDaysofaMonth[0]) {
                daysCount += 1;
            }
            //End the loop if Last working days are added in list
            if(lastWorkingDatesofMonth.size() == lastWorkingDaysofaMonth[0]) {
                daysCount = -1;
            }
        }
                
        for(Task taskobj : lstNewTask) {
            //Check if Task due date is not within the last working days of a month added in metadata
            if(!lastWorkingDatesofMonth.isEmpty() && !lastWorkingDatesofMonth.contains(taskobj.ActivityDate)) {
                /*If task Due Date is not null update the due date acc. to below criteria
                * when block 2, Onboarding Task is created on Friday (the due date will fall on Saturday) then move the due date to Monday
                * when block 3, Onboarding Task is created on Saturday (the due date will fall on Sunday) then move the due date to Monday
                */
                if(taskobj.ActivityDate != null) { //If Activity Date is not null
                    datetime myDate = datetime.newInstance(taskobj.ActivityDate.year(), taskobj.ActivityDate.month(), taskobj.ActivityDate.day());
                    String day = myDate.format('EEEE');
                    //If Due date falls on weekend push it to weekdays
                    if(daysMap.containsKey(day) && !daysMap.isEmpty()) {
                        taskobj.ActivityDate = taskobj.ActivityDate.addDays(daysMap.get(day));
                        System.debug('Task Due Date>> '+ taskobj.ActivityDate);
                    }
                }
                taskDueDateValue = taskobj.ActivityDate;
            }
        }
        System.debug('Task Due Date Value>> '+taskDueDateValue);
        //Get the next working dates if due date falls within the last working days of a month
        if(!lastWorkingDatesofMonth.isEmpty() && lastWorkingDatesofMonth.contains(taskDueDateValue)) {
            for(Integer i=1; i<dueDatesCount; i++) {
                Datetime taskDates = taskDueDateValue.addDays(i);
                String taskDays = taskDates.format('EEEE');
                if(taskDays != WEEKEND[0] && taskDays != WEEKEND[1] && dueDatesList.size() < lastWorkingDaysofaMonth[0]) {
                    dueDatesList.add(date.newinstance(taskDates.year(), taskDates.month(), taskDates.day()));
                }
                //Continue the loop if size is not same
                if(dueDatesList.size() != lastWorkingDaysofaMonth[0]) {
                    dueDatesCount += 1;
                }
                //End the loop if Last working days are added in list
                if(dueDatesList.size() == lastWorkingDaysofaMonth[0]) {
                    nextWorkingDate = taskDates;
                    dueDatesCount = -1;
                }
            } 
        }
        System.debug('Due Date List '+dueDatesList+ ' Next Working Date '+nextWorkingDate);
        
        for(Task taskobj : lstNewTask) {
            //Check if Task due date is within the last working days of a month added in metadata
            if((!lastWorkingDatesofMonth.isEmpty() && lastWorkingDatesofMonth.contains(taskobj.ActivityDate)) && nextWorkingDate != null) {
                taskobj.ActivityDate = Date.newInstance(nextWorkingDate.year(), nextWorkingDate.month(), nextWorkingDate.day());//working day of next month 
                datetime myDates = datetime.newInstance(taskobj.ActivityDate.year(), taskobj.ActivityDate.month(), taskobj.ActivityDate.day());
                String days = myDates.format('EEEE');
                //If Due date falls on weekend push it to weekdays
                if(daysMap.containsKey(days) && !daysMap.isEmpty()) {
                    taskobj.ActivityDate = taskobj.ActivityDate.addDays(daysMap.get(days));
                }
            }
             System.debug('Task Due Date>> '+ taskobj.ActivityDate);
        }
    }
    
    /**
* @description 
* @author Yi Zhang | 12/08/2020 
* @param newMap 
**/
    public static void updateRelatedAccountScheduledEngagementCall(Map<Id, Task> newMap) {
        // Task record of type call cycle & AccountId != null
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Task t : newMap.values()) {
            if(t.AccountId != null && t.RecordTypeId == DM_RecordType.rtId_Task_CallCycle && t.ActivityDate != null) {
                accountsToUpdate.put(t.AccountId, new Account(Id = t.AccountId, Scheduled_Engagement_Call__c = t.ActivityDate));
            }
        }
        
        SM_Account.updateScheduledEngagementCall(accountsToUpdate);
    }
    
    /**
* @description added for CCRM-13853 - capture tasks with subject "ON BOARDING" and account's update Onboarding Status
* @author Simplus MS | 31/05/2021 
* @param newMap 
**/
    public static void updateRelatedAccountOnboardingStatus(Map<Id, Task> newMap) {
        Map<Id, Account> accountsToUpdateOnboardingCall = new Map<Id, Account>();
        for(Task t : newMap.values()) {
            if(t.AccountId != null && t.RecordTypeId == DM_RecordType.rtId_Task_OnboardingCall && t.ActivityDate != null && t.Subject == 'ON BOARDING') {
                accountsToUpdateOnboardingCall.put(t.AccountId, new Account(Id = t.AccountId, Onboarding_Status__c = 'Onboarding Task Created'));
            }
        }
        
        if (accountsToUpdateOnboardingCall.size() > 0){
            SM_Account.updateAccountList(JSON.serialize(accountsToUpdateOnboardingCall.values()));
        }
    }
}