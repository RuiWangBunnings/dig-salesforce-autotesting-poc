/*******************************************************************************************************
* Class Name      	: DM_SpecialBuyLineItem
* Description		: Data Layer - Selector for Sobject Special_Buy_Line_Item__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 29/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              29/05/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_SpecialBuyLineItem {
    
    /**
    * @description 
    * @author Yi Zhang | 29/05/2020 
    * @param specialBuyIds 
    * @return List<Special_Buy_Line_Item__c> 
    **/
    public static List<Special_Buy_Line_Item__c> getNotExpiredSpecialBuyLineItems(List<Id> specialBuyIds) {
        return new List<Special_Buy_Line_Item__c>([
            SELECT Id, Name, Cost__c,            // Special Buy Cost (Ex-GST) ($)
            // special buy fields
            Special_Buy__c,
            Special_Buy__r.Id,
            Special_Buy__r.Name,                // supplier quote number
            Special_Buy__r.Requested_Date__c,   // start date
            Special_Buy__r.Expiry_Date__c,      // end date
            Special_Buy__r.Location_Type__c,    // location type
            Special_Buy__r.States__c            // states
            FROM Special_Buy_Line_Item__c
            WHERE Special_Buy__r.Expiry_Date__c >= TODAY
            AND Special_Buy__c IN :specialBuyIds
        ]);
    }
}