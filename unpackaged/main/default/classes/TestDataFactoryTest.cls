/*******************************************************************************************************
* Class Name      	: TestDataFactoryTest
* Description		: Test Class for TestDataFactory
* Author          	: Simplus - MS
* Created On      	: 27/07/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus - MS         27/07/2021		1000				Initial version
* Bunnings dev         28/08/2024		1001				CRMS -17 - Single and Bulk Account Transfer
******************************************************************************************************/
@isTest
public class TestDataFactoryTest {
	
    /**
     * @description test Test all the methods in TestDataFactory
     * @author 
     */
    @isTest
    public static void test () {
        Profile profAdmin = [SELECT Id
                             FROM Profile
                             WHERE Name = 'System Administrator'];
        Test.startTest();
        TestDataFactory.createUsers(1, profAdmin.Id);
        TestDataFactory.createProject(1);
        TestDataFactory.createCalendarView('TestCalendarView', userInfo.getUserId());
        List<UserRole> lstRoles = TestDataFactory.createTSRoles(1);
        List<Account> lstAccount = TestDataFactory.createAccounts(1);
        INSERT lstAccount;
        List<Contract__c> lstContract = TestDataFactory.createContracts(1);
        INSERT lstContract;
        TestDataFactory.createContractLineItems(1);
        TestDataFactory.createInactiveContact();
        TestDataFactory.createStandardLeads(1);
        TestDataFactory.createStandardLead();
        TestDataFactory.getTaskRecordNoId();
        TestDataFactory.getTaskRelationRecordNoId();
        TestDataFactory.getEventRecordNoId();
        TestDataFactory.getEventRelationRecordNoId();
        TestDataFactory.createOpenCases(lstAccount[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createClosedCases(lstAccount[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createContacts(lstAccount[0].Id, userInfo.getUserId(), 1);
        List<Opportunity> lstOppty = TestDataFactory.createOpenOpportunities(lstAccount[0].Id, userInfo.getUserId(), 1);
        INSERT lstOppty;
        TestDataFactory.createClosedOpportunities(lstAccount[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createSupplierQuotes(lstOppty[0].Id, lstAccount[0].Id, 1);
        TestDataFactory.createOpenEventsWithWhatId(lstContract[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createClosedEventsWithWhatId(lstContract[0].Id, userInfo.getUserId(), 1);        
        TestDataFactory.createSpendBandReviews(lstContract[0].Id, 1, userInfo.getUserId(), userInfo.getUserId());
        TestDataFactory.createOpenTasksWithWhatId(lstContract[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createClosedTasksWithWhatId(lstContract[0].Id, userInfo.getUserId(), 1);
        TestDataFactory.createNoExpiredContracts(userInfo.getUserId(), 'Australia', 1);
        TestDataFactory.createExpiredContracts(userInfo.getUserId(), 'Australia', 1);
        TestDataFactory.createContractLineItems(lstContract[0].Id, 'Contract', 'A1', System.today().addDays(1), 1);        
        List<Id> idContracts = new List<Id>();
        idContracts.add(lstContract[0].Id);
        List<Id> idAccounts = new List<Id>();
        idAccounts.add(lstAccount[0].Id);
        List<Double> maxAmounts = new List<Double>();
        maxAmounts.add(25.20);
        List<String> extIds = new List<String>();
        extIds.add('Test Id');
        TestDataFactory.createCustomerContracts(lstAccount[0].Id, idContracts);
        TestDataFactory.createAccCustomerContracts(idAccounts, idContracts);
        List<Spend_Band__c> lstSpendBand = TestDataFactory.createSpendBands(maxAmounts, extIds, 'Australia');
        INSERT lstSpendBand;
        TestDataFactory.createSpendBandReview(lstAccount[0].Id, lstSpendBand[0].Id, lstSpendBand[0].Id, 'Australia');
        TestDataFactory.createAssistedSales(lstAccount[0].Id, 1);
        List<Store__c> lstStores = TestDataFactory.createStores(1);
        INSERT lstStores;
        TestDataFactory.createStoreMember(lstStores[0].Id, userInfo.getUserId(), lstRoles[0].Id);
        TestDataFactory.createOperationsRegion('Test Member', lstRoles[0].Id, userInfo.getUserId());
        TestDataFactory.createProdSubDepartments(1);
        TestDataFactory.createStoreAssists(userInfo.getUserId(), lstStores[0].Id, 1);
        TestDataFactory.createSpecialBuy('Test SpecialBy', System.today());
        
        TestDataFactory.createTopics(1);
        TestDataFactory.createQuotes(lstOppty[0].Id, 'Quote', 1);
        TestDataFactory.createConsentPayloadJSON();
        TestDataFactory.createEntity();
        TestDataFactory.createContactPointAddress();
        TestDataFactory.createContactPointEmail();
        TestDataFactory.createContactPointPhone();
       // TestDataFactory.createSingleAccountRequest(); 
        Test.stopTest();
    }
    

     /**
    * @description      testDataAccountTransfer
    * @author           Sowjanya
    **/
    @isTest
    public static void testDataAccountTransfer () {
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(2, p.Id);
 
        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('456465',users[0].id);

        Test.startTest();
        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        Account_Request__c accountRequest = TestDataFactory.createSingleAccountRequest(users[0].id,'asd8',users[1].id,'testsingle');
        
        Test.stopTest();
    }
}