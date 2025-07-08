/*******************************************************************************************************
* Class Name      	: SM_LifeCycleCallCycleBatch
* Description		: A Batchable, Schedulable to create Life Cycle Call Cycle Tasks for Trade Specialists
* Author          	: Bunnings Dev
* Created On      	: 17/05/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				    Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev              17/05/2022		1000				Initial version (SFSUP-716)
******************************************************************************************************/
public class SM_LifeCycleCallCycleBatch implements Database.Batchable<sObject>, Schedulable {

    String teamMbrId;
    String query;
    String bizDateStart;

    public SM_LifeCycleCallCycleBatch(String teamMbrId, String bizDateStart) {
        this.teamMbrId = teamMbrId;
        this.bizDateStart = bizDateStart;
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {        

        query = 'SELECT Id, Store__c, Store__r.Engagement_Model__c, Store__r.Location_Type__c, Store__r.Country__c, Store__r.Store_Call__c,' +
            ' Team_Member__c, Team_Member_Call__c, Call_Volume__c, Team_Member__r.Country__c ' + 
            ' FROM Store_Member__c ' + 
            ' WHERE Status__c = \'' + Constants.STOREMEMBER_ACTIVE_STATUS + '\' ' + 
            ' AND Role__c = \'' + Constants.STOREMEMBER_TS_ROLENAME + '\' ' + 
            ' AND Team_Member__r.IsActive = true ' +
            ' AND Team_Member__r.Is_TS__c = true ' +
            ' AND Store__r.LifeCycle_Model__c = \'Active\' ' +            
            ' AND Store__r.Location_Type__c IN (\'' + Constants.STORE_TYPE_WAREHOUSE + '\', \'' + Constants.STORE_TYPE_STORE + '\') ';
        
        if (teamMbrId != null) {
			query += ' AND Team_Member__c =:teamMbrId';
		}

        query += ' ORDER BY Id ASC';

        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Store_Member__c> scope) {
        try {
            for (Store_Member__c member : scope) {
                System.debug('***member: '+member);

                SM_CallCycle.createMonthlyLifeCycleCallCycle(member, bizDateStart);
            }
        } catch (Exception e) {
            ApplicationLogger.log('SM_LifeCycleCallCycleBatch', 'Task', 'Batch', e);
        }

    }

    public void finish(Database.BatchableContext BC) {
        AsyncApexJob asyncJob = [SELECT Status, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        List<String> toS = new List<String>{asyncJob.CreatedBy.Email};
        String msg = 'The batch Apex job processed ' + asyncJob.TotalJobItems + ' batches with '+ asyncJob.NumberOfErrors + ' failures.';

        CSUtils.sendEmail(toS, 'SM_LifeCycleCallCycleBatch - ' + asyncJob.Status, msg);
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_LifeCycleCallCycleBatch(null, null), 10);
    }


}