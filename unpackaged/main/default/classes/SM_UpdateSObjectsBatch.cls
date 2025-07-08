/*******************************************************************************************************
* Class Name      	: SM_UpdateSObjectsBatch
* Description		: Reusable batch class to update records async
* Author          	: Simplus - MS
* Created On      	: 07/12/2021
* Modification Log	: 
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            07/12/2021		1000				Initial version 
******************************************************************************************************/
public class SM_UpdateSObjectsBatch implements Database.Batchable<sObject>{

    private list<sObject> lRecords = new list<sObject>(); 
    private String method = '';
    private Boolean allOrNone = TRUE;
    private String SObjectName = '';
    
    public SM_UpdateSObjectsBatch(List<sObject> lRecords, String method, Boolean allOrNone, String SObjectName) {
        this.lRecords = lRecords != null ? lRecords : new List<sObject>();
        this.method = method != null ? method : 'None';
        this.allOrNone = allOrNone != null ? allOrNone : TRUE;
        this.SObjectName = SObjectName != null ? SObjectName : 'SObject';
    }
    
    public List<sObject> start(Database.BatchableContext BC) {
        return this.lRecords;
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> lRecords){
        // process each batch of records
        system.debug('In batch');
        try {
            if(lRecords!=null && !lRecords.isEmpty()){
                Database.update(lRecords, this.allOrNone);
            }
        } catch(Exception e) {
            System.debug(e.getStackTraceString());
            ApplicationLogger.log('SM_UpdateSObjectsBatch - ' + this.method, this.SObjectName, 'BatchApex', e);
        }
    }
    public void finish(Database.BatchableContext bc){
    }
    
}