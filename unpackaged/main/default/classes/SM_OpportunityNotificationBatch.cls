/*******************************************************************************************************
* Class Name      	: SM_OpportunityNotificationBatch
* Description		: Service layer for Opportunity Related Notification Batch
* Author          	: Simplus - Yi Zhang
* Created On      	: 04/09/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              04/09/2020		1000				Initial version
******************************************************************************************************/
global class SM_OpportunityNotificationBatch implements Database.Batchable<sObject>, Schedulable {
    
    String query;
    Date d1;
    Date d2;
    Date d3;

    /**
    * @description 
    * @author Yi Zhang | 04/09/2020 
    **/
    global SM_OpportunityNotificationBatch() {
        Date d = Date.today();
        d1 = d.addDays(5);
        d2 = d.addDays(20);
        d3 = d.addDays(25);
        query = 'SELECT Id, Name, Account.Name, StageName, CloseDate, OwnerId, ' + 
        '(SELECT Field, OldValue, NewValue, CreatedDate FROM Histories ORDER BY CreatedDate DESC LIMIT 1), ' + 
        '(SELECT Id FROM Tasks WHERE ActivityDate > TODAY AND Status = \'Open\' LIMIT 1), ' + 
        '(SELECT Id FROM Events WHERE ActivityDate > TODAY LIMIT 1) ' + 
        'FROM Opportunity ' + 
        'WHERE (StageName IN (\'Presenting\', \'Pending\') ' + 
        'AND RecordType.Name IN (\'Estimate Opportunity\', \'Farm Shed Opportunity\', \'Schedule Opportunity\', \'NZ Standard Opportunity\') ' + 
        'AND (CloseDate = :d1 OR CloseDate = :d2 OR CloseDate = :d3)) ' + 
        'OR (StageName = \'Proposal Ready\' ' + 
        'AND RecordType.Name IN (\'Estimate Opportunity\', \'Farm Shed Opportunity\', \'Schedule Opportunity\') ' + 
        ')';
        // List<Opportunity> opps = [
        //     SELECT Id, RecordType.Name, StageName, CloseDate, OwnerId, 
        //             (SELECT Field, OldValue, NewValue, CreatedDate FROM Histories ORDER BY CreatedDate DESC LIMIT 1),
        //             (SELECT Id FROM Tasks WHERE ActivityDate >= TODAY AND Status = 'Open' LIMIT 1),
        //             (SELECT Id FROM Events WHERE ActivityDate >= TODAY LIMIT 1)
        //             FROM Opportunity 
        //             WHERE StageName = 'Presenting' 
        //             AND RecordType.Name IN ('Estimate Opportunity', 'Farm Shed Opportunity', 'Schedule Opportunity', 'NZ Standard Opportunity')
        //             AND (CloseDate = :d1 OR CloseDate = :d2 OR CloseDate = :d3)
        // ];
    }

    /**
    * @description 
    * @author Yi Zhang | 04/09/2020 
    * @param BC 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Yi Zhang | 04/09/2020 
    * @param BC 
    * @param scope 
    **/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> opps = (List<Opportunity>) scope;
        try {
            for(Opportunity oppty : opps) {

                // CCRM-290, follow up notification, for pending / presenting only
                if(oppty.StageName == 'Presenting' || oppty.StageName == 'Pending') {
                    // no future dated activity
                    // no change to opportunity since the stage change
                    if(oppty.Tasks.isEmpty() && oppty.Events.isEmpty()
                        && (oppty.Histories.isEmpty() || oppty.Histories[0].Field == 'StageName')) {
                        // generate notification
                        Map<String, Object> flowInput = new Map<String, Object>();
                        flowInput.put('customNotificationTypeName', 'Opportunity Notification');
                        flowInput.put('targetId', oppty.Id);
                        flowInput.put('recipientIds', new List<String>{oppty.OwnerId});
                        if(oppty.CloseDate == d1) {
                            flowInput.put('notificationTitle', 'Opportunity Closing Soon');
                            flowInput.put('notificationBody', oppty.Name + ' is due to close in five days and requires your attention.');
                        } else if(oppty.CloseDate == d2 || oppty.CloseDate == d3) {
                            flowInput.put('notificationTitle', 'Opportunity Follow Up');
                            flowInput.put('notificationBody', oppty.Name + ' requires follow up.');
                        }
                        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
                        sendCustomNotifiFlow.start();
                    }
                }
                // CCRM-289, overdue notification, for proposal ready 
                if(oppty.StageName == 'Proposal Ready') {
                    
                    System.debug(LoggingLevel.DEBUG, JSON.serialize(oppty));
                    System.debug(LoggingLevel.DEBUG, JSON.serialize(oppty.Histories));

                    // opportunity is not updated (stage changed, or any activity created) for 7 calendar days since being set to Proposal Ready, 
                    // and does not have a future dated activity
                    if(oppty.Tasks.isEmpty() && oppty.Events.isEmpty()
                    && oppty.Histories.isEmpty() == false && oppty.Histories[0].Field == 'StageName' 
                    && oppty.Histories[0].CreatedDate.date() == Date.today() - 7) {
                        // generate notification
                        Map<String, Object> flowInput = new Map<String, Object>();
                        flowInput.put('customNotificationTypeName', 'Opportunity Notification');
                        flowInput.put('targetId', oppty.Id);
                        flowInput.put('recipientIds', new List<String>{oppty.OwnerId});
                        flowInput.put('notificationTitle', 'Overdue Opportunity');
                        flowInput.put('notificationBody', ' Opportunity ' + oppty.Name + ' is overdue for presentation to ' + oppty.Account.Name + '. Please review immediately.');
                        Flow.Interview.Send_Custom_Notification sendCustomNotifiFlow = new Flow.Interview.Send_Custom_Notification(flowInput);
                        sendCustomNotifiFlow.start();
                    }
                }
                
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_OpportunityNotificationBatch.execute', 'Opportunity', 'Batch', e);
        }
        
        
    }

    /**
    * @description 
    * @author Yi Zhang | 04/09/2020 
    * @param BC 
    **/
    global void finish(Database.BatchableContext BC) {
        // finish code
    }

    /**
    * @description 
    * @author Yi Zhang | 04/09/2020 
    * @param SC 
    **/
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_OpportunityNotificationBatch(), 150);
    }
}