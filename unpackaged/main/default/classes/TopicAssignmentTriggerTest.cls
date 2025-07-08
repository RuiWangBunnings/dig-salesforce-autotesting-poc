/*******************************************************************************************************
* Class Name      	: TopicAssignmentTriggerTest
* Description		: Topic Assignment trigger test
* Author          	: Simplus - Francis Benzon
* Created On      	: 24/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        24/06/2020		1000				Initial version
******************************************************************************************************/
@IsTest
private class TopicAssignmentTriggerTest {
    /**
    *  Method name  :  dataSetup
    *  Description  :  Setup data for test class
    *  Author       :  Francis Benzon
    **/
    @testSetup static void dataSetup() {
		//create Umbrella groups
		List<Umbrella_Group__c> ugList = TestDataFactory.createUmbrellaGroups(1);
		insert ugList;
		
		//create Account
		List<Account> acctList = TestDataFactory.createAccounts(1);
		insert acctList;
		
		//create Umbrella Beneficiries
		List<Umbrella_Beneficiary__c> ubList = TestDataFactory.createUmbrellaBeneficiaries(acctList[0].ID, ugList[0].ID, 1);
		insert ubList;
		
		//create Umbrella Beneficiries
		List<Topic> topicList = TestDataFactory.createTopics(1);
        topicList[0].Name = 'Test' + String.valueOf(Math.random());
		insert topicList;
		
		Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.AU_TRADE_SPECIALIST_PROFILEENAME LIMIT 1];
		list<User> users = TestDataFactory.createUsers(2, p.Id);
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
            insert users;
        }
            
        List<Store__c> storeList = TestDataFactory.createStores(1);
        storeList[0].Operations_Region_Code__c = 'NSW';
        insert storeList;

		Operations_Region__c newOR = TestDataFactory.createOperationsRegion(storeList[0].Operations_Region_Code__c, null, null);
		insert newOR;
		
    }

    @IsTest
    static void testBehavior() {
        ID umbrellaGroupID = [SELECT ID FROM Umbrella_Group__c].ID;
		ID recTopicID = [SELECT ID FROM Topic].ID;
		ID orID = [SELECT ID FROM Operations_Region__c].ID;
		List<TopicAssignment> taList = new List<TopicAssignment>();

        Test.startTest();
        
		//create topic for Umbrella Group 
		TopicAssignment ta = new TopicAssignment();
		ta.EntityId = umbrellaGroupID; 
		ta.topicId = recTopicID;

        taList.add(ta);
		
		
		TopicAssignment ta1 = new TopicAssignment();
		ta1.EntityId = orID; 
		ta1.topicId = recTopicID;

        taList.add(ta1);
		
		insert taList;
		System.assert(taList.size() == 2);
		
		delete taList;
		
        Test.stopTest();

    }
}