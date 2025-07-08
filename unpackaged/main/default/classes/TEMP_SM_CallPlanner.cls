/*******************************************************************************************************
* Class Name        : SM_CallPlanner
* Description       : 
* Author            : Simplus MS
* Created On        : 
* Modification Log  :
******************************************************************************************************/

public without sharing class TEMP_SM_CallPlanner {
    public static final List<String> TM_PROFILES = new List<String>{'Account Manager', 'NZ Account Manager', 'Organisations Sales', 'Sales Person BDM', 'Sales Person BDM - Insurance', 'Sales Person Contact Centre'};
    public static final List<String> ASM_PROFILES = new List<String>{'Sales Manager', 'NZ Sales Manager', 'System Administrator', 'National Manager', 'Organisations Sales Manager', 'Support Manager - Trade PA'};
    public static final String WEEKDAYS = 'Mon;Tue;Wed;Thu;Fri';
    public static final List<String> FREQUENCY_GROUP1 = new List<String>{'Daily', '3 x Week', 'Twice Weekly'};
    public static final Map<String, Integer> FREQUENCY_GROUP2 = new Map<String, Integer>{'Weekly'=> 7, 'Bi-Weekly'=>14, 'Every 4 weeks'=>28, 'Every 8 weeks'=>56};
    public static final String DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

    public static Integer eventStartHour = 0;
    public static Integer eventStartMinute = 0;
    public static Integer eventEndHour = 0;
    public static Integer eventEndMinute = 0;

    @AuraEnabled
    public static String executePlans(List<Account> accounts, List<Contact> oldContacts, List<Contact> newContacts) {
        try {
            // update contacts
            Map<Id, Contact> newContactMap = new Map<Id, Contact>(newContacts);
            // for contacts in old map but not in new map, add it with null values in fields
            for(Contact con : newContacts) {
                newContactMap.put(con.Id, con);
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
                String subject = accountMap.get(newContact.AccountId).Name + ' - ' + newContact.Name;
                Id eventOwnerId = accountMap.get(newContact.AccountId).OwnerId;
                Id accountId = newContact.AccountId;

                newEvents.addAll(createEvents(subject, eventOwnerId, contactId, accountId, newContact.First_Day__c, newContact.Recurrence__c, newContact.Target_Call_Frequency__c, newContact.Call_Days__c));
            }
            

            if(newEvents.size() > 0) {
                System.debug('newEvents '+newEvents.size());
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
            return '';
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
        } 
        else return null;
        
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
        Set<Event> events = new Set<Event>();
        Integer daysBetween = startDate.daysBetween(endDate);
        frequencyDays = (frequency == 'Daily') ? WEEKDAYS : frequencyDays;
        for(Integer i = 0; i <= daysBetween; ) {
            DateTime dt = (DateTime) startDate.addDays(i);

            // 'Daily', '3 x Week', 'Twice Weekly'
            if(FREQUENCY_GROUP1.contains(frequency)) { 
                if(frequencyDays.contains(dt.format('E'))) {
                    events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                }
                i++;
            }
            // 'Weekly'=> 7, 'Bi-Weekly'=>14, 'Every 4 weeks'=>28, 'Every 8 weeks'=>56
            else if(FREQUENCY_GROUP2.containsKey(frequency)) { 
                //System.debug(LoggingLevel.DEBUG, 'contactId: ' + contactId);
                events.add(createEvent(subject, eventOwnerId, contactId, accountId, dt));
                i = i + FREQUENCY_GROUP2.get(frequency);
            } else {
                break;
            }
        }
        events.remove(null);
        List<Event> evs = new List<Event>();
        for(Event ev : events) {
            evs.add(ev);
        }
        return evs;
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
        if(startDateTime >= currentMonthDateTime()) {
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
        else return null;
        
    }
    public static DateTime currentMonthDateTime() {
        return DateTime.newInstance(Date.today().year(), Date.today().month(), 1, 0, 0, 0);
    }
}