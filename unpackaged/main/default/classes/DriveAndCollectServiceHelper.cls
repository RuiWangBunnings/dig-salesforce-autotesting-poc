public class DriveAndCollectServiceHelper {
	@InvocableMethod(label='Converted Appointment Schedule to Selected TimeZone' description='Takes the scheduled values as a string and returns the converted values as a string')
    public static List<ServiceAppointment> ConvertAppointmentScheduleTimeZone(List<ServiceAppointment> serviceAppointments) {
        List<ServiceAppointment> processedList = new List<ServiceAppointment>();
        
        for(ServiceAppointment serviceAppointment: serviceAppointments)
        {
            ServiceAppointment processed = new ServiceAppointment();
            
            //here we test Store_Timezone__c for null, normally it will always have a value but during test the assigned value is null
            processed.SchedStartTime = DateTime.valueOf(serviceAppointment.SchedStartTime.format('yyyy-MM-dd HH:mm:ss', serviceAppointment.Store_Timezone__c != null ? serviceAppointment.Store_Timezone__c : 'Australia/Melbourne'));
            processed.SchedEndTime = DateTime.valueOf(serviceAppointment.SchedEndTime.format('yyyy-MM-dd HH:mm:ss', serviceAppointment.Store_Timezone__c != null ? serviceAppointment.Store_Timezone__c : 'Australia/Melbourne'));
            processedList.add(processed);
        }
        
        return processedList;
    }
    
    
}