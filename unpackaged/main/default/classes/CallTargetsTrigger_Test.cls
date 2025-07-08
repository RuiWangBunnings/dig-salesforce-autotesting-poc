/*******************************************************************************************************
* Class Name        : CallTargetsTrigger_Test
* Description       : Test class for CallTargetsTrigger
* Author            : Simplus - Yi Zhang
* Created On        : 18/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              18/06/2020      1000                Initial version
******************************************************************************************************/
@isTest
public class CallTargetsTrigger_Test {
    @isTest
    public static void testCallTargetsTrigger() {
        // create AM user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Account Manager' LIMIT 1];
        List<User> users = TestDataFactory.createUsers(3, p.Id);
        insert users;

        Test.startTest();
        System.runAs(new User(ID = UserInfo.getUserID())) {
            // no end date
            List<Call_Targets__c> targets = new List<Call_Targets__c>{
                new Call_Targets__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 30),
                new Call_Targets__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today() + 1, End_Date__c = Date.today() + 29),

                new Call_Targets__c(Team_Member__c = users[1].Id, Start_Date__c = Date.today() + 30),
                
                new Call_Targets__c(Team_Member__c = users[2].Id, Start_Date__c = Date.today() + 1, End_Date__c = Date.today() + 29)
            };
            insert targets;    

            /* AM 1 */
            // insert another one with no end date, expect error
            Call_Targets__c errorTarget = new Call_Targets__c(Team_Member__c = users[0].Id, Start_Date__c = Date.today());
            try {
                insert errorTarget;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallTargetsTriggerHandler.MESSAGE_ACTIVE_TARGET_ALREADY_EXIST), 'expected error message ' + CallTargetsTriggerHandler.MESSAGE_ACTIVE_TARGET_ALREADY_EXIST);
            }
            // insert another one with overlap, expect error
            errorTarget.Start_Date__c  = Date.today();
            errorTarget.End_Date__c = Date.today() + 10;
            try {
                insert errorTarget;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS), 'expected error message ' + CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS);
            }

            /* AM 2 */
            errorTarget = new Call_Targets__c(Team_Member__c = users[1].Id, Start_Date__c = Date.today(), End_Date__c = Date.today() + 35);
            try {
                insert errorTarget;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS), 'expected error message ' + CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS);
            }

            /* AM 3 */
            errorTarget = new Call_Targets__c(Team_Member__c = users[2].Id, Start_Date__c = Date.today());
            try {
                insert errorTarget;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS), 'expected error message ' + CallTargetsTriggerHandler.MESSAGE_DATE_RANGE_OVERLAPS);
            }

            // update, expect success
            targets[1].End_Date__c = Date.today() + 28;
            update targets[1];
            System.assertEquals(Date.today() + 28, [SELECT Id, End_Date__c FROM Call_Targets__c WHERE Id = :targets[1].Id].End_Date__c, 'End date not updated');

        }
        Test.stopTest();
    }
}