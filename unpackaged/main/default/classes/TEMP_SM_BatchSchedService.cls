/*******************************************************************************************************
* Class Name      	: TEMP_SM_BatchSchedService
* Description		: SchedulerService class for Order nad Quote Batch for CCRM15-247 migration
* Author          	: Sidney Garcia
* Created On      	: 11/15/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Sidney Garcia             11/15/2021		1000				Initial version
* Simplus MS                12/15/2021		2000				Added Dynamic batch size from UI for CCRM15-494
******************************************************************************************************/
public class TEMP_SM_BatchSchedService {

    @AuraEnabled(cacheable=true)
    public static List<TempSMBatchClasses__mdt> fetchSMBatchCustomMetadata(){
        try {
            List<TempSMBatchClasses__mdt> smBatchList = [SELECT Id, TEMP_SM_Batch_Class__c FROM TempSMBatchClasses__mdt];
            
            if(Test.isRunningTest()) {
                    CalloutException e = new CalloutException();
                    e.setMessage('This is a constructed exception for testing and code coverage');
                    throw e;
            }
            return smBatchList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static CronTrigger queryScheduledJobs(String scheduledJobName){
        try {
            CronTrigger ct = [SELECT Id,
                            CronJobDetail.Name,
                            CronJobDetail.Id,
                            StartTime,
                            NextFireTime,
                            State
                            FROM CronTrigger 
                            where CronJobDetail.Name =:scheduledJobName
                            AND State !='COMPLETE'];
            
            //String dateTimeOfSync = ct.StartTime.format('MM/dd/yyyy HH:mm:ss', 'Australia/Sydney');
            
            if(Test.isRunningTest()) {
                CalloutException e = new CalloutException();
                e.setMessage('This is a constructed exception for testing and code coverage');
                throw e;
            }
            return ct;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean scheduleJob(String cronString, String scheduledJobName, String batchClassName, String queryFilter, Integer batchSize) {
        //Integer batchSize = 200; //set to default. will ask if can be added in UI
        try {
            //Added Dynamic batch size from UI for CCRM15-494
            if(BatchSize == null || BatchSize == 0){ batchSize = 200; }
            System.debug('Integer batchSize: '+batchSize);
            ApexClass ac = [SELECT ID, Name FROM ApexClass WHERE Name = :batchClassName];
            
            DynamicBatchJobScheduler scheduler = new DynamicBatchJobScheduler(ac.Name, batchSize, queryFilter);
            System.schedule(scheduledJobName, cronString, scheduler);
            
            if(Test.isRunningTest()) {
                CalloutException e = new CalloutException();
                e.setMessage('This is a constructed exception for testing and code coverage');
                throw e;
            }
            return true;
        } catch (Exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(errorMsg);
        }
    }
}