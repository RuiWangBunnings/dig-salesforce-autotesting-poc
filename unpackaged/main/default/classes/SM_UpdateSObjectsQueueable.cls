/*******************************************************************************************************
* Class Name      	: SM_UpdateSObjectsQueueable
* Description		: Queueable class to update records async
					  using Queueable since the process is sometimes initiated in a future method
					  Future method cannot be called from a future or batch method
* Author          	: Simplus - MS
* Created On      	: 07/12/2021
* Modification Log	: 
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            07/12/2021		1000				Initial version
******************************************************************************************************/
public class SM_UpdateSObjectsQueueable implements Queueable {
    private list<sObject> lRecords = new list<sObject>(); 
    private String method = '';
    private Boolean allOrNone = TRUE;
    private String SObjectName = '';
    
    public SM_UpdateSObjectsQueueable(List<sObject> lRecords, String method, Boolean allOrNone, String SObjectName) {
        this.lRecords = lRecords;
        this.method = method;
        this.allOrNone = allOrNone;
        this.SObjectName = SObjectName;
    }
    
    public void execute(System.QueueableContext qc) {
        if (this.lRecords != null){
            Database.executeBatch(new SM_UpdateSObjectsBatch(this.lRecords, this.method, this.allOrNone, this.SObjectName));
            System.debug('batch started');
        }
    }
}