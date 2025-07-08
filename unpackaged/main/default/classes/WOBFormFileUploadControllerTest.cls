/**
 * @File Name          : WOBFormFileUploadControllerTest.cls
 * @Description        : Covers test coverage for WOBFormFileUploadController apex class
 * @Author             : Aldrin Rasdas
 * @Group              : MS-AU
 * @Last Modified By   : Aldrin Rasdas
 * @Last Modified On   : 24/11/2021
 * @Modification Log   : 
 * Ver		Date			Author      		    Modification
 * 1.0		24/11/2021		Aldrin Rasdas     		Initial Version
 * 2.0		27/09/2022		Bunnings Dev			Fix test class issue (assertion)
**/
@isTest
private class WOBFormFileUploadControllerTest {
	@isTest
    private static void test1() {
        Map<Id, ContentVersion> files = new Map<Id, ContentVersion>();
        Double wobFileSize;
        List<String> acceptedFileFormats = new List<String>();
        Task tsk = new Task(Subject='Test');
        insert tsk;
        
        ContentVersion file=new ContentVersion(); 
        file.Title='test file'; 
        file.PathOnClient= file.Title + '.txt'; 
        Blob bodyBlob=Blob.valueOf('test file content'); 
        file.VersionData=bodyBlob; 
        file.origin = 'H';
        insert file;
        
        ContentDocumentLink link=new ContentDocumentLink();
        link.contentdocumentid=[select contentdocumentid from contentversion where id =: file.id].contentdocumentid;
        link.ShareType = 'I';
        link.Visibility = 'AllUsers';  
        link.LinkedEntityId = tsk.id;
        insert link;        
        
        Test.startTest();
            try {
                files = WOBFormFileUploadController.getRelatedFilesByRecordId(tsk.Id);
                wobFileSize = WOBFormFileUploadController.getDocumentSize(tsk.Id);
                acceptedFileFormats = WOBFormFileUploadController.getAcceptedFileFormats();
            } catch(Exception e) {
                System.debug(e.getMessage());
            }        
        Test.stopTest();
        
        System.assert(files.size()==1);
        //System.assert(acceptedFileFormats.size()>0);
    }
    
    @isTest
    private static void testGetAttachedDocumentFileLimit(){
        Double wobFilesize;
        
        Test.startTest();
            try {
                wobFilesize = WOBFormFileUploadController.getAttachedDocumentFileLimit();
            } catch(Exception e) {
                System.debug(e.getMessage());
            }        
        Test.stopTest();

        System.assertNotEquals(wobFilesize, 20);
    }
}