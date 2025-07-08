/*******************************************************************************************************
* Class Name      	: SM_CallCycleBatch
* Description		: A Batchable, Schedulable to create Call Cycle Tasks for Trade Specialists
* Author          	: Simplus - Yi Zhang
* Created On      	: 22/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang                  22/07/2020		1000				Initial version
* Simplus MS                20/10/2021		2000				Added Logic for CCRM15-79 & CCRM15-80
* Bunnings Dev              26/05/2022      3000                SFSUP-716 - LifeCycle Model roll-out                
******************************************************************************************************/
public class SM_CallCycleBatch implements Database.Batchable<sObject>, Schedulable {
    
    String query;

    public SM_CallCycleBatch() {
        query = 'SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Store__r.Country__c, Store__r.Store_Call__c, ' +
        'Team_Member__c, Team_Member_Call__c, Call_Volume__c, Team_Member__r.Country__c ' + 
        ' FROM Store_Member__c ' + 
        ' WHERE Status__c = \'' + Constants.STOREMEMBER_ACTIVE_STATUS + '\' ' + 
        ' AND Role__c = \'' + Constants.STOREMEMBER_TS_ROLENAME + '\' ' + 
        ' AND Team_Member__r.IsActive = true ' + 

        // For single user testing, PLEASE REMOVE IF TO RUN FULL FUNCTION
        //' AND Team_Member__c IN (\'0059D0000036I3dQAE\', \'0059D000002v51XQAQ\' )' + 

        ' AND Team_Member__r.Is_TS__c = true ' + 
        ' AND Store__r.Engagement_Model__c != null ' +
        ' AND Store__r.LifeCycle_Model__c = null ' + // SFSUP-716
        ' AND Store__r.Location_Type__c IN (\'' + Constants.STORE_TYPE_WAREHOUSE + '\', \'' + Constants.STORE_TYPE_STORE + '\') ' + 
        ' ORDER BY Id ASC';

        // List<Store_Member__c> members = [
            // SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Team_Member__c 
            // FROM Store_Member__c
            // WHERE Status__c = 'Active'
            // AND Role__c = 'Trade Specialist'
            // AND Team_Member__r.IsActive = true
            // AND Team_Member__r.Is_TS__c = true
            // AND Store__r.Engagement_Model__c != null
            // AND Store__r.Location_Type__c IN ('Warehouse', 'Small Format Store')
            // ORDER BY Id ASC
        // ];
    }

    /**
    * @description 
    * @author Yi Zhang | 22/07/2020 
    * @param BC 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query: '+query);
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Yi Zhang | 22/07/2020 
    * @param BC 
    * @param scope 
    **/
    public void execute(Database.BatchableContext BC, List<Store_Member__c> scope) {
        // execute code
        System.debug('scope: '+scope);
        try {
            for(Store_Member__c member : scope) {
                System.debug('member: '+member);
                SM_CallCycle.createMonthlyCallCycle(member);
            }    
        } catch(Exception e) {
            ApplicationLogger.log('SM_CallCycleBatch', 'Task', 'Batch', e);
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 22/07/2020 
    * @param BC 
    **/
    public void finish(Database.BatchableContext BC) {
        // finish code
    }

    /**
    * @description 
    * @author Yi Zhang | 22/07/2020 
    * @param SC 
    **/
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_CallCycleBatch(), 10);
    }
}