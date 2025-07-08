/*******************************************************************************************************
* Class Name      	: DM_Event_Test
* Description		: Test class for DM_Event
* Author          	: Simplus - Yi Zhang
* Created On      	: 15/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class DM_Event_Test {
    /**
    * @description 
    * @author Yi Zhang | 15/06/2020 
    **/
    @isTest
    public static void testGetEvents() {
        Test.startTest();
        System.assertEquals(0, DM_Event.getOpenEvents(null, null).size(), 'no event created, no event retrieved');
        System.assertEquals(0, DM_Event.getOpenEventsWithWhoIds(new Set<Id>{null}, new Set<Id>{null}).size(), 'no event created, no event retrieved');
        System.assertEquals(0, DM_Event.getOpenEventsWithWhatIds(new Set<Id>{null}, new Set<Id>{null}).size(), 'no event created, no event retrieved');
        Test.stopTest();
    }
}