/*******************************************************************************************************
* Class Name        : AccountRequestTriggerTest
* Description       : AccountRequest trigger test
* Author            : Sowjanya
* Created On        : 29/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          20/07/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/
@IsTest
private class AccountRequestTriggerTest {
    /**
    *  Method name  :  dataSetup
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @testSetup static void dataSetup() {

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(3, p.Id);
                
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            insert users;
            User usr3 = [SELECT Id FROM User WHERE UserName like 'employee2%'];
            usr3.isActive=false;
            update usr3;
        }
        
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].Power_Pass_Account_Number__c = '456465';
        accounts[1].Power_Pass_Account_Number__c = '56767';
        insert accounts;
    
    }

     /**
    *  Method name  :  test before insert trigger
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeInsert() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee0%'];
        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('456465',usr.id);

        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        
        Test.startTest();
        
        insert accountRequests;
        
        Test.stopTest();

        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Pending Transfer',accReq.Status__c,'Status is updated');
        system.assertEquals('TestCompany0',accReq.Account__r.Name,'Account Name is populated');
    }

     /**
    *  Method name  :  test before insert Bulk trigger
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeInsertBulk() {
    
       List<User> usr = [SELECT Id FROM User WHERE UserName like 'employee%'];
        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('456465',usr[0].id);
        accReqs.put('56767',usr[1].id);
        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        Test.startTest();
        
        insert accountRequests;
        
        Test.stopTest();

        Account_Request__c accReq1 = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Pending Transfer',accReq1.Status__c,'Status is updated');
        system.assertEquals('TestCompany0',accReq1.Account__r.Name,'Account Name is populated');
        Account_Request__c accReq2 = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[1].Id LIMIT 1];
        system.assertEquals('Pending Transfer',accReq2.Status__c,'Status is updated');
        system.assertEquals('TestCompany1',accReq2.Account__r.Name,'Account Name is populated');

}
     /**
    *  Method name  :  test before insert trigger with negative scenario - Acc not exists
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeInsertNegativeAccnotExists() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee0%'];
        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('67676876',usr.id);

        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        
        Test.startTest();
        
        insert accountRequests;
        
        Test.stopTest();

        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Validation Failed',accReq.Status__c,'Status is updated');
       
    }

     /**
    *  Method name  :  test before insert trigger with negative scenario - owner inactive
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeInsertNegativeNewOwnerInactive() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee2%'];

        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('56767',usr.id);

        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        
        Test.startTest();
        
        insert accountRequests;
        
        Test.stopTest();

        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Validation Failed',accReq.Status__c,'Status is updated');
        system.assertEquals('New Owner is Inactive',accReq.Failed_Reason__c,'Failed_Reason__c is updated');
    }

     /**
    *  Method name  :  test before insert trigger with negative scenario - new owner inactive and Acc not exists
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeInsertNegativeNewOwnerInactiveAccNotexists() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee2%'];

        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('6768788',usr.id);

        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        
        Test.startTest();
        
        insert accountRequests;
        
        Test.stopTest();

        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Validation Failed',accReq.Status__c,'Status is updated');
        system.assertEquals('Power Pass Account not found and New Owner is Inactive',accReq.Failed_Reason__c,'Failed_Reason__c is updated');
    }

     /**
    *  Method name  :  test before update trigger 
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeUpdate() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee0%'];
        Map<String,String> accReqs = new Map<String,String>();
        accReqs.put('456465',usr.id);

        List<Account_Request__c> accountRequests = TestDataFactory.createBulkAccountRequests(accReqs);
        insert accountRequests;
        User usr1 = [SELECT Id FROM User WHERE UserName like 'employee1%'];
        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c,New_Owner__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        accReq.New_Owner__c=usr1.id;
        Test.startTest();
        
        update accReq;
        
        Test.stopTest();

        Account_Request__c accReqUpd = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequests[0].Id LIMIT 1];
        system.assertEquals('Pending Transfer',accReqUpd.Status__c,'Status is updated');
        system.assertEquals('TestCompany0',accReqUpd.Account__r.Name,'Account Name is populated');
    }

     /**
    *  Method name  :  test before update trigger - Single Acc transfer
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeUpdateSingleAccountTransferUserInactive() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee0%'];
        User usr3 = [SELECT Id FROM User WHERE UserName like 'employee2%'];
        Account_Request__c accountRequest = TestDataFactory.createSingleAccountRequest(usr.id,'56767',usr3.id,'testsingle');
        insert accountRequest;
        User usr1 = [SELECT Id FROM User WHERE UserName like 'employee1%'];
        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c,New_Owner__c from Account_Request__c WHERE Id =: accountRequest.Id];
        accReq.Transfer_approval_status__c = 'Approved';
        Test.startTest();
        
        update accReq;
        
        Test.stopTest();

        Account_Request__c accReqUpd = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequest.Id];
       // system.assertEquals('Completed',accReqUpd.Status__c,'Status is updated');
        
    }
    
    /**
    *  Method name  :  test before update trigger - Single Acc transfer
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @IsTest
    static void testBeforeUpdateSingleAccountTransfer() {
        User usr = [SELECT Id FROM User WHERE UserName like 'employee0%'];
        User usr1 = [SELECT Id FROM User WHERE UserName like 'employee1%'];
        Account_Request__c accountRequest = TestDataFactory.createSingleAccountRequest(usr.id,'56767',usr1.id,'testsingle');
        insert accountRequest;
        
        Account_Request__c accReq = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c,New_Owner__c from Account_Request__c WHERE Id =: accountRequest.Id];
        accReq.Transfer_approval_status__c = 'Approved';
        Test.startTest();
        
        update accReq;
        
        Test.stopTest();

        Account_Request__c accReqUpd = [Select id,PowerPass_Account_Number__c,Account__r.Name,Status__c,Failed_Reason__c from Account_Request__c WHERE Id =: accountRequest.Id];
       // system.assertEquals('Completed',accReqUpd.Status__c,'Status is updated');
        
    }
}