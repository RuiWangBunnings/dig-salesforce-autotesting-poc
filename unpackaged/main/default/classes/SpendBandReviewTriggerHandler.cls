/*******************************************************************************************************
* Class Name      	: SpendBandReviewTriggerHandler
* Description		: Spend Band Review Trigger Handler
* Author          	: Bunnings Dev
* Created On      	: 23/08/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          23/08/2023		1000				BUNDIG-23897 - Initial version
* Jasper R. Galapon     01/09/2023      1001                BUNDIG-23854 - Spend Review Review error: Attempt to de-reference a null object
* Jasper R. Galapon     05/09/2023      1002                BUNDIG-23897 - Spend Band Review - Incorrect Reviewer and Approver Comments
******************************************************************************************************/
public class SpendBandReviewTriggerHandler {

    public static void beforeUpdate(Map<Id, Spend_Band_Review__c> oldMap, List<Spend_Band_Review__c> newList) {
        updateSpendBandReview(oldMap, newList);
    }

    
    /**
    * @description Update Reviewer/Approver comment
    * @author Bunnings Dev| 23/08/2023
    */    
    public static void updateSpendBandReview(map<Id,Spend_Band_Review__c> oldMap, list<Spend_Band_Review__c> newList) {
        Set<Id> newSBRIds = new Set<Id>();            

        for (Spend_Band_Review__c newSBR : newList) {
            Spend_Band_Review__c oldSBR = oldMap.get(newSBR.Id);

            if (oldSBR.Status__c != newSBR.Status__c)
                newSBRIds.add(newSBR.Id);            
        }

        System.debug(LoggingLevel.FINEST, '***newSBRIds: ' + newSBRIds);

        if (!newSBRIds.isEmpty()) {
            try {

                // Build a map of the comments from the approval process
                Map<Id, Map<String, String>> allUpdatedSpendBandReviewsByIds = new Map<Id, Map<String, String>>();
                Map<Id, Map<String, String>> allUpdatedSpendBandReviewsStatusByIds = new Map<Id, Map<String, String>>();
                Set<Id> processIds = new Set<Id>();

                Map<String, String> approvalComments = new Map<String, String>();
                Map<String, String> approvalStatus = new Map<String, String>();

                // SFSUP-468 - Added order by and limit to get the last 2 updates (Level 1/2)
                for (Spend_Band_Review__c item : [SELECT Id, Status__c, (SELECT Id, StepStatus, Comments, ProcessInstanceId, ProcessNodeId, ActorId, OriginalActorId, ProcessNode.Name 
                    FROM ProcessSteps WHERE StepStatus IN ('Rejected', 'Approved') ORDER BY CreatedDate DESC LIMIT 2)
                    FROM Spend_Band_Review__c
                    WHERE Id IN :newSBRIds
                ]) {
                    // SFSUP-468 - Commented out
                    // Map<String, String> approvalComments = allUpdatedSpendBandReviewsByIds.containsKey(item.Id) ? allUpdatedSpendBandReviewsByIds.get(item.Id) : new Map<String, String>();
                    // Map<String, String> approvalStatus = allUpdatedSpendBandReviewsStatusByIds.containsKey(item.Id) ? allUpdatedSpendBandReviewsStatusByIds.get(item.Id) : new Map<String, String>();
                
                    // BUNDIG-23897
                    approvalComments.clear();
                    approvalStatus.clear();
                    
                    for (ProcessInstanceHistory pItem : item.ProcessSteps) {
                        System.debug(LoggingLevel.FINEST, '***ITEM: '+pItem.ProcessNode.Name + ' / ' + pItem.Comments);
                    
                        if (pItem.ProcessNode.Name == 'Level 1 Approval') {
                            approvalComments.put('Level 1 Approval', pItem.Comments);
                            approvalStatus.put('Level 1 Approval', pItem.StepStatus);
                        }
                        if (pItem.ProcessNode.Name == 'Level 2 Approval') {
                            approvalComments.put('Level 2 Approval', pItem.Comments);
                            approvalStatus.put('Level 2 Approval', pItem.StepStatus);
                        }

                        allUpdatedSpendBandReviewsByIds.put(item.Id, approvalComments);
                        allUpdatedSpendBandReviewsStatusByIds.put(item.Id, approvalStatus);
                    }                    
                }

                System.debug(LoggingLevel.FINEST, '***approvalComments: '+approvalComments);
                System.debug(LoggingLevel.FINEST, '***allUpdatedSpendBandReviewsByIds: '+allUpdatedSpendBandReviewsByIds);

                // Loop through and update the comments
                for (Spend_Band_Review__c item : newList) {
                    
					//BUNDIG-23897
                    Spend_Band_Review__c oldSBR = oldMap.get(item.Id);
                    
                    // BUNDIG-23854
                    // if (!allUpdatedSpendBandReviewsByIds.isEmpty() && allUpdatedSpendBandReviewsByIds.get(item.Id).containsKey('Level 1 Approval')) {
                    if (!allUpdatedSpendBandReviewsByIds.isEmpty() && !allUpdatedSpendBandReviewsByIds.get(item.Id).isEmpty()) {
                        if (allUpdatedSpendBandReviewsByIds.get(item.Id).containsKey('Level 1 Approval')) {
                            if (allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 1 Approval') == null 
                                || allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 1 Approval').trim().length() == 0) {
                                if (allUpdatedSpendBandReviewsStatusByIds.get(item.Id).get('Level 1 Approval') == 'Rejected') {
                                    item.addError('Approver 1 comments required');
                                }
                            } else { 
                                //BUNDIG-23897 clear A1 comment if A2 rejects
                                if(item.Level_2_Action__c == 'R' && item.Status__c == 'A1' && oldSBR.Status__c != item.Status__c){
                                	item.Level_1_Comments__c = null;
                                }else{
                                    // SFSUP-448 - Hard char limit due to EBS
                                    if (allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 1 Approval').length() > 250) {
                                        item.Level_1_Comments__c = allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 1 Approval').substring(0, 250);
                                    } else {
                                        item.Level_1_Comments__c = allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 1 Approval');
                                    }                                     
                                }                                                                                  
                            }
                        }
                    }

                    // BUNDIG-23854
                    // if (!allUpdatedSpendBandReviewsByIds.isEmpty() && allUpdatedSpendBandReviewsByIds.get(item.Id).containsKey('Level 2 Approval')) {
                    if (!allUpdatedSpendBandReviewsByIds.isEmpty() && !allUpdatedSpendBandReviewsByIds.get(item.Id).isEmpty()) {
                        if (allUpdatedSpendBandReviewsByIds.get(item.Id).containsKey('Level 2 Approval')) {
                            if (allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 2 Approval') == null ||
                                    allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 2 Approval').trim().length() == 0) {
                                if (allUpdatedSpendBandReviewsStatusByIds.get(item.Id).get('Level 2 Approval') == 'Rejected') {
                                    item.addError('Approver 2 comments required');
                                }
                            } else { 
                                //BUNDIG-23897 clear A2 comment if A1 approves or rejects
                                if((item.Status__c == 'A' || item.Status__c == 'A2') && oldSBR.Status__c != item.Status__c){
                                    item.Level_2_Comments__c = null;
                                }else{
									// SFSUP-448 - Hard char limit due to EBS
                                    if (allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 2 Approval').length() > 250 ) {
                                        item.Level_2_Comments__c = allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 2 Approval').substring(0, 250);
                                    } else {
                                        item.Level_2_Comments__c = allUpdatedSpendBandReviewsByIds.get(item.Id).get('Level 2 Approval');
                                    }                                    
                                }           
                            }
                        }
                    }
                }
                
            } catch (Exception e) {
                ApplicationLogger.log('SpendBandReviewTriggerHandler', 'Spend_Band_Review__c', 'Trigger', e);
            }
        }
    }
            
}