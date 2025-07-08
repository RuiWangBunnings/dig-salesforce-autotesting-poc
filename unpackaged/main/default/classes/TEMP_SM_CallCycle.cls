/*******************************************************************************************************
* Class Name      	: TEMP_SM_CallCycle
* Description		: temporary batch class to run NZ Accounts only - cloned batch of SM_CallCycle
* Author          	: Simplus MS
* Created On      	: 03/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* 03/08/2021          03/08/2021		1000				Initial version
* Deepika Pentareddy 08/05/2024      2000                Change engagement/onboarding call flow MicroStrategy report to Transaction Report BUNDIG-12013
******************************************************************************************************/
public with sharing class TEMP_SM_CallCycle {
    public static final List<String> WEEKEND = new List<String>{'Sat', 'Sun'};
    public static final String SUBJECT_FREQUENT_CONTACT_REMINDER = 'Regular Contact Reminder - Frequent';
    public static final String SUBJECT_LESS_FREQUENT_CONTACT_REMINDER = 'Regular Contact Reminder - Less Frequent';
    public static final String SUBJECT_CREDIT_LIMIT_INCREASED = 'Credit Limit Increased';

    /**
    * @description  Create call cycle tasks for single store member (trade specialist)
    * @author Yi Zhang | 21/07/2020 
    * @param member 
    **/
    public static void createMonthlyCallCycle(Store_Member__c member) {
        // Store_Member__c should have below fields:
        // - Store__r.Engagement_Model__c
        // - Store__r.Location_Type__c
        // - Team_Member__c

        String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c; // variable is never used??

        List<Date> dates = businessDatesCurrentMonth; // for testing purpose, can change businessDates to dates other than current month's

        // model 1: Max calls created by Customer Engagement algorithm
        // get accounts
        List<Account> accounts = accountsForModel1(member);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT);

        // model 2: Top X frequent contact – to call every second month
        // get accounts
        accounts = accountsForModel2And3(member, DM_EngagementModel.MODEL_FREQUENT);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_FREQUENT);

        // model 3: Top X less frequent – to call every 5th month
        // get accounts
        accounts = accountsForModel2And3(member, DM_EngagementModel.MODEL_LESS_FREQUENT);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_LESS_FREQUENT);
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param member 
    * @return String 
    **/
    public static List<Account> accountsForModel1(Store_Member__c member) {
        List<Account> accounts = new List<Account>();
        String queryString;
        String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c;
        Integer queryLimit = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT).get(key);

        // query 
        if(queryLimit > 0) {
            queryString = '' + 
            ' SELECT Id, Call_Reason__c, OwnerId FROM Account ' + 
            ' WHERE OwnerId = \'' + member.Team_Member__c + '\' ' + 
            ' AND Do_Not_Call__c = false ' +
            ' AND Call_Reason__c != null ' +
            ' AND Account_Status__c != \'Terminated\' ' + 
            ' AND Account_Status__c != \'Inactive\' ' + 
            ' AND RecordType.DeveloperName = \'NZ_Customer\' ';

            // for new model, additional clause required
            queryString += (member.Store__r.Engagement_Model__c == Constants.STORE_MODEL_NEW) ? ' AND Digitally_Managed__c = false ' : '';

            queryString += ' AND Call_Reason__c != NULL AND Call_Priority__c != NULL AND Call_Priority__c != 0.0 '; // FIX UAT_CCRM-13431 PRB0048304, last Updated 29JUN2021-Added CallPrio!=null

            // order and limit
            queryString += ' ORDER BY Call_Priority__c ASC NULLS last, Call_Cycle_Ranking__c ASC NULLS last LIMIT ' + queryLimit;

            System.debug(LoggingLevel.DEBUG, queryString);

            // query accounts
            accounts = Database.query(queryString);
        }

        return accounts;
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param member 
    * @param model 
    * @return String 
    **/
    public static List<Account> accountsForModel2And3(Store_Member__c member, String model) {
        List<Account> accounts = new List<Account>();
        String queryString;
        String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c;
        Integer queryLimit = DM_EngagementModel.limitMap.get(model).get(key);
        if(queryLimit > 0) {
            Integer lastNthMonth = (model == DM_EngagementModel.MODEL_FREQUENT) ? 1 : 4;
            queryString = '' + 
            ' SELECT Id, OwnerId, ' + 
            ' (SELECT Id FROM Tasks WHERE ActivityDate >= LAST_N_MONTHS:' + lastNthMonth + ' AND ActivityDate <= THIS_MONTH LIMIT 1), ' +
            ' (SELECT Id FROM Events WHERE ActivityDate >= LAST_N_MONTHS:' + lastNthMonth + ' AND ActivityDate <= THIS_MONTH LIMIT 1) ' +
            ' FROM Account ' + 
            ' WHERE OwnerId = \'' + member.Team_Member__c + '\' ' + 
            ' AND Do_Not_Call__c = false ' + 
            ' AND Account_Status__c != \'Terminated\' ' + 
            ' AND Account_Status__c != \'Inactive\' ' + 
            ' AND RecordType.DeveloperName IN (\'AU_Customer\', \'NZ_Customer\') ';
            
            // for new model, additional clause required
            queryString += (member.Store__r.Engagement_Model__c == Constants.STORE_MODEL_NEW) ? ' AND Digitally_Managed__c = false ' : '';

            // order and limit 
            queryString += ' ORDER BY R12_Sales_Rank__c ASC NULLS last LIMIT 10000 ';

            System.debug(LoggingLevel.DEBUG, queryString);

            // query accounts and reduce to limit
            List<Account> accountsNoLimit = Database.query(queryString);
            Integer count = 0;
            for(Account a : accountsNoLimit) {
                if(a.Tasks.isEmpty() && a.Events.isEmpty()) {
                    accounts.add(a);
                    count ++;
                }
                if(count >= queryLimit) {
                    break;
                }
            }
        }

        return accounts;
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param accounts 
    * @param businessDates 
    * @param model 
    **/
    public static void createCallCycleTasks(List<Account> accounts, List<Date> businessDates, String model) {
        // if accounts.size() <= businessDates.size(), one task per day
        // if accounts.size() >  businessDates.size(), then stack
        List<Task> tasks = new List<Task>();
        Integer accountCount = accounts.size();
        Integer businessDatesCount = businessDates.size();
        if(accountCount > 0) {
            Integer count = 0;
            if(accountCount <= businessDatesCount) {
                for(Integer i = 0; i < accountCount; i++) {
                    Account a = accounts[i];
                    String subject = model == DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT ? a.Call_Reason__c : (model == DM_EngagementModel.MODEL_FREQUENT ? SUBJECT_FREQUENT_CONTACT_REMINDER : SUBJECT_LESS_FREQUENT_CONTACT_REMINDER);

                    tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, businessDates[i]));
                }
            } else {
                // eg. 22 days and 80 accounts
                // 80 % 22 = 14 (meaning first 14 days should be more than one task)
                // task per day for first 14 days :(80 - 14) / 22 + 1= 3 + 1 = 4
                // boundary = 14 * 4 = 56
                Integer daysWithMultipleTasks = Math.mod(accountCount, businessDatesCount);
                Integer tasksPerDay = (accountCount - daysWithMultipleTasks) / businessDatesCount + 1;
                Integer reduceTaskBoundary = tasksPerDay * daysWithMultipleTasks;
                for(Integer i = 0; i < accountCount; i ++) {
                    Account a = accounts[i];
                    String subject = model == DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT ? a.Call_Reason__c : (model == DM_EngagementModel.MODEL_FREQUENT ? SUBJECT_FREQUENT_CONTACT_REMINDER : SUBJECT_LESS_FREQUENT_CONTACT_REMINDER);

                    if(i < reduceTaskBoundary) {
                        // e.g. i = 4, means 5th account, should be on day 1
                        Integer dayIndex = (i - Math.mod(i, tasksPerDay)) / tasksPerDay;
                        tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, businessDates[dayIndex]));
                    } else {
                        // e.g. i = 60, means 61st account, should be on day 15 (59..61)
                        // 60 - 56 = 4
                        // 4 % 3 = 1
                        // (4 - 1) / 3 = 1
                        Integer tempI = i - reduceTaskBoundary;
                        Integer dayIndex = daysWithMultipleTasks + (tempI - Math.mod(tempI, tasksPerDay - 1)) / (tasksPerDay - 1);
                        tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, businessDates[dayIndex]));
                    }
                }
            }
        }

        if(tasks.size() > 0) {
            insert tasks;
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 23/07/2020 
    * @param d 
    * @return Date 
    **/
    public static Date nextBusinessDate(Date d) {
        d = d.addDays(1);
        Datetime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        String dayInWeek = dt.format('E');
        if(dayInWeek == WEEKEND[0]) {
            return d.addDays(2);
        } else if(dayInWeek == WEEKEND[1]) {
            return d.addDays(1);
        } else {
            return d;
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param d 
    * @return List<Date> 
    **/
    public static List<Date> businessDatesForMonth(Date d) {
        List<Date> dates = new List<Date>();
        Integer numberOfDays = Date.daysInMonth(d.year(), d.month());
        for(Integer i = 1; i <= numberOfDays; i++) {
            Datetime dt = DateTime.newInstance(d.year(), d.month(), i, 0, 0, 0);
            if(WEEKEND.contains(dt.format('E')) == false) {
                dates.add(dt.date());
            }
        }
        return dates;
    }

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @return List<Date> 
    **/
    public static List<Date> businessDatesCurrentMonth {
        get {
            if(businessDatesCurrentMonth == null) {
                businessDatesCurrentMonth = businessDatesForMonth(Date.today());
            }
            return businessDatesCurrentMonth;
        } set;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getStandardOpptyRTs(){
        Map<String, Id> rtMap = new Map<String, Id>();
        rtMap.put('Australia', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_AU_STANDARD).getRecordTypeId());
        rtMap.put('New Zealand', Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.OPPTY_RT_NZ_STANDARD).getRecordTypeId());
        return rtMap;
    }

 

    public class CallCycleWrapper {
        @AuraEnabled
        public List<Task> tasks;
        @AuraEnabled
        public Event event;
        @AuraEnabled
        public String eventTitle;       // A separate var to store event title e.g. Call scheduled for: 13/10/2020 10:45 (timezone per user config)
        @AuraEnabled
        public Account account;
        @AuraEnabled
        public List<TopicAssignment> topics;
        @AuraEnabled
        public List<Contact> contacts;
        @AuraEnabled
        public String powerPassUrl;
        @AuraEnabled
        public String opptyCosUrl;      // the based url to construct a COS url 
        @AuraEnabled
        public String opptyRT;          // new oppty's record type Id (based on account's country)
        @AuraEnabled
        public Decimal rescheduleLimit;
        @AuraEnabled
        public String eventId;          // For mobile, return the new Event's Id so that lwc can popualate accordingly
        
        //Added for CCRM-554 by Aldrin Rasdas 11.Nov.2020
        @AuraEnabled
        //public String productSalesReportUrl; //Product Sales Report 
        public String transactionSalesReportUrl; //BUNDIG-12013
        
    }
}