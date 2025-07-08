/**
 * @author            : Simplus MS
 * @last modified on  : 05-20-2021
 * @last modified by  : Simplus MS
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-20-2021   Simplus MS   Initial Version
**/

@isTest
public class SM_UpdateOwnerOpportunityBatchTest {

    @testSetup
    static void makeData() {
        Profile sysAdProfile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User user1 = new User(
            Alias = 'standt1', Email='testUser1@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Integration User', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = sysAdProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testUser12x@testorg.com', Country__c = 'Australia'
        );
        User user2 = new User(
            Alias = 'standt2', Email='testUser2@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='testUser2', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = sysAdProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testUser22x@testorg.com', Country__c = 'Australia'
        );
        List<User> insertUsers = new List<User>();
        insertUsers.add(user1);
        insertUsers.add(user2);

        insert insertUsers;

    }

    @isTest
    static void testBatchable() {
        insertTestData();

        Opportunity oGOpp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity LIMIT 1];
        Test.startTest();
        SM_UpdateOwnerOpportunityBatch batchClass = new SM_UpdateOwnerOpportunityBatch();
        Id batchId = Database.executeBatch(batchClass);
        Test.stopTest();
    }

    private static void insertTestData() {
        List<String> names = new List<String>{'Integration User', 'testUser2'};
        List<User> userList = [SELECT Id FROM User WHERE Name IN :names];
        system.debug(userList);

        if(userList.size() > 0) {
            Id AUCustRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AU Customer').getRecordTypeId();
            Id stdOpptyRecType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            Id cosQuoteRecType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('COS Quote').getRecordTypeId();
            
            Store__c storeTest = new Store__c(
                Name = 'test Store', Location_Code__c = 'test LocCode'
            );
            Account acc = new Account(
                RecordTypeId = AUCustRecType, Name = 'test Account', OwnerId = userList[1].Id
            );
            insert acc;

            Opportunity oppty = new Opportunity(
                RecordTypeId = stdOpptyRecType, Name = 'test Oppty', StageName = 'New', CloseDate = Date.Today(), Site_Address__c = 'test Site', AccountId = acc.Id, OwnerId = userList[1].Id
            );
            insert oppty;

            acc.OwnerId = userList[0].Id;
            update acc;

			system.debug(acc);
            system.debug(oppty);
                
            //create account and rel opptys
            //oppty should have rel quote and order
            //oppty owner and account owner should be different

            // SELECT Id, OwnerId, Account.OwnerId, 
            //     (SELECT Id, OwnerId, IsSyncing, OpportunityId FROM Quotes), 
            //     (SELECT Id, OwnerId, OpportunityId FROM Orders) 
            // FROM Opportunity
        }
    }
}