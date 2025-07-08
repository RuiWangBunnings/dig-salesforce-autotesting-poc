/*******************************************************************************************************
* Class Name      	: BulkAccountReqTransferScheduler
* Description		: BulkAccountReqTransferScheduler
* Author          	: Bunnings Dev
* Created On      	: 22/10/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     6/06/2023		1000				Initial version - BUNDIG-14708
*******************************************************************************************************/
global class BulkAccountReqTransferScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
	ID BatchId = Database.executeBatch(new SM_BulkAccountRequestTransferBatch(), 10000);
}

}