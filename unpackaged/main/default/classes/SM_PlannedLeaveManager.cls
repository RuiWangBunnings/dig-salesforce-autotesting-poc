/*******************************************************************************************************
* Class Name      	: SM_PlannedLeaveManager
* Description		: Service layer plannedLeaveManager LWC
* Author          	: Simplus MS
* Created On      	: 23/11/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            23/11/2021		1000				Initial version
******************************************************************************************************/

public with sharing class SM_PlannedLeaveManager {

    @AuraEnabled
    public static List<Planned_Leave__c> getLeaves(String runningUserId) {
        final List<String> ALLOWED_PROFILES = new List<String>{'Light Commercial Manager', 'NZ Light Commercial Manager', 'NZ Trade Specialist', 'Trade Specialist'};


        List<Planned_Leave__c> leaves = new List<Planned_Leave__c>();
        User curUser = DM_User.getUser(runningUserId);
        if(ALLOWED_PROFILES.contains(curUser.Profile.Name)) {
            leaves = [
                SELECT Id, Start_Date__c, End_Date__c, Status__c, OwnerId, Approver__c
                FROM Planned_Leave__c 
                WHERE OwnerId =:runningUserId ORDER BY Createddate DESC];
        }
        return leaves;
    }

    @AuraEnabled
    public static String submitLeave(Date startDate, Date endDate, String comments) {
        String resp = '';
        try {
            Database.SaveResult res = Database.insert(
                new Planned_Leave__c(
                    Start_Date__c = startDate,
                    End_Date__c = endDate,
                    Comments__c = comments,
                    Status__c = 'Approval In Progress')
            );
            if(res.isSuccess()) {
                Id plId = res.getId();
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(plId);
                Approval.ProcessResult processResult = Approval.process(req);
                if(processResult.getInstanceStatus() == 'Pending') {
                    resp = 'success';
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return resp;
    }

    @AuraEnabled
    public static String cancelLeave(String plRecId){
        String resp = '';
        try {
            Planned_Leave__c plRec = [SELECT Id, Status__c, Start_Date__c FROM Planned_Leave__c WHERE Id =:plRecId LIMIT 1];
            switch on plRec.Status__c {
                when 'Approval In Progress' {
                    cancelOnApprovalPL(plRecId);
                    resp = 'successCancelOnApprovalPL';
                }
                when 'Approved' {
                    if(plRec.Start_Date__c >= Date.Today()) {
                        cancelApprovedPL(plRecId);
                        resp = 'successCancelApprovalPL';
                    } else resp = 'startDateLessThanToday';
                }
                when 'Not Approved' {
                    resp = 'notApproved';
                }
                when else {}
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return resp;
    }

    @AuraEnabled
    public static String checkIfTSRCM(String runningUserId){
        List<String> PROFILES = new List<String> {
            'Light Commercial Manager', 'NZ Light Commercial Manager', 'Trade Specialist', 'NZ Trade Specialist'
        };
        try {
            User u = DM_User.getUser(runningUserId);
            if(PROFILES.contains(u.Profile.Name)) {
                if(u.Profile.Name == 'Light Commercial Manager' || u.Profile.Name == 'NZ Light Commercial Manager')
                    return 'isRCM';
                else if(u.Profile.Name == 'Trade Specialist' || u.Profile.Name == 'NZ Trade Specialist')
                    return 'isTS';
                else return '';
            }
            else
                return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void cancelOnApprovalPL(String plRecId) {
        ProcessInstanceWorkitem[] pVal = [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId = :plRecId AND ProcessInstance.Status = 'Pending']; 
        if(pVal.size() > 0){
            Approval.ProcessWorkItemRequest Preq= new Approval.ProcessWorkItemRequest();
            Preq.setAction('Removed');
            Preq.setWorkItemId(pVal[0].Id);
            Approval.ProcessResult result = Approval.process(Preq);
            system.debug('approvalProcessResult: ' + result);
            update new Planned_Leave__c(Id = plRecId, Status__c='Leave Cancelled');
        }
    }

    private static void cancelApprovedPL(String plRecId) {
        update new Planned_Leave__c(Id = plRecId, Status__c='Leave Cancelled');
    }

    @auraEnabled
    public static String getRecordsForApproval(String runningUserId) {
        
        Map<Id, Id> plIdtoApprovIdMap = new Map<Id,Id>();
        List<ApprovalsWrap> returnMap = new List<ApprovalsWrap>();

        List<ProcessInstanceWorkitem> recordList = [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status = 'Pending' AND ActorId = :runningUserId];
        if(recordList != null) {
            for(ProcessInstanceWorkitem pi : recordList) {
                plIdtoApprovIdMap.put(pi.ProcessInstance.TargetObjectId, pi.Id);
            }
        }
        
        if(plIdtoApprovIdMap != null) {
            List<Planned_Leave__c> PLs = [SELECT Owner.Name, Start_Date__c, End_Date__c FROM Planned_Leave__c WHERE Id IN :plIdtoApprovIdMap.keySet() ORDER BY CreatedDate DESC];
            if(PLs != null) {
                for(Planned_Leave__c PL : PLs) {
                    returnMap.add(new ApprovalsWrap(
                        plIdtoApprovIdMap.get(PL.Id), PL.Owner.Name, String.valueOf(PL.Start_Date__c), String.valueOf(PL.End_Date__c)
                        ));
                }
            }
        }

        return JSON.serialize(returnMap);

    }

    private class ApprovalsWrap {
        String Id;
        String OwnerName;
        String StartDate;
        String EndDate;

        public ApprovalsWrap(String id, String ownerName, String startDate, String endDate) {
            this.Id = Id;
            this.OwnerName = ownerName;
            this.StartDate = startDate;
            this.EndDate = endDate;
        }
    }

}

// global static Map<String, Object> mApprovalRecallAction(String sContentID, String sName) {
//     System.debug('>>> ID_Item.mApprovalRecallAction(...)');

//     ...

//     // submitter is the person recalling, so we have permission to do so (otherwise we need to be an admin: https://success.salesforce.com/ideaView?id=08730000000iY1aAAE)
//     if (oApproval.CreatedById == UserInfo.getUserId()) {        
//         Approval.ProcessWorkitemRequest oPWR = new Approval.ProcessWorkitemRequest(); 
//         oPWR.setComments('Recalled by `' + oApproval.CreatedBy.Name + '`');
//         oPWR.setAction('Removed');
//         if (!Test.isRunningTest()) { // can't seem to create ProcessInstanceWorkItem records in tests
//             oPWR.setWorkItemId(oWorkItemList[0].id);
//             Approval.ProcessResult oPR = Approval.process(oPWR);
//         }

//         // Next the approval process needs to have a recalled action that sets `cms__Approval__c.Status = 'Recalled'` which is levraged by OrchestraCMS - but just incase these were deleted we are changing the status in apex as well
//         oApproval.cms__Status__c = 'Recalled';
//         oApproval.Content_Status__c = 'Recalled';
//         update oApproval;
//         System.debug('=== ID_Item.mApprovalRecallAction(...): `JSON.serialize(oPWR)=' + JSON.serialize(oPWR) + '`');
//         return new Map<String, Object>{'bSuccess' => true, 'sPWR' => JSON.serialize(oPWR)};
//     }
//     // we assume `this.bApprovalRecalVisible` did our security checks  
//     else {
//         // we leverage the functionality that an email service allows us to run under a adming user
//         Messaging.SingleEmailMessage oMessage = new Messaging.SingleEmailMessage();
//         try {
//             // find our email service to use, as convention we prefixed it with class name 
//             EmailServicesAddress oEmailServiceAddress = [
//                 SELECT e.SystemModstamp, e.RunAsUserId, e.LocalPart, e.LastModifiedDate, e.LastModifiedById, e.IsActive, e.Id, e.FunctionId, e.EmailDomainName, e.CreatedDate, e.CreatedById, e.AuthorizedSenders 
//                 FROM EmailServicesAddress e
//                 WHERE e.IsActive = true AND e.LocalPart LIKE 'ID_Item%' // `LIKE` is case-insensetive, so we keep capitialization same as class name as it's easier for search and replace 
//                 ].get(0); 
//             oMessage.toAddresses = new String[] {
//                 oEmailServiceAddress.LocalPart + '@' + oEmailServiceAddress.EmailDomainName
//             };
//         }
//         catch (Exception e) {
//             System.debug('=== ID_Item.mApprovalRecallAction(...): ERROR: no email service setup, `e' + String.valueOf(e) + '`');
//             return new Map<String, Object>{'bSuccess' => true, 'e' => JSON.serialize('ERROR: no email service setup, `e' + String.valueOf(e) + '`')};
//         }
//         Map<String, Object> oParameterMap = new Map<String, Object>{'sAction' => 'mApprovalRecallActionWithAdminPermissions', 'sApprovalID' => oApproval.Id};
//         oMessage.subject = '=== ID_Item.mApprovalRecallAction(...): `JSON.serialize(oParameterMap)=' + JSON.serialize(oParameterMap) + '`'; // using subject is not safe because SF can modify it sometimes (ex. prefixing `Sandbox`  
//         oMessage.plainTextBody = JSON.serialize(oParameterMap);
//         Messaging.SendEmailResult[] oResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {oMessage});

//         System.debug('=== ID_Item.mApprovalRecallAction(...): `oResults' + String.valueOf(oResults) + '`');

//         System.debug('<<< ID_Item.mApprovalRecallAction(...)');
//         if (oResults[0].success) {
//             return new Map<String, Object>{'bSuccess' => true, 'oResults' => JSON.serialize(String.valueOf(oResults))};
//         } else {
//             return new Map<String, Object>{'bSuccess' => false, 'oResults' => JSON.serialize(String.valueOf(oResults))};
//         }
//     }       
// }