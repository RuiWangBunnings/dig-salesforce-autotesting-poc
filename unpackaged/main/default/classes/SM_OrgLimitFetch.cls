/*******************************************************************************************************
* Class Name      	: SM_OrgLimitFetch
* Description		: A schedulable class that feeds selected limit status into Org_Limit__c custom object
* Author          	: Simplus MS-AU
* Created On      	: 01-June-2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS-AU			01/Jun/20201	1000				Initial version
******************************************************************************************************/
public class SM_OrgLimitFetch implements Schedulable {
    public void execute(SchedulableContext SC) {
         SM_OrgLimitFetch.populateLimits();
    }
    
    public static void populateLimits() {
        Map<String, String> remainingLimitFieldMap = new Map<String, String>{
            'HourlyPublishedPlatformEvents' => 'HourlyPublishedPlatformEvents_Used__c',
            'HourlyPublishedStandardVolumePlatformEvents' => 'HrlyPublishedStdVolPEs_Used__c',
            'MonthlyPlatformEventsUsageEntitlement' => 'MonthlyPlatformEvents_Used__c'
        };
            
        Map<String, String> limitFieldMap = new Map<String, String>{
            'HourlyPublishedPlatformEvents' => 'HourlyPublishedPlatformEvents_Limit__c',
            'HourlyPublishedStandardVolumePlatformEvents' => 'HrlyPublishedStdVolPEs_Limit__c',
            'MonthlyPlatformEventsUsageEntitlement' => 'MonthlyPlatformEvents_Limit__c'
        };            
        
        Org_Limit__c olimit = new Org_Limit__c();
        Map<String, OrgLimit> limitsMap = OrgLimits.getMap();
        for (String key : remainingLimitFieldMap.keySet()) {
            OrgLimit ol = limitsMap.get(key);
            olimit.put(remainingLimitFieldMap.get(key), ol.getValue());
            olimit.put(limitFieldMap.get(key), ol.getLimit());
        }         
        
        insert olimit;
    }
    
    public static void schedule(integer everyHour, String jobName) {
		String cron1 = string.valueOf(everyHour) + ' 0 * * * ?'; 
		SM_OrgLimitFetch job1 = new SM_OrgLimitFetch();
        System.schedule(jobName, cron1, job1);
    }
}