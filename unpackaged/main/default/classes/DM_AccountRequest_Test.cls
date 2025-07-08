/*******************************************************************************************************
* Class Name        : DM_AccountRequest_Test
* Description       : Data Layer - Selector for Sobject Account Request
* Author            : Bunnings Developer
* Created On        : 30/10/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          30/10/2024      1001                Initial version
* -----------------------------------------------------------------------------------------------------*/
@IsTest
public class DM_AccountRequest_Test {
    /**
    *  Method name  :  dataSetup
    *  Description  :  Setup data for test class
    *  Author       :  Sowjanya
    **/
    @testSetup static void dataSetup() {

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
        list<User> users = TestDataFactory.createUsers(3, p.Id);
                User u1 = users[1];
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
        
        Account_Request__c ar = TestDataFactory.createSingleAccountRequest(u1.id,'456465',thisUser.id,'acc transfer');
        insert ar;
    
    }
    
     /**
    *  Method name  :  testgetPowerPassNumbers
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetPowerPassNumbers() {
        List<Account_Request__c> arList = [Select PowerPass_Account_Number__c,id from Account_Request__c];
        Test.startTest();
        Set<String> powerPassSet = DM_AccountRequest.getPowerPassNumbers(arList);
        Test.stopTest();
        system.assertEquals(1,powerPassSet.size(),'retreived');
        
    }
/**
    *  Method name  :  testgetpowerpassNewOwnerMap
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetpowerpassNewOwnerMap() {
        List<Account_Request__c> arList = [Select PowerPass_Account_Number__c,id,New_Owner__c from Account_Request__c];
        Test.startTest();
        Map<String,String> newOwnerMap = DM_AccountRequest.getpowerpassNewOwnerMap(arList);
        Test.stopTest();
        system.assertEquals(1,newOwnerMap.size(),'New Owner Map');
        
    }
    
    /**
    *  Method name  :  testgetAccountTransferRequests
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetAccountTransferRequests() {
        List<Account_Request__c> arList = [Select PowerPass_Account_Number__c,id,New_Owner__c from Account_Request__c];
        List<id> idList = new List<id>();
        idlist.add(arList[0].id);
        Test.startTest();
        List<Account_Request__c> aList  = DM_AccountRequest.getAccountTransferRequests(idlist);
        Test.stopTest();
        system.assertEquals(1,aList.size(),'New Transfer List');
        
    }
    /**
    *  Method name  :  testgetAccountTransferRequestsByAccid
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetAccountTransferRequestsByAccid() {
        List<Account> arList = [Select id from Account];
        Set<id> idList = new Set<id>();
        idlist.add(arList[0].id);
        Test.startTest();
        List<Account_Request__c> aList  = DM_AccountRequest.getAccountTransferRequestsByAccid(idlist);
        Test.stopTest();
        system.assertEquals(1,aList.size(),'New Transfer List');
        
    }
    
    /**
    *  Method name  :  testgetBulkAccountTransferRequests
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetBulkAccountTransferRequests() {
        List<Account> arList = [Select id from Account];
        List<User> uList = [Select id from User];
        String accountid =arList[0].id;
        String userid = uList[0].id;
        Test.startTest();
        List<Account_Request__c> aList  = DM_AccountRequest.getBulkAccountTransferRequests(accountid,userid);
        Test.stopTest();
        system.assertEquals(0,aList.size(),'Bulk Transfer List');
        
    }
    
    /**
    *  Method name  :  testgetPendingSingleAccountTransferRequest
    *  Description  :  
    *  Author       :  Bunnigs Dev
    **/
    @IsTest
    static void testgetPendingSingleAccountTransferRequest() {
        List<Account> arList = [Select id from Account];
        List<User> uList = [Select id from User];
        String accountid =arList[0].id;
        String userid = uList[0].id;
        Test.startTest();
        List<Account_Request__c> aList  = DM_AccountRequest.getPendingSingleAccountTransferRequest(accountid);
        Test.stopTest();
        system.assertEquals(1,aList.size(),'Single Account Transfer List');
        
    }
}