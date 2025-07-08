/*******************************************************************************************************
* Class Name        : SM_CallPlanner
* Description       : Service layer for Plan AM Call Cycle epic
* Author            : Simplus - Yi Zhang
* Created On        : 22/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              22/06/2020      1000                Initial version
* Yi Zhang              01/09/2020      2000                Expand AM / ASM Profiles per CCRM-7142
* Simplus MS            07/10/2021      3000                CCRM15-190 provide rechecking and use of batch for large list of events, added methods checkDMLOperationRecords, getHashFromEventObj, and getHashToEventMap to use on executePlans()
* Simplus MS            04/11/2021      3001                CCRM15-190/CCRM15-379 Updated logical error on executePlans method
* Jasper R. Galapon     10/04/2024      3002                BUNDIG-12187 - Call Planner - Add 3 Week and Quarterly Target Call Frequency
******************************************************************************************************/
public without sharing class SM_CallPlanner {
    public static final List<String> TM_PROFILES = new List<String>{'Account Manager', 'NZ Account Manager', 'Organisations Sales', 'Sales Person BDM', 'Sales Person BDM - Insurance', 'Sales Person Contact Centre'};
    public static final List<String> ASM_PROFILES = new List<String>{'Sales Manager', 'NZ Sales Manager', 'System Administrator', 'National Manager', 'Organisations Sales Manager', 'Support Manager - Trade PA'};
    public static final String WEEKDAYS = 'Mon;Tue;Wed;Thu;Fri';
    public static final List<String> FREQUENCY_GROUP1 = new List<String>{'Daily', '3 x Week', 'Twice Weekly'};
    public static final Map<String, Integer> FREQUENCY_GROUP2 = new Map<String, Integer>{'Weekly'=> 7, 'Bi-Weekly'=>14, 'Every 3 weeks'=>21, 'Every 4 weeks'=>28, 'Every 8 weeks'=>56, 'Every quarter'=>91};
    public static final String DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

    public static Integer eventStartHour = 0;
    public static Integer eventStartMinute = 0;
    public static Integer eventEndHour = 0;
    public static Integer eventEndMinute = 0;

    /**
    * @description 
    * @author Yi Zhang | 22/06/2020 
    * @param runningUserId 
    * @return CallPlannerWrapper 
    **/
    @AuraEnabled
    public static CallPlannerWrapper getContacts(String runningUserId) {
        CallPlannerWrapper resp = new CallPlannerWrapper();
        User user = DM_User.getUser(runningUserId);

        // If AM, retrieve contacts, no question asked
        if(TM_PROFILES.contains(user.Profile.Name)) {
            resp.isAM = true;
            resp.contacts = DM_Contact.getContactsBasedOnAcctOwner(runningUserId).values(); //0051m000000FEmXAAW
            resp.accounts = DM_Account.getCustomerAndProspectAccountsOwnedBy(runningUserId);

            // figure out the call target
            resp.currentCallTarget = 0;
            List<Call_Targets__c> targets = DM_CallTargets.getRelatedCallTargets(new Set<Id>{runningUserId}, new Set<Id>());
            resp.callTargets = targets;
            Date today = Date.today();
            for(Call_Targets__c t : targets) {
                if(t.Start_Date__c <= today && t.End_Date__c == null) {
                    resp.currentCallTarget = Integer.valueOf(t.Total_Target__c)*20;
                } else if(t.Start_Date__c <= today && t.End_Date__c >= today) {
                    resp.currentCallTarget = Integer.valueOf(t.Total_Target__c)*20;
                }
            }
        } 
        // If ASM, retrieve managed AMs
        else if(ASM_PROFILES.contains(user.Profile.Name)) {
            resp.isASM = true;
            resp.accountManagers = (user.Profile.Name == 'System Administrator') ? 
                    DM_User.getActiveUsersOfProfiles(TM_PROFILES) : 
                    DM_User.getActiveUsersManagedBy(user.Id, TM_PROFILES);
        }


        return resp;
    }

    /**
    * @description 
    * @author Yi Zhang | 01/07/2020 
    * @param accounts 
    * @param oldContacts 
    * @param newContacts 
    * @return String 
    **/
    @AuraEnabled
    public static String executePlans(List<Account> accounts, List<Contact> oldContacts, List<Contact> newContacts) {
        try {
            // TODO validation again
            // make sure new contacts' frequency, first day, recurrence are all set
            // update accounts
            if(accounts.size() > 0) {
                update accounts;
            }            

            // update contacts
            Map<Id, Contact> oldContactMap = new Map<Id, Contact>(oldContacts);            
            Map<Id, Contact> newContactMap = new Map<Id, Contact>(newContacts);
            // for contacts in old map but not in new map, add it with null values in fields
            for(Id contactId : oldContactMap.keySet()) {
                if(newContactMap.containsKey(contactId) == false) {
                    newContactMap.put(contactId, new Contact(
                        Id = contactId,
                        Target_Call_Frequency__c = null,
                        First_Day__c = null,
                        Recurrence__c = null,
                        Call_Days__c = null,
                        AccountId = oldContactMap.get(contactId).AccountId
                        ));
                }
            }
            if(newContactMap.size() > 0) {
                update newContactMap.values();
            }
            
            // requery Account for event subjects
            List<String> accountIds = new List<String>();
            for(Contact c : newContactMap.values()) {
                accountIds.add(c.AccountId);
            }
            Map<Id, Account> accountMap = new Map<Id, Account>(DM_Account.getAccounts(accountIds));

            // Populate event start / end hour / minute
            Initialisation__mdt settings = DM_Initialisation.getCCRMInitialisation();
            List<String> splittedStrings = settings.Planned_Call_Start_Time__c.split(':');
            eventStartHour = Integer.valueOf(splittedStrings[0]);
            eventStartMinute = Integer.valueOf(splittedStrings[1]);
            splittedStrings = settings.Planned_Call_End_Time__c.split(':');
            eventEndHour = Integer.valueOf(splittedStrings[0]);
            eventEndMinute = Integer.valueOf(splittedStrings[1]);
            String returnStr = '';
            String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
            List<String> deleteEventClauses = new List<String>();
            List<Event> newEvents = new List<Event>();
            for(Id contactId: newContactMap.keySet()) {
                Contact newContact = newContactMap.get(contactId);
                Contact oldContact = oldContactMap.get(contactId);
                String subject = accountMap.get(newContact.AccountId).Name + ' - ' + newContact.Name;
                Id eventOwnerId = accountMap.get(newContact.AccountId).OwnerId;
                Id accountId = newContact.AccountId;
                if(oldContact == null) {  
                    newEvents.addAll(createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
                } else {
                    if(String.isBlank(newContact.Target_Call_Frequency__c)) {           // Remove an existing contact
                        // delete
                        deleteEventClauses.add(generateClause(contactId, null, oldContact.Recurrence__c));
                    } else {
                        if(oldContact.Target_Call_Frequency__c == newContact.Target_Call_Frequency__c) {

                            DateTime oldFirstDayTime = oldContact.First_Day__c;
                            DateTime newFirstDayTime = newContact.First_Day__c;

                            if(oldContact.First_Day__c < newContact.First_Day__c 
                                && oldFirstDayTime.format('E') == newFirstDayTime.format('E')) {     // Update first day (delete events)
                                // delete
                                deleteEventClauses.add(generateClause(contactId, null, newContact.First_Day__c.addDays(-1))); // CCRM15-190/CCRM15-379
                            }

                            if(oldContact.First_Day__c > newContact.First_Day__c
                                && oldFirstDayTime.format('E') == newFirstDayTime.format('E')) {     
                                    // Update first day (create events)

                                // create 
                                newEvents.addAll(createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, oldContact.First_Day__c.addDays(-1), newContact.Target_Call_Frequency__c, newContact.Call_Days__c)); // CCRM15-190/CCRM15-379
                            }

                            if(oldContact.First_Day__c != newContact.First_Day__c
                                && oldFirstDayTime.format('E') != newFirstDayTime.format('E')) {    // Update first day (delete & create events)
                                    // delete
                                deleteEventClauses.add(generateClause(contactId, null, oldContact.Recurrence__c));
                                // create 
                                newEvents.addAll(createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
                            }

                            if(oldContact.Recurrence__c > newContact.Recurrence__c) {   // Update recurrence (delete events)
                                // delete
                                deleteEventClauses.add(generateClause(contactId, newContact.Recurrence__c.addDays(1), oldContact.Recurrence__c));
                            }

                            if(oldContact.Recurrence__c < newContact.Recurrence__c) {  // Update recurrence (create events)

                                newEvents.addAll(
                                    createEventsChangedRecurrence(subject, eventOwnerId, contactId, accountId, oldContact.Recurrence__c.addDays(1), newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c, newContact.First_Day__c));

                                // create 
                                // rebase the start date of the new events
                                // if(frequencyList1.contains(newContact.Target_Call_Frequency__c)) {
                                //     newEvents.addAll(
                                //     createEvents(subject, eventOwnerId, contactId, accountId, 
                                //         rebaseStartDate(newContact.First_Day__c, oldContact.Recurrence__c, newContact.Target_Call_Frequency__c), 
                                //         newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
                                // }
                                // else {
                                //     newEvents.addAll(
                                //     createEvents(subject, eventOwnerId, contactId, accountId, oldContact.Recurrence__c.addDays(1), newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
                                // }

                                //createEvents(String subject, Id eventOwnerId, Id contactId, Id accountId, Date startDate, Date endDate, String frequency, String frequencyDays)

                                // deletes all task records of contact
                            }
                        } else {                                                       // Update frequency
                            // delete
                            deleteEventClauses.add(generateClause(contactId, null, oldContact.Recurrence__c));
                            // create 
                            newEvents.addAll(createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
                        }
                    }
                }
            }
            
            // C(create) D(delete) events
            String deleteEventQuery = '';
            List<String> deleteEventQueryList = new List<String>();

            // TODO if query is longer than 4,000 characters, split into multiple queries
            if(deleteEventClauses.size() > 0) {
                DateTime now = DateTime.now();
                deleteEventQuery = 'SELECT Id ' 
                + 'FROM Event '
                + 'WHERE Planned_Call__c = true ' 
                + 'AND Status__c = \'Open\' ' 
                + 'AND (' + String.join(deleteEventClauses, ' OR ') + ')';
            }
            if(String.isNotBlank(deleteEventQuery)) {
                List<Event> eventsToDelete = Database.query(deleteEventQuery);
                if(eventsToDelete.size() > 0 ) {
                    System.debug('eventsToDelete '+eventsToDelete.size());

                    if (eventsToDelete.size() < 600 ){ // to avoid CPU limit
                        System.debug('on synchronous delete');
                        delete eventsToDelete;
                        eventsToDelete = checkDMLOperationRecords(eventsToDelete, false);
                        if(eventsToDelete.size() > 0) {
                            System.debug('on synchronous delete - reprocess');
                            delete eventsToDelete;
                            eventsToDelete = checkDMLOperationRecords(eventsToDelete, false);
                            if(eventsToDelete.size() > 0) {
                                ApplicationLogger.log('SM_CallPlannerDML-delete', '', 'values: ' +JSON.serialize(eventsToDelete), 'SM_CallPlannerDML.executePlans');
                            }
                        }
                    }
                    else {
                        if(eventsToDelete.size() > 12500 || newEvents.size() > 12500)
                            return 'error';
                        else {
                            Database.executeBatch(new SM_CallPlannerBatchDML(eventsToDelete, false, false), 600);
                            returnStr = 'warning';
                        }
                    }
                }
            }

            if(newEvents.size() > 0) {
                System.debug('newEvents '+newEvents.size());
                if (newEvents.size() < 2000 ){ // to avoid CPU limit
                    System.debug('on synchronous insert');
                    insert newEvents;
                    newEvents = checkDMLOperationRecords(newEvents, true);
                    if(newEvents.size() > 0) {
                        System.debug('on synchronous insert - reprocess');
                        insert newEvents;
                        newEvents = checkDMLOperationRecords(newEvents, true);
                        if(newEvents.size() > 0) {
                            ApplicationLogger.log('SM_CallPlannerDML-insert', '', 'values: ' +JSON.serialize(newEvents), 'SM_CallPlannerDML.executePlans');
                        }
                    }
                }
                else {
                    if(newEvents.size() > 12500) {
                        return 'error';
                    } else {
                        Database.executeBatch(new SM_CallPlannerBatchDML(newEvents, true, false), 2000);
                        returnStr = 'warning';
                    }
                }
            }

            returnStr = (returnStr != '') ? returnStr : 'query: ' + deleteEventQuery + '        new: ' + (newEvents.size());
            return returnStr;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }

    /**
    * @description - checks if current DB records is as expected of expected operation
    * @author Simplus MS | 06/10/2021 
    * @param List<Event> eventList - event List
    * @param Boolean isInsert - set to true if insert operation, set to false if delete operation
    * @return List<Event> 
    **/
    public static List<Event> checkDMLOperationRecords(List<Event> eventsList, Boolean isInsert) {

        if(isInsert) {
            Set<String> subjectSet = new Set<string>();
            Set<Datetime> startDateTimeSet = new Set<Datetime>();
            Set<Datetime> endDateTimeSet = new Set<Datetime>();
            Set<Id> whoIdSet = new Set<Id>();
            Set<Id> whatIdSet = new Set<Id>();
            Set<Id> ownerIdSet = new Set<Id>();
            Map<String, Event> origHashToEventMap = getHashToEventMap(eventsList); //hashString->event to set Event fields as key
            
            for(Event ev : eventsList) {
                subjectSet.add(ev.Subject);
                startDateTimeSet.add(ev.StartDateTime);
                endDateTimeSet.add(ev.EndDateTime);
                whoIdSet.add(ev.WhoId);
                whatIdSet.add(ev.WhatId);
                ownerIdSet.add(ev.OwnerId);
            }

            List<Event> retrievedEventsList = [
                SELECT Id, Subject, EventSubtype, Sub_type__c, Status__c, StartDateTime, EndDateTime, WhoId, WhatId, Planned_Call__c, OwnerId
                FROM Event
                WHERE Subject IN :subjectSet
                    AND StartDateTime IN :startDateTimeSet
                    AND EndDateTime IN :endDateTimeSet
                    AND WhoId IN :whoIdSet
                    AND WhatId IN :whatIdSet
                    AND OwnerId IN :ownerIdSet
                    AND EventSubtype = 'Event' AND Sub_type__c = 'Engagement Call' AND Status__c = 'Open' AND Planned_Call__c = true
            ];

            if(retrievedEventsList.size() > 0) {
                for(Event ev : retrievedEventsList) {
                    String currentHash = getHashFromEventObj(ev);
                    origHashToEventMap.remove(currentHash); // remove existing Events on record
                }
            }

            return origHashToEventMap.values();
        } else {
            List<Event> retrievedEventsList = new List<Event>();
            Set<Id> eventIdSet = new Set<Id>();
            for(Event ev : eventsList) {
                eventIdSet.add(ev.Id);
            }
            retrievedEventsList = [
                SELECT Id FROM Event 
                WHERE Id IN :eventIdSet 
                ];
            return retrievedEventsList;
        }
        
    }
    
    private static String getHashFromEventObj(Event ev) {
        return ev.Subject + String.valueOfGmt(ev.StartDateTime) + String.valueOfGmt(ev.EndDateTime) + ev.WhoId + ev.WhatId + ev.OwnerId;
    }
    
    private static Map<String, Event> getHashToEventMap(List<Event> eventsList) {
        Map<String, Event> hashToEventMap = new Map<String, Event>();
        for(Event ev : eventsList) {
            hashToEventMap.put(getHashFromEventObj(ev), ev);
        }
        return hashToEventMap;
    }

    /**
    * @description 
    * @author Yi Zhang | 02/07/2020 
    * @param whoId 
    * @param startDate 
    * @param endDate 
    * @return String 
    **/
    public static String generateClause(String whoId, Date startDate, Date endDate) {
        String strQuery = '(WhoId = \'' + whoId + '\'';
        
        if(startDate != null) // use for oldContact.Recurrence__c > newContact.Recurrence__c Ln 161
            strQuery = strQuery + ' AND StartDateTime >= ' + formatStartDate(startDate);
        
        strQuery = strQuery +  ' AND EndDateTime <= ' + formatEndDate(endDate) + ')';
        return strQuery;
        // Only Delete events in the future, so start date is no longer required
        // AND StartDateTime >= ' + formatStartDate(startDate) + '
    }

    /**
    * @description 
    * @author Yi Zhang | 02/07/2020 
    * @param d 
    * @return String 
    **/
    public static String formatStartDate(Date d) {
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day(), 0, 0, 0);
        return dt.formatGmt(DATETIME_FORMAT);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 02/07/2020 
    * @param d 
    * @return String 
    **/
    public static String formatEndDate(Date d) {
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day(), 23, 59, 59);
        return dt.formatGmt(DATETIME_FORMAT);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 02/07/2020 
    * @param subject 
    * @param eventOwnerId 
    * @param contactId 
    * @param startDate 
    * @param endDate 
    * @param frequency 
    * @param frequencyDays 
    * @return List<Event> 
    **/
    public static List<Event> createEvents(String subject, Id eventOwnerId, Id contactId, Id accountId, Date startDate, Date endDate, String frequency, String frequencyDays) {
        List<Event> events = new List<Event>();
        Integer daysBetween = startDate.daysBetween(endDate);
        frequencyDays = (frequency == 'Daily') ? WEEKDAYS : frequencyDays;
        for(Integer i = 0; i <= daysBetween; ) {
            DateTime dt = (DateTime) startDate.addDays(i);

            System.debug('***frequency: ' + frequency);

            // 'Daily', '3 x Week', 'Twice Weekly'
            if(FREQUENCY_GROUP1.contains(frequency)) { 
                if(frequencyDays.contains(dt.format('E'))) {
                    events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                }
                i++;
            }
            // 'Weekly'=> 7, 'Bi-Weekly'=>14, 'Every 3 weeks'=>21, 'Every 4 weeks'=>28, 'Every 8 weeks'=>56, 'Every quarter'=>91
            else if(FREQUENCY_GROUP2.containsKey(frequency)) { 
                //System.debug(LoggingLevel.DEBUG, 'contactId: ' + contactId);
                events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                i = i + FREQUENCY_GROUP2.get(frequency);
            } else {
                break;
            }
        }
        return events;
    }

    /**
    * @description 
    * @author Simplus MS | 09/11/2021 
    **/
    public static List<Event> createEventsChangedRecurrence(String subject, Id eventOwnerId, Id contactId, Id accountId, Date startDate, Date endDate, String frequency, String frequencyDays, Date newFirstDate) {
        List<Event> events = new List<Event>();
        Integer daysBetween = startDate.daysBetween(endDate);
        frequencyDays = (frequency == 'Daily') ? WEEKDAYS : frequencyDays;

        if(FREQUENCY_GROUP2.containsKey(frequency)) { 
            // 'Weekly'=> 7, 'Bi-Weekly'=>14, 'Every 4 weeks'=>28, 'Every 8 weeks'=>56
            Integer daysBetweenFreq2 = newFirstDate.daysBetween(endDate);

            for(Integer i = 0; i <= daysBetweenFreq2; ) {
                Date curDate = newFirstDate.addDays(i);
                DateTime dt = (DateTime) newFirstDate.addDays(i);
                if(curDate >= startDate) {
                    events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                }
                i = i + FREQUENCY_GROUP2.get(frequency);
            }
        } else if(FREQUENCY_GROUP1.contains(frequency)) { 
            for(Integer i = 0; i <= daysBetween; ) {
                DateTime dt = (DateTime) startDate.addDays(i);
    
                // 'Daily', '3 x Week', 'Twice Weekly'
                if(frequencyDays.contains(dt.format('E'))) {
                    events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                }
                i++;
            }
        }
        return events;
    }

    /**
    * @description 
    * @author Yi Zhang | 02/07/2020 
    * @param subject 
    * @param eventOwnerId 
    * @param whoId 
    * @param startDate 
    * @return Event 
    **/
    public static Event createEvent(String subject, Id eventOwnerId, Id whoId, Id whatId, DateTime startDate) {
        DateTime startDateTime = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
        return new Event(
            Subject = subject,
            //RecordTypeId = '',
            EventSubtype = 'Event',
            Sub_type__c = 'Engagement Call', // new value Engagement Call, label Purpose
            Status__c = 'Open',              // label Event Status
            StartDateTime = startDateTime.addHours(eventStartHour).addMinutes(eventStartMinute),
            EndDateTime = startDateTime.addHours(eventEndHour).addMinutes(eventEndMinute),
            WhoId = whoId,
            WhatId = whatId,
            Planned_Call__c = true,
            OwnerId = eventOwnerId
        );
    }

    // /**
    // * @description 
    // * @author Yi Zhang | 02/07/2020 
    // * @param newFirstDay 
    // * @param oldRecurrence 
    // * @param frequency 
    // * @return Date 
    // **/
    // public static Date rebaseStartDate(Date newFirstDay, Date oldRecurrence, String frequency) {
    //     if(FREQUENCY_GROUP1.contains(frequency)) {
    //         return oldRecurrence;
    //     }
    //     if(FREQUENCY_GROUP2.containsKey(frequency)) {
    //         Integer gap = FREQUENCY_GROUP2.get(frequency);
    //         Integer daysBetween = newFirstDay.daysBetween(oldRecurrence);
    //         // if daysBetween is 0 or negative, means a new start
    //         if(daysBetween <= 0) {
    //             return newFirstDay;
    //         }
    //         daysBetween = Math.mod(daysBetween, gap);
    //         if(daysBetween == 0) {
    //             return oldRecurrence;
    //         } else {
    //             return oldRecurrence.addDays(gap - daysBetween);
    //         }
    //     }
    //     return oldRecurrence;
    // }
    
    /**
     * @description Wrapper class for AuraEnabled methods
     */
    public class CallPlannerWrapper {
        @AuraEnabled
        public List<Contact> contacts;      // all contacts belonging to the AM
        @AuraEnabled
        public List<Account> accounts;      // all accounts belonging to the AM
        @AuraEnabled
        public Boolean isAM;                // AM flag, if running user is of Account Manager, NZ Account Manager profiles
        @AuraEnabled
        public Boolean isASM;               // ASM flag, if running user is of Sales Manager, NZ Sales Manager profiles
        @AuraEnabled
        public List<User> accountManagers;     // Used by ASM
        @AuraEnabled
        public Integer currentCallTarget;   // Call Target as of today
        @AuraEnabled
        public List<Call_Targets__c> callTargets;   // All Call Targets
        
    }
}