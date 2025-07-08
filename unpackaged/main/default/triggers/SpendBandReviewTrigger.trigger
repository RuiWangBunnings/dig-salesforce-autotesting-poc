/*******************************************************************************************************
* Trigger Name      : SpendBandReviewTrigger
* Description       : Logic to copy the comments from the approval step to the object comment fields
* Author            : Simplus - Haider Raza
* Created On        : 05/03/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           05/03/2020      1000                Initial version
* Simplus MS            09/08/2021      2000                Added logic for turning on/off trigger using custom metadata
* Bunnings Dev          21/03/2022      3000                SFSUP-468 - Fix latest comments issue
* Bunnings Dev          23/03/2022      4000                SFSUP-448 - Limit Approve/Reject comments to 250 char
* Bunnings Dev          14/04/2022      5000                SFSUP-632 - Moved pre-population of comments/status map to make sure 
*                                                           that we only assign if it has gone through the approval process
* Bunnings Dev          14/07/2022      600                 SFSUP-873 - SBR approval updates returning a null object reference error
* Jasper R. Galapon     30/08/2023      700                 BUNDIG-23897 - Move trigger logic to trigger handler
******************************************************************************************************/
trigger SpendBandReviewTrigger on Spend_Band_Review__c (before insert, before update, before delete, after update, after insert, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate && DM_ProcessAutomation.ccrmProcessAutomation.Spend_Band_Review_Trigger_Update__c) {            
            SpendBandReviewTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.new);           
        }
    }
}