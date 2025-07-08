/*******************************************************************************************************
* Class Name        : CallPlanLeaveTrigger_Test
* Description       : Test class for CallPlanLeaveTrigger
* Author            : Simplus - Yi Zhang
* Created On        : 13/07/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              13/07/2020      1000                Initial version
******************************************************************************************************/
@isTest
public class CallPlanLeaveTrigger_Test {
    @isTest
    public static void testCallPlanLeaveTrigger() {
        // create AM user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        List<User> users = TestDataFactory.createUsers(3, p.Id);
        insert users;

        Test.startTest();
        System.runAs(new User(ID = UserInfo.getUserID())) {
            // no end date
            List<Call_Plan_Leave__c> leaves = new List<Call_Plan_Leave__c>{
                new Call_Plan_Leave__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 11, End_Date__c = Date.today() + 20),
                new Call_Plan_Leave__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 21, End_Date__c = Date.today() + 30)
            };
            insert leaves;    

            // insert another one with some overlap, expect error
            Call_Plan_Leave__c errorLeave = new Call_Plan_Leave__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 12, End_Date__c = Date.today() + 13);
            try {
                insert errorLeave;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallPlanLeaveTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS), 'expected error message ' + CallPlanLeaveTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS);
            }
            // update existing leave with some overlap, expect error
            leaves[1].Start_Date__c = Date.today() + 20;
            try {
                update leaves[1];
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallPlanLeaveTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS), 'expected error message ' + CallPlanLeaveTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS);
            }
            
            // Create events
            List<Event> events = new List<Event>{
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 31),
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 32),
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 33),
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 34),
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 35),
                SM_CallPlanner.createEvent('Test 1', users[0].Id, null, null, Date.today() + 36)
            };
            insert events;
            System.assertEquals(6, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Status__c = :Constants.EVENT_STATUS_OPEN].size(), 'Events not created with Status = Open');

            // test insert's impact on events
            Call_Plan_Leave__c testLeave = new Call_Plan_Leave__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 31, End_Date__c = Date.today() + 33);
            insert testLeave;
            System.assertEquals(3, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Outcome__c = :Constants.EVENT_OUTCOME_ON_LEAVE AND Status__c = :Constants.EVENT_STATUS_COMPLETED].size(), '3 Events not updated with Outcome = On Leave and Status = Completed');

            // test update's impact on events (extend)
            testLeave.End_Date__c = Date.today() + 34;
            update testLeave;
            System.assertEquals(4, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Outcome__c = :Constants.EVENT_OUTCOME_ON_LEAVE AND Status__c = :Constants.EVENT_STATUS_COMPLETED].size(), '4 Events not updated with Outcome = On Leave and Status = Completed');

            // test update's impact on events (reduce)
            testLeave.End_Date__c = Date.today() + 32;
            update testLeave;
            System.assertEquals(2, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Outcome__c = :Constants.EVENT_OUTCOME_ON_LEAVE AND Status__c = :Constants.EVENT_STATUS_COMPLETED].size(), '2 Events not updated with Outcome = On Leave and Status = Completed');

            // test update's impact on events (shift)
            testLeave.Start_Date__c = Date.today() + 35;
            testLeave.End_Date__c = Date.today() + 35;
            update testLeave;
            System.assertEquals(1, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Outcome__c = :Constants.EVENT_OUTCOME_ON_LEAVE AND Status__c = :Constants.EVENT_STATUS_COMPLETED].size(), '1 Events not updated with Outcome = On Leave and Status = Completed');

            // test test's impact on events
            delete testLeave;
            System.assertEquals(6, [SELECT Id FROM Event WHERE OwnerId = :users[0].Id AND Status__c = :Constants.EVENT_STATUS_OPEN].size(), 'Events not open again');

        }
        Test.stopTest();
    }
}