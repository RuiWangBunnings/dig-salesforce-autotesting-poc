/**
 * @author            : Simplus MS
 * @last modified on  : 13/10/2021
 * @last modified by  : Simplus MS
 * @description       : Created in place of CCRM15-190 calendar events not being created on user's calendar
**/
public with sharing class SM_CallPlannerBatchDML implements Database.Batchable<sObject> {
    
    private list<Event> eventsList = new list<Event>(); 
    private Boolean isSecondRun = false;
    private Boolean isInsert = false;
    private final String SUCCESS_TITLE = 'Calendar Update Success';
    private final String SUCCESS_BODY = 'Your calendar is now updated with your confirmed call plans.';
    private final String FAILED_TITLE = 'Calendar Update Unsuccessful/Incomplete';
    private final String FAILED_BODY = 'Your calendar was not successfully updated to the call plans you\'ve confirmed. Please contact your System Admin and provide your User Details and Time and Date of this instance.';

    /**
    * @param List<Event> eventsList 
    * @param Boolean isinsert - set true if insert operation, false if delete operation
    * @param Boolean isSecondRun - set true if is a re-run
    **/
    public SM_CallPlannerBatchDML(List<Event> eventsList, Boolean isinsert, Boolean isSecondRun) {
        this.eventsList = eventsList;
        if(this.eventsList == null) {
            this.eventsList = new List<Event>();
        }
        this.isInsert = isInsert;
        this.isSecondRun = isSecondRun;
    }

    public List<Event> start(Database.BatchableContext BC) {
        return this.eventsList;
    }

    public void execute(Database.BatchableContext BC, List<Event> elist) {
        String op = (isSecondRun == false) ? '1st delete' : '2nd delete';

        if(isInsert) {
            try {
                System.debug('on unsynchronous insert - ' + op);
                Database.insert(elist, false);
            } catch(Exception e) {
                ApplicationLogger.log('SM_CallPlannerBatchDML-' + op, 'Event', 'BatchApex', e);
            }
        } else {
            try {
                System.debug('on unsynchronous delete' + op);
                Database.delete(elist, false);
            } catch(Exception e) {  
                ApplicationLogger.log('SM_CallPlannerBatchDML-' + op, 'Event', 'BatchApex', e);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        
        if(isInsert) {
            eventsList = SM_CallPlanner.checkDMLOperationRecords(eventsList, true);

            if(eventsList.size() > 0) {
                if(!isSecondRun && !Test.isRunningTest()) {
                    Database.executeBatch(new SM_CallPlannerBatchDML(eventsList, true, true), 2000);
                } else {
                    ApplicationLogger.log('SM_CallPlannerBatchDML-insert', '', 'values: ' +JSON.serialize(eventsList), 'SM_CallPlannerBatchDML.finish');
                    sendNotification(FAILED_TITLE, FAILED_BODY);
                }
            } else {
                sendNotification(SUCCESS_TITLE, SUCCESS_BODY);
            }
        } else {
            eventsList = SM_CallPlanner.checkDMLOperationRecords(eventsList, false);

            if(eventsList.size() > 0) {
                if(!isSecondRun && !Test.isRunningTest()) {
                    Database.executeBatch(new SM_CallPlannerBatchDML(eventsList, false, true), 1500);
                } else {
                    ApplicationLogger.log('SM_CallPlannerBatchDML-delete', '', 'values: ' +JSON.serialize(eventsList), 'SM_CallPlannerBatchDML.finish');    
                    sendNotification(FAILED_TITLE, FAILED_BODY);
                }
            } else {
                sendNotification(SUCCESS_TITLE, SUCCESS_BODY);
            }
        }
    }

    private void sendNotification(String msgTitle, String msgBody) {
        //send out notification to user of the success status of a batchedDML on events
        Id notificationTypeId = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName='Call_Planner_Events_Status_Notification' LIMIT 1].Id;

        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(msgTitle);
        notification.setBody(msgBody);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId('000000000000000AAA'); //dummy Id per https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Messaging_CustomNotification.htm#custom_notification_usage
        
        // Actually send the notification
        try {
            notification.send(new Set<String> { UserInfo.getUserId() });
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        } finally {
            return;
        }
    }

}