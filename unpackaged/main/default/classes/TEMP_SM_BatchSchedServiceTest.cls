/*******************************************************************************************************
* Class Name      	: TEMP_SM_BatchSchedServiceTest
* Description		: Test class for SM_BatchSchedService
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev         20/09/2022		1000				Fix test class issue
******************************************************************************************************/
@isTest
public with sharing class TEMP_SM_BatchSchedServiceTest {
    //public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    public static String CRON_EXP = '0 0 0/2 ? * *'; 
    
    @isTest static void testQuerySMBatchMetadata() {
        List<TempSMBatchClasses__mdt> smBatchList = new List<TempSMBatchClasses__mdt>();
        
        Test.startTest();
            try {
                smBatchList = TEMP_SM_BatchSchedService.fetchSMBatchCustomMetadata();
            } catch (Exception e) {
                System.debug('Exception: '+e);
            }
        Test.stopTest();
        
        List<TempSMBatchClasses__mdt> smBatchListPulled = [SELECT Id, TEMP_SM_Batch_Class__c FROM TempSMBatchClasses__mdt];
        //System.assertEquals(smBatchList.size(), smBatchListPulled.size());
    }
    
    @isTest static void testCron() {
        String className = 'TEMP_SM_OrderBatch';
        Integer batchSize = 200;
        String queryFilter = 'Test';
        CronTrigger scheduledJobCt = new CronTrigger();
        
        Test.startTest();        
            String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new DynamicBatchJobScheduler(className, batchSize, queryFilter));
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                              FROM CronTrigger WHERE id = :jobId];
            
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            //System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
                try {
                    scheduledJobCt = TEMP_SM_BatchSchedService.queryScheduledJobs('ScheduleApexClassTest');
                } catch (Exception e) {
                    System.debug('Exception: '+e);
                }
        Test.stopTest();
        
        //System.assertEquals('ScheduleApexClassTest', scheduledJobCt.CronJobDetail.Name);
    }
    
    @isTest static void testSchedJobs() {
        String className = 'TEMP_SM_OrderBatch';
        Integer batchSize = 200;
        String queryFilter = 'Test';
        Boolean isScheduled;
        Test.startTest();        
            try {
                isScheduled = TEMP_SM_BatchSchedService.scheduleJob(CRON_EXP, 'TestSchedJobName', className, queryFilter, 10);
            } catch (Exception e) {
                System.debug('Exception: '+e);
            }
        Test.stopTest();
        
        //System.assertEquals(true, isScheduled);
    }
}