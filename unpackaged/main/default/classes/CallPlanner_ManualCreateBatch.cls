/**
 * @author            : Simplus MS
 * @last modified on  : 25/11/2021
 * @last modified by  : Simplus MS
**/
public with sharing class CallPlanner_ManualCreateBatch implements Database.Batchable<sObject> {
    
    List<String> PROFILES = new List<String>{'Account Manager', 'NZ Account Manager', 'Organisations Sales', 'Sales Person BDM', 'Sales Person BDM - Insurance', 'Sales Person Contact Centre'};

    String query;
    
    public CallPlanner_ManualCreateBatch() {
        query = 
        'SELECT Id, Name, Target_Call_Frequency__c, First_Day__c, Recurrence__c, Call_Days__c, AccountId ' +
        'FROM Contact ' +
        'WHERE Target_Call_Frequency__c != NULL AND Recurrence__c != NULL AND First_Day__c != NULL ' +
        'AND Account.Owner.isActive = TRUE ' +
        'AND Account.Owner.Name != \'Default User\' ' +
        'AND Account.Owner.Profile.Name IN :PROFILES ' +
        'AND Account.RecordType.DeveloperName IN (\'AU_Customer\', \'NZ_Customer\', \'AU_Prospect\', \'NZ_Prospect\')' +
        'AND Account.Account_Status__c IN (\'Active\', \'Referred\')' +
        'ORDER BY Account.Name ASC, Name ASC';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query: '+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        try{
            TEMP_SM_CallPlanner.executePlans(null, null, scope);
        } catch(Exception e) {
            System.debug(e);
        }
    }

    public void finish(Database.BatchableContext BC) { 

    }

}