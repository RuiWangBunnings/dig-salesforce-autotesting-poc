/*******************************************************************************************************
* Class Name        : cplDeleteTempQueueable
* Description       : Delete Customer Price List Temp Record
* Author            : Jasper R. Galapon
* Created On        : 27/12/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          27/12/2023      1000                BUNDIG-26295 - Initial version
******************************************************************************************************/

public class cplDeleteTempQueueable implements Queueable {
    private String custId;

    public cplDeleteTempQueueable(String custId) {
        this.custId = custId;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('***INSIDE cplDeleteTempQueueable');

            List<Customer_Price_List__c> cplToDelete = [SELECT Id FROM Customer_Price_List__c WHERE (Start_Date__c = NULL AND End_Date__c = NULL) AND Status__c = 'Inactive' AND Account__r.Power_Pass_Account_Number__c =:custId];
            System.debug(LoggingLevel.FINEST, '***cplToDelete: ' + cplToDelete);

            // DO WE NEED TO LOG SUCCESSFUL DELETION??
            DELETE cplToDelete;

        } catch(Exception e) {
            // Create Application Log
            ApplicationLogger.log('cplDeleteTempQueueable', 'Customer_Price_List__c', 'Queueable', e);
        }
    }

}