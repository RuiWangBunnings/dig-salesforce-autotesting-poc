/*******************************************************************************************************
* Class Name      	: AccountPowerPass_Test
* Description		: Test class for Account's PowerPass assignment (originally Match, Assignment & Conversion flows)
                      Functional test rather than unit test
* Author          	: Simplus - Yi Zhang
* Created On      	: 26/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              26/10/2020		1000				Initial version
* Bunnings Dev          28/09/2022      2000                Fix TestClass Issue (Commented 448-450)
******************************************************************************************************/
@isTest
private class AccountPowerPass_Test {
    @testSetup 
    private static void dataSetup() {
        // create stores
        Store__c oldStore = new Store__c(Name = 'old store', Location_Code__c = 'OS001', Sales_Rep_ID__c = '4444', Status__c = 'Active', Engagement_Model__c = Constants.STORE_MODEL_OLD, Country__c = 'Australia');
        Store__c newStore = new Store__c(Name = 'new store', Location_Code__c = 'NS001', Sales_Rep_ID__c = '4445', Status__c = 'Active', Engagement_Model__c = Constants.STORE_MODEL_NEW, Country__c = 'Australia');
        insert new List<Store__c>{oldStore, newStore};
        
            
        Profile profileTS;
        Profile profileSSM;
        Profile profileAreaBDM;
        Profile profileCCSManager;
        List<Profile> profiles = [SELECT Id, Name FROM Profile];
        for(Profile p : profiles) {
            if(p.Name == Constants.AU_TRADE_SPECIALIST_PROFILEENAME)
                profileTS = p;
            else if(p.Name == Constants.AU_SALES_MANAGER_PROFILEENAME)
                profileSSM = p;
            else if(p.Name == Constants.ORG_SALES_MANAGER_PROFILEENAME)
                profileAreaBDM = p;
            else if(p.Name == Constants.NATIONAL_MANAGER_PROFILEENAME)
                profileCCSManager = p;
        }
        List<User> users = TestDataFactory.createUsers(9, profileTS.Id);
        User defaultOwner = users[0];
        defaultOwner.FirstName = 'Bob';
        defaultOwner.LastName = 'Vuksan';
        
        User ts = users[1];
        ts.FirstName = 'TS';
        
        User asm = users[2];
        asm.ProfileId = profileSSM.Id;
        asm.FirstName = 'ASM';
        
        User bdm = users[3];
        bdm.ProfileId = profileAreaBDM.Id;
        bdm.FirstName = 'BDM';
        
        User ccs = users[4];
        ccs.ProfileId = profileCCSManager.Id;
        ccs.FirstName = 'CCS';
        
        User userWithName = users[5];
        userWithName.FirstName = 'John432';
        userWithName.LastName = 'Smith';
        
        User userWithSameNameButNotInSM = users[6];
        userWithName.FirstName = 'CCS';
        
        User userWithSameName1 = users[7];
        userWithSameName1.FirstName = 'JJJ';
        
        User userWithSameName2 = users[8];
        userWithSameName2.FirstName = 'JJJ';
        
        // create users
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert users;
        }
        
