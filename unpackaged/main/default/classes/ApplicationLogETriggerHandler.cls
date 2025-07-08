/*******************************************************************************************************
* Class Name      	: ApplicationLogETriggerHandler
* Description		: Trigger Handler for Application 
* Author          	: Bunnings Dev
* Created On      	: 31/03/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          31/03/2022		1000				SFSUP-289 - Log COS API Callout details
******************************************************************************************************/
public class ApplicationLogETriggerHandler {

    public static void afterInsert(Map<Id, Application_Log__e> oldMap, Map<Id, Application_Log__e> newMap) {
        createApplicationLog(newMap.values());
    }

    private static List<ApplicationLog__c> createApplicationLog(List<Application_Log__e> newList) {
        List<ApplicationLog__c> appLogToInsert = new List<ApplicationLog__c>();

        if (newList.isEmpty()) {
            return null;
        }

        for (Application_Log__e appLog : newList) {
            if (appLog.Source__c.contains('SM_ClientCredProvider')) {                
                appLogToInsert.add(new ApplicationLog__c(Source__c = appLog.Source__c, Type__c = appLog.Type__c, Method__c = appLog.Method__c, 
                    Function_Name__c = appLog.Function_Name__c, Endpoint_URL__c = appLog.Endpoint_URL__c, Body__c = appLog.Body__c));
            }
        }
        
        if (!appLogToInsert.isEmpty()) {
            try {
                INSERT appLogToInsert;
            } catch (Exception e) {
                ApplicationLogger.log('ApplicationLogETriggerHandler.createApplicationLog', 'Application Log Platform Event', 'Trigger', e);
            }
        }

        return appLogToInsert;
    }
}