/**
 * @author            : Simplus MS
 * @last modified on  : 06/12/2021
 * @last modified by  : Simplus MS
**/
@isTest
public with sharing class SM_PlannedLeaveManagerTest {
    
    @TestSetup
    static void makeData(){
        Id RCMProfId;
        Id TSProfId;
        List<String> PROFILES = new List<String>{ Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME, Constants.AU_TRADE_SPECIALIST_PROFILEENAME };
        List<Profile> userProfiles = [ SELECT Id, Name FROM Profile WHERE Name IN : PROFILES ];
        for(Profile prof : userProfiles) {
            if(prof.Name == Constants.AU_LIGHT_COMMERCIAL_MANAGER_PROFILEENAME)
                RCMProfId = prof.Id;
            if(prof.Name == Constants.AU_TRADE_SPECIALIST_PROFILEENAME)
                TSProfId = prof.Id;
        }
        
        User managerUser = TestDataFactory.createUsers(1, RCMProfId)[0];
        managerUser.LastName = 'RCM';
        User TSUser = TestDataFactory.createUsers(1, TSProfId)[0];
        TSUser.LastName = 'Trade Specialist';
        List<User> users = new List<User>{managerUser, TSUser};
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
            TSUser.ManagerId = managerUser.Id;
            update users;
        }
    }

    @isTest
    static void createAndSubmitPlannedLeave() {
        User u = [SElECT Id FROM User WHERE Name = 'Trade Specialist' LIMIT 1];

        Test.startTest();
        String submitStatus;
        System.runAs(u) {
            SM_PlannedLeaveManager.checkIfTSRCM(u.Id);
            submitStatus = SM_PlannedLeaveManager.submitLeave(Date.today(), Date.today(), 'Testing');
        }
        String checkIfTSRCM = SM_PlannedLeaveManager.checkIfTSRCM(u.Id);
        List<Planned_Leave__c> pendingPLannedLeave = SM_PlannedLeaveManager.getLeaves(u.Id);
        Test.stopTest();
        System.assertEquals('success', submitStatus);
        System.assertEquals(1, pendingPLannedLeave.size());
    }

    @isTest
    static void confirmPLsForApproval() {
        User u = [SElECT Id FROM User WHERE Name = 'Trade Specialist' LIMIT 1];
        Id managerId = [SELECT Id FROM User WHERE Name = 'RCM' LIMIT 1].Id;

        System.runAs(u) {
            SM_PlannedLeaveManager.submitLeave(Date.today(), Date.today(), 'Testing');
        }

        Test.startTest();
        String returnString = SM_PlannedLeaveManager.getRecordsForApproval(managerId);
        Test.stopTest();

        System.assertNotEquals(null, returnString);
    }

    @isTest
    static void cancelSubmittedLeaves() {
        User u = [SElECT Id FROM User WHERE Name = 'Trade Specialist' LIMIT 1];
        User manager = [SELECT Id FROM User WHERE Name = 'RCM' LIMIT 1];
        List<Planned_Leave__c> pendingPLannedLeave = new List<Planned_Leave__c>();
        Test.startTest();
        System.runAs(u) {
            SM_PlannedLeaveManager.submitLeave(Date.today().addDays(-1), Date.today().addDays(-1), 'Testing');
            pendingPLannedLeave = SM_PlannedLeaveManager.getLeaves(u.Id);
            SM_PlannedLeaveManager.cancelLeave(pendingPLannedLeave[0].Id);
            SM_PlannedLeaveManager.submitLeave(Date.today(), Date.today(), 'Testing');
            SM_PlannedLeaveManager.submitLeave(Date.today().addDays(1), Date.today().addDays(1), 'Testing');
        }
        System.runAs(manager) {
            List<ApprovalsWrap> JSONResponse = (List<ApprovalsWrap>) JSON.deserialize(SM_PlannedLeaveManager.getRecordsForApproval(manager.Id), List<ApprovalsWrap>.Class);
            system.debug(JSONResponse);
            List<ProcessInstanceWorkItem> pVal = [SELECT Id, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE Id=:JSONResponse[0].Id AND ProcessInstance.Status = 'Pending'];
            system.debug(pVal);
            Approval.ProcessWorkItemRequest Preq= new Approval.ProcessWorkItemRequest();
            Preq.setAction('Approve');
            Preq.setWorkItemId(pVal[0].Id);
            Approval.ProcessResult result = Approval.process(Preq);
        }
        System.runAs(u) {
            pendingPLannedLeave = SM_PlannedLeaveManager.getLeaves(u.Id);
            SM_PlannedLeaveManager.cancelLeave(pendingPLannedLeave[0].Id);
            SM_PlannedLeaveManager.cancelLeave(pendingPLannedLeave[1].Id);
            SM_PlannedLeaveManager.cancelLeave(pendingPLannedLeave[2].Id);
            pendingPLannedLeave = SM_PlannedLeaveManager.getLeaves(u.Id);
        }
        Test.stopTest();

        System.assertEquals('Leave Cancelled', pendingPLannedLeave[0].Status__c);
        System.assertEquals('Leave Cancelled', pendingPLannedLeave[1].Status__c);
    }

    private class ApprovalsWrap {
        String Id;
        String OwnerName;
        String StartDate;
        String EndDate;
    }
    
    @isTest
    public static void afterUpdateMethod() {
        Test.startTest();
        List<RecordType> recordTypeList = [Select Id, Name, SobjectType From RecordType Where SobjectType = 'Task' AND Name = 'Call Cycle Call'];
        
        User u = [SElECT Id FROM User WHERE Name = 'Trade Specialist' LIMIT 1];
        User manager = [SELECT Id FROM User WHERE Name = 'RCM' LIMIT 1];
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        List<Task> tasks = TestDataFactory.createOpenTasksWithWhatId(accounts[0].Id, u.Id, 4);
        tasks[0].RecordTypeId = recordTypeList[0].Id;
        tasks[0].ActivityDate = System.today();
        tasks[1].RecordTypeId = recordTypeList[0].Id;
        tasks[1].ActivityDate =System.today() +1;
        tasks[2].RecordTypeId = recordTypeList[0].Id;
        tasks[2].ActivityDate =System.today()+2;
        tasks[3].RecordTypeId = recordTypeList[0].Id;
        tasks[3].ActivityDate =System.today()+3;
        insert tasks;

        Planned_Leave__c p1 = new Planned_Leave__c(Start_Date__c = System.today(),End_Date__c = System.today()+1,Status__c= 'Approval In Progress', OwnerId = u.Id);
        insert p1;
        p1.Status__c= 'Approved';
        update p1;
        Planned_Leave__c p2 = new Planned_Leave__c(Start_Date__c = System.today()+1,End_Date__c = System.today()+1,Status__c= 'Approval In Progress', OwnerId = u.Id);
        insert p2;
        p2.Status__c= 'Leave Cancelled';
        update p2;
        Test.stopTest();
    }
    
}