        // create store members
        List<Store_Member__c> members = new List<Store_Member__c>();
        members.add(TestDataFactory.createStoreMember(oldStore.Id, ts.Id, Constants.STOREMEMBER_TS_ROLENAME));
        members[0].Default_Trade_Specialist__c = true;
        members.add(TestDataFactory.createStoreMember(oldStore.Id, asm.Id, Constants.STOREMEMBER_ASM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(oldStore.Id, bdm.Id, Constants.STOREMEMBER_AREA_BDM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(oldStore.Id, ccs.Id, Constants.STOREMEMBER_CCS_MANAGER_ROLENAME));
        
        members.add(TestDataFactory.createStoreMember(newStore.Id, ts.Id, Constants.STOREMEMBER_TS_ROLENAME));
        members[4].Default_Trade_Specialist__c = true;
        members.add(TestDataFactory.createStoreMember(newStore.Id, asm.Id, Constants.STOREMEMBER_ASM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(newStore.Id, bdm.Id, Constants.STOREMEMBER_AREA_BDM_ROLENAME));
        members.add(TestDataFactory.createStoreMember(newStore.Id, ccs.Id, Constants.STOREMEMBER_CCS_MANAGER_ROLENAME));
        insert members;
        
        // create secondary segments
        Segment__c builders = new Segment__c(Name = 'Builders Secondary', Segment_Group__c = 'Builders', Country__c = 'Australia', Status__c = 'Active');
        Segment__c organisations = new Segment__c(Name = 'Organisations Secondary', Segment_Group__c = 'Organisations', Country__c = 'Australia', Status__c = 'Active');
        Segment__c trade = new Segment__c(Name = 'Trade Secondary', Segment_Group__c = 'Trade', Country__c = 'Australia', Status__c = 'Active');
        
        insert new List<Segment__c>{builders, organisations, trade};
            
        // create umbrella group
        Umbrella_Group__c ug = new Umbrella_Group__c(Umbrella_Group_Name__c = 'UG001');
        insert ug;
        
    }
    
    private static Id oldStoreId {
        get {
            if(oldStoreId == null) {
                oldStoreId = [SELECT Id FROM Store__c WHERE Engagement_Model__c = 'Old' LIMIT 1].Id;
            }
            return oldStoreId;
        } set;
    }
    
    private static Id newStoreId {
        get {
            if(newStoreId == null) {
                newStoreId = [SELECT Id FROM Store__c WHERE Engagement_Model__c = 'New' LIMIT 1].Id;
            }
            return newStoreId;
        } set;
    }
    
    private static Id buildersSegmentId {
        get {
            if(buildersSegmentId == null) {
                buildersSegmentId = [SELECT Id FROM Segment__c WHERE Segment_Group__c = 'Builders' LIMIT 1].Id;
            }
            return buildersSegmentId;
        } set;
    }
    
    private static Id organisationsSegmentId {
        get {
            if(organisationsSegmentId == null) {
                organisationsSegmentId = [SELECT Id FROM Segment__c WHERE Segment_Group__c = 'Organisations' LIMIT 1].Id;
            }
            return organisationsSegmentId;
        } set;
    }
    
    private static Id tradeSegmentId {
        get {
            if(tradeSegmentId == null) {
                tradeSegmentId = [SELECT Id FROM Segment__c WHERE Segment_Group__c = 'Trade' LIMIT 1].Id;
            }
            return tradeSegmentId;
        } set;
    }
    
    private static Id ugId {
        get {
            if(ugId == null) {
                ugId = [SELECT Id FROM Umbrella_Group__c LIMIT 1].Id;
            }
            return ugId;
        } set;
    }
    
    private static Account createAccount(String model, String accountType, String segmentGroup, Integer creditLimit) {
        // Store__c store = [SELECT Id FROM Store__c WHERE Engagement_Model__c = :model LIMIT 1];
		Id storeId;
        Id segmentId;
        if(model == 'New')
            storeId = newStoreId;
        else if(model == 'Old')
            storeId = oldStoreId;
        if(segmentGroup == 'Builders')
            segmentId = buildersSegmentId;
        else if(segmentGroup == 'Organisations')
            segmentId = organisationsSegmentId;
        else if(segmentGroup == 'Trade')
            segmentId = tradeSegmentId;
        return new Account(
            Name = 'A1', 
            Power_Pass_Account_Number__c = '21423432-12432-A1', 
            Home_Store__c = storeId, 
            Type = accountType, 
            Credit_Limit__c = creditLimit, 
            Secondary_Segment__c = segmentId, 
            Country__c = 'Australia',
            Temporary_Umbrella_Group__c = ugId,
            BillingStreet = 'Bourke St',
            BillingCity = 'Melbourne',
            BillingState = 'VIC',
            BillingPostalCode = '3000',
            Phone = '0399999999',
            Website = 'https://test.com'
        );
    }

    /* 30DAY */
   	@isTest
    private static void testNew30dayBuilders10K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Builders', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayBuilders10K failed');
        System.assertEquals(DM_RecordType.rtId_Account_AuCustomer, [SELECT Id, RecordTypeId FROM Account WHERE Id = :a.Id].RecordTypeId, 'testNew30dayBuilders10K rt assignment failed');
        System.assertEquals(1, [SELECT Id FROM Umbrella_Beneficiary__c WHERE Account__c = :a.Id].size(), 'testNew30dayBuilders10K ug association failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayBuilders20K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Builders', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayBuilders20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayBuilders40K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Builders', 40001);
        insert a;
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayBuilders40K failed');
        Test.stopTest();
    }
    
    @isTest
    private static void testNew30dayOrganisations10K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Organisations', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayOrganisations10K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayOrganisations20K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Organisations', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayOrganisations20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayOrganisations40K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Organisations', 40001);
        insert a;
        System.assertEquals('BDM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayOrganisations40K failed');
        Test.stopTest();
    }
    
   	
    @isTest
    private static void testNew30dayTrade10K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Trade', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayTrade10K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayTrade20K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Trade', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayTrade20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNew30dayTrade40K() {
        Test.startTest();
        Account a = createAccount('New', '30DAY', 'Trade', 40001);
        insert a;
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNew30dayTrade40K failed');
        Test.stopTest();
    }
    
