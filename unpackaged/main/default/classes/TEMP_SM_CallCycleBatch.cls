/*******************************************************************************************************
* Class Name      	: TEMP_SM_CallCycleBatch
* Description		: A Batchable, Schedulable to create Call Cycle Tasks for Trade Specialists
* Author          	: Simplus MS
* Created On      	: 03/08/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* 03/08/2021          03/08/2021		1000				Initial version
******************************************************************************************************/
public class TEMP_SM_CallCycleBatch implements Database.Batchable<sObject>, Schedulable { 
    
    String query;

    public TEMP_SM_CallCycleBatch() {
        query = 'SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Team_Member__c ' + 
            ' FROM Store_Member__c ' + 
            ' WHERE Status__c = \'' + Constants.STOREMEMBER_ACTIVE_STATUS + '\' ' + 
            ' AND Role__c = \'' + Constants.STOREMEMBER_TS_ROLENAME + '\' ' + 
            ' AND Team_Member__r.IsActive = true ' + 
            ' AND Team_Member__r.Is_TS__c = true ' + 
            ' AND Store__r.Engagement_Model__c != null ' + 
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
        try {
            for(Store_Member__c member : scope) {
                TEMP_SM_CallCycle.createMonthlyCallCycle(member);
            }    
        } catch(Exception e) {
            ApplicationLogger.log('TEMP_SM_CallCycle', 'Task', 'Batch', e);
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
        Database.executeBatch(new TEMP_SM_CallCycleBatch(), 10);
    }
}