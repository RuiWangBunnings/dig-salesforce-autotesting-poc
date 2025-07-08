/*******************************************************************************************************
* Class Name      	: WOBRecordTypeSelectorController_Test
* Description		: Test class of WOBRecordTypeSelectorController
* Author          	: Simplus MS
* Created On      	: 07/02/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS             	07/02/2022		1000				Initial version
******************************************************************************************************/
@isTest
public with sharing class WOBRecordTypeSelectorController_Test {
    @isTest
    private static void getListOfRecordTypeTest() {
        Test.startTest();
        List<WOBRecordTypeSelectorController.RecordTypeListWrapper> oppRecordTypeList= WOBRecordTypeSelectorController.getListOfRecordType();
        Test.stopTest();

        System.assertEquals(True, oppRecordTypeList.size() > 0, 'To fetch Opportunity Record types failed');
    }
}