/***************************************************************************************************
* Class Name      	: FileDownloadCtrl_Test
* Description		: This is the test class for FileDownloadCtrl apex class
* Author          	: Simplus - Aldrin Rasdas
* Created On      	: 11-Jan-2021
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Aldrin Rasdas         02-Dec-2020		1000				Initial version
*****************************************************************************************************/
@istest
private class FileDownloadCtrl_Test {
    private class PLCON_HttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
    
            // Creating a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('"' + EncodingUtil.base64Encode(blob.toPdf('test file content')) + '"');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class PLCON_HttpCalloutMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
    
            // Creating a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"401-Unauthorized"}');
            res.setStatus('Unauthorized');
            res.setStatusCode(401);
            return res;
        }
    }    
    
    @isTest
    static void testMethod01() {
        Test.startTest();
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new PLCON_HttpCalloutMock());

        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        FileDownloadCtrl.OutputFile out = FileDownloadCtrl.getFile(null, 'PLCON_FileDownload').file;
        Test.stopTest();        
        
        System.assertEquals(null, out.recordId);
        system.assertEquals(null, out.errorMessage);
        system.assertEquals(false, out.isError);
        system.assertEquals(false, String.isblank(out.fileBlob));
    }
    
    @isTest
    static void testMethod02() {
        Test.startTest();
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new PLCON_HttpCalloutMockError());

        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        FileDownloadCtrl.OutputFile out = FileDownloadCtrl.getFile(null, 'PLCON_FileDownload').file;
        List<ApplicationLog__c> logs = new List<ApplicationLog__c>();
        logs.add(new ApplicationLog__c(Type__c='Outbound message'));
        FileDownloadCtrl.saveLogs(JSON.serialize(logs));
        Test.stopTest();        
        System.debug(out.isError);
        System.assertEquals(null, out.recordId);
        system.assertEquals(false, string.isblank(out.errorMessage));
        system.assertEquals(true, out.isError);
        system.assertEquals(true, String.isblank(out.fileBlob));        
    }        
}