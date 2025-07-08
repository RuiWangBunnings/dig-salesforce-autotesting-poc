/*******************************************************************************************************
* Class Name      	: UmbrellaBeneficiaryTriggerHandler_Test
* Description		: Test Class for UmbrellaBeneficiaryTriggerHandler
* Author          	: Simplus MS
* Created On      	: 18/01/2022
* Modification Log	: 
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            18/01/2022		1000				Initial version
******************************************************************************************************/
@IsTest
public with sharing class UmbrellaBeneficiaryTriggerHandler_Test {

    @testSetup
    static void testDataSetup(){
        
        //Create Account
        List<Account> accts = TestDataFactory.createAccounts(1);
        insert accts;

        // umbrella group
        List<Umbrella_Group__c> groups = TestDataFactory.createUmbrellaGroups(1);
        insert groups;

        // umbrella beneficiary
        List<Umbrella_Beneficiary__c> beneficiaries = TestDataFactory.createUmbrellaBeneficiaries(accts[0].Id, groups[0].Id, 1);
        insert beneficiaries;


    }

    @isTest 
    static void TestAvoidActiveDuplicateUmbrellaBeneficiaries() {
        
        Id accId = [Select Id From Account Limit 1].Id;
        Id groupId = [Select Id From Umbrella_Group__c Limit 1].Id;

        Test.startTest();
            List<Umbrella_Beneficiary__c> beneficiaries = TestDataFactory.createUmbrellaBeneficiaries(accId, groupId, 1);
            try{
                insert beneficiaries;
            }catch(Exception e){
                System.debug(e.getMessage());
                System.assertEquals(true, e.getMessage().contains(System.Label.Avoid_Duplicate_Umbrella_Beneficiaries), 'Failed to Avoid Duplicate Umbrella Beneficiaries');
            }
        Test.stopTest();
    }

    @isTest 
    static void TestAvoidInactiveDuplicateUmbrellaBeneficiaries() {
        
        Id accId = [Select Id From Account Limit 1].Id;
        Id groupId = [Select Id From Umbrella_Group__c Limit 1].Id;

        Test.startTest();
            Umbrella_Beneficiary__c umb = [Select Id, Status__c From Umbrella_Beneficiary__c Limit 1];
            umb.Status__c = 'Inactive';
            update umb;

            List<Umbrella_Beneficiary__c> beneficiaries = TestDataFactory.createUmbrellaBeneficiaries(accId, groupId, 1);
            try{
                insert beneficiaries;
            }catch(Exception e){
                System.debug(e.getMessage());
            }
        Test.stopTest();
        
        List<Umbrella_Beneficiary__c> umbList = [Select Id, Status__c From Umbrella_Beneficiary__c Where Account__c =: accId];
        System.assertEquals(2, umbList.size(), 'Failed to Avoid Duplicate Umbrella Beneficiaries');
    }
}