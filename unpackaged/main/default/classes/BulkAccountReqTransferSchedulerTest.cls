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
@isTest
public class BulkAccountReqTransferSchedulerTest {
    
 @isTest

     static void testOrderBatchSchedule() {


          Test.startTest();

          BulkAccountReqTransferScheduler scheduler = new BulkAccountReqTransferScheduler();

          scheduler.execute(null);

          Test.stopTest();



     }
}