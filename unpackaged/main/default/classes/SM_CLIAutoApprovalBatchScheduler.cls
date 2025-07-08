/*******************************************************************************************************
* Class Name      	: SM_CLIAutoApprovalBatchScheduler
* Description		: Schedulable class of SM_CLIAutoApprovalBatch
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     30/07/2024		1000				BUNDIG-34611 - Initial version 
******************************************************************************************************/

public class SM_CLIAutoApprovalBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SM_CLIAutoApprovalBatch(null));
    }
}