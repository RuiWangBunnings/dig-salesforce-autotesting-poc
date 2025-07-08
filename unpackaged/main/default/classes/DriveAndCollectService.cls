/*******************************************************************************************************
* Apex Name       	: DriveAndCollectService
* Description    	: REST API for Data Pull
* Author            : Simplus - John Dayondon
* Created On        : 02/02/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer        Date      Modification ID    Description
* -----------------------------------------------------------------------------------------------------
* John Dayondon   02/02/2022    1000        Initial version
******************************************************************************************************/
@RestResource(urlMapping='/schedulermanagement/v1/')
global with sharing class DriveAndCollectService 
{
	@HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        
        try
        {
            Integer numberOfFutureDays = RestContext.request.params.get('NumberOfFutureDays') == null ? 2 : integer.valueOf(RestContext.request.params.get('NumberOfFutureDays'));
            String lastUpdated = RestContext.request.params.get('LastUpdated');
            
            //actually build the payload here
            List<DriveAndCollectServiceAppointment> listOfAppointments = new List<DriveAndCollectServiceAppointment>();  
            
            //get the matching records
            String query = 'select Id, SchedStartTime, DaysInTheFuture__c, FirstName__c,LastName__c,Email__c,StoreId__c,Status,Order_Number__c from ServiceAppointment where ParentRecordType=\'Account\' AND ((DaysInTheFuture__c <=' + numberOfFutureDays + ' AND DaysInTheFuture__c >= 0)';
            query = string.isNotBlank(lastUpdated) ? query + ' OR LastModifiedDate > ' + lastUpdated + ')' : query + ')';
            List<ServiceAppointment> listOfMatchingServiceAppointment = Database.query(query);
            for(ServiceAppointment serviceAppointment: listOfMatchingServiceAppointment)
            {
                DriveAndCollectServiceAppointment appointment = new DriveAndCollectServiceAppointment();
                appointment.Id = serviceAppointment.Id;
                appointment.appointmentDateTime = serviceAppointment.SchedStartTime != null ? string.valueOf(serviceAppointment.SchedStartTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')) : '';
                appointment.firstName = serviceAppointment.FirstName__c;
                appointment.lastName = serviceAppointment.LastName__c;
                appointment.email = serviceAppointment.Email__c;
                appointment.status = serviceAppointment.Status;
                appointment.orderNumber = serviceAppointment.Order_Number__c;
                //appointment.timeZone = serviceAppointment.Store_Timezone__c;
                appointment.Locationid = string.isNotBlank(serviceAppointment.StoreId__c) ? integer.valueOf(serviceAppointment.StoreId__c) : 0;
                listOfAppointments.add(appointment);
            }      
            
            res.responseBody = Blob.valueOf(JSON.serialize(listOfAppointments));
            res.statusCode = 200;
        }
        catch(Exception ex)
        {
            system.debug(ex.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize('{"message":"' + ex.getMessage() + '""}'));
            res.statusCode = 500;
        }
    }
    
    @HttpPost
    global static void doPost()
    {
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        
        try
        {
            //check if they passed the params in the body
            system.debug(req.requestBody.toString());
            DriveAndCollectRequestBody readRequest = DriveAndCollectRequestBody.parse(req.requestBody.toString());
            
            //actually build the payload here
            List<DriveAndCollectServiceAppointment> listOfAppointments = new List<DriveAndCollectServiceAppointment>();
            
            //get the matching records
            String query = 'select Id, SchedStartTime, DaysInTheFuture__c, FirstName__c,LastName__c,Email__c,StoreId__c,Status,Order_Number__c from ServiceAppointment where ParentRecordType=\'Account\' AND ((DaysInTheFuture__c <=' + readRequest.NumberOfFutureDays + ' AND DaysInTheFuture__c >= 0)';
            query = string.isNotBlank(readRequest.LastUpdated) ? query + ' OR LastModifiedDate > ' + readRequest.LastUpdated + ')' : query + ')';
            system.debug(query);
            List<ServiceAppointment> listOfMatchingServiceAppointment = Database.query(query);
            for(ServiceAppointment serviceAppointment: listOfMatchingServiceAppointment)
            {
                DriveAndCollectServiceAppointment appointment = new DriveAndCollectServiceAppointment();
                appointment.Id = serviceAppointment.Id;
                appointment.appointmentDateTime = serviceAppointment.SchedStartTime != null ? string.valueOf(serviceAppointment.SchedStartTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')) : '';
                appointment.firstName = serviceAppointment.FirstName__c;
                appointment.lastName = serviceAppointment.LastName__c;
                appointment.email = serviceAppointment.Email__c;
                appointment.status = serviceAppointment.Status;
                appointment.orderNumber = serviceAppointment.Order_Number__c;
                //appointment.timeZone = serviceAppointment.Store_Timezone__c;
                appointment.Locationid = string.isNotBlank(serviceAppointment.StoreId__c) ? integer.valueOf(serviceAppointment.StoreId__c) : 0;
                listOfAppointments.add(appointment);
            }        
            res.responseBody = Blob.valueOf(JSON.serialize(listOfAppointments));
            res.statusCode = 200;
        }
        catch(Exception ex)
        {
            system.debug(ex.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize('{"message":"' + ex.getMessage() + '""}'));
            res.statusCode = 500;
        }
    }
}