/*******************************************************************************************************
* Class Name        : ApplicationLogETriggerHandlerTest
* Description       : Application Log (Platform Event) trigger test
* Author            : Bunnings Dev
* Created On        : 31/03/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev          31/03/2022      1000                Initial version
******************************************************************************************************/
@IsTest
public class ApplicationLogETriggerHandlerTest {

    @isTest 
    public static void validEvent_Test() {
        Application_log__e appLog = new Application_Log__e(Source__c = 'SM_ClientCredProvider.retrieveToken', Type__c = 'Outbound message', Method__c = 'POST', 
                    Function_Name__c = 'POST', Endpoint_URL__c = 'callout:BNSIT_Webservices_AuthProvider', Body__c = 'Test body');

        Test.startTest();        
            Database.SaveResult sr = EventBus.publish(appLog);            
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
    }
    
}