/*******************************************************************************************************
* Apex Name       	: DriveAndCollectService_Test
* Description    	: Test Class for DriveAndCollectService
* Author            : Simplus - John Dayondon
* Created On        : 14/02/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer        	Date      		Modification ID    	Description
* -----------------------------------------------------------------------------------------------------
* John Dayondon   	14/02/2022    	1000        		Initial version
* Bunnings Dev		26/09/2022		2000				Fix SOQL Limit issue (only happening in prod)
******************************************************************************************************/
@isTest
public class DriveAndCollectService_Test {
    static testmethod void runGetAppointmentBooking() {
        //create Person Account
        RecordType personeAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Person Account'];
        
        Account personAccount = new Account(RecordTypeId = personeAccountRecordType.Id, Lastname = 'Account', FirstName = 'TestOnly', PersonEmail = 'test@test.com.au');
        insert personAccount;
        
        //create asset 
        Asset newAsset = new Asset(Name ='Test Asset', AccountId = personAccount.Id);
        insert newAsset;
        
        //create service resource
        ServiceResource serviceResource = new ServiceResource(Name = 'Test Service Resource', IsActive = true, ResourceType = 'S', AssetId = newAsset.Id);
        insert serviceResource;
        
        //create the store operating hours to define the timezone
        OperatingHours operatingHours = new OperatingHours(Name ='Test-StoreHrs', TimeZone = 'Australia/Melbourne');
        insert operatingHours;
        
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name = 'Test-Store', OperatingHoursId = operatingHours.Id, IsActive = true);
        insert serviceTerritory;
        
