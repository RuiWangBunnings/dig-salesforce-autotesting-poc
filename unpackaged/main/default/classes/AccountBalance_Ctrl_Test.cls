/****************************************************************************************
* Class : AccountBalance_Ctrl_Test
* Created By : bob alicante
----------------------------------------------------------------------------------------
* Description : Test class for AccountBalance_Ctrl
----------------------------------------------------------------------------------------
* Version History:
* VERSION     DEVELOPER NAME        DATE            DETAIL FEATURES
  1.0         bob alicante          08.12.2020      Initial Development
***************************************************************************************/
@isTest
private with sharing class AccountBalance_Ctrl_Test {    
    @isTest
    public static void testGetAccountBalance() {

        // create Account record
        Account objAccount = new Account(
            type = 'CREDIT',
            Name = 'Test Account Integration'
        );
        insert objAccount;
        
        Test.startTest();
        
        // Set mock callout class
        //Test.setMock(HttpCalloutMock.class, new GetAccountBalanceMockResponseGenerator());
		Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"account Balance":"$200.00"}', 200, false));
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        List<Account> listAccounts = AccountBalance_Ctrl.getAccountBalance(objAccount.Id, false);
        Test.stopTest();
    }

    @isTest
    public static void testForLastRefresh() {
        // create Account record
        Account objAccount = new Account(
            type = 'CREDIT',
            Name = 'Test Account Integration',
            Last_Refresh_On__c = System.now()
        );
        insert objAccount;
        
        Test.startTest();
        
        // Set mock callout class
        //Test.setMock(HttpCalloutMock.class, new GetAccountInvoicesMockResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('{"overdueInvoices": [{"trxNumber": "6126/90003407","trxDate": "2019-09-30T16:00:00.000Z","amountDue": 8.46,"dueDate": "2019-11-29T16:00:00.000Z"}]}', 200, false));

        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        List<Account> listAccounts = AccountBalance_Ctrl.getAccountBalance(objAccount.Id, false);
		Test.stopTest();
    }
    
    @isTest
    public static void testForInvalidResponse() {
        // create Account record
        Account objAccount = new Account(
            type = 'CREDIT',
            Name = 'Test Account Integration',
            Last_Refresh_On__c = System.now()
        );
        insert objAccount;
        
        Test.startTest();
        
        // Set mock callout class
        //Test.setMock(HttpCalloutMock.class, new GetAccountBalanceInvalidResponse());
        Test.setMock(HttpCalloutMock.class, new SM_RESTCalloutMock('test', 200, false));
        List<Account> listAccounts = AccountBalance_Ctrl.getAccountBalance(objAccount.Id, false);
		Test.stopTest();
    }    
}