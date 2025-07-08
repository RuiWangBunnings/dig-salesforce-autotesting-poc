/**
 * @author            : Simplus MS
 * @last modified on  : 03/12/2021
 * @last modified by  : Simplus MS
**/
public with sharing class PlannedLeaveTriggerHandler {
    
    public static void beforeInsert(List<Planned_Leave__c> PlsList) {
        Map<Id,Id> userIdToMgrIdMap = new Map<Id,Id>();
        for(Planned_Leave__c PL : PlsList) {
            userIdToMgrIdMap.put(PL.OwnerId, null);
        }
        List<User> userList = [SELECT Id, ManagerId FROM User WHERE Id IN :userIdToMgrIdMap.keySet()];
        for (User u : userList) {
            userIdToMgrIdMap.put(u.Id, u.ManagerId);
        }
        if(userIdToMgrIdMap != null) {
            for(Planned_Leave__c PL : PlsList) {
                PL.Approver__c = userIdToMgrIdMap.get(PL.OwnerId);
            }
        }
    }
    
    public static void beforeUpdate(Map<Id,Planned_Leave__c> PlsMap) {
        Map<Id,String> PlIdToCommentMap = new Map<Id,String>();
        List<ProcessInstance> piList = [
            SELECT Id, TargetObjectId, Status, 
            (SELECT Id, StepStatus, Comments 
            FROM Steps WHERE StepStatus IN ('Approved','Rejected'))
            FROM ProcessInstance WHERE TargetObjectId IN :PlsMap.keySet() AND Status != 'Removed'
        ];
        system.debug(piList);
        if(piList != null) {
            for(ProcessInstance pi : piList) {
                if(pi.Steps != null && pi.Steps[0].Comments != null)
                    PlIdToCommentMap.put(pi.TargetObjectId, pi.Steps[0].Comments);
            }
        }
        for(Planned_Leave__c pl : PlsMap.values()) {
            pl.Approver_Comment__c = (PlIdToCommentMap.get(pl.Id) != null) ? PlIdToCommentMap.get(pl.Id) : '';
        }
    }
    
    public static void afterUpdate(List<Planned_Leave__c> PlsList) {
        getRelatedTaskRecord(PlsList);        
    }
    
    /**
    * @description  Business logic after planned leave update CCRM15-414
    * @param newList 
    **/
    public static void getRelatedTaskRecord(List<Planned_Leave__c> PlsList) {

        Date addedDays;
        Integer daysCount;
        Map<Id,Planned_Leave__c> ownerIdAndStatusMap = new Map<Id,Planned_Leave__c>();
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        List<Task> updateTaskList = new List<Task>();
        Set<Date> plannedLeaveSet = new Set<Date>();

        //Get all the planned leave record when status is approved or leave cancelled
        for(Planned_Leave__c plannedL : PlsList) {
            if(plannedL.Status__c == 'Approved' || plannedL.Status__c == 'Leave Cancelled') {
                ownerIdAndStatusMap.put(plannedL.OwnerId, plannedL);
            }
            if(plannedL.Start_Date__c < plannedL.End_Date__c ) {
                System.debug('Start date are less than End Date');
                daysCount = plannedL.Start_Date__c.daysBetween(plannedL.End_Date__c);
                System.debug('daysCount '+daysCount);
                plannedLeaveSet.add(plannedL.End_Date__c);
                plannedLeaveSet.add(plannedL.Start_Date__c);
                for(Integer i=1;i<=daysCount;i++) {
                    addedDays = plannedL.Start_Date__c+i;
                    plannedLeaveSet.add(addedDays);
                }
                System.debug('plannedLeaveSetIF>> '+plannedLeaveSet);
                
            }
            if(plannedL.Start_Date__c == plannedL.End_Date__c) {
                System.debug('Start and End Date are equal');
                plannedLeaveSet.add(plannedL.End_Date__c);
                System.debug('plannedLeaveSet2If>> '+plannedLeaveSet);
            }
        }
        System.debug('Planned Leave Owner Status Map>> '+ownerIdAndStatusMap);
        System.debug('planned Leave Date Set>> '+plannedLeaveSet);
        
        //Get all the task with same owner Id as planned Leave
        List<Task> relatedTaskList = [Select Id, RecordTypeId, RecordType.Name, OwnerId, ActivityDate, Previous_Record_Type__c,Status From Task Where OwnerId In: ownerIdAndStatusMap.KeySet()];
        System.debug('Task Records>> '+relatedTaskList);
        List<RecordType> recordTypeList = [Select Id, Name, SobjectType From RecordType Where SobjectType = 'Task'];
        System.debug('Task Record Type>> '+recordTypeList);

        //Create Map of recordttype name and Id
        for(RecordType r: recordTypeList) {
            recordTypeMap.put(r.Name, r.Id);
        }
        System.debug('Task Record Type Map>> '+recordTypeMap);
        
        for(Task tasks : relatedTaskList) {
            if(ownerIdAndStatusMap.get(tasks.OwnerId).Status__c == 'Approved' && plannedLeaveSet.contains(tasks.ActivityDate)
              && (tasks.RecordTypeId == recordTypeMap.get('Call Cycle Call') || tasks.RecordTypeId == recordTypeMap.get('Reducing and Lapsing Call') || tasks.RecordTypeId == recordTypeMap.get('Apprentice Follow up Calls')))
            {
                System.debug('Inside If');
                tasks.Previous_Record_Type__c = tasks.RecordType.Name;
                tasks.RecordTypeId = recordTypeMap.get('On Leave');
                tasks.Status = 'Completed';
                updateTaskList.add(tasks);
            }
            else if(ownerIdAndStatusMap.get(tasks.OwnerId).Status__c == 'Leave Cancelled' && tasks.RecordTypeId == recordTypeMap.get('On Leave')) 
            {
                System.debug('Inside Elseif');
                tasks.RecordTypeId = recordTypeMap.get( tasks.Previous_Record_Type__c);
                updateTaskList.add(tasks);
            }
        }
        System.debug('Task to Update>> '+updateTaskList);
        if(updateTaskList.size() > 0) {
            update updateTaskList;
        }
    }
    
}