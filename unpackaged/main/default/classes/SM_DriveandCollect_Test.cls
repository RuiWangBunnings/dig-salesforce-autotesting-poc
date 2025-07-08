/*******************************************************************************************************
* Class Name      	: SM_DriveandCollect_Test
* Description		: Test class for SM_DriveandCollect
* Author          	: Bunnings Dev
* Created On      	: 6/06/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     6/06/2023		1000				Initial version - BUNDIG-14708
* Jasper R. Galapon		19/10/2023		1001				BUNDIG-26279 - Test Class failures in PROD
******************************************************************************************************/

@isTest
private class SM_DriveandCollect_Test {

    @isTest
    public static void test_decryptDriveAndCollectParam() {
        Test.startTest();
        List<SM_DriveandCollect.flowInput> fInput = new List<SM_DriveandCollect.flowInput>();
        SM_DriveandCollect.flowInput a = new SM_DriveandCollect.flowInput();
        a.inputCustomerFirstName = 'JbT7%2BL35fYUadhWoVMqLFQ%3D%3D';
        a.inputCustomerEmail = 'UkHRXRNbXERzbU3k8F3y7cfHgNmtZAxnI9OIlpZBy0A%3D';
        a.inputOrderNumber = '1nV1UtP2mUMUtbI2EM3Fhg%3D%3D';
        a.inputStoreId = 'Tc2f5VFgA5T8LaQLvRF%2FQQ%3D%3D';
        a.inputiVector = 'NsxMkbbzCGYt19c9HjsYUg%3D%3D';
        fInput.add(a);
        	
        List<SM_DriveandCollect.flowOutput> fOutput = SM_DriveandCollect.decryptDriveAndCollectParam(fInput);
        System.assertNotEquals(fOutput, null);
		Test.stopTest();       
    }

	@isTest
    public static void test_getCustomMetadataType() {
        Test.startTest();
        	List<Drive_and_Collect_Configuration__mdt> drive = SM_DriveandCollect.getCustomMetadataType();
        	System.assertNotEquals(drive, null);
        Test.stopTest();
    }    
}