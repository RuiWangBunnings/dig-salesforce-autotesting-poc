/*******************************************************************************************************
* Class Name      	: SM_CosQuoteAndOppSyncQueueable
* Description		: Queueable class to prevent batch from calling the future method
* Author          	: Bunnings Dev
* Created On      	: 21/08/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     21/08/2023		1000				Initial version - BUNDIG-24085
*******************************************************************************************************/
public class SM_CosQuoteAndOppSyncQueueable implements Queueable {
    private List<Opportunity> oppUpdateList = new List<Opportunity>();
    private Map<Id, Id> mapRec = new Map<Id, Id>();

    public SM_CosQuoteAndOppSyncQueueable(Map<Id, Id> mapRec) {
        this.mapRec = mapRec;
    }

    public void execute(System.QueueableContext qc) {
        if (!this.mapRec.isEmpty()) {            
            for (Id key : mapRec.keySet()) {
                oppUpdateList.add(new Opportunity(Id = mapRec.get(key), SyncedQuoteId = key));
            }
        }
        if (!oppUpdateList.isEmpty()) {
            try {
                UPDATE oppUpdateList;
            } catch (Exception e) {
                ApplicationLogger.log('QuoteTriggerHandler.SM_CosQuoteAndOppSyncQueueable', 'Quote', 'Trigger', e);
            }
        }
    }    
}