/**
*   =====================================================================================
*   Class Name          : CustomerPriceListHelper
*   Description         : Helper for functions associated to customer price lists
*   Author              : Simplus - Purba Ghosh
*   Created On          : 01 Mar 2020
*   Modification Log    :
*   =====================================================================================
*   Developer       Date            Modification ID         Description
*   =====================================================================================
*   Purba Ghosh     01 Mar 2020     1000                    Initial version
*   =====================================================================================
*/
public without sharing class CustomerPriceListHelper {
  /**
   *  Method name  :  getCustomerPriceLists
   *  Description  :  Get PriceList record
   *  Author       :  Francis Benzon
   *  Return Type  :  List<Customer_Price_List__c>
   *  Parameter    :  String accountId
   *                  - Record Id of the account
   *                  String recordStatus
   *                  - Status of the customer price list 
   */   
    public static List<Customer_Price_List__c> getCustomerPriceLists(String accountId, String recordStatus) {      
        List<Customer_Price_List__c> customerPriceList = new List<Customer_Price_List__c>();
        String cpsApproved = System.Label.CPSApproved;
        String inActive = System.Label.Inactive; 
        if(accountId != null) {
            try {
                customerPriceList = [SELECT Id, Name, Account__c, End_Date__c, Price_List__c,
                                    Price_List__r.Price_List_Name__c, Start_Date__c, Status__c, Pricing_Assignment_Status__c,
                                    Change_Requested_On__c, Action__c
                                    From Customer_Price_List__c 
                                    WHERE Pricing_Assignment_Status__c != :cpsApproved
                                    AND Account__c = :accountId
                                    AND Status__c = :inActive
                                    ];                                    
            } catch (exception e) {
                ApplicationLogger.log('getCustomerPriceLists', 'Customer_Price_List__c', 'CustomerPriceListHelper', e);
            }
        }
        return customerPriceList;
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 7/2/2020 
    * @param String accountId 
    * @return List<Customer_Price_List__c> 
    **/
    public static List<Customer_Price_List__c> getRelatedCustomerPriceLists(String accountId){
        List<Customer_Price_List__c> customerPriceList = new List<Customer_Price_List__c>();

        try{
            customerPriceList = [SELECT Id, Name, Account__c, End_Date__c, Price_List__c,
                                    Price_List__r.Price_List_Name__c, Start_Date__c, Status__c, Pricing_Assignment_Status__c,
                                    Change_Requested_On__c, Action__c
                                    From Customer_Price_List__c 
                                    WHERE Account__c = :accountId
                                    ];

        } catch (exception e) {
            ApplicationLogger.log('getCustomerPriceLists', 'Customer_Price_List__c', 'CustomerPriceListHelper', e);
        }
        
        return customerPriceList;
    }
}