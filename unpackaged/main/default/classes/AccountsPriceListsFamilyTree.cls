/*******************************************************************************************************
* Class Name      	: AccountsPriceListsFamilyTree
* Description		: Controller for AccountsForApproval component
* Author          	: Simplus - Francis Benzon
* Created On      	: 06/03/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        06/03/2020		1000				Initial version
* Francis Benzon        12/05/2020		2000				Tracked with update Pricing Assignment
******************************************************************************************************/
global without sharing class AccountsPriceListsFamilyTree{
    
    String cpsApproved = System.Label.CPSApproved;
    String inActive = System.Label.Inactive;
    String active = System.Label.Active;    
    
    global String accountId{get;set;}
    
    global Account account{
        get {
            account = [Select Id, Name, Country__c, Spend_Band__c, Spend_Band__r.Name, 
                        Proposed_Spend_Band__r.Name, Proposed_Spend_Band__c, PL_FTD_Summary__c, Record_Type_Name__c
                        FROM Account where ID =: accountId];
            return account; 
        }
       set;
    }
    
    global List<Price_List__c> priceLists {
        get {
            priceLists = new List<Price_List__c>();
			Set<String> pricingStatusSet = new Set<String>{cpsApproved, 'Pending Removal Approval'};
                    
            List<Price_List__c> plLst = new List<Price_List__c>();
            plLst = [SELECT Id, Name, Price_List_Name__c  
                        FROM Price_List__c 
                        WHERE ID IN (SELECT Price_List__c FROM Customer_Price_List__c 
                        WHERE Account__c = :accountId 
                        AND Pricing_Assignment_Status__c NOT IN :pricingStatusSet
                        AND Status__c = :inActive)];
                      
            if(!plLst.isEmpty()) {
                for(Price_List__c pl : plLst) {
                    priceLists.add(pl);
                }                               
            }
            return priceLists;          
        }
        set;
    }

    global List<Price_List__c> forRemovalPriceList {
        get {
            forRemovalPriceList = new List<Price_List__c>();
			Set<String> pricingStatusSet = new Set<String>{ 'Pending Removal Approval'};
                    
            List<Price_List__c> plLst = new List<Price_List__c>();
            plLst = [SELECT Id, Name, Price_List_Name__c  
                        FROM Price_List__c 
                        WHERE ID IN (SELECT Price_List__c FROM Customer_Price_List__c 
                        WHERE Account__c = :accountId 
                        AND Pricing_Assignment_Status__c IN :pricingStatusSet
                        AND Status__c = :active)];
                      
            if(!plLst.isEmpty()) {
                for(Price_List__c pl : plLst) {
                    forRemovalPriceList.add(pl);
                }                               
            }
            return forRemovalPriceList;          
        }
        set;
    }

    global String prospectPricing{
        get{
            prospectPricing = account.PL_FTD_Summary__c;
            return prospectPricing;
        }
        set;
    }
    
    global List<Price_List__c> currentPriceLists {
        get {
            currentPriceLists = new List<Price_List__c>();
                       
            List<Price_List__c> currentPList = new List<Price_List__c>();
            currentPList = [SELECT Id, Name, Price_List_Name__c
                        FROM Price_List__c 
                        WHERE ID IN (SELECT Price_List__c FROM Customer_Price_List__c 
                        WHERE Account__c = :accountId
                        AND Status__c = :active)];
            
            if(!currentPList.isEmpty()) {
                for(Price_List__c pl : currentPList) {
                    currentPriceLists.add(pl);
                }                               
            }
            return currentPriceLists;          
        }
        set;
    }
    
    
    global List<Family_Tree_Discount__c> famTreeDisc {
        get {
            famTreeDisc = new List<Family_Tree_Discount__c>();
            Set<String> pricingStatusSet = new Set<String>{cpsApproved, 'Pending Removal Approval'};
            
            List<Family_Tree_Discount__c> famTreeLst = new List<Family_Tree_Discount__c>();
            famTreeLst = [SELECT Id, Name FROM Family_Tree_Discount__c 
                            WHERE ID IN (SELECT Family_Tree_Discount__c FROM Customer_Family_Tree_Discount__c
                            WHERE Account__c = :accountId 
                            AND Pricing_Assignment_Status__c NOT IN: pricingStatusSet
                            AND Status__c = :inActive)];
 
            if(!famTreeLst.isEmpty()) { 
                for(Family_Tree_Discount__c ftd : famTreeLst) {
                    famTreeDisc.add(ftd);
                }                               
            }
            return famTreeDisc;         
        }
        set;
    }

    global List<Family_Tree_Discount__c> forRemovalFamilyTreeDiscount {
        get {
            forRemovalFamilyTreeDiscount = new List<Family_Tree_Discount__c>();
            Set<String> pricingStatusSet = new Set<String>{'Pending Removal Approval'};
            
            List<Family_Tree_Discount__c> famTreeLst = new List<Family_Tree_Discount__c>();
            famTreeLst = [SELECT Id, Name FROM Family_Tree_Discount__c 
                            WHERE ID IN (SELECT Family_Tree_Discount__c FROM Customer_Family_Tree_Discount__c
                            WHERE Account__c = :accountId 
                            AND Pricing_Assignment_Status__c IN: pricingStatusSet
                            AND Status__c = :active)];
 
            if(!famTreeLst.isEmpty()) { 
                for(Family_Tree_Discount__c ftd : famTreeLst) {
                    forRemovalFamilyTreeDiscount.add(ftd);
                }                               
            }
            return forRemovalFamilyTreeDiscount;         
        }
        set;
    }
    
    global List<Family_Tree_Discount__c> activeFamTreeDisc {   
        get {
            activeFamTreeDisc = new List<Family_Tree_Discount__c>();
            
            List<Family_Tree_Discount__c> famTreeLst = new List<Family_Tree_Discount__c>();
            famTreeLst = [SELECT Id, Name FROM Family_Tree_Discount__c 
                            WHERE ID IN (SELECT Family_Tree_Discount__c FROM Customer_Family_Tree_Discount__c
                            WHERE Account__c = :accountId 
                            AND Status__c = :active)];
 
            if(!famTreeLst.isEmpty()) { 
                for(Family_Tree_Discount__c ftd : famTreeLst) {
                    activeFamTreeDisc.add(ftd);
                }                               
            }
            return activeFamTreeDisc;         
        }
        set;
    }
    
    
    global  AccountsPriceListsFamilyTree() {
        //constructor
    }
    
     global String NewLine {
        get { return '\r\n'; }
        set;
    }
            
}