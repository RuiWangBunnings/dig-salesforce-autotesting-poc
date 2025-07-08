/*******************************************************************************************************
* Class Name      	: PriceListTriggerHandler_Test
* Description		: Test class for PriceListTriggerHandler
* Author          	: Jasper R. Galapon
* Created On      	: 19/12/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     19/12/2023		1000				Initial version
******************************************************************************************************/

@isTest
public with sharing class PriceListTriggerHandler_Test {
    
    @isTest static void test_countPriceList() {

        Price_List_Definition__c pld = new Price_List_Definition__c();
        insert pld;

        Price_List__c pb1 = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()), Start_Date__c = (Date.today()), End_Date__c = Date.newInstance(2024, 12, 31));
        Price_List__c pb2 = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()), Start_Date__c = (Date.today()), End_Date__c = Date.newInstance(2024, 6, 30));
        Price_List__c pb3 = new Price_List__c(Status__c = 'Active', Price_List_Definition__c = pld.Id, Price_List_Header_ID__c = String.valueOf(Math.random()), Start_Date__c = (Date.today()), End_Date__c = Date.newInstance(2024, 7, 30));
        insert new List<Price_List__c>{pb1, pb2, pb3};
            
       	pb1.Status__c = 'Expired';
        update pb1;
        
        delete pb3;        
    }
}