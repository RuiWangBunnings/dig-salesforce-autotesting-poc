/*******************************************************************************************************
* Class Name      	: SM_Utility
* Description		: Utiliy class which contains reusable methods
* Author          	: Jasper R. Galapon
* Created On      	: 2/06/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     2/06/2023		1000				Initial version - BUNDIG-14708
* Jasper R. Galapon     30/06/2023      1001                BUNDIG-22401 / BUNDIG-22402 - New/Renewal Contract / Contract Amendments - Email Notifications
* Jasper R. Galapon     09/08/2023      1002                BUNDIG-23679 - Added new method for sending bell notification
* Jasper R. Galapon     16/08/2023      1003                BUNDIG-24085 - Added new method to get Org configs
* Jasper R. Galapon     12/12/2023      1004                BUNDIG-26295 - Added new method for Pricing Assignment Error Logging
* Jasper R. Galapon     10/06/2025      1005                BUNDIG-51801 - Ability to Access a Thread ID
******************************************************************************************************/

public class SM_Utility {
    
    public static String performDecryptWithIV(String stringToDecrypt, String StringIV) {        
        List<Drive_and_Collect_Configuration__mdt> dcSetup = SM_DriveandCollect.getCustomMetadataType();
        String strKey = dcSetup[0].Algorithm_Name__c;
        String strDecrKey = dcSetup[0].Decryption_Key__c;

        Blob key = Blob.valueOf(strDecrKey);
        Blob ivKey = EncodingUtil.base64Decode(StringIV);
        Blob encryptedString = EncodingUtil.base64Decode(stringToDecrypt);
        Blob decrypted = Crypto.decrypt(strKey, key, ivKey, encryptedString);
        String decryptedString = decrypted.toString();

        return decryptedString;
    }

    /**
    * Send an email with from Address
    **/
    public static void sendEmail(String fromAddress, List<String> recipients, String subject, String message){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setOrgWideEmailAddressId(fromAddress);
        email.setToAddresses(recipients);
        email.setSubject(subject);
        email.setPlainTextBody(message);
        email.setHtmlBody(message);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

    /**
    * Send bell notification
    **/
    public static void sendBellNotification(String devName, Set<String> recipientIds, String msgTitle, String msgBody) {
        
        Id notificationTypeId = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =:devName LIMIT 1].Id;

        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(msgTitle);
        notification.setBody(msgBody);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId('000000000000000AAA'); //dummy Id per https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Messaging_CustomNotification.htm#custom_notification_usage
        
        // Actually send the notification
        try {
            // notification.send(new Set<String> { UserInfo.getUserId() });
            notification.send(recipientIds);
        }
        catch (Exception e) {
            ApplicationLogger.log('SM_Utility.sendBellNotification', devName, 'SM_Utility', e);
            System.debug('Problem sending notification: ' + e.getMessage());            
        } finally {
            return;
        }
    }

    /**
    * Get Org configs
    **/
    public static SM_Configs__c orgConfig {
        get {
            if (orgConfig == null) orgConfig = SM_Configs__c.getInstance();
            return orgConfig;
        }
        private set;
    }

    /**
     * Pricing Assignment Error Logging
    **/
    public static Map<String, Object> mapFieldsForPricingAssignmentErrorLog(String powerpassNumber, String sourceApexMethod, String calloutType, HttpRequest request, HttpResponse response, Map<Id, Map<String, String>> cplMap, Exception e, String ErrMessage) {
        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('POWERPASSNUMBER', powerpassNumber);
        tempMap.put('SOURCEAPEXMETHOD', sourceApexMethod);
        tempMap.put('CALLOUTTYPE', calloutType);
        tempMap.put('REQUEST', request);
        tempMap.put('RESPONSE', response);
        tempMap.put('MAPTOSERIALIZE', cplMap);        
        tempMap.put('RETRYPARAMS', cplMap);
        tempMap.put('E', e);
        tempMap.put('ERRORMESSAGE', ErrMessage);

        return tempMap;
    }

    /**
     * Pricing Assignment Error Description and Meaning
    **/

