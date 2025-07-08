/*******************************************************************************************************
* Class Name      	: SM_Case_Test
* Description		: Test class for SM_Case
* Author          	: Simplus - Yi Zhang
* Created On      	: 01/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              01/10/2020		1000				Initial version
* MS Simplus            15/10/2020		2000				Added to Improve Test Coverage on Case Insert for Case Trigger
* MS Simplus            21/06/2021      3000                Added to cover 
* Jasper R. Galapon		20/06/2023		2000				BUNDIG-21197 - New/Renewal Contracts - No Case Created When A1 Rejects
******************************************************************************************************/
@isTest
private class SM_Case_Test {
    // BUNDIG-21197
    @isTest
    private static void testCreateCase() {
        Test.startTest();
            try {
                SM_Case.createCase(null, '');
            } catch(Exception e) {}
            
            Boolean result = SM_Case.createCase(new Contract__c(), 'Test comment');
            System.assertEquals(true, result, 'case should have been created successfully');
        Test.stopTest();
    }
    
    /**
    * @description Added to Improve Test Coverage on Case Insert for Case Trigger
    * @author MS Simplus | 15/06/2021 
    **/
    @isTest
    private static void testCaseInsert() {
        
        List<Account> accounts = TestDataFactory.createAccounts(2);
        accounts[0].Contract_Group__c = accounts[1].Id;
        insert accounts;
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Constants.AU_CONTRACT_CASE).getRecordTypeId();
        List<Case> newList = new List<Case>();
        for(Integer i=0; i<2; i++ ){
            Case caseRec = new Case();
            caseRec.RecordTypeId = caseRecordTypeId;
			caseRec.AccountId = accounts[i].Id;       
            caseRec.Type = 'Contract Request';
            //caseRec.Subtype__c = 'Contract Review - Changes Required';
            caseRec.Description = 'Test comment'+i;
            caseRec.Run_Case_Assignment_via_Apex__c = true;
            caseRec.Contract_States__c = 'NATIONAL';
            caseRec.Cost_Zones__c = 'ALL';
            newList.add(caseRec);
        }
        
        Test.startTest();
        	insert newList;        	
        Test.stopTest();
    }

    /**
    * @description  - added to cover CaseTriggerHandler.checkContractGroupField method
    * @author Simplus MS | 21/06/2021 
    **/
    @isTest
    static void test_checkContractGroupField() {
        RecordType auCustomerRecType = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE Name = 'AU Customer' 
            AND sObjectType='Account' LIMIT 1];

        insert new List<Account> {
            new Account(
            Name = 'test Account', RecordTypeId = auCustomerRecType.Id
            ),
            new Account(
            Name = 'test Account Master', RecordTypeId = auCustomerRecType.Id
            )
        };
        
        List<Account> accList = [SELECT Id, Name, Contract_Group__c FROM Account];
        Account masterAcc = new Account();
        Account nonMasterAcc = new Account();
        for(Account ac : accList) {
            if(ac.Name.contains('Master')) masterAcc = ac;
            else nonMasterAcc = ac; 
        }
        nonMasterAcc.Contract_Group__c = masterAcc.Id;
        update nonMasterAcc;

        Account acc = [SELECT Id FROM Account Where Name='test Account' LIMIT 1];
        List<RecordType> rts = [SELECT Id, DeveloperName from RecordType WHERE SObjectType='Case' AND DeveloperName IN ('NZ_Contract_Requests','Quote_Request')];
        Id rTAUContractReqId;
        Id rTnonContactRequestId;

        for(RecordType rt: rts) {
            if(rt.DeveloperName == 'NZ_Contract_Requests') rTAUContractReqId = rt.Id;
            else rTnonContactRequestId = rt.Id;
        }
        Test.startTest();
        try{ insert new Case(AccountId = acc.Id, RecordTypeId = rTAUContractReqId, Contract_States__c = 'NATIONAL', Cost_Zones__c = 'ALL' ); }
        catch(Exception e) {}

        insert new Case(AccountId = acc.Id, RecordTypeId = rTnonContactRequestId, Run_Case_Assignment_via_Apex__c = true, Contract_States__c = 'NATIONAL', Cost_Zones__c = 'ALL');

        Test.stopTest();
    }
}