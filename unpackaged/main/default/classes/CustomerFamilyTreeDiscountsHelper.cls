/**
*   =======================================================================================
*   Class Name          : CustomerFamilyTreeDiscountsHelper
*   Description         : Helper for functions associated to customer family tree discounts
*   Author              : Simplus - Purba Ghosh
*   Created On          : 01 Mar 2020
*   Modification Log    : 02 Mar 2020 FrancisBenzon : added soql 
*   =======================================================================================
*   Developer       Date            Modification ID         Description
*   =======================================================================================
*   Purba Ghosh     01 Mar 2020     1000                    Initial version
*   =======================================================================================
*/
public without sharing class CustomerFamilyTreeDiscountsHelper {
  /**
   *  Method name  :  getPendingCustomerFamilyTreeDiscounts
   *  Description  :  Get Customer Family Tree Discount record
   *  Author       :  Francis Benzon
   *  Return Type  :  List<Customer_Family_Tree_Discount__c>
   *  Parameter    :  String accountId
   *                  - Record Id of the account
   *                  String recordStatus
   *                  - Status of the customer price list 
   */   
   
    public static List<Customer_Family_Tree_Discount__c> getPendingCustomerPriceFiles(String accountId, String recordStatus) {     
        List<Customer_Family_Tree_Discount__c> customerFamilyTreeDiscounts = new List<Customer_Family_Tree_Discount__c>();   String cpsApproved = System.Label.CPSApproved;
        String inActive = System.Label.Inactive; 
        
        if(accountId != null) {
            try {
                customerFamilyTreeDiscounts = [SELECT Id, Name, Account__c, End_Date__c, Family_Tree_Discount__c,
                                    Family_Tree_Discount__r.Name, Start_Date__c, Status__c, Pricing_Assignment_Status__c,
                                    Change_Requested_On__c, Action__c
                                    From Customer_Family_Tree_Discount__c 
                                    WHERE Pricing_Assignment_Status__c != :cpsApproved
                                    AND Status__c = :inActive
                                    AND Account__c = :accountId];                                    
            } catch (exception e) {
                ApplicationLogger.log('getPendingCustomerPriceFiles', 'Customer_Family_Tree_Discount__c', 'CustomerFamilyTreeDiscountsHelper', e);
            }
        }
        return customerFamilyTreeDiscounts;
   }

   /**
   * @description 
   * @author John Paul Peñaflor | 7/2/2020 
   * @param String accountId 
   * @return List<Customer_Family_Tree_Discount__c> 
   **/
   public static List<Customer_Family_Tree_Discount__c> getRelatedCustomerFamilyTreeDiscount(String accountId) {     
    List<Customer_Family_Tree_Discount__c> customerFamilyTreeDiscounts = new List<Customer_Family_Tree_Discount__c>();
    
    try {
        customerFamilyTreeDiscounts = [SELECT Id, Name, Account__c, End_Date__c, Family_Tree_Discount__c,
                            Family_Tree_Discount__r.Name, Start_Date__c, Status__c, Pricing_Assignment_Status__c,
                            Change_Requested_On__c, Action__c
                            From Customer_Family_Tree_Discount__c 
                            WHERE Account__c = :accountId];                                    
    } catch (exception e) {
        ApplicationLogger.log('getPendingCustomerPriceFiles', 'Customer_Family_Tree_Discount__c', 'CustomerFamilyTreeDiscountsHelper', e);
    }

    return customerFamilyTreeDiscounts;
}
}