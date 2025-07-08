/****************************************************************************************
* Class : AccountBalance_Ctrl
* Created By : bob alicante
----------------------------------------------------------------------------------------
* Description : Controller for AccountBalance web component.
----------------------------------------------------------------------------------------
* Utility Test Data : AccountBalance_Ctrl_Test
----------------------------------------------------------------------------------------
* Version History:
* VERSION     DEVELOPER NAME        DATE            DETAIL FEATURES
  1.0         bob alicante          02.12.2020      Initial Development
***************************************************************************************/
public with sharing class AccountBalance_Ctrl {
    @AuraEnabled
    public static List<Account> getAccountBalance(Id accountId, Boolean isManualRefresh) {
      System.debug('*** getAccountBalance ***');
        List<Account> listAccounts = new List<Account>();
        long lastRefreshMinutes;
        Integer minutes = 0;
        System.debug('listAccounts--->' + listAccounts);
        System.debug('isManualRefresh--->' + isManualRefresh);
        listAccounts = [
            SELECT
                Id,
                Account_Balance_JSON__c,
                Type,
                Power_Pass_Account_Number__c,
                RecordType.Name,
                Account_Balance__c,
                Last_Refresh_On__c
            FROM
                Account
            WHERE
                Id = :accountId
        ];
        System.debug('listAccounts[0].Type----->' + listAccounts[0].Type);
        if (listAccounts[0].Type != 'CASH') {
            if (listAccounts[0].Last_Refresh_On__c != null) {
                lastRefreshMinutes = getRefreshTimeDiff(listAccounts[0].Last_Refresh_On__c);
            }
            System.debug('lastRefreshMinutes----->' + lastRefreshMinutes);
            System.debug('listAccounts[0].Last_Refresh_On__c----->' + listAccounts[0].Last_Refresh_On__c);
            if (System.label.Account_Balance_Integration_Time != null) {
                minutes = Integer.valueOf(System.label.Account_Balance_Integration_Time);
            }
            if (!isManualRefresh && (listAccounts[0].Last_Refresh_On__c == null || lastRefreshMinutes >= minutes)) {
                System.debug('*** IN IF ***');
                listAccounts = getCalloutData(listAccounts);
            }
            else if(isManualRefresh) {
                System.debug('*** IN else ***');
                listAccounts = getCalloutData(listAccounts);
            }
        }
        // listAccounts = getCalloutData(listAccounts);
        return listAccounts;
    }

    @AuraEnabled
    public static List<Account> getCalloutData(List<Account> listAccounts) {
        System.debug('listAccounts--->' + listAccounts);
        listAccounts = fetchAccountBalance(listAccounts);
        System.debug('fetchAccountBalance listAccounts--->' + listAccounts);
        listAccounts = fetchInvoices(listAccounts);
        System.debug('fetchInvoices listAccounts--->' + listAccounts);
        listAccounts = updateAccounts(listAccounts);
        System.debug('updateAccounts listAccounts--->' + listAccounts);
        return listAccounts;
    }

    // @future
    public static List<Account> updateAccounts(List<Account> listAccounts) {
        System.debug('Update took place');
        try {
            System.debug('befor update listAccounts--->' + listAccounts);
            listAccounts[0].Last_Refresh_On__c = System.now();
            update listAccounts;
            System.debug('after update listAccounts--->' + listAccounts);
        }
        Catch(Exception e) {
            // exception goes here
        }
        return listAccounts;
    }

    public static List<Account> fetchAccountBalance(List<Account> listAccounts) {        
        System.debug('*** fetchAccountBalance ***');
        String countryCode = 'NZ';
        System.debug('listAccounts---->' + listAccounts[0].RecordType.Name);
        if (String.valueOf(listAccounts[0].RecordType.Name).startsWith('AU')) {
            countryCode = 'AU';
        }
        
        Map<String,String> params = new Map<String, String>();
        params.put('{{COUNTRY}}', countryCode);
        params.put('{{ACCT_NBR}}', listAccounts[0].Power_Pass_Account_Number__c);
        System.debug('countryCode---->' + countryCode);
        /*
        String endpoint = 'callout:'
                          + System.Label.BN_Named_Credential
                          +'/commercial-customer-services/api/v1/'
                          + countryCode
                          + '/customer/'
                          + listAccounts[0].Power_Pass_Account_Number__c
                          + '/get_account_balance';
        String method = 'GET';
		*/
        // String body = JSON.serialize(wrapper, true);
        //String body = '';
        try {
            //HttpRequest request = SM_RESTCallout.createHttpRequest(endpoint, method, body);
            //HttpResponse response = SM_RESTCallout.makeCallout(request);
            HttpRequest request = SM_WSHelper.buildHttpRequestFromWSDef('ACCT_Overdue_Balance', params);
            HttpResponse response = (new http()).send(request);
            System.debug('request--->' + request);
            System.debug('response--->' + response);
            if (response.getStatusCode() == 200 || response.getStatusCode() == 400) {
                Map<String, String> result =
                    (
                        Map<String, String>)JSON.deserialize(response.getBody(),
                        Map<String, String>.class
                    );
                System.debug('result--->' + result);
                System.debug('result--->' + result.get('account Balance').remove('$'));
                String strBalance = result.get('account Balance').remove('$');
                strBalance = strBalance.replaceAll(',', '');
                listAccounts[0].Account_Balance__c = Decimal.valueOf(strBalance);
                System.debug('listAccounts--->' + listAccounts);
            }
        }
        Catch(Exception e) {
            // exception comes here
            System.debug('ERROR ==>' + e.getMessage() + '\n\n' + e.getStackTraceString());
        }
        return listAccounts;
    }

    public static List<Account> fetchInvoices(List<Account> listAccounts) {
        String countryCode = 'NZ';
        if (String.valueOf(listAccounts[0].RecordType.Name).startsWith('AU')) {
            countryCode = 'AU';
        }
        
        Map<String,String> params = new Map<String, String>();
        params.put('{{COUNTRY}}', countryCode);
        params.put('{{ACCT_NBR}}', listAccounts[0].Power_Pass_Account_Number__c);
        
        System.debug('*** fetchInvoices ***');
        /*
        String endpoint = 'callout:'
                            + System.Label.BN_Named_Credential
                            + '/commercial-customer-services/api/v1/'
                            + countryCode
                            + '/customer/'
                            + listAccounts[0].Power_Pass_Account_Number__c
                            + '/get_overdue_invoices';
        String method = 'GET';
		*/

        //String body = '';
        try {
            //HttpRequest request = SM_RESTCallout.createHttpRequest(endpoint, method, body);
            //HttpResponse response = SM_RESTCallout.makeCallout(request);
            HttpRequest request = SM_WSHelper.buildHttpRequestFromWSDef('ACCT_Overdue_Invoices', params);
            HttpResponse response = (new http()).send(request);
            System.debug('request--->' + request);
            System.debug('response--->' + response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 400) {
                listAccounts[0].Account_Balance_JSON__c =response.getBody();
                System.debug('listAccounts[0].Account_Balance_JSON__c---->' + listAccounts[0].Account_Balance_JSON__c);
            }
        }
        Catch(Exception e) {
            // exception comes here
            System.debug('ERROR ==>' + e.getMessage() + '\n\n' + e.getStackTraceString());
        }
        return listAccounts;
    }

    public static long getRefreshTimeDiff(Datetime lastRefreshOn) {
        Long currentTime = DateTime.now().getTime();
        Long lastRefreshOnTime = lastRefreshOn.getTime();
        Long milliseconds = currentTime - lastRefreshOnTime;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        return minutes;
    }
}