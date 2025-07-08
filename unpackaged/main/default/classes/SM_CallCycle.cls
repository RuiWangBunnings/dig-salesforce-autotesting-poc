/*******************************************************************************************************
* Class Name        : SM_CallCycle
* Description       : Domain / Service layer for Call Cycle
* Author            : Simplus - Yi Zhang
* Created On        : 20/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              20/07/2020      1000                Initial version
* Yi Zhang              17/09/2020      2000                Added methods for Call Cycle Form
* Simplus MS            15/06/2021      3000                Updated accountsForModel1 method
* Simplus MS            18/07/2021      4000                Added logic in createCallCycleTasksForCreditLimitIncrease for INC0982513
* Simplus MS            20/10/2021      5000                Added Logic for CCRM15-79, CCRM15-80 & CCRM15-180
* Simplus MS            03/11/2021      6000                Added Logic for CCRM15-316: Generate call cycle calls for the first three weeks of a month
* Simplus MS            03/12/2021      6000                Added Logic for CCRM15-414: Planned Leave - Task Volume and Allocation
* Simplus MS			19/01/2021		6001				Added Logic for CCRM15-578: Call Cycle did not take into account Planned Leave 
* Bunnings Dev          17/05/2022      7000                SFSUP-716 - LifeCycle Model roll-out
* Bunnings Dev          31/10/2022      8000                BUNDIG-12626 - New Maintaining Workflow - Use a specific guide flow for Maintaining calls
* Bunnings Dev 			7/11/2022		9000				BUNDIG-12767 - resolve issue if any of lifecycle reasons is set up 0% in custom metadata type.
******************************************************************************************************/
public with sharing class SM_CallCycle {
    public static final List<String> WEEKEND = new List<String>{'Sat', 'Sun'};
    public static final String SUBJECT_FREQUENT_CONTACT_REMINDER = 'Regular Contact Reminder - Frequent';
    public static final String SUBJECT_LESS_FREQUENT_CONTACT_REMINDER = 'Regular Contact Reminder - Less Frequent';
    public static final String SUBJECT_CREDIT_LIMIT_INCREASED = 'Credit Limit Increased';
    
    // SFSUP-716 - Start
    public static void createMonthlyLifeCycleCallCycle(Store_Member__c member, String bizStartDate) {
        System.debug('***createMonthlyLifeCycleCallCycle');

        List<Account> reducingAccount = new List<Account>();
        List<Account> lapsingAccount = new List<Account>();
        List<Account> growingAccount = new List<Account>();
        List<Account> maintainingAccount = new List<Account>();
        
        // Use to store Accounts per call reason
        List<Account> reducingAccountRecords = new List<Account>();
        List<Account> lapsingAccountRecords = new List<Account>();
        List<Account> growingAccountRecords = new List<Account>();
        List<Account> maintainingAccountRecords = new List<Account>();
                
        Set<Date> plSet = getPlannedLeavesWeekdays(member.Team_Member__c);
        List<Date> dates = new List<Date>();

        System.debug('***bizStartDate: '+bizStartDate);

        if (bizStartDate == null) {
            dates = businessDatesCurrentMonth;
        } else {            
            //List<Date> dates = businessDatesForMonth(date.newInstance(2022, 5, 2));
            Date convertedDate = Date.valueOf(bizStartDate);
            System.debug('***convertedDate: '+convertedDate);

            dates = businessDatesForMonth(convertedDate);
        }

        System.debug('***plSet: '+plSet);
        System.debug('***Dates: '+dates);
        
        List<Account> accounts = accountsLifeCycleCallCycle(member);

		// Populate list accoring to call reason
        for (Account ac : accounts) {
            if (ac.LifeCycle_Call_Reason__c == 'Reducing')
                reducingAccountRecords.add(ac);
            if (ac.LifeCycle_Call_Reason__c == 'Lapsing')
                lapsingAccountRecords.add(ac);
            if (ac.LifeCycle_Call_Reason__c == 'Growing')
                growingAccountRecords.add(ac);
            if (ac.LifeCycle_Call_Reason__c == 'Maintaining')
                maintainingAccountRecords.add(ac);
        }
                
        Map<String, Decimal> callReasonMap = getLifeCycleCallReason();        
                
        // Calculate the number of accounts that is required to be included in the call cycle based on the %tage defined
        // Round the number to the nearest whole number, if %tage value is less than 0 set it to 1
        // BUNDIG-12767 added if check for any of lifecycle reason is set up 0 % in custom metadata type. 
        // If not, reuse the original logic otherwise use default 0.
        Decimal reducingValue = 0 ;
        if(callReasonMap.get('Reducing')  != 0 && callReasonMap.get('Reducing') != NULL){
            reducingValue = (member.Call_Volume__c * (callReasonMap.get('Reducing') / 100)) < 1 ? 1 : member.Call_Volume__c * (callReasonMap.get('Reducing') / 100);
        	reducingValue = reducingValue.round(System.RoundingMode.HALF_EVEN);
        }

        Decimal lapsingValue = 0;
        if(callReasonMap.get('Lapsing') != 0 && callReasonMap.get('Lapsing') != NULL){
            lapsingValue = (member.Call_Volume__c * (callReasonMap.get('Lapsing') / 100)) < 1 ? 1 : member.Call_Volume__c * (callReasonMap.get('Lapsing') / 100);
        	lapsingValue = lapsingValue.round(System.RoundingMode.HALF_EVEN);
        }

        Decimal growingValue = 0;
        if(callReasonMap.get('Growing') != 0 && callReasonMap.get('Growing') != NULL){
            growingValue = (member.Call_Volume__c * (callReasonMap.get('Growing') / 100)) < 1 ? 1 : member.Call_Volume__c * (callReasonMap.get('Growing') / 100);
        	growingValue = growingValue.round(System.RoundingMode.HALF_EVEN);
        }

        Decimal maintainingValue = 0;
        if(callReasonMap.get('Maintaining') != 0 && callReasonMap.get('Maintaining') != NULL){
        	maintainingValue = (member.Call_Volume__c * (callReasonMap.get('Maintaining') / 100)) < 1 ? 1 : member.Call_Volume__c * (callReasonMap.get('Maintaining') / 100);
        	maintainingValue = maintainingValue.round(System.RoundingMode.HALF_EVEN);            
        }

        System.debug('***Member Call Volume: '+member.Call_Volume__c);
        System.debug('***Required number of Accounts - Reducing: ' + reducingValue + ' / Lapsing: ' + lapsingValue + ' / Growing: ' + growingValue + ' / Maintainig: ' + maintainingValue);

        Decimal remainingReducing = 0;
        Decimal lapsing_Reducing_Total = 0;
        Decimal remainingLapsing = 0;
        Decimal growing_Lapsing_Reducing_Total = 0;
        Decimal remainingGrowing = 0;
        Decimal maintaining_Growing_Lapsing_Reducing_Total = 0;
        Decimal remainingMaintaining = 0;       

        for (Account acc : accounts) {

            if (reducingAccountRecords.size() != 0) {
                if (acc.LifeCycle_Call_Reason__c == 'Reducing') {
                    if (reducingAccount.size() != reducingValue) {
                        reducingAccount.add(acc);                    
                    }
                }
            }               

            // Calculate remaining from the %tage value            
			remainingReducing = reducingValue - reducingAccount.size();            
            System.debug('***remainingReducing: '+remainingReducing);

            if (lapsingAccountRecords.size() != 0) {
                if (acc.LifeCycle_Call_Reason__c == 'Lapsing') {
                    lapsing_Reducing_Total = lapsingValue + remainingReducing;
                    System.debug('***LAPSING TOTAL: '+ lapsing_Reducing_Total + '= ' + lapsingValue + '+' + remainingReducing);
                    System.debug('***lapsingAccount.size(): '+ lapsingAccount.size());
    
                    if (lapsingAccount.size() < lapsing_Reducing_Total) {
                        lapsingAccount.add(acc);
                    }
                }
            } else {
                lapsing_Reducing_Total = lapsingValue + remainingReducing;
            }
            System.debug('***lapsing_Reducing_Total: '+lapsing_Reducing_Total);

            // Calculate remaining from the %tage value            
            remainingLapsing = lapsing_Reducing_Total - lapsingAccount.size() < 0 ? 0 : lapsing_Reducing_Total - lapsingAccount.size();
            System.debug('***remainingLapsing: '+ String.valueOf(lapsing_Reducing_Total - lapsingAccount.size()));

            if (growingAccountRecords.size() != 0) {
                if (acc.LifeCycle_Call_Reason__c == 'Growing') {                                                  
                    growing_Lapsing_Reducing_Total = growingValue + remainingLapsing;
                    System.debug('***GROWING TOTAL: '+ growing_Lapsing_Reducing_Total + '= ' + growingValue + '+' + remainingLapsing);
                    System.debug('***growingAccount.size(): '+growingAccount.size());
    
                    if (growingAccount.size() < growing_Lapsing_Reducing_Total) {
                        growingAccount.add(acc);
                    }
                }
            } else {
                growing_Lapsing_Reducing_Total = growingValue + remainingLapsing;
            }
            System.debug('***growing_Lapsing_Reducing_Total: '+growing_Lapsing_Reducing_Total);

            // Calculate remaining from the %tage value            
            remainingGrowing = growing_Lapsing_Reducing_Total - growingAccount.size() < 0 ? 0 : growing_Lapsing_Reducing_Total - growingAccount.size();
            System.debug('***remainingGrowing: '+remainingGrowing);
                                    
            if (acc.LifeCycle_Call_Reason__c == 'Maintaining') {                                
                maintaining_Growing_Lapsing_Reducing_Total = maintainingValue + remainingGrowing;               
                System.debug('***MAINTAINING TOTAL: '+ maintaining_Growing_Lapsing_Reducing_Total + '= ' + maintainingValue + '+' + remainingGrowing);
                System.debug('***maintainingAccount.size(): '+maintainingAccount.size());

                if (maintainingAccount.size() < maintaining_Growing_Lapsing_Reducing_Total) {                
                    maintainingAccount.add(acc);
                }
            }

			// Calculate remaining from the %tage value
			remainingMaintaining = maintainingValue - maintainingAccount.size() < 0 ? maintainingAccount.size() - maintainingValue : maintainingValue - maintainingAccount.size();                                 
        }

        System.debug('***Counts: Reducing Account: ' + reducingAccount.size() + '/' + remainingReducing + ' - Lapsing Account: ' + lapsingAccount.size() + '/' + lapsing_Reducing_Total + ' - Growing Account: ' + growingAccount.size() + '/' + growing_Lapsing_Reducing_Total + ' - Maintaining Account: ' + maintainingAccount.size() + '/' + maintaining_Growing_Lapsing_Reducing_Total);
                
        // Combine all Call Reasons account into 1 for task creation
        List<Account> allAccount = new List<Account>();
        allAccount.addAll(reducingAccount);
        allAccount.addAll(lapsingAccount);
        allAccount.addAll(growingAccount);
        allAccount.addAll(maintainingAccount);
                
        System.debug('***ALL ACOUNTS count: ' + allAccount.size());

        createLifeCycleCallCycleTasks(allAccount, dates, plSet);

    }

    private static Map<String, Decimal> getLifeCycleCallReason() {
        Map<String, Decimal> callReasonMap = new Map<String, Decimal>();
        for (LifeCycle_Model_Call_Reason__mdt lcm : [SELECT Call_Reason__c, Percentage_Value__c FROM LifeCycle_Model_Call_Reason__mdt]) {
            callReasonMap.put(lcm.Call_Reason__c, lcm.Percentage_Value__c);
        }
        return callReasonMap;
    }

    public static void createLifeCycleCallCycleTasks(List<Account> accounts, List<Date> businessDates, Set<Date> plannedLeaveSet) {
        // if accounts.size() <= businessDates.size(), one task per day
        // if accounts.size() >  businessDates.size(), then stack
        
        List<Task> tasks = new List<Task>();
        
        Set<Date> bizDatesSet = new Set<Date>(businessDates);
        Set<Date> reducedBizDatesSet = new Set<Date>(bizDatesSet);
        System.debug('***businessDates: '+ businessDates);
        System.debug('***before bizdates size: '+ reducedBizDatesSet.size());
        System.debug('***accounts.size(): '+ accounts.size());
        System.debug('***bizDatesSet.size(): '+ bizDatesSet.size());
    
        Set<Date> plSet = new Set<Date>(plannedLeaveSet);
        System.debug('***plSet: '+plSet);

        for (Date dt : plSet) {
            if (reducedBizDatesSet.contains(dt))
                reducedBizDatesSet.remove(dt);
        }

        List<Date> bizDates = new List<Date>(reducedBizDatesSet);
        System.debug('***after bizdates size: '+ reducedBizDatesSet.size());

        Integer accSize = 0;

        if (bizDatesSet.size() > 0) {
            if (accounts.size() > bizDatesSet.size() || accounts.size() > reducedBizDatesSet.size()) { // Jasper
                accSize = accounts.size() * reducedBizDatesSet.size() / bizDatesSet.size();
            } else {
                accSize = accounts.size();
            }
        }

        Integer bizDatesSize = bizDates.size();
        System.debug('***accSize size: '+ accSize);
        System.debug('***bizDatesSize size: '+ bizDatesSize);
        
        if (accSize > 0) {
            Integer count = 0;

            Id rtId_Task_CallCycle = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Cycle Call').getRecordTypeId();
            Id rtId_Reducing_Lapsing = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Reducing and Lapsing Call').getRecordTypeId();
			Id rtId_Maintaining = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Maintaining Call').getRecordTypeId();//Added for BUNDIG-12626
            if (accSize <= bizDatesSize) {
                for (Integer i = 0; i < accSize; i++) {   
                    Account a = accounts[i];                    

                    String subject = a.LifeCycle_Call_Reason__c + ' Customer Call';
                    String subType = (a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing') ? 'Reducing and Lapsing Call' : 'Engagement Call';
                    //commented out below for BUNDIG-12626
                    //String recTypeId = (a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing') ? rtId_Reducing_Lapsing : rtId_Task_CallCycle;
					//added below for BUNDIG-12626
					String recTypeId = null;
                    if(a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing'){
                        recTypeId = rtId_Reducing_Lapsing;
                    }else if(a.LifeCycle_Call_Reason__c == 'Maintaining'){
                        recTypeId = rtId_Maintaining;
                    }else{
                        recTypeId = rtId_Task_CallCycle;
                    }                  
                    
                    System.debug('***Creating Task for: '+a.Name + '/' + a.LifeCycle_Call_Reason__c + '/' + subject + '/' + subType);

                    // Create Task
                    tasks.add(SM_Task.createLifeCycleCallCycleTask(recTypeId, a.Id, a.OwnerId, subject, subType, bizDates[i]));                    
                }
            } else {
                // eg. 22 days and 80 accounts
                // 80 % 22 = 14 (meaning first 14 days should be more than one task)
                // task per day for first 14 days :(80 - 14) / 22 + 1= 3 + 1 = 4
                // boundary = 14 * 4 = 56
                Integer daysWithMultipleTasks = Math.mod(accSize, bizDatesSize);
                Integer tasksPerDay = (accSize - daysWithMultipleTasks) / bizDatesSize + 1;
                Integer reduceTaskBoundary = tasksPerDay * daysWithMultipleTasks;

                System.debug('***daysWithMultipleTasks: '+daysWithMultipleTasks);
                System.debug('***tasksPerDay: '+tasksPerDay);
                System.debug('***reduceTaskBoundary: '+reduceTaskBoundary);

                for (Integer i = 0; i < accSize; i ++) {
                    Account a = accounts[i];

                    String subject = a.LifeCycle_Call_Reason__c + ' Customer Call';
                    String subType = (a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing') ? 'Reducing and Lapsing Call' : 'Engagement Call';
                    //commented out below for BUNDIG-12626
                    //String recTypeId = (a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing') ? rtId_Reducing_Lapsing : rtId_Task_CallCycle;
					//added below for BUNDIG-12626
                    String recTypeId = null;
                    if(a.LifeCycle_Call_Reason__c == 'Reducing' || a.LifeCycle_Call_Reason__c == 'Lapsing'){
                        recTypeId = rtId_Reducing_Lapsing;
                    }else if(a.LifeCycle_Call_Reason__c == 'Maintaining'){
                        recTypeId = rtId_Maintaining;
                    }else{
                        recTypeId = rtId_Task_CallCycle;
                    } 
                    
                    if (i < reduceTaskBoundary) {
                        // e.g. i = 4, means 5th account, should be on day 1
                        Integer dayIndex = (i - Math.mod(i, tasksPerDay)) / tasksPerDay;

                        System.debug('***Creating Task for: '+a.Name + '/' + a.LifeCycle_Call_Reason__c + '/' + subject + '/' + subType);
                        tasks.add(SM_Task.createLifeCycleCallCycleTask(recTypeId, a.Id, a.OwnerId, subject, subType, bizDates[dayIndex]));
                    } else {
                        // e.g. i = 60, means 61st account, should be on day 15 (59..61)
                        // 60 - 56 = 4
                        // 4 % 3 = 1
                        // (4 - 1) / 3 = 1
                        Integer tempI = i - reduceTaskBoundary;
                        Integer dayIndex = daysWithMultipleTasks + (tempI - Math.mod(tempI, tasksPerDay - 1)) / (tasksPerDay - 1);

                        // Create Task
                        System.debug('***Creating Task for: '+a.Name + '/' + a.LifeCycle_Call_Reason__c + '/' + subject + '/' + subType);
                        tasks.add(SM_Task.createLifeCycleCallCycleTask(recTypeId, a.Id, a.OwnerId, subject, subType, bizDates[dayIndex]));                        
                    }
                }
            }
        }

        System.debug('***Task Size: '+tasks.size());    

        if (tasks.size() > 0) {
            try {
                insert tasks;                        
            } catch (Exception e) {
                ApplicationLogger.log('createLifeCycleCallCycleTasks', 'Task', 'Batch', e);
            }            
        }
        
    }
    // SFSUP-716 - End

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
        //String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c;
        
        Set<Date> plSet = getPlannedLeavesWeekdays(member.Team_Member__c); // CCRM15-414

        List<Date> dates = businessDatesCurrentMonth; // for testing purpose, can change businessDates to dates other than current month's
        
        // model 1: Max calls created by Customer Engagement algorithm
        // get accounts
        List<Account> accounts = accountsForModel1(member);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT, plSet);// for plSet ccrm15-414
        
        // model 2: Top X frequent contact – to call every second month
        // get accounts
        accounts = accountsForModel2And3(member, DM_EngagementModel.MODEL_FREQUENT);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_FREQUENT, plSet);
        
        // model 3: Top X less frequent – to call every 5th month
        // get accounts
        accounts = accountsForModel2And3(member, DM_EngagementModel.MODEL_LESS_FREQUENT);
        // create tasks
        createCallCycleTasks(accounts, dates, DM_EngagementModel.MODEL_LESS_FREQUENT, plSet);
    }

    // SFSUP-716 - Updates in the quarantine rule
    public static List<Account> accountsLifeCycleCallCycle(Store_Member__c member) {
        System.debug('***accountsLifeCycleCallCycle');

        List<Account> accounts = new List<Account>();
        Set<String> lifeCycleCallReasons = new Set<String>{'Reducing','Lapsing','Growing','Maintaining'};


        String queryString;
        Integer queryLimit = member.Call_Volume__c == null ? 0 : member.Call_Volume__c.intValue();
        
        Integer quarantineMonths = getQuarantineMonthValue(member.Team_Member__r.Country__c);
        Boolean hasQuarantineMdt = quarantineMonths != 0 ? true : false;
        
        System.debug('***quarantineMonths: ' + quarantineMonths);
        System.debug('***hasQuarantineMdt: ' + hasQuarantineMdt);
        System.debug('***queryLimit: '+queryLimit);
        
        Id rt_Reducing_or_Lapsing_Customer_Call = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Reducing and Lapsing Call').getRecordTypeId();       
        Id rtId_Maintaining = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Maintaining Call').getRecordTypeId();//Added for BUNDIG-12626
        Set<String> rtTasks = new Set<String>{DM_RecordType.rtId_Task_CallCycle, rt_Reducing_or_Lapsing_Customer_Call, rtId_Maintaining}; //Added rtId_Maintaining for BUNDIG-12626

        if (queryLimit > 0) {

            queryString = 'SELECT Id, Name, LifeCycle_Call_Reason__c, OwnerId';
            
            if (hasQuarantineMdt) {
                queryString = queryString + 
                    ', (SELECT Id FROM Tasks' +
                    //' WHERE RecordTypeId = \''+ rt_Reducing_or_Lapsing_Customer_Call +'\'' + //SFSUP-716
                    ' WHERE RecordTypeId IN :rtTasks ' +
                    //' AND ActivityDate >= LAST_N_MONTHS:' + quarantineMonths + ' AND ActivityDate <= THIS_MONTH LIMIT 1) ';
                    ' AND ActivityDate >= LAST_N_MONTHS:' + quarantineMonths + ' AND ActivityDate <= THIS_MONTH) '; //SFSUP-716
            }

            queryString = queryString + 
                ' FROM Account ' + 
                ' WHERE OwnerId = \'' + member.Team_Member__c + '\' ' + 
                ' AND Do_Not_Call__c = false ' +
                ' AND LifeCycle_Call_Reason__c IN :lifeCycleCallReasons' +
                ' AND Account_Status__c != \'Terminated\' ' + 
                ' AND Account_Status__c != \'Inactive\' ' + 
                ' AND RecordType.DeveloperName IN (\'AU_Customer\', \'NZ_Customer\') ';
            
            // for new model, additional clause required
            //queryString += (member.Store__r.LifeCycle_Model__c == Constants.STORE_MODEL_NEW) ? ' AND Digitally_Managed__c = false ' : '';
            //System.debug('***queryString4: '+queryString);

            queryString += ' AND LifeCycle_Call_Reason__c != NULL AND LifeCycle_Call_Priority__c != NULL AND LifeCycle_Call_Ranking__c != 0.0 ';            

            // order and limit
            queryString += ' ORDER BY LifeCycle_Call_Priority__c ASC NULLS last, LifeCycle_Call_Ranking__c ASC NULLS last ';

            if (hasQuarantineMdt) {
                queryString += ' LIMIT 10000';
            } else {
                queryString += ' LIMIT ' + queryLimit;
            }
            
            // query accounts
            List<Account> accountsNoLimit = Database.query(queryString);
            Integer count = 0;

            System.debug('***accountsNoLimit: ' + accountsNoLimit.size());
            
            if (hasQuarantineMdt) {
                
                for (Account a : accountsNoLimit) {
                    if (a.Tasks.isEmpty()) {
                        accounts.add(a);
                        count += 1;
                    }

                    // No limit is needed
                    //if (count >= queryLimit)
                    //    break;
                }
            } else {
                accounts = accountsNoLimit;
            }
        }

        System.debug('***accounts size: '+ accounts.size());
    
        return accounts;
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
        // String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c + member.Store__r.Country__c;
        // Integer queryLimit = DM_EngagementModel.limitMap.get(DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT).get(key);
        Integer queryLimit = member.Call_Volume__c == null ? 0 : member.Call_Volume__c.intValue(); //CCRM15-79 - Assign limit with call volume value from Store Member
        
        Integer quarantineMonths = getQuarantineMonthValue(member.Team_Member__r.Country__c);
        Boolean hasQuarantineMdt = quarantineMonths != 0 ? true : false;
        
        System.debug('quarantineMonths - ' + quarantineMonths);
        System.debug('hasQuarantineMdt - ' + hasQuarantineMdt);
        
        Id callCycleRecType = DM_RecordType.rtId_Task_CallCycle;

        // SFSUP-716 - Start - Changes in the quarantine rule, additional Record Type to be checked
        Id rt_Reducing_or_Lapsing_Customer_Call = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Reducing and Lapsing Call').getRecordTypeId();       
        Id rtId_Maintaining = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Maintaining Call').getRecordTypeId();//Added for BUNDIG-12626
        Set<String> rtTasks = new Set<String>{callCycleRecType, rt_Reducing_or_Lapsing_Customer_Call, rtId_Maintaining};//Added rtId_Maintaining for BUNDIG-12626
        // SFSUP-716 - End

        System.debug('queryLimit >> '+queryLimit);
        // query 
        if(queryLimit > 0) {
            
            queryString = '' + 
                ' SELECT Id, Call_Reason__c, OwnerId';
            
            if(hasQuarantineMdt) {
                queryString = queryString + 
                    ', (SELECT Id FROM Tasks' +
                    //' WHERE RecordTypeId = \''+ callCycleRecType +'\'' + //SFSUP-716
                    ' WHERE RecordTypeId IN :rtTasks ' +
                    //' AND ActivityDate >= LAST_N_MONTHS:' + quarantineMonths + ' AND ActivityDate <= THIS_MONTH LIMIT 1) ';
                    ' AND ActivityDate >= LAST_N_MONTHS:' + quarantineMonths + ' AND ActivityDate <= THIS_MONTH) '; //SFUSP-622
            }
            
            queryString = queryString + 
                ' FROM Account ' + 
                ' WHERE OwnerId = \'' + member.Team_Member__c + '\' ' + 
                ' AND Do_Not_Call__c = false ' +
                ' AND Call_Reason__c != null ' +
                ' AND Account_Status__c != \'Terminated\' ' + 
                ' AND Account_Status__c != \'Inactive\' ' + 
                ' AND RecordType.DeveloperName IN (\'AU_Customer\', \'NZ_Customer\')';
            
            // for new model, additional clause required
            queryString += (member.Store__r.Engagement_Model__c == Constants.STORE_MODEL_NEW) ? ' AND Digitally_Managed__c = false ' : '';
            
            queryString += ' AND Call_Reason__c != NULL AND Call_Priority__c != NULL AND Call_Priority__c != 0.0 '; // FIX UAT_CCRM-13431 PRB0048304, last Updated 29JUN2021-Added CallPrio!=null
            
            // order and limit
            queryString += ' ORDER BY Call_Priority__c ASC NULLS last, Call_Cycle_Ranking__c ASC NULLS last ';

            if(hasQuarantineMdt) queryString += ' LIMIT 10000';
            else queryString += ' LIMIT ' + queryLimit;
            
            System.debug('queryString: '+queryString);
            
            // query accounts
            List<Account> accountsNoLimit = Database.query(queryString);
            Integer count = 0;
            
            if(hasQuarantineMdt) {//CCRM15-180
                
                for(Account a : accountsNoLimit) {
                    // system.debug('accountsNoLimit -- ' + a);
                    // System.debug('a*** '+a.Tasks.isEmpty());
                    if(a.Tasks.isEmpty()) {
                        accounts.add(a);
                        count += 1;
                    }
                    if(count >= queryLimit)
                        break;
                }
            } else {
                accounts = accountsNoLimit;
            }
        }
        System.debug('accounts size - '+ accounts.size());
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
        String key = member.Store__r == null ? null : member.Store__r.Engagement_Model__c + member.Store__r.Location_Type__c + member.Store__r.Country__c; //CCRM15-80 - Ability to set call cycle volumes per country
        Integer queryLimit = DM_EngagementModel.limitMap.get(model).get(key);
        
        Integer quarantineMonths = getQuarantineMonthValue(member.Store__r.Country__c);
        Boolean hasQuarantineMdt = quarantineMonths != 0 ? true : false;
        
        if(queryLimit > 0) {
            Integer lastNthMonth = (model == DM_EngagementModel.MODEL_FREQUENT) ? 1 : 4;
            
            if(hasQuarantineMdt) {
                if(lastNthMonth < quarantineMonths) {
                    lastNthMonth = quarantineMonths;
                }
            }
            
            queryString = '' + 
                ' SELECT Id, OwnerId, ';
            queryString = queryString + 
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
            
            System.debug('queryString: '+queryString);
            
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
    
    public static Integer getQuarantineMonthValue(String country) {
        
        List<Call_Cycle_Quarantine_Month__mdt> quarantineConfig = new List<Call_Cycle_Quarantine_Month__mdt>();
        quarantineConfig.addAll([
            SELECT Country__c, Number_of_months__c
            FROM Call_Cycle_Quarantine_Month__mdt
            WHERE Enabled__c = true AND Country__c = :country
        ]);
        Integer value = 0;
        if(quarantineConfig.size() > 0) {
            for(Call_Cycle_Quarantine_Month__mdt ccqm : quarantineConfig) {
                value = Integer.valueOf(ccqm.Number_of_months__c);
            }
        }
        return value;
    }
    
    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @param accounts 
    * @param businessDates 
    * @param model 
    **/
    public static void createCallCycleTasks(List<Account> accounts, List<Date> businessDates, String model, Set<Date> plannedLeaveSet) {//, List<Planned_Leave__c> plannedLeaveList
        // if accounts.size() <= businessDates.size(), one task per day
        // if accounts.size() >  businessDates.size(), then stack
        
        List<Task> tasks = new List<Task>();
        
        Set<Date> bizDatesSet = new Set<Date>(businessDates);
        Set<Date> reducedBizDatesSet = new Set<Date>(bizDatesSet);
        system.debug('businessDates '+businessDates);
        System.debug('before bizdates size ' + reducedBizDatesSet.size());
    
        Set<Date> plSet = new Set<Date>(plannedLeaveSet);
        system.debug('plSet '+plSet);
        for(Date dt : plSet) {
            if(reducedBizDatesSet.contains(dt))
            reducedBizDatesSet.remove(dt);
        }
        List<Date> bizDates = new List<Date>(reducedBizDatesSet);
        System.debug('after bizdates size ' + reducedBizDatesSet.size());
        
        System.debug('accounts size ' + accounts.size());
        Integer accSize = 0;
        if (bizDatesSet.size() > 0){
            accSize = accounts.size() * reducedBizDatesSet.size() / bizDatesSet.size();
        }
        Integer bizDatesSize = bizDates.size();
        System.debug('accSize size ' + accSize);
        System.debug('bizDatesSize size ' + bizDatesSize);
        
        if(accSize > 0) {
            Integer count = 0;
            if(accSize <= bizDatesSize) {
                for(Integer i = 0; i < accSize; i++) {   
                    Account a = accounts[i];
                    String subject = model == DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT ? a.Call_Reason__c : (model == DM_EngagementModel.MODEL_FREQUENT ? SUBJECT_FREQUENT_CONTACT_REMINDER : SUBJECT_LESS_FREQUENT_CONTACT_REMINDER);
                    tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, bizDates[i]));
                }
            } else {
                // eg. 22 days and 80 accounts
                // 80 % 22 = 14 (meaning first 14 days should be more than one task)
                // task per day for first 14 days :(80 - 14) / 22 + 1= 3 + 1 = 4
                // boundary = 14 * 4 = 56
                Integer daysWithMultipleTasks = Math.mod(accSize, bizDatesSize);
                Integer tasksPerDay = (accSize - daysWithMultipleTasks) / bizDatesSize + 1;
                Integer reduceTaskBoundary = tasksPerDay * daysWithMultipleTasks;
                for(Integer i = 0; i < accSize; i ++) {
                    Account a = accounts[i];
                    String subject = model == DM_EngagementModel.MODEL_CUSTOMER_ENGAGEMENT ? a.Call_Reason__c : (model == DM_EngagementModel.MODEL_FREQUENT ? SUBJECT_FREQUENT_CONTACT_REMINDER : SUBJECT_LESS_FREQUENT_CONTACT_REMINDER);

                    if(i < reduceTaskBoundary) {
                        // e.g. i = 4, means 5th account, should be on day 1
                        Integer dayIndex = (i - Math.mod(i, tasksPerDay)) / tasksPerDay;
                        tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, bizDates[dayIndex]));
                    } else {
                        // e.g. i = 60, means 61st account, should be on day 15 (59..61)
                        // 60 - 56 = 4
                        // 4 % 3 = 1
                        // (4 - 1) / 3 = 1
                        Integer tempI = i - reduceTaskBoundary;
                        Integer dayIndex = daysWithMultipleTasks + (tempI - Math.mod(tempI, tasksPerDay - 1)) / (tasksPerDay - 1);
                        tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, subject, bizDates[dayIndex]));
                    }
                }
            }
        }
        if(tasks.size() > 0) {
            try {
                insert tasks;
            } catch (Exception e) {
                ApplicationLogger.log('createCallCycleTasks', 'Task', 'Trigger', e);
            }
            // for(Task tsk : tasks) {
            //     system.debug(tsk.Subject + ' - ' + tsk.ActivityDate);
            // }
            System.debug('Task size ' + tasks.size());
        }
    }
    
    /**
    * @description 
    * @author Yi Zhang | 23/07/2020 
    * @param accounts 
    **/
    public static void createCallCycleTasksForCreditLimitIncrease(Set<Account> accounts) {
        // TODO all account types or certain account types?
        try {
            if(accounts.size() > 0) {
                // build task list, exclude accounts which have call cycle task scheduled for the remaining of the month
                List<Task> tasks = new List<Task>();
                List<Task> taskCreation = new List<Task>();
                List<Id> accountIds = new List<Id>((new Map<Id, Account>(new List<Account>(accounts))).keySet());
                List<Account> accountsWithCallCycleTasks = DM_Account.getAccountsWithCustomerEngagementCallThisMonth(accountIds);
                System.debug('accountsWithCallCycleTasks: '+accountsWithCallCycleTasks);
                List<Account> acctList = new List<Account>();
                for(Account a : accountsWithCallCycleTasks) {
                    if(a.Tasks.size() == 0 && a.Events.size() == 0) {
                        tasks.add(SM_Task.createCallCycleTask(a.Id, a.OwnerId, SUBJECT_CREDIT_LIMIT_INCREASED, nextBusinessDate(Date.today())));
                    }
                }
                // insert tasks
                if(tasks.size() > 0) {
                    try{
                        insert tasks;
                    } catch(Exception e) {
                        ApplicationLogger.log('createCallCycleTasksForCreditLimitIncrease', 'Account', 'Trigger', e);
                    }
                }
                //Added below logic for INC0982513
                //If credit limit increased but task is not generated
                for(Account acct : accounts) {
                    acctList = [SELECT Id, OwnerId, Credit_Limit_Increased_Check__c ,
                                (SELECT Id FROM Tasks WHERE Subject = 'Credit Limit Increased')
                                FROM Account
                                WHERE Id =: acct.Id
                                AND Owner.IS_TS__c = true
                                AND RecordType.Name != 'Person Account'];
                    System.debug('acctList '+acctList);
                }
                for(Account acctObj : acctList) {
                    if(acctObj.Credit_Limit_Increased_Check__c == true && acctObj.Tasks.size() == 0) {
                        taskCreation.add(SM_Task.createCallCycleTask(acctObj.Id, acctObj.OwnerId, SUBJECT_CREDIT_LIMIT_INCREASED, nextBusinessDate(Date.today())));
                    }
                }
                if(taskCreation.size() > 0) {
                    System.debug('taskCreation '+taskCreation);
                    try{
                        insert taskCreation;
                    } catch(Exception e) {
                        ApplicationLogger.log('createCallCycleTasksForCreditLimitIncrease', 'Account', 'Trigger', e);
                    }
                }
            }
        } catch(Exception e) {
            ApplicationLogger.log('createCallCycleTasksForCreditLimitIncrease', 'Account', 'Trigger', e);
        }
    }
    
    /**
    * @description 
    * @author Yi Zhang | 27/07/2020 
    * @param oppty 
    * @param task 
    * @return Map<String, String> {status: 'successful|failed', error: 'errorMessage', opptyId: '0061m00000xxxxxxxx'}
    **/
    @AuraEnabled
    public static Map<String, String> createOpportunityForCallCycleTask(Opportunity oppty, Task task) {
        Map<String, String> response = new Map<String, String>();
        try {
            insert oppty;
            
            task.Opportunity__c = oppty.Id;
            update task;
            response.put('status', 'successful');
            response.put('opptyId', oppty.Id);
        } catch(Exception e) {
            // response.put('status', 'failed');
            // response.put('error', e.getMessage());
            // TODO Error Logging
            throw new AuraHandledException(e.getMessage());
        }
        return response;
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
    
    // CCRM15-414 - returns Dates of planned leaves on weekdays
    private static Set<Date> getPlannedLeavesWeekdays(Id teamMemberId) {
        Date addedDays;
        Integer daysCount;
        Set<Date> plSet = new Set<Date>();
        //List of planned leaves 
        List<Planned_Leave__c> plannedLeaveList = [
            SELECT Id, OwnerId, Status__c, End_Date__c, Start_Date__c 
            FROM Planned_Leave__c 
            WHERE Status__c = 'Approved' And OwnerId = :teamMemberId AND Start_Date__c != NULL AND End_Date__c != NULL];
        System.debug('plannedLeaveList>> '+plannedLeaveList);
        
        for(Planned_Leave__c plannedLeaves : plannedLeaveList) {
            if(plannedLeaves.Start_Date__c < plannedLeaves.End_Date__c ) {
                System.debug('Start date are less than End Date');
                daysCount = plannedLeaves.Start_Date__c.daysBetween(plannedLeaves.End_Date__c);
                plSet.add(plannedLeaves.End_Date__c);
                plSet.add(plannedLeaves.Start_Date__c);
                for(Integer i=1;i<=daysCount;i++) {
                    addedDays = plannedLeaves.Start_Date__c+i;
                    plSet.add(addedDays);
                }
            }
            if(plannedLeaves.Start_Date__c == plannedLeaves.End_Date__c) {
                System.debug('Start and End Date are equal');
                plSet.add(plannedLeaves.End_Date__c);
            }
        }
        for(Date dt : plSet) {
            if(WEEKEND.contains(DateTime.newInstance(dt.year(), dt.month(), dt.day(), 0, 0, 0).format('E')) == true) {
                plSet.remove(dt);
            }
        }
        System.debug('plSet>> '+plSet);
        return plSet;
    }
    // /**
    // * @description 
    // * @author Yi Zhang | 21/07/2020 
    // * @param d 
    // * @return List<Date> 
    // **/
    // public static List<Date> businessDatesForMonth(Date d) {
    //     List<Date> dates = new List<Date>();
    //     Integer firstDay = d.day(); // CCRM15-316 generate callcycle with startdate on the date or batch run
    //     Integer numberOfDays = Date.daysInMonth(d.year(), d.month()) - (firstDay + 1); // CCRM15-316
    //     System.debug('firstDay '+firstDay+' numberOfDays '+numberOfDays);
    //     for(Integer i = firstDay; i <= numberOfDays; i++) {
    //         Datetime dt = DateTime.newInstance(d.year(), d.month(), i, 0, 0, 0);
    //         if(WEEKEND.contains(dt.format('E')) == false ) {
    //             dates.add(dt.date());
    //         }
    //         //CCRM15-316: Generate call cycle calls for the first three weeks of a month
    //         if(i==21){
    //             break;
    //         }
    //     }
    //     return dates;
    // }

    /**
    * @description - re-wrote for CCRM15-316/CCRM15-414/CCRM15-578, original commented out above
    * @author Simplus MS | 19-01-2022 
    * @param Date d 
    * @return List<Date> 
    **/
    public static List<Date> businessDatesForMonth(Date d) {
        List<Date> dates = new List<Date>();
        Integer firstDay = d.day(); // CCRM15-316 generate callcycle with startdate on the date or batch run
        for(Integer i = firstDay; i <= 21; i++) {
            Datetime dt = DateTime.newInstance(d.year(), d.month(), i, 0, 0, 0);
            if(WEEKEND.contains(dt.format('E')) == false ) {
                dates.add(dt.date());
            }
        }

        System.debug('***businessDatesForMonth (dates): '+dates);
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
    
    /**
    * @description 
    * @author Yi Zhang | 17/09/2020 
    * @param accountId 
    * @param formFactor 
    * @param context 
    * @return CallCycleWrapper 
    **/
    @AuraEnabled
    public static CallCycleWrapper callCycleFormInit(String accountId, String formFactor, String context) {
        CallCycleWrapper resp = new CallCycleWrapper();
        // move to data layer later
        Account a = DM_Account.getAccountWithContactsEngagementCallActivities(accountId);
        // if formFactor is set and equal to Small, it's from Mobile, only Event matters
        // task related doesn't need to load
        if(formFactor == 'Small') {
            // get event
            if(a.Events.size() == 1) {
                resp.event = a.Events[0];
            } else {
                resp.event = new Event(
                    Subject = 'Call',
                    StartDateTime = Datetime.now(),
                    // DurationInMinutes = 30,
                    EndDateTime = Datetime.now().addMinutes(30),
                    Sub_type__c = 'Engagement Call',
                    Status__c = 'Open',
                    WhatId = accountId
                );
            }
        } else {
            // get tasks - all future tasks with purpose = Engagement Call & Open
            resp.tasks = a.Tasks;
            // get event - earliest incomplete event with purpose = Engagement Call
            if(a.Events.size() == 1) {
                resp.event = a.Events[0];
            }
            // get topics
            if(String.isNotBlank(a.Home_Store__c)) {
                resp.topics = new List<TopicAssignment>([SELECT Id, Topic.Name FROM TopicAssignment WHERE EntityId = :a.Home_Store__c]);
            }
            if(String.isNotBlank(a.Assigned_Store__c)) {
                resp.topics = new List<TopicAssignment>([SELECT Id, Topic.Name FROM TopicAssignment WHERE EntityId = :a.Assigned_Store__c]);
            }
            // get powerpass url
            Initialisation__mdt config = DM_Initialisation.ccrmInitialisation;
            if(String.isNotBlank(a.Power_Pass_Account_Number__c) && String.isNotBlank(config.COS_Powerpass_URL__c)) {
                resp.powerPassUrl = config.COS_Powerpass_URL__c.replace('###ACCT_NO###', a.Power_Pass_Account_Number__c);
            }
            // get cos url
            resp.opptyCosUrl = config.COS_New_Quote_URL__c;
            // get new oppty's record type (based on account's country)
            resp.opptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get((a.Country__c == Constants.COUNTRY_NZ ? Constants.OPPTY_RT_NZ_STANDARD : Constants.OPPTY_RT_AU_STANDARD)).getRecordTypeId();
            // get reschedule limit
            resp.rescheduleLimit = config.Call_Cycle_Attempts__c;
            // get contacts
            resp.contacts = a.Contacts;
            //resp.productSalesReportUrl = config.COS_Product_Sales_Report_URL__c;
            resp.transactionSalesReportUrl = config.COS_Transaction_Sales_Report_URL__c; //BUNDIG-12013
        }
        // get account
        resp.account = a;
        
        // when launched via quick action, only one task or event
        if(context == 'flowScreen') {
            if(resp.event == null) {
                if(resp.tasks != null && resp.tasks.size() > 1) {
                    resp.tasks = new List<Task>{resp.tasks[0]};
                        }
            } else {
                if(resp.tasks != null && resp.tasks.size() > 0) {
                    // compare task with event
                    if(resp.event.StartDateTime <= (Datetime) resp.tasks[0].ActivityDate) {
                        resp.tasks = new List<Task>();
                    } else {
                        resp.event = null;
                        resp.tasks = new List<Task>{resp.tasks[0]};
                            }
                }
            }
        }
        
        // add subject (including localized date time) to resp.event
        if(resp.event != null) {
            resp.eventTitle = 'Call scheduled for: ' + resp.event.StartDateTime.format('dd/MM/yyyy HH:mm');
        }
        
        return resp;
    }

    /**
    * @description 
    * @author Bunnings Dev | 15/06/2022
    * @param accountId 
    * @param formFactor 
    * @param context 
    * @return CallCycleWrapper 
    **/
    @AuraEnabled
    public static CallCycleWrapper lifecycleCallCycleFormInit(String accountId, String formFactor, String context, String taskSubType, String reasonGroup) {
        CallCycleWrapper resp = new CallCycleWrapper();
        // move to data layer later
        Account a = DM_Account.getAccountWithContactsCallActivities(accountId, taskSubType, reasonGroup);
        // if formFactor is set and equal to Small, it's from Mobile, only Event matters
        // task related doesn't need to load
        if(formFactor == 'Small') {
            // get event
            if(a.Events.size() == 1) {
                resp.event = a.Events[0];
            } else {
                resp.event = new Event(
                    Subject = 'Call',
                    StartDateTime = Datetime.now(),
                    // DurationInMinutes = 30,
                    EndDateTime = Datetime.now().addMinutes(30),
                    Sub_type__c = 'Reducing and Lapsing Call',
                    Status__c = 'Open',
                    WhatId = accountId
                );
            }
        } else {
            // get tasks - all future tasks with purpose = Engagement Call & Open
            resp.tasks = a.Tasks;
            // get event - earliest incomplete event with purpose = Engagement Call
            if(a.Events.size() == 1) {
                resp.event = a.Events[0];
            }
            // get topics
            if(String.isNotBlank(a.Home_Store__c)) {
                resp.topics = new List<TopicAssignment>([SELECT Id, Topic.Name FROM TopicAssignment WHERE EntityId = :a.Home_Store__c]);
            }
            if(String.isNotBlank(a.Assigned_Store__c)) {
                resp.topics = new List<TopicAssignment>([SELECT Id, Topic.Name FROM TopicAssignment WHERE EntityId = :a.Assigned_Store__c]);
            }
            // get powerpass url
            Initialisation__mdt config = DM_Initialisation.ccrmInitialisation;
            if(String.isNotBlank(a.Power_Pass_Account_Number__c) && String.isNotBlank(config.COS_Powerpass_URL__c)) {
                resp.powerPassUrl = config.COS_Powerpass_URL__c.replace('###ACCT_NO###', a.Power_Pass_Account_Number__c);
            }
            // get cos url
            resp.opptyCosUrl = config.COS_New_Quote_URL__c;
            // get new oppty's record type (based on account's country)
            resp.opptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get((a.Country__c == Constants.COUNTRY_NZ ? Constants.OPPTY_RT_NZ_STANDARD : Constants.OPPTY_RT_AU_STANDARD)).getRecordTypeId();
            // get reschedule limit
            resp.rescheduleLimit = config.Call_Cycle_Attempts__c;
            // get contacts
            resp.contacts = a.Contacts;
            //resp.productSalesReportUrl = config.COS_Product_Sales_Report_URL__c;
            resp.transactionSalesReportUrl = config.COS_Transaction_Sales_Report_URL__c; //BUNDIG-12013

        }
        // get account
        resp.account = a;
        
        // when launched via quick action, only one task or event
        if(context == 'flowScreen') {
            if(resp.event == null) {
                if(resp.tasks != null && resp.tasks.size() > 1) {
                    resp.tasks = new List<Task>{resp.tasks[0]};
                        }
            } else {
                if(resp.tasks != null && resp.tasks.size() > 0) {
                    // compare task with event
                    if(resp.event.StartDateTime <= (Datetime) resp.tasks[0].ActivityDate) {
                        resp.tasks = new List<Task>();
                    } else {
                        resp.event = null;
                        resp.tasks = new List<Task>{resp.tasks[0]};
                            }
                }
            }
        }
        
        // add subject (including localized date time) to resp.event
        if(resp.event != null) {
            resp.eventTitle = 'Call scheduled for: ' + resp.event.StartDateTime.format('dd/MM/yyyy HH:mm');
        }
        
        return resp;
    }
        
    /**
    * @description 
    * @author Yi Zhang | 23/09/2020 
    * @param account 
    * @param task 
    * @param event 
    * @param newTask 
    * @param recipientType 
    * @param recipientCountry 
    * @param recipientId 
    * @param email 
    * @return CallCycleWrapper 
    **/
    @AuraEnabled
    public static CallCycleWrapper updateAccountAndActivity(Account account, Task task, Event event, Task newTask, 
                                                            String recipientType, String recipientCountry, String recipientId, String email) {
                                                                
        try {
            CallCycleWrapper resp = new CallCycleWrapper();
            if(account != null) {
                update account;
            }
            if(task != null) {
                update task;
            }
            if(event != null) {
                if(event.Id != null) {
                    update event;
                } else {
                    insert event;
                    resp.eventId = event.Id;
                }
            }
            if(newTask != null) {
                newTask.Subject = task.Subject;
                newTask.WhatId = task.WhatId;
                newTask.Call_Cycle_Attempt__c = (task.Call_Cycle_Attempt__c == null) ? 1 : task.Call_Cycle_Attempt__c + 1;
                newTask.OwnerId = task.OwnerId;
                newTask.Sub_type__c = 'Engagement Call';
                newTask.Status = 'Open';
                newTask.RecordTypeId = DM_RecordType.rtId_Task_CallCycle;
                if(task.Objectives__c != null) {//Added Logic for CCRM15-307
                    newTask.Objectives__c = task.Objectives__c;
                }
                insert newTask;
            }
            if(recipientType != null && recipientId != null) {
                // depending on the country & object, select the right template
                Messaging.reserveSingleEmailCapacity(1);
                
                String templateName = 'Missed_call_cycle_call';
                templateName = (recipientCountry == Constants.COUNTRY_NZ ? 'NZ_' : 'AU_') + templateName;
                templateName = templateName + (recipientType == 'Contact' ? '_Contact' : '');
                List<EmailTemplate> templates = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = :templateName];
                if(templates.isEmpty()) {
                    throw new AuraHandledException('Unable to find the email template with name ' + templateName);
                }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(templates[0].Id);
                mail.setSaveAsActivity(false);
                mail.setToAddresses(new List<String>{email});
                if(recipientType == 'Contact') {
                    mail.setTargetObjectId(recipientId);
                } else {
                    mail.setTreatTargetObjectAsRecipient(false);
                    mail.setTargetObjectId([SELECT Id FROM Contact LIMIT 1].Id);
                    mail.setWhatId(recipientId);
                }
                
                Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
            }
            return resp;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Bunnings Dev | 10/06/2022
    * @description Use in LifeCycle call cycle form
    * @param account 
    * @param task 
    * @param event 
    * @param newTask 
    * @param recipientType 
    * @param recipientCountry 
    * @param recipientId 
    * @param email 
    * @return CallCycleWrapper 
    **/
    @AuraEnabled
    public static CallCycleWrapper updateAccountAndActivityCallCycle(Account account, Task task, Event event, Task newTask,
                                                            String recipientType, String recipientCountry, String recipientId, String email) {
                                                                
        try {
            CallCycleWrapper resp = new CallCycleWrapper();
            if (account != null) {
                update account;
            }
            if (task != null) {
                update task;
            }
            if (event != null) {
                if (event.Id != null) {
                    update event;
                } else {
                    insert event;
                    resp.eventId = event.Id;
                }
            }
            if (newTask != null) {
                // BUNDIG-12626
                String rTypeId;
                if (task.Subject.contains('Reducing') || task.Subject.contains('Lapsing')) {
                    rTypeId = DM_RecordType.rtId_Task_ReducingLapsing;
                } else if (task.Subject.contains('Growing')) {
                    rTypeId = DM_RecordType.rtId_Task_CallCycle;
                } else if (task.Subject.contains('Maintaining')) {
                    rTypeId = DM_RecordType.rtId_Task_Maintaining;
                }

                newTask.Subject = task.Subject;
                newTask.WhatId = task.WhatId;
                newTask.Call_Cycle_Attempt__c = (task.Call_Cycle_Attempt__c == null) ? 1 : task.Call_Cycle_Attempt__c + 1;            
                newTask.OwnerId = task.OwnerId;
                newTask.Type = 'Phone';
                newTask.Status = 'Open';
                // BUNDIG-12626
                // newTask.RecordTypeId = task.Subject.contains('Reducing') || task.Subject.contains('Lapsing') ? DM_RecordType.rtId_Task_ReducingLapsing : DM_RecordType.rtId_Task_CallCycle;
                newTask.RecordTypeId = rTypeId;

                if (task.Objectives__c != null) {
                    newTask.Objectives__c = task.Objectives__c;
                }
                
                insert newTask;
            }
            if (recipientType != null && recipientId != null) {
                // depending on the country & object, select the right template
                Messaging.reserveSingleEmailCapacity(1);
                
                String templateName = 'Missed_call_cycle_call';
                templateName = (recipientCountry == Constants.COUNTRY_NZ ? 'NZ_' : 'AU_') + templateName;
                templateName = templateName + (recipientType == 'Contact' ? '_Contact' : '');
                List<EmailTemplate> templates = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = :templateName];
                if (templates.isEmpty()) {
                    throw new AuraHandledException('Unable to find the email template with name ' + templateName);
                }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(templates[0].Id);
                mail.setSaveAsActivity(false);
                mail.setToAddresses(new List<String>{email});
                if (recipientType == 'Contact') {
                    mail.setTargetObjectId(recipientId);
                } else {
                    mail.setTreatTargetObjectAsRecipient(false);
                    mail.setTargetObjectId([SELECT Id FROM Contact LIMIT 1].Id);
                    mail.setWhatId(recipientId);
                }
                
                Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
            }
            return resp;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description 
    * @author Bunnings Dev | 14/06/2022
    * @param contactId
    * @return Contact
    **/
    @AuraEnabled    
    public static Contact getContactSelected(Id contactId) {
        List<Contact> retContact = new List<Contact>([SELECT Id, Preferred_Contact_Method__c FROM Contact WHERE Id =:contactId]);        
        if (retContact != null) {
            return retContact[0];
        } else {
            return null;
        }
    }

    /**
    * @description 
    * @author Bunnings Dev | 14/06/2022
    * @param selectedContact
    * @return Contact
    **/
    @AuraEnabled
    public static Contact updateContactSelected(Contact selectedContact) {
        try {
            if (selectedContact != null)
                update selectedContact;
        } catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
        return selectedContact;
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