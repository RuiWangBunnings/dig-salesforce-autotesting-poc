/*******************************************************************************************************
* Class Name      	: SM_CLIAutoApprovalBatch
* Description		: Contract Line Item auto approval batch
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     30/07/2024		1000				BUNDIG-34611 - Initial version 
* Jasper R. Galapon     08/10/2024      1001                BUNDIG-37307 - Fixing CreatedDate condition
******************************************************************************************************/

public class SM_CLIAutoApprovalBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Integer dayBuffer;
    private Integer queryLimit;
    String query;
    String crDate;

    public SM_CLIAutoApprovalBatch(String crDate) {
        this.crDate = crDate;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        this.dayBuffer = Integer.valueOf(DM_Initialisation.getCCRMInitialisation().Contract_Line_Item_Auto_Approval_Buffer__c);
        this.queryLimit = Integer.valueOf(DM_Initialisation.getCCRMInitialisation().CLI_Auto_Approval_Batch_Limit__c);

        if (String.isNotBlank(crDate)) {
            Date targetDate = Date.valueOf(crDate);
            DateTime startOfDay = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
            DateTime endOfDay = DateTime.newInstance(targetDate, Time.newInstance(23, 59, 59, 999));

            System.debug(LoggingLevel.FINEST, '***dayBuffer: ' + dayBuffer + ' - Limit: ' + queryLimit + ' - startOfday: ' + startOfDay + ' - endOfday: ' + endOfDay);
        }
        
        Date cutoffDate = Date.today().addDays(-dayBuffer);
        DateTime cutoffDateTime = DateTime.newInstance(cutoffDate.year(), cutoffDate.month(), cutoffDate.day(), 23, 59, 59);

        query = 'SELECT Id FROM Contract_Line_Item__c ' +
            'WHERE Line_Status__c =  \'A1\' ' +
            'AND Line_Type__c = \'' + 'Amendment' +'\' ' +
            'AND Auto_Approval_Eligibility__c = TRUE ' +
            'AND Auto_Approved__c = FALSE ';

        if (crDate != null) {
            query += 'AND CreatedDate >= :startOfDay AND CreatedDate <= :endOfDay ';
        } else {
            query += 'AND CreatedDate < :cutoffDateTime ';
        }            
        query += 'LIMIT ' + queryLimit;

        System.debug(LoggingLevel.FINEST, '***query: ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contract_Line_Item__c> scope) {
        List<Contract_Line_Item__c> cliToUpdate = new List<Contract_Line_Item__c>();
        List<Object_Event_Bridge__c> eventBridgeToCreate = new List<Object_Event_Bridge__c>();

        try {
            for (Contract_Line_Item__c cli : scope) {
                cli.Reviewer_Action__c = 'A';
                cli.Reviewer_Action_Date__c = Date.today();
                cli.Reviewer_Comments__c = 'Auto Approved';
                cli.Approver_Action__c = 'A';
                cli.Approver_Action_Date__c = Date.today();
                cli.Approver_Comments__c = 'Auto Approved';
                cli.Auto_Approved__c = TRUE;
                cli.Auto_Approved_Date__c = Date.today();

                cliToUpdate.add(cli);
            }

            System.debug(LoggingLevel.FINEST, '***cliToUpdate: ' + cliToUpdate);
            Database.SaveResult[] results = Database.update(cliToUpdate, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug(LoggingLevel.FINEST, '***Successfully updated - CLI ID: ' + sr.getId());

                    Object_Event_Bridge__c oeb = new Object_Event_Bridge__c();
                    oeb.Record_Id__c = sr.getId();
                    oeb.Object_Name__c = 'Contract_Line_Item__c';                
                    oeb.Operation__c = 'Edit';
        
                    eventBridgeToCreate.add(oeb);
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }

            System.debug(LoggingLevel.FINEST, '***eventBridgeToCreate: ' + eventBridgeToCreate);
            if (!eventBridgeToCreate.isEmpty()) {
                try {
                    INSERT eventBridgeToCreate;
                } catch (Exception e) {
                    System.debug('Error inserting records: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            List<String> adminEmails = SM_Utility.getSystemAdministratorEmails();
            CSUtils.sendEmail(adminEmails, 'Contract Amendment Auto Approval - FAILED', 'The contract amendment auto approval batch has failed.');
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        AsyncApexJob asyncJob = [SELECT Status, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        List<String> toS = new List<String>{asyncJob.CreatedBy.Email};
        String msg = 'The batch Apex job processed ' + asyncJob.TotalJobItems + ' batches with '+ asyncJob.NumberOfErrors + ' failures.';

        List<String> adminEmails = SM_Utility.getSystemAdministratorEmails();
        CSUtils.sendEmail(adminEmails, 'SM_CLIAutoApprovalBatch - ' + asyncJob.Status, msg);
    }
    
}