    public static String pricingAssignmentErrorDescription(String strErr) {
        Map<String, String> tempMap = new Map<String, String>();
        tempMap.put('NOT ALLOWED - CONFLICTING PRICING LEVELS', 'The customer already has a spend band id different to the spend band you try to assign to the customer');
        tempMap.put('NOT ALLOWED - DATE OVERLAP WITH OTHER PRICE LIST', 'The customer has spend band with State = NATIONAL or the equal to the State parameter AND cost zone = ALL or equal to the cost zone parameter');
        tempMap.put('THIS PRICE LIST IS ALREADY IN USE. PLEASE ENTER A UNIQUE PRICE LIST', 'The price list header id is attached to the customer and is effective on the date given in the parameter');
        tempMap.put('NATIONAL/ALL, ADDITIONAL ROW NOT ALLOWED', 'The customer has a price list with State = NATIONAL and cost zone = ALL');
        tempMap.put('NATIONAL/COST ZONE TO NATIONAL/ALL, MUST END DATE EXISTING RECORD', 'Changing from NATIONAL and specific cost zone to NATIONAL/ALL must first end date existing record');
        tempMap.put('STATE/ALL, ALLOW OTHER STATE', 'The customer currently on state = parameter state AND state not = NATIONAL and cost zone not ALL');
        tempMap.put('STATE/* TO NATIONAL/*, MUST END DATE EXISTING RECORD(S)', 'Changing from specific STATE to NATIONAL must first end date existing record');
        tempMap.put('STATE/COST ZONE TO STATE/OTHER COST ZONE', 'The customer is already on the parameter State and is not NATIONAL and on the parameter Cost Zone and is not ALL');
        tempMap.put('NATIONAL/COST ZONE TO STATE/COST ZONE', 'The customer is on price list with State = NATIONAL and cost zone = parameter cost zone and is not ALL');
        tempMap.put('NATIONAL/COST ZONE TO STATE/ALL', 'The customer is on price list with State = NATIONAL and cost zone NOT ALL, but  parameter cost zone and is ALL');
        tempMap.put('ASSIGNMENT COULD NOT BE CREATED.', 'Exception occurred in the assign_customer routine');
        tempMap.put('CUSTOMER NOT ASSIGNED TO THE PRICELIST', 'The given price list is not currenlty assigned to the customer');
        tempMap.put('CUSTOMER UNASSIGNED FROM PRICELIST', 'Customer successfully unassigned from the price list');
        tempMap.put('CUSTOMER NOT UNASSIGNED FROM THE PRICELIST', 'Cannot unassigned customer from the price list');
        tempMap.put('VALIDATION SUCCESSFUL', 'Validation successful');
        tempMap.put('CUSTOMER ASSIGNED TO PRICELIST…', 'Customer successfully assigned to the price list');
        tempMap.put('SUCCESSFULL VALIDATION OF CUSTOMER ASSIGNMENT TO PRICELIST', 'Successfull validation of customer assignment to pricelist');

        return tempMap.get(strErr);
    }

    /**
     * Update an object
     * How to use
     * Map<String, Object> fieldsToUpdate = new Map<String, Object>{'Name' => 'New Account Name', 'Phone' => '123-456-7890'};
     * SM_Utility.updateRecord('Account', '001xx000003DHP0AAO', fieldsToUpdate);
    **/
        
    public static void updateRecord(String objectName, Id recordId, Map<String, Object> updatedFields) {
        String soqlQuery = 'SELECT Id FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
        SObject recordToUpdate = Database.query(soqlQuery);

        for (String fieldName : updatedFields.keySet()) {
            recordToUpdate.put(fieldName, updatedFields.get(fieldName));
        }
            
        try {
            update recordToUpdate;
            System.debug(objectName + ' ' + recordId + ' updated successfully.');
        } catch (DmlException e) {
            System.debug('Failed to update ' + objectName + ': ' + e.getMessage());
        }
    }

    /**
     * Insert a record
     * How to use
     * Map<String, Object> accountFields = new Map<String, Object>{'Name' => 'Acme Corporation', 'Phone' => '123-456-7890'};
     * SM_Utility.insertRecord('Account', accountFields);
    **/        
    public static void insertRecord(String objectType, Map<String, Object> fieldMap) {
        try {
            // Create a new instance of the specified object type
            sObject record = Schema.getGlobalDescribe().get(objectType).newSObject();
            
            // Set the fields with the provided values
            for (String fieldName : fieldMap.keySet()) {
                record.put(fieldName, fieldMap.get(fieldName));
            }
            
            insert record;
            System.debug(LoggingLevel.FINEST, '***Record inserted successfully: ' + record);
        } catch (DmlException e) {
            System.debug(LoggingLevel.FINEST, '***An error occurred while inserting the record: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('An unexpected error occurred: ' + e.getMessage());
            throw e;
        }
    }
    /**
     * Get System Administrators Email
    **/ 
    public static List<String> getSystemAdministratorEmails() {
        List<String> adminEmails = new List<String>();
        
        for (User admin : [SELECT Email 
                           FROM User 
                           WHERE Profile.Name = 'System Administrator' 
                           AND IsActive = true 
                           AND Email != null]) {
            adminEmails.add(admin.Email);
        }
        
        return adminEmails;
    }
    

    /**
    * @description getOpptyFollowUpDatePresentingStage
    * @author Bunnings Dev | 2024-10-30
    * @return Notification_Date__mdt 
    **/
    
    public static Integer getOpptyFollowUpDatePresentingStage() {
        Notification_Date__mdt opptyFollowUpPresentingDays = Notification_Date__mdt.getInstance('OpportunityFollowUpPresentingStage');
        
        return Integer.valueof(opptyFollowUpPresentingDays.Number_of_Days__c);
    }

    /**
    * @description BUNDIG-51801 - getThreadingToken
    * @author JasperRG | 10/06/2025
    * @return List of tokens 
    **/
    @InvocableMethod(label='Get Threading Token')
    public static List<String> getThreadingToken(List<Id> recordIds) {

        List<String> tokens = new List<String>();

        for (Id recId : recordIds) {
            tokens.add(EmailMessages.getFormattedThreadingToken(recId));
        }
        return tokens;
    }
}