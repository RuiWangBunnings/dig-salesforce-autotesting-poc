/*******************************************************************************************************
* Class Name      	: SM_Order_Test
* Description		: Test class for SM_Order
* Author          	: Simplus - Yi Zhang
* Created On      	: 09/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              09/10/2020		1000				Initial version
* Bunnings dev          03/10/2024      1001				Adding Before Insert Trigger logic
******************************************************************************************************/
@isTest
private class SM_Order_Test {
    @isTest
    private static void testInvoicedSubmittedOrders() {
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
        // create opportunities
        List<Opportunity> opps = TestDataFactory.createOpenOpportunities(accounts[0].Id, UserInfo.getUserId(), 2);
        insert opps;
        // create orders
        Order order1 = new Order(AccountId = accounts[0].Id, OpportunityId = opps[0].Id, Status = 'Invoiced', EffectiveDate = Date.today(), Total_Value_excl_GST__c = 1000);
        Order order2 = new Order(AccountId = accounts[0].Id, OpportunityId = opps[0].Id, Status = 'Submitted', EffectiveDate = Date.today(), Total_Value_excl_GST__c = 2000);
        Order order3 = new Order(AccountId = accounts[0].Id, OpportunityId = opps[1].Id, Status = 'Invoiced', EffectiveDate = Date.today(), Total_Value_excl_GST__c = 3000);
        Order order4 = new Order(AccountId = accounts[0].Id, OpportunityId = opps[1].Id, Status = 'Submitted', EffectiveDate = Date.today(), Total_Value_excl_GST__c = 4000);

        Test.startTest();
        insert new List<Order>{order1, order2, order3, order4};
        Opportunity opp1 = [SELECT Id, Order_Fulfilment_Amount__c, Pending_Order_Amount__c FROM Opportunity WHERE Id = :opps[0].Id];
        System.assertEquals(order1.Total_Value_excl_GST__c, opp1.Order_Fulfilment_Amount__c, 'Invoiced amount should be order fulfilment amount on opportunity');
        System.assertEquals(order2.Total_Value_excl_GST__c, opp1.Pending_Order_Amount__c, 'Submitted amount should be pending order amount on opportunity');

        // change order2's status to invoiced
        order2.Status = 'Invoiced';
        update order2;
        opp1 = [SELECT Id, Order_Fulfilment_Amount__c, Pending_Order_Amount__c FROM Opportunity WHERE Id = :opps[0].Id];
        System.assertEquals(order1.Total_Value_excl_GST__c + order2.Total_Value_excl_GST__c, opp1.Order_Fulfilment_Amount__c, 'Order_Fulfilment_Amount__c should be the sum');
        System.assertEquals(0, opp1.Pending_Order_Amount__c, 'Pending_Order_Amount__c should reduce to 0');

        // change order3's status to submitted
        order3.Status = 'Submitted';
        update order3;
        Opportunity opp2 = [SELECT Id, Order_Fulfilment_Amount__c, Pending_Order_Amount__c FROM Opportunity WHERE Id = :opps[1].Id];
        System.assertEquals(order3.Total_Value_excl_GST__c + order4.Total_Value_excl_GST__c, opp2.Pending_Order_Amount__c, 'Pending_Order_Amount__c should be the sum');
        System.assertEquals(0, opp2.Order_Fulfilment_Amount__c, 'Order_Fulfilment_Amount__c should reduce to 0');
        Test.stopTest();
    }
}