/*******************************************************************************************************
* Class Name      	: SM_CLIAutoApprovalBatchTest
* Description		: Test class for SM_CLIAutoApprovalBatch
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     30/07/2024		1000				BUNDIG-34611 - Initial version 
******************************************************************************************************/

@isTest
private class SM_CLIAutoApprovalBatchTest {

    @TestSetup
    static void makeData() {
        List<Contract__c> contracts = TestDataFactory.createContracts(1);
        contracts[0].Contract_Approval_Status__c = 'Customer Approved';
        insert contracts;
                
        List<Contract_Line_Item__c> clis = new List<Contract_Line_Item__c>();
        Integer index = 0;
        String rand = String.valueOf(Math.random());
        for (Integer i = 0; i < 5; i++) {
            Contract_Line_Item__c cli = new Contract_Line_Item__c(Contract__c = contracts[0].Id, Line_Status__c = 'A1', Line_Type__c = 'Amendment',
				Auto_Approval_Eligibility__c = TRUE, CreatedDate = Date.today().addDays(-10), Contract_Item_ID__c = rand + ' ' + i);
            clis.add(cli);
        }
        insert clis;        
    }
    
    @isTest
    static void CLIAutoApprovalBatchTest() {
        // Get the Contract Line Items
        List<Contract_Line_Item__c> clis = [SELECT Id FROM Contract_Line_Item__c];
        System.assertEquals(5, clis.size(), 'Expected 5 Contract Line Items');
        
        Test.startTest();
        	Date tmpDate = Date.today() - 10;
        	String strDate = String.valueOf(tmpDate);
            SM_CLIAutoApprovalBatch batch = new SM_CLIAutoApprovalBatch(strDate);
            Database.executeBatch(batch);
        Test.stopTest();
                
        List<Object_Event_Bridge__c> oebs = [SELECT Id FROM Object_Event_Bridge__c];
        System.assertEquals(5, oebs.size(), 'Expected 5 Object Event Bridge records');
    }
    
	@isTest
	static void SchedulerTest() {
        Test.startTest();
        	String jobId = System.schedule('Test SM_CLIAutoApprovalBatch', '0 0 23 * * ?', new SM_CLIAutoApprovalBatchScheduler());
        Test.stopTest();
                
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 23 * * ?', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }

}