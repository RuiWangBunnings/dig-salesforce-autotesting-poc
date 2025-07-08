public class cplExceptionErrorQueueable implements Queueable {
    private String accountId;
    private Map<String, Object> acctFieldsToUpdate;
    private Map<String, Object> appLogFields;
    
    public cplExceptionErrorQueueable(String accountId, Map<String, Object> acctFieldsToUpdate, Map<String, Object> appLogFields) {
        this.accountId = accountId;
        this.acctFieldsToUpdate = acctFieldsToUpdate;
        this.appLogFields = appLogFields;
    }
    
    public void execute(QueueableContext context) {
        SM_Utility.updateRecord('Account', accountId, acctFieldsToUpdate);
        SM_Utility.insertRecord('ApplicationLog__c', appLogFields);
    }
}