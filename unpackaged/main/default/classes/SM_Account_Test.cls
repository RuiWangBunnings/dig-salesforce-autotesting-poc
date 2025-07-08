/*******************************************************************************************************
* Class Name      	: SM_Account_Test
* @description		: Test class for SM_Account
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_Account_Test {

    /**
     * @description makeData - Test data creation method
     * @author Juan M. Cutrera
     */
    @TestSetup
    static void makeData(){
        List<Account> accountList = TestDataFactory.createAccounts(2);
        accountList[0].Scheduled_Engagement_Call__c = Date.today();
        accountList[1].Scheduled_Engagement_Call__c = Date.today().addDays(-1);
        insert accountList;
    }

    /**
     * @description testMapAssignedStore - Test method for mapAssignedStore
     * @author Juan M. Cutrera
     */
    @isTest
    static void testMapAssignedStore() {
        Store__c testStore;
        Account acc;
        Map<Id, Id> result = new Map<Id,Id>();
        Map<Id, Id> acctIDOwnerIDMap = new Map<Id, Id>();
        // Step 1: Create a User with a Location_Code__c using TestDataFactory
        Profile profAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUser = TestDataFactory.createUsers(1, profAdmin.Id).get(0);
            testUser.Location_Code__c = 'LOC123';
            insert testUser;
        }
        Test.startTest();
        System.runAs(testUser){
            // Step 2: Create a Store with a matching Location_Code__c
             testStore = TestDataFactory.createStores(1).get(0);
            testStore.Location_Code__c = 'LOC123';
            insert testStore;
    
            // Step 3: Create an Account with the test User as the Owner
             acc = TestDataFactory.createAccounts(1).get(0);
            insert acc;
            acc.OwnerId = testUser.Id;
            update acc;
        }
        test.stopTest();


        // Step 4: Prepare input data
        List<Account> assignedStoreAcctList = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :acc.Id];
        acctIDOwnerIDMap.put(acc.Id, acc.OwnerId);

        // Step 5: Call the method
        System.runAs(testUser){
            result = SM_Account.mapAssignedStore(assignedStoreAcctList, acctIDOwnerIDMap);
        }

        // Step 6: Verify the results
         Assert.areEqual(1, result.size(), 'The result map should contain one entry.');
         Assert.areEqual(testStore.Id, result.get(acc.Id), 'The Assigned_Store__c should match the test Store ID.');
    }

    /**
     * @description testUpdateScheduledEngagementCall - Test method for updateScheduledEngagementCall
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testUpdateScheduledEngagementCall(){
        List<Account> accountList = [SELECT Id, Name,Scheduled_Engagement_Call__c FROM Account];
        //Update the accountList with the Scheduled_Engagement_Call__c field
        // to the next day
        Map<Id,Account> accountMap = new Map<Id,Account>();
        for (Integer i = 0; i < accountList.size(); i++) {
            Account acc = accountList[i];
            //keep the first account with the same date but update the rest
            if (i != 0) {
                //make the Date today - 1 so that it updates 
                acc.Scheduled_Engagement_Call__c = Date.today().addDays(1);
            }
            accountMap.put(acc.Id, acc);
        }
        SM_Account.updateScheduledEngagementCall(accountMap);
        // Query the updated accounts
        List<Account> updatedAccounts = [SELECT Id, Name, Scheduled_Engagement_Call__c FROM Account WHERE Id IN :accountMap.keySet()];
        for(Account acc: updatedAccounts){
            if(acc.Name == 'TestCompany0'){
                Assert.areEqual(Date.Today(), acc.Scheduled_Engagement_Call__c, 'Account should not be updated');
            }else if(acc.Name == 'TestCompany1'){
                Assert.areEqual(Date.Today().addDays(1), acc.Scheduled_Engagement_Call__c, 'Account should be updated');
            }
        }
    }


    /**
     * @description testUpdateAccountList - Test method for updateAccountList
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testUpdateAccountList(){
        List<Account> accountList = [SELECT Id, Name FROM Account];
        accountList.get(0).Name = 'Test Account'; //update Name of firstAccount
        String accountListJson = JSON.serialize(accountList);
        Test.startTest();
            SM_Account.updateAccountList(accountListJson);  
        Test.stopTest();
        // Query the updated accounts
        Account updatedAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        // Assert: Verify the result
        Assert.isNotNull(updatedAccount, 'Updated Account should not be null');
    }

    /**
     * @description testUpdateAccountListException - Test method for updateAccountList
     * @author Juan M. Cutrera
     */
    @isTest
    static void testUpdateAccountListException() {
        // Step 1: Create an account with invalid data (e.g., missing required fields)
        List<Account> invalidAccounts = new List<Account>();
        invalidAccounts.add(new Account( Name = null)); // Invalid Id and missing Name

        // Step 2: Serialize the invalid accounts to JSON
        String accountListJson = JSON.serialize(invalidAccounts);

        // Step 3: Call the future method
        Test.startTest();
            SM_Account.updateAccountList(accountListJson); // This should fail and trigger the exception
        Test.stopTest();

        List<ApplicationLog__c>  appList = [SELECT Id FROM ApplicationLog__c ];
        Assert.isNotNull(appList, 'ApplicationLog__c should not be null');
        Assert.isTrue(appList.size() > 0, 'ApplicationLog__c should have at least one record');
    }

    /**
    * @description  Test method for createAccount
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testUpsertAccountList() {

        String newName = 'Test Account';
        List<Account> accountList = [SELECT Id, Name FROM Account];
        accountList.get(0).Name = newName;
        Test.startTest();
        // Act: Call the method
        SM_Account.upsertAccountList(accountList);
        Test.stopTest();
        Account insertedAccount = [SELECT Id FROM Account WHERE Name = :newName LIMIT 1];
        // Assert: Verify the result
        Assert.isNotNull(insertedAccount.Id, 'Account ID should not be null');
    }

    /**
    * @description  Test method for createAccount
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testUpsertAccountListException() {


        List<Account> invalidAccounts = new List<Account>();
        invalidAccounts.add(new Account( Name = null));

        // Act: Call the method
        Test.startTest();
        try {
            SM_Account.upsertAccountList(invalidAccounts);
            Assert.fail('Expected exception was not thrown');
        } catch (Exception e) {
            Assert.isTrue(true);
        }
        Test.stopTest();

    }

    /**
     * @description testBuildNewAccount 
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testBuildNewAccount(){
        Account acc1 = SM_Account.buildNewAccount(TestDataFactory.createEntity());
        Consent_ConsentManagerPayload.Entity modifiedEntity = TestDataFactory.createEntity();
        modifiedEntity.getPerson().firstName = null;
        Account acc2 = SM_Account.buildNewAccount(modifiedEntity);

        Assert.isNotNull(acc1, 'Account should not be null');
        Assert.isNotNull(acc2, 'Account should not be null');
        Assert.areEqual(acc1.firstName, 'TestFirstName', 'FirstName should be TestFirstName');
        Assert.areEqual(acc2.firstName, null, 'FirstName should be null');
    }
    
}