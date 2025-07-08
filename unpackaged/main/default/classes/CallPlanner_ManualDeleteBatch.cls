/**
 * @author            : Simplus MS
 * @last modified on  : 25/11/2021
 * @last modified by  : Simplus MS
**/
public with sharing class CallPlanner_ManualDeleteBatch implements Database.Batchable<sObject> {

    String query;
    Integer retryCount = 0;
    List<String> PROFILES = new List<String>{'Account Manager', 'NZ Account Manager', 'Organisations Sales', 'Sales Person BDM', 'Sales Person BDM - Insurance', 'Sales Person Contact Centre'};
    List<String> ACC_RECTYPES = new List<String>{'AU_Customer', 'NZ_Customer', 'AU_Prospect', 'NZ_Prospect'};
    List<String> ACC_STATUS = new List<String>{'Active', 'Referred'};

    public CallPlanner_ManualDeleteBatch(Integer retCount) {
        query = 
        'SELECT Id, WhatId, TYPEOF What WHEN Account THEN Owner.Profile.Name, RecordType.DeveloperName, Account_Status__c, Owner.isActive, Owner.Name END ' +
        'FROM Event ' +
        'WHERE EventSubtype = \'Event\' AND Sub_type__c = \'Engagement Call\' AND Status__c =\'Open\' AND Planned_Call__c = true ' +
        'AND StartDateTime >= THIS_MONTH AND What.Type=\'Account\' AND Who.Type=\'Contact\'';

        this.retryCount = retCount;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query: '+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Event> scope) {
        if(this.retryCount < 2) {
            List<Event> evs = filterEvents(scope);
            Database.delete(evs, false);
        }
    }

    public void finish(Database.BatchableContext BC) { 
        Integer retCount = this.retryCount + 1;
        if(this.retryCount < 2) {
            Database.executeBatch(new CallPlanner_ManualDeleteBatch(retCount), 100);
        } else {
            Database.executeBatch(new CallPlanner_ManualCreateBatch(), 10);
        }
    }

    private List<Event> filterEvents(List<Event> evs) {
        List<Event> returnEvs = new List<Event>();
        for(Event ev : evs) {
            if(ev.What instanceOf Account) {
                Account acc = ev.What;
                if(PROFILES.contains(acc.Owner.Profile.Name) && 
                ACC_RECTYPES.contains(acc.RecordType.DeveloperName) && 
                ACC_STATUS.contains(acc.Account_Status__c) && acc.Owner.IsActive == true &&
                acc.Owner.Name != 'Default User')
                    returnEvs.add(ev);
            }
        }
        return returnEvs;
    }

}