/*******************************************************************************************************
* Class Name      	: SM_DriveandCollect
* Description		: Service layer of Drive and Collect functionality
* Author          	: Jasper R. Galapon
* Created On      	: 3/02/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     3/02/2023		1000				Initial version - BUNDIG-14708
******************************************************************************************************/

public class SM_DriveandCollect {
        
    // BUNDIG-12037 - Used in the Drive and Collect Flow to decrypt the URL values
    @InvocableMethod(label='Decrypt Input in the URL' description='Takes the parameter from the URL and decrypt')
    public static List<flowOutput> decryptDriveAndCollectParam(List<flowInput> inputs) {
        String decryptedFirstName;
        String decryptedEmail;
        String decryptedOrderNumber;
        String decryptedStoreId;
        List<flowOutput> returnOutput = new List<flowOutput>(); 

        for (flowInput f : inputs) {
            String decodedFirstName = EncodingUtil.urlDecode(f.inputCustomerFirstName, 'UTF-8');
            String decodedEmail = EncodingUtil.urlDecode(f.inputCustomerEmail, 'UTF-8');
            String decodedOrderNumber = EncodingUtil.urlDecode(f.inputOrderNumber, 'UTF-8');
            String decodedStoreId = EncodingUtil.urlDecode(f.inputStoreId, 'UTF-8');
            String decodedIV = EncodingUtil.urlDecode(f.inputiVector, 'UTF-8');

            System.debug('***DECODED - FN: '+decodedFirstName + ' / EMAIL: ' + decodedEmail + ' / ORDER: ' + decodedOrderNumber + ' / STORE: ' + decodedStoreId + ' / IV: ' + decodedIV);

            decryptedFirstName = SM_Utility.performDecryptWithIV(decodedFirstName, decodedIV);
            decryptedEmail = SM_Utility.performDecryptWithIV(decodedEmail, decodedIV);
            decryptedOrderNumber = SM_Utility.performDecryptWithIV(decodedOrderNumber, decodedIV);
            decryptedStoreId = SM_Utility.performDecryptWithIV(decodedStoreId, decodedIV);
            
            System.debug('***DECRYPTED - FN: ' + decryptedFirstName + ' / EMAIL: ' + decryptedEmail + ' / ORDER: ' + decryptedOrderNumber + ' / STORE: ' + decryptedStoreId);
        }
    
        returnOutput.add(new flowOutput(decryptedFirstName, decryptedEmail, decryptedOrderNumber, decryptedStoreId, ''));
        
        return returnOutput;
    }

    // Wrapper class to handle flow input
    public class flowInput {
        @InvocableVariable
        public String inputCustomerFirstName;

        @InvocableVariable
        public String inputCustomerEmail;

        @InvocableVariable
        public String inputOrderNumber;

        @InvocableVariable
        public String inputStoreId;

        @InvocableVariable
        public String inputiVector;        
    }

    // Wrapper class to handle flow output
    public class flowOutput {
        @InvocableVariable
        public String outputCustomerFirstName;

        @InvocableVariable
        public String outputCustomerEmail;

        @InvocableVariable
        public String outputOrderNumber;

        @InvocableVariable
        public String outputStoreId;

        @InvocableVariable
        public String outputiVector;

        public flowOutput(String outputCustomerFirstName, String outputCustomerEmail, String outputOrderNumber, String outputStoreId, String outputiVector) {
            this.outputCustomerFirstName = outputCustomerFirstName;
            this.outputCustomerEmail = outputCustomerEmail;
            this.outputOrderNumber = outputOrderNumber;
            this.outputStoreId = outputStoreId;
            this.outputiVector = outputiVector;
        }
    }

        
    // BUNDIG-12037 - Get Drive and Collect setup
    public static List<Drive_and_Collect_Configuration__mdt> getCustomMetadataType() {
        return [SELECT Id, Algorithm_Name__c, Decryption_Key__c FROM Drive_and_Collect_Configuration__mdt WHERE DeveloperName = 'Drive_and_Collect_Setup'];
    }

}