        //create the appointment here
        //2000
        //ServiceAppointment serviceAppointment = new ServiceAppointment(ParentRecordId=personAccount.Id,SchedStartTime= date.valueOf('2022-02-25T16:00:00.000Z'),SchedEndTime=date.valueOf('2022-02-25T16:30:00.000Z'),ServiceTerritoryId=serviceTerritory.Id,Email='john@simplus.com',Order_Number__c='1234567',UpdateAppointmentRedirectURLForEmails__c='test.salesforce.com',StartDateTimeTimeZoneSpecific__c= datetime.valueOf('2022-02-25 09:00:00'));
        ServiceAppointment serviceAppointment = new ServiceAppointment(ParentRecordId = personAccount.Id, SchedStartTime = DateTime.now(), SchedEndTime = DateTime.now().addDays(25), ServiceTerritoryId = serviceTerritory.Id, Email = 'test@test.com.au', Order_Number__c = '1234567', UpdateAppointmentRedirectURLForEmails__c = 'test.salesforce.com', StartDateTimeTimeZoneSpecific__c = DateTime.now().addDays(25));
        insert serviceAppointment;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'GET');
        //2000
        //req.requestURI = '/schedulermanagement/v1/?NumberOfFutureDays=7&LastUpdated="2022-02-09T16:03:18.000Z"';
        
        String dt = DateTime.now().format('dd/MM/yyyy hh:mm a');				
		DateTime dtParse = DateTime.parse(dt);
		String convertedDate = dtParse.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'.000Z\'');
		
        String json = '{"NumberOfFutureDays":7, "LastUpdated":'+'"'+convertedDate+'"'+'}';        
                
        req.requestBody = Blob.valueOf(json);
        //2000
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        	DriveAndCollectService.doGet();
        Test.stopTest();
    }
    
    static testmethod void runPostAppointmentBooking() {
        //create Person Account
        RecordType personeAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Person Account'];
        
        Account personAccount = new Account(RecordTypeId = personeAccountRecordType.Id, Lastname = 'Account', FirstName = 'TestOnly', PersonEmail='test@test.com.au');
        insert personAccount;
        
        //create asset 
        Asset newAsset = new Asset(Name = 'Test Asset', AccountId = personAccount.Id);
        insert newAsset;
        
        //create service resource
        ServiceResource serviceResource = new ServiceResource(Name = 'Test Service Resource', IsActive = true, ResourceType = 'S',AssetId = newAsset.Id);
        insert serviceResource;
        
        //create the store operating hours to define the timezone
        OperatingHours operatingHours = new OperatingHours(Name = 'Test-StoreHrs', TimeZone = 'Australia/Melbourne');
        insert operatingHours;
        
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name = 'Test-Store', OperatingHoursId = operatingHours.Id, IsActive = true);
        insert serviceTerritory;
        
        //create the appointment here
        //2000
        //ServiceAppointment serviceAppointment = new ServiceAppointment(ParentRecordId=personAccount.Id,SchedStartTime= date.valueOf('2022-02-28T16:00:00.000Z'),SchedEndTime=date.valueOf('2022-02-28T16:30:00.000Z'),ServiceTerritoryId=serviceTerritory.Id,Email='john@simplus.com',Order_Number__c='1234567',UpdateAppointmentRedirectURLForEmails__c='test.salesforce.com',StartDateTimeTimeZoneSpecific__c= datetime.valueOf('2022-02-28 09:00:00'));
        ServiceAppointment serviceAppointment = new ServiceAppointment(ParentRecordId = personAccount.Id, SchedStartTime = DateTime.now(), SchedEndTime = DateTime.now().addDays(20), ServiceTerritoryId = serviceTerritory.Id, Email = 'test@test.com.au', Order_Number__c = '1234567', UpdateAppointmentRedirectURLForEmails__c = 'test.salesforce.com', StartDateTimeTimeZoneSpecific__c = DateTime.now().addDays(20));
        insert serviceAppointment;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestURI = '/schedulermanagement/v1/';
        //2000
        //req.requestBody = Blob.valueOf('{"NumberOfFutureDays":7,"LastUpdated":"2022-02-10T16:30:00.000Z"}');

        String dt = DateTime.now().format('dd/MM/yyyy hh:mm a');				
		DateTime dtParse = DateTime.parse(dt);
		String convertedDate = dtParse.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'.000Z\'');
		
        String json = '{"NumberOfFutureDays":7, "LastUpdated":'+'"'+convertedDate+'"'+'}';        

        req.requestBody = Blob.valueOf(json);
		//2000
		
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        	DriveAndCollectService.doPost();
        Test.stopTest();
    }
    
	static testMethod void runConvertAppointmentScheduleTimeZone() {
        try {
            //create Person Account
            RecordType personeAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Person Account'];
            
            Account personAccount = new Account(RecordTypeId = personeAccountRecordType.Id, Lastname = 'Account', FirstName = 'TestOnly', PersonEmail = 'test@test.com.au');
            insert personAccount;
                
            //create asset 
            Asset newAsset = new Asset(Name = 'Test Asset', AccountId = personAccount.Id);
            insert newAsset;
                
            //create service resource
            ServiceResource serviceResource = new ServiceResource(Name = 'Test Service Resource', IsActive = true, ResourceType = 'S',AssetId = newAsset.Id);
            insert serviceResource;
                
            //create the store operating hours to define the timezone
            OperatingHours operatingHours = new OperatingHours(Name = 'Test-StoreHrs', TimeZone = 'Australia/Melbourne');
            insert operatingHours;
                
            ServiceTerritory serviceTerritory = new ServiceTerritory(Name = 'Test-Store', OperatingHoursId = operatingHours.Id, IsActive = true);
            insert serviceTerritory;
                
            //create the appointment here 
            ServiceAppointment serviceAppointment = new ServiceAppointment(ParentRecordId = personAccount.Id, SchedStartTime = Date.valueOf('2022-02-28T16:00:00.000Z'), SchedEndTime = Date.valueOf('2022-02-28T16:30:00.000Z'), ServiceTerritoryId = serviceTerritory.Id, Email = 'test@test.com.au', Order_Number__c = '1234567', UpdateAppointmentRedirectURLForEmails__c = 'test.salesforce.com', StartDateTimeTimeZoneSpecific__c = DateTime.valueOf('2022-02-28 09:00:00'));
            insert serviceAppointment;
            
            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            serviceAppointments.add(serviceAppointment);
            
            Test.startTest();
            	DriveAndCollectServiceHelper.ConvertAppointmentScheduleTimeZone(serviceAppointments);
            Test.stopTest();
        }
        
        catch(Exception ex) {
            system.debug(ex.getMessage());
        }
      
    }
}