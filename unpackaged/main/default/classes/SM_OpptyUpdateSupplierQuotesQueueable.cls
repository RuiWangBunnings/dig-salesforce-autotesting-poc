/*******************************************************************************************************
* Class Name      	: SM_OpptyUpdateSupplierQuotesQueueable
* Description		: Queueable class to prevent batch from calling the future method
* Author          	: Bunnings Dev
* Created On      	: 21/11/2024
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev     21/11/2024		1000				Initial version - CRMS - 204
*******************************************************************************************************/


public with sharing class SM_OpptyUpdateSupplierQuotesQueueable implements Queueable {

    private list<Supplier_Quote__c> lQuotes = new list<Supplier_Quote__c>(); 

    private List<Supplier_Quote__c> oppQuoteList = new List<Supplier_Quote__c>();
	String Status;
    public SM_OpptyUpdateSupplierQuotesQueueable(List<Supplier_Quote__c> lQuotes,String status) {
        this.lQuotes = lQuotes;
        this.Status=status;
    }


    public void execute(System.QueueableContext qc) {
        System.debug('lQuotes:'+lQuotes);
        if (!this.lQuotes.isEmpty()) {            
            for (Supplier_Quote__c sq : lQuotes) {
               
                if(this.status == 'Accepted'){
                  if(sq.Status__c != 'Cancelled' && sq.Status__c != 'Lost'){
                    sq.Status__c = this.Status;
                	}  
                }else if (this.status == 'Lost'){
                    if(sq.Status__c != 'Cancelled'){
                    sq.Status__c = this.Status;
                	} 
                    
                }
                
              
            }
            System.debug('lQuotes:'+lQuotes);
        }
        if (!lQuotes.isEmpty()) {
            try {
                UPDATE lQuotes;
            } catch (Exception e) {
                ApplicationLogger.log('QuoteTriggerHandler.SM_OpptyUpdateSupplierQuotesQueueable', 'Opportunity', 'Trigger', e);
            }
        }
        
    }
}