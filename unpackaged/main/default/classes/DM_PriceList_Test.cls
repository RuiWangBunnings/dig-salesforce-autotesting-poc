/*******************************************************************************************************
* Class Name      	: DM_PriceList_Test
* Description		: Test class for DM_PriceList
* Author          	: Simplus - Yi Zhang
* Created On      	: 01/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              01/10/2020		1000				Initial version
* Bunnings Dev          24/10/2022      2000                BUNDIG-11664 - Test method to cover new method
******************************************************************************************************/
@isTest
private class DM_PriceList_Test {
    @isTest
    private static void testGetAvailablePriceList() {
        // Price_List_Definition__c
        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;
        // Price_List__c
        Price_List__c pb = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()));
        insert pb;
        // Pricing_Assignment_Visibility__c
        Pricing_Assignment_Visibility__c pav = new Pricing_Assignment_Visibility__c(Profile__c = 'System Administrator', Price_List_Definition__c = pld.Id);
        insert pav;
        Test.startTest();
        try {
            DM_PriceList.getAvailablePriceList(null);
        } catch(Exception e) {
        }

        DM_PriceList.getAvailablePriceList(new List<String>{'System Administrator'});
        Test.stopTest();
    }
    
    @isTest
    private static void testGetSpendBandCurrent() {
        Spend_Band__c sb = new Spend_Band__c(Name = 'Test', Min_Amount__c = 25001, Max_Amount__c = 50000, Spend_Band_Id__c = 'TEST12345');
        insert sb;
        
        Test.startTest();
        	DM_PriceList.getSpendBandCurrent(sb.Id);
        Test.stopTest();
    }
}