/*******************************************************************************************************
* Class Name      	: AssistedSalesTemplateController
* Description		: Controller to query child record of Assisted Sales in an email template
* Author          	: Simplus - Francis Benzon
* Created On      	: 15/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        15/05/2020		1000				Initial version
******************************************************************************************************/
global without sharing class AssistedSalesTemplateController{
    
    String cpsApproved = System.Label.CPSApproved;

    
    global String assistedSaleId{get;set;}
    
    global  AssistedSalesTemplateController() {
        //constructor
    }
        
    global List<Store_Assist__c> storeAssistList {
        get {
            storeAssistList = new List<Store_Assist__c>();
                    
            for(Store_Assist__c sa : [SELECT ID, Start_Date__c, End_Date__c, Store__c, Store__r.Name 
                                        FROM Store_Assist__c                            
                                        WHERE Assisted_Sale__c = :assistedSaleId]) {
                storeAssistList.add(sa);
            }  
                      
            return storeAssistList;          
        }
        set;
    }
    
    global List<Category_Assist__c> categoryAssistList {
        get {
            categoryAssistList = new List<Category_Assist__c>();
                       
                    
            for(Category_Assist__c ca : [SELECT ID, Start_Date__c, End_Date__c, Category__c, Category__r.Name 
                                            FROM Category_Assist__c                             
                                            WHERE Assisted_Sale__c = :assistedSaleId]) {
                categoryAssistList.add(ca);
            }  
                      
            return categoryAssistList;        
        }
        set;
    }       
}