/*******************************************************************************************************
* Class Name      	: SM_ApplicationLogPurgeBatch_Test
* Description		: Test class for SM_ApplicationLogPurgeBatch
* Author          	: Simplus - Yi Zhang
* Created On      	: 05/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              05/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class SM_ApplicationLogPurgeBatch_Test {
    @isTest
    public static void testApplicationLogPurgeBatch() {
        // set up data
        List<ApplicationLog__c> logs = new List<ApplicationLog__c>{
            new ApplicationLog__c(Type__c = 'Exception'),
            new ApplicationLog__c(Type__c = 'Exception'),
            new ApplicationLog__c(Type__c = 'Exception'),
            new ApplicationLog__c(Type__c = 'Exception'),
            new ApplicationLog__c(Type__c = 'Exception')
        };
        insert logs;
        Test.setCreatedDate(logs[0].Id, Datetime.now() - 61);
        Test.setCreatedDate(logs[1].Id, Datetime.now() - 62);

        Test.startTest();
        System.assertEquals(5, [SELECT COUNT() FROM ApplicationLog__c], 'logs not setup properly');
        // schedulable (not immediate)
        Id jobId = System.schedule('Application Log Purge Test', 
            '0 0 2 * * ?', 
            new SM_ApplicationLogPurgeBatch());
        // batchable
        Database.executebatch(new SM_ApplicationLogPurgeBatch());
        Test.stopTest();
        System.assertEquals(3, [SELECT COUNT() FROM ApplicationLog__c], 'logs not purged properly');

    }
}