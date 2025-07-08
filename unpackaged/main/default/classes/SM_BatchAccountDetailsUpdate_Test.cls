/*******************************************************************************************************
* Class Name      	: SM_BatchAccountDetailsUpdate_Test
* Description		: test class for Batch class for bulk update account number and identification number
* Author          	: Bunnings dev
* Created On      	: 22/10/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          22/10/2024      1000                Initial version
* -----------------------------------------------------------------------------------------------------*/

@isTest
public class SM_BatchAccountDetailsUpdate_Test {
	
    @testSetup 
    public static void testDataSetup() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Trade Specialist
        
        List<User> users = TestDataFactory.createUsers(4, p.Id);
        insert users;
        users[0].ManagerId = users[1].Id;
        users[1].ManagerId = users[2].Id;
        users[2].ManagerId = users[3].Id;
        update users;
        
        User u = users[0];
        
        System.runAs(users[0]) {
            List<Account> accts = TestDataFactory.createAccounts(3);
            String personRecordType = DM_RecordType.rtId_Account_AuCustomer;
            accts[1].Transfer_approval_status__c = 'Submitted for approval';
            accts[1].Power_Pass_Account_Number__c = '1223';
            accts[1].RecordTypeId =personRecordType;
            insert accts;
            
         			
        }
            
    }
    
     /**
    * @description test_BatchAccountDetailsUpdate
    * @author Bunnings Dev
    * @param none
    **/
    @isTest
    public static void test_BatchAccountDetailsUpdate() {
        Test.startTest();
        List<Account> accs1 = [Select id, Account_number__c, Account_Identification__c,RecordTypeId,Power_Pass_Account_Number__c,Country__c from Account];
            system.debug('accs1:'+ accs1);
            SM_BatchAccountDetailsUpdate obj = new SM_BatchAccountDetailsUpdate();
            Database.QueryLocator ql = obj.start(null);
            obj.execute(null,accs1);
            obj.finish(null);
        Test.stopTest();
    }
    
}