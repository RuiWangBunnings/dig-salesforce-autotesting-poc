/*******************************************************************************************************
* Class Name      	: DynamicBatchJobSchedulerTest
* Description		: Test class for DynamicBatchJobScheduler
* Author          	: Simplus MS
* Created On      	: 21/10/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS                21/10/2021		1000				Initial version
* Bunnings Dev              20/09/2022		2000				Fix test class issue
*******************************************************************************************************/

@isTest
public class DynamicBatchJobSchedulerTest {
   //public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    public static String CRON_EXP = '0 0 0/2 ? * *';
    
    @isTest 
    static void testSchedBatchWithQueryFilter() {
        String className = 'TEMP_SM_OrderBatch';
        Integer batchSize = 200;
        String queryFilter = 'Test';
        CronTrigger scheduledJobCt = new CronTrigger();
        
        Test.startTest();
        DynamicBatchJobScheduler scheduler = new DynamicBatchJobScheduler(className, batchSize, queryFilter);
        String jobId =  System.schedule('ScheduleApexClassTest', CRON_EXP, scheduler);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
       //System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    
    @isTest
    static void testSchedBatchWithoutQueryFilter() {
        String className = 'TEMP_SM_OrderBatch';
        Integer batchSize = 200;
        String queryFilter = null;
        CronTrigger scheduledJobCt = new CronTrigger();
        
        Test.startTest();
        DynamicBatchJobScheduler scheduler = new DynamicBatchJobScheduler(className, batchSize, queryFilter);
        String jobId =  System.schedule('ScheduleApexClassTest', CRON_EXP, scheduler);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
       //System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
}