/*******************************************************************************************************
* Class Name      	: DM_Task_Test
* Description		: Test class for DM_Task
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class DM_Task_Test {
    /**
    * @description 
    * @author Yi Zhang | 15/06/2020 
    **/
    @isTest
    public static void testGetTasks() {
        Test.startTest();
        System.assertEquals(0, DM_Task.getOpenTasks(null, null).size(), 'no task created, no task retrieved');
        System.assertEquals(0, DM_Task.getOpenTasksWithWhoIds(new Set<Id>{null}, new Set<Id>{null}).size(), 'no task created, no task retrieved');
        System.assertEquals(0, DM_Task.getOpenTasksWithWhatIds(new Set<Id>{null}, new Set<Id>{null}).size(), 'no task created, no task retrieved');
        Test.stopTest();
    }
}