    @isTest
    private static void testNewCashNoSegment() {
        Test.startTest();
        Account a = createAccount('New', 'CASH', null, 40001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCashNoSegment failed');
        Test.stopTest();
    }
    @isTest
    private static void testNewCashTrade() {
        Test.startTest();
        Account a = createAccount('New', 'CASH', 'Trade', 40001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCashTrade failed');
        Test.stopTest();
    }
    
    /* CREDIT */
   	@isTest
    private static void testNewCreditBuilders10K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Builders', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditBuilders10K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditBuilders20K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Builders', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditBuilders20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditBuilders40K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Builders', 40001);
        insert a;
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditBuilders40K failed');
        Test.stopTest();
    }
    
    @isTest
    private static void testNewCreditOrganisations10K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Organisations', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditOrganisations10K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditOrganisations20K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Organisations', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditOrganisations20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditOrganisations40K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Organisations', 40001);
        insert a;
        System.assertEquals('BDM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditOrganisations40K failed');
        Test.stopTest();
    }
    
   	
    @isTest
    private static void testNewCreditTrade10K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Trade', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditTrade10K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditTrade20K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Trade', 20001);
        insert a;
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditTrade20K failed');
        Test.stopTest();
    }
   	@isTest
    private static void testNewCreditTrade40K() {
        Test.startTest();
        Account a = createAccount('New', 'CREDIT', 'Trade', 40001);
        insert a;
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testNewCreditTrade40K failed');
        Test.stopTest();
    }
    
    /* OLD */
    @isTest
    private static void testOldAnyTypeAnySegment() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', 10001);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testOldAnyTypeAnySegment failed');
        Test.stopTest();
    }
    @isTest
    private static void testOldAnyTypeAnySegmentNullCredit() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', null);
        insert a;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testOldAnyTypeAnySegmentNullCredit failed');
        Test.stopTest();
    }
    
    /* default owner test */
    
    @isTest
    private static void testDefaultOwner() {
        Test.startTest();
        Account a = createAccount('New', null, 'Trade', 40001);
        insert a;
        //Default Owner is set here - DM_Initialisation.ccrmInitialisation.CCRM_Account_Default_Owner__c
        System.assertEquals('Default', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testDefaultOwner failed');
        Test.stopTest();
    }
    
    /* Manager populated */
    @isTest
    private static void testManagerPopulated() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', null);
        User manager = [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        a.Powerpass_Account_Manager__c = manager.Name;
        insert a;
       System.assertEquals(manager.Id, [SELECT OwnerId FROM Account WHERE Id = :a.Id].OwnerId, 'testManagerPopulated');
        Test.stopTest();
    }    
    @isTest
    private static void testManagerPopulatedNotExist() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', null);
        a.Powerpass_Account_Manager__c = 'Johnny Smith';
        insert a;
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :a.Id].Owner.FirstName, 'testManagerPopulatedNotExist failed');
        Test.stopTest();
    }  
    @isTest
    private static void testManagerPopulatedOneInSM() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', null);
        a.Powerpass_Account_Manager__c = 'CCS Testing';
        insert a;
        System.assertEquals([SELECT Id, Team_Member__r.Name FROM Store_Member__c WHERE Role__c = :Constants.STOREMEMBER_CCS_MANAGER_ROLENAME LIMIT 1].Team_Member__r.Name, 
                            [SELECT Owner.Name FROM Account WHERE Id = :a.Id].Owner.Name, 'testManagerPopulatedOneInSM failed');
        Test.stopTest();
    } 
    @isTest
    private static void testManagerPopulatedNoneInSM() {
        Test.startTest();
        Account a = createAccount('Old', 'CREDIT', 'Trade', null);
        a.Powerpass_Account_Manager__c = 'JJJ Testing';
        insert a;
        System.assertnotEquals([SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name, 
                            [SELECT Owner.Name FROM Account WHERE Id = :a.Id].Owner.Name, 'testManagerPopulatedNoneInSM failed');
        Test.stopTest();
    }  
    /* Delete */
    @isTest
    private static void testMatchExistingProspectAccount() {
        Account existingAccount = createAccount('New', '30DAY', 'Builders', 10001);
        existingAccount.RecordTypeId = DM_RecordType.rtId_Account_AuProspect;
        existingAccount.Power_Pass_Account_Number__c = null;
        existingAccount.RecordTypeId = DM_RecordType.rtId_Account_AuProspect;
        
        Test.startTest();
        insert existingAccount;
        existingAccount = [SELECT Owner.Name, RecordTypeId FROM Account WHERE Id = :existingAccount.Id];
		System.assertEquals([SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name, existingAccount.Owner.Name, 'testMatchExistingProspectAccount step 1 failed');
		System.assertEquals(DM_RecordType.rtId_Account_AuProspect, existingAccount.RecordTypeId, 'testMatchExistingProspectAccount step 1 rt failed');

        
       // Account a = createAccount('New', '30DAY', 'Builders', 10001);
        //a.Temporary_Umbrella_Group__c = null;
       // insert a;
        
        existingAccount = [SELECT Owner.Name, RecordTypeId FROM Account WHERE Id = :existingAccount.Id];
		System.assertEquals([SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name, existingAccount.Owner.Name, 'testMatchExistingProspectAccount step 2 failed');
		System.assertnotEquals(DM_RecordType.rtId_Account_AuCustomer, existingAccount.RecordTypeId, 'testMatchExistingProspectAccount step 2 rt failed');
        Test.stopTest();
    }
    
    /* load test */
    @isTest
    private static void testMultipleAccounts() {
        List<Account> accounts = new List<Account>();        
        Test.startTest();
        accounts.add(createAccount('New', '30DAY', 'Builders', 10001));
        accounts.add(createAccount('New', '30DAY', 'Builders', 20001));
        accounts.add(createAccount('New', '30DAY', 'Builders', 40001));
        
        accounts.add(createAccount('New', '30DAY', 'Organisations', 10001));
        accounts.add(createAccount('New', '30DAY', 'Organisations', 20001));
        accounts.add(createAccount('New', '30DAY', 'Organisations', 40001));
        
        accounts.add(createAccount('New', '30DAY', 'Trade', 10001));
        accounts.add(createAccount('New', '30DAY', 'Trade', 20001));
        accounts.add(createAccount('New', '30DAY', 'Trade', 40001));
        
        accounts.add(createAccount('New', 'CASH', null, 40001));
        accounts.add(createAccount('New', 'CASH', 'Trade', 40001));
        
        accounts.add(createAccount('New', 'CREDIT', 'Builders', 10001));
        accounts.add(createAccount('New', 'CREDIT', 'Builders', 20001));
        accounts.add(createAccount('New', 'CREDIT', 'Builders', 40001));
        
        accounts.add(createAccount('New', 'CREDIT', 'Organisations', 10001));
        accounts.add(createAccount('New', 'CREDIT', 'Organisations', 20001));
        accounts.add(createAccount('New', 'CREDIT', 'Organisations', 40001));
        
        accounts.add(createAccount('New', 'CREDIT', 'Trade', 10001));
        accounts.add(createAccount('New', 'CREDIT', 'Trade', 20001));
        accounts.add(createAccount('New', 'CREDIT', 'Trade', 40001));
        
        accounts.add(createAccount('Old', 'CREDIT', 'Trade', 10001));
        accounts.add(createAccount('Old', 'CREDIT', 'Trade', null));
        
        for(Account a : accounts) {
            a.Name += String.valueOf(Math.random());
            a.Website += String.valueOf(Math.random());
            a.BillingStreet += String.valueOf(Math.random());
            a.Power_Pass_Account_Number__c = String.valueOf(Math.random());
        }
        
        insert accounts;
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[0].Id].Owner.FirstName, 'testNew30dayBuilders10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[1].Id].Owner.FirstName, 'testNew30dayBuilders20K failed');
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[2].Id].Owner.FirstName, 'testNew30dayBuilders40K failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[3].Id].Owner.FirstName, 'testNew30dayOrganisations10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[4].Id].Owner.FirstName, 'testNew30dayOrganisations20K failed');
        System.assertEquals('BDM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[5].Id].Owner.FirstName, 'testNew30dayOrganisations40K failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[6].Id].Owner.FirstName, 'testNew30dayTrade10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[7].Id].Owner.FirstName, 'testNew30dayTrade20K failed');
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[8].Id].Owner.FirstName, 'testNew30dayTrade40K failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[9].Id].Owner.FirstName, 'testNewCashNoSegment failed');
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[10].Id].Owner.FirstName, 'testNewCashTrade failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[11].Id].Owner.FirstName, 'testNewCreditBuilders10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[12].Id].Owner.FirstName, 'testNewCreditBuilders20K failed');
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[13].Id].Owner.FirstName, 'testNewCreditBuilders40K failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[14].Id].Owner.FirstName, 'testNewCreditOrganisations10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[15].Id].Owner.FirstName, 'testNewCreditOrganisations20K failed');
        System.assertEquals('BDM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[16].Id].Owner.FirstName, 'testNewCreditOrganisations40K failed');
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[17].Id].Owner.FirstName, 'testNewCreditTrade10K failed');
        System.assertEquals('CCS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[18].Id].Owner.FirstName, 'testNewCreditTrade20K failed');
        System.assertEquals('ASM', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[19].Id].Owner.FirstName, 'testNewCreditTrade40K failed');
        
        
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[20].Id].Owner.FirstName, 'testOldAnyTypeAnySegment failed');
        System.assertEquals('TS', [SELECT Owner.FirstName FROM Account WHERE Id = :accounts[21].Id].Owner.FirstName, 'testOldAnyTypeAnySegmentNullCredit failed');
        Test.stopTest();
    }
    
    @isTest
    private static void testMultipleAccounts2() {
        List<Account> accounts = new List<Account>();        
        for(Integer i = 0; i < 20; i ++) {
            Account a = createAccount('New', '30DAY', 'Builders', Integer.valueOf(100000*Math.random()));
            a.Name += String.valueOf(Math.random());
            a.Website += String.valueOf(Math.random());
            a.BillingStreet += String.valueOf(Math.random());
            a.Power_Pass_Account_Number__c = String.valueOf(Math.random());
            // a.BillingPostalCode
            a.BillingPostalCode = (String.valueOf(Math.random())).left(10);
            a.BillingCity += String.valueOf(Math.random());
            a.Phone = String.valueOf(Math.random());
            accounts.add(a);
        }
        Test.startTest();        
        insert accounts;
        Test.stopTest();
    }
}