/*******************************************************************************************************
* Class Name      	: TEMP_SM_OrderBatch
* Description		: Temporary batch class to Insert/Update Order for CCRM15-247 migration
* Author          	: Simplus MS
* Created On      	: 08/10/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS                08/10/2021		1000				Initial version
******************************************************************************************************/
public class TEMP_SM_OrderBatch implements Database.Batchable<sObject> {
    
    String query;
    String queryFilter;

    public TEMP_SM_OrderBatch(){
    }

    public TEMP_SM_OrderBatch(String queryFilter) {
        this.queryFilter = queryFilter;    
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('batchName? ' + queryFilter);
        if(queryFilter != null){
            query = 'SELECT Id, AccountID__c, Assigned_Store__c, Cancellation_Comments__c, Cancellation_Reason__c, ' +
                'Comments__c, Contact_Name__c, COS_Date__c, COS_ID__c, COS_Number__c, COS_Token__c, ' +
                'Created_by_TM_Name__c, Created_by_TM_Number__c, Customer_Job_Address__c, Customer_Job_Number__c, ' +
                'Customer_Order_Number__c, Date_Processed__c, Delivery_Collection_Date__c, Delivery_Contact__c, ' +
                'Discount_incl_GST__c, Follow_Up_Date__c, GST__c, On_Hold__c, Order_Status__c, Prices_Validity_Date__c, Contact_Number__c, ' +
                'Effective_Date__c, QuoteId__c, QuoteId__r.OpportunityId, Shipping_City__c, Shipping_Country__c, Shipping_Postal_Code__c, Shipping_State__c, ' +
                'Shipping_Street__c, Status__c, Total_Cost_excl_GST__c, Total_Cost_incl_GST__c, Total_Value_excl_GST__c, ' +
                'Total_Value_incl_GST__c, Type_of_Delivery__c, Updated_by_TM_Name__c, Updated_by_TM_Number__c, OpportunityId__c, ' +
                'Error_Message__c, Log_Type__c, Log_Object_Name__c, Source_Type__c, Function_Name__c ' +
                'FROM Staging_Object__c ' +
                'WHERE COS_ID__c != null AND Object_Name__c = \'Order\' AND Status__c = \'Open\' AND Batch_Name__c =\'' + queryFilter + '\'';
        }else{
            query = 'SELECT Id, AccountID__c, Assigned_Store__c, Cancellation_Comments__c, Cancellation_Reason__c, ' +
                'Comments__c, Contact_Name__c, COS_Date__c, COS_ID__c, COS_Number__c, COS_Token__c, ' +
                'Created_by_TM_Name__c, Created_by_TM_Number__c, Customer_Job_Address__c, Customer_Job_Number__c, ' +
                'Customer_Order_Number__c, Date_Processed__c, Delivery_Collection_Date__c, Delivery_Contact__c, ' +
                'Discount_incl_GST__c, Follow_Up_Date__c, GST__c, On_Hold__c, Order_Status__c, Prices_Validity_Date__c, Contact_Number__c, ' +
                'Effective_Date__c, QuoteId__c, QuoteId__r.OpportunityId, Shipping_City__c, Shipping_Country__c, Shipping_Postal_Code__c, Shipping_State__c, ' +
                'Shipping_Street__c, Status__c, Total_Cost_excl_GST__c, Total_Cost_incl_GST__c, Total_Value_excl_GST__c, ' +
                'Total_Value_incl_GST__c, Type_of_Delivery__c, Updated_by_TM_Name__c, Updated_by_TM_Number__c, OpportunityId__c, ' +
                'Error_Message__c, Log_Type__c, Log_Object_Name__c, Source_Type__c, Function_Name__c ' +
                'FROM Staging_Object__c ' +
                'WHERE COS_ID__c != null AND Object_Name__c = \'Order\' AND Status__c = \'Open\' ';
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Staging_Object__c> scope) {
        // execute code
        System.debug('Scope :: '+ scope);

        List<Order> orderList = new List<Order>();
        List<Quote> quoteList = new List<Quote>();

        try {
            for(Staging_Object__c stOrder : scope) {
                if(String.isNotBlank(stOrder.COS_ID__c)) {
                    Order ord = new Order();
                    ord.AccountId = stOrder.AccountID__c;
                    ord.Assigned_Store__c = stOrder.Assigned_Store__c;
                    ord.Cancellation_Comments__c = stOrder.Cancellation_Comments__c;
                    ord.Cancellation_Reason__c = stOrder.Cancellation_Reason__c;
                    ord.Comments__c = stOrder.Comments__c;
                    ord.Contact_Name__c = stOrder.Contact_Name__c;
                    ord.COS_Date__c = stOrder.COS_Date__c;
                    ord.COS_ID__c = stOrder.COS_ID__c;
                    ord.Name = stOrder.COS_Number__c;
                    ord.COS_Token__c = stOrder.COS_Token__c;
                    ord.Created_by_TM_name__c = stOrder.Created_by_TM_Name__c;
                    ord.Created_by_TM_Number__c = stOrder.Created_by_TM_Number__c;
                    ord.Customer_Job_Address__c = stOrder.Customer_Job_Address__c;
                    ord.Customer_Job_Number__c = stOrder.Customer_Job_Number__c;
                    ord.Customer_Order_Number__c = stOrder.Customer_Order_Number__c;
                    ord.Delivery_Collection_Date__c = stOrder.Delivery_Collection_Date__c;
                    ord.Delivery_Contact__c = stOrder.Delivery_Contact__c;
                    ord.Discount_incl_GST__c = stOrder.Discount_incl_GST__c;
                    ord.Follow_Up_Date__c = stOrder.Follow_Up_Date__c;
                    ord.GST__c = stOrder.GST__c;
                    ord.On_Hold__c = stOrder.On_Hold__c;
                    //ord.OpportunityId = stOrder.OpportunityId__c;
                    ord.Status = stOrder.Order_Status__c;
                    ord.Prices_Validity_Date__c = stOrder.Prices_Validity_Date__c;
                    ord.QuoteId = stOrder.QuoteId__c;
                    ord.EffectiveDate = stOrder.Effective_Date__c;
                    ord.ShippingCity = stOrder.Shipping_City__c;
                    ord.ShippingCountry = stOrder.Shipping_Country__c;
                    ord.ShippingPostalCode = stOrder.Shipping_Postal_Code__c;
                    ord.ShippingState = stOrder.Shipping_State__c;
                    ord.ShippingStreet = stOrder.Shipping_Street__c;
                    ord.Total_Cost_excl_GST__c = stOrder.Total_Cost_excl_GST__c;
                    ord.Total_Cost_incl_GST__c = stOrder.Total_Cost_incl_GST__c;
                    ord.Total_Value_excl_GST__c = stOrder.Total_Value_excl_GST__c;
                    ord.Total_Value_incl_GST__c = stOrder.Total_Value_incl_GST__c;
                    ord.Type_of_Delivery__c = stOrder.Type_of_Delivery__c;
                    ord.Updated_by_TM_Name__c = stOrder.Updated_by_TM_Name__c;
                    ord.Updated_by_TM_Number__c = stOrder.Updated_by_TM_Number__c;
                    ord.OpportunityId = stOrder.QuoteId__r.OpportunityId;
        
                    orderList.add(ord);
                }

                if(String.isNotBlank(stOrder.QuoteId__c) && String.isNotBlank(stOrder.Contact_Number__c)) {
                    Quote quo = new Quote();
                    quo.Id = stOrder.QuoteId__c;
                    quo.Phone = stOrder.Contact_Number__c;
                    quoteList.add(quo);
                }
            }

            Map<Id,Quote> quoteMap = new Map<Id,Quote>();
            quoteMap.putall(quoteList);

            // Update quotes
            if(quoteMap.size()>0){
                update quoteMap.values();
             }
            
            // Upsert orders
            if(orderList.size() > 0) {
                Database.UpsertResult[] urList = Database.upsert(orderList, Order.COS_ID__c, false);
                Set<Id> completedOrdIds = new Set<Id>();

                Map<String, Database.Error> resultsWithErrorMap = new Map<String, Database.Error>();
                for(Integer i=0; i<urList.size(); i++) {
                    System.debug(urList.get(i).isSuccess());
                    if (urList.get(i).isSuccess()) {
                        completedOrdIds.add(urList.get(i).getId());
                    } else {
                        String cosId = orderList.get(i).COS_ID__c;
                        Database.Error error = urList.get(i).getErrors().get(0);
                        resultsWithErrorMap.put(cosId, error);
                    }   
                }
        
                Set<String> completedCOSIds = new Set<String>();
                for(Order ord : [SELECT COS_ID__c FROM Order WHERE Id IN :completedOrdIds]) {
                    completedCOSIds.add(ord.COS_ID__c);
                }
        
                List<Staging_Object__c> completedStgRecList = new List<Staging_Object__c>();
                //Iterate through each staging object record and update status and date processed
                //If an operation is unsuccessful, log details into staging object error detail fields
                for(Staging_Object__c stOrder : scope) {
                    if(completedCOSIds.contains(stOrder.COS_ID__c)) {
                        stOrder.Status__c = 'Completed';
                        stOrder.Date_Processed__c = Datetime.now(); 

                        //Clear error log details
                        if(String.isNotBlank(stOrder.Error_Message__c)) {
                            stOrder.Error_Message__c = '';    
                            stOrder.Log_Type__c = ''; 
                            stOrder.Log_Object_Name__c = '';
                            stOrder.Source_Type__c = '';
                            stOrder.Function_Name__c = '';
                        }
                    } else {
                        stOrder.Status__c = 'With Error';
                        stOrder.Log_Type__c = 'Exception';
                        stOrder.Source_Type__c = 'Batch';
                        stOrder.Log_Object_Name__c = 'Order';
                        stOrder.Function_Name__c = 'TEMP_SM_OrderBatch';
                        stOrder.Error_Message__c = resultsWithErrorMap.get(stOrder.COS_ID__c).getStatusCode() + ' : ' +
                                                   resultsWithErrorMap.get(stOrder.COS_ID__c).getMessage();
                    }
                    completedStgRecList.add(stOrder);
                }

                //Update staging orders
                if(completedStgRecList.size() > 0) {
                    try {
                        Update completedStgRecList;
                    } catch(Exception e) {
                        ApplicationLogger.log('TEMP_SM_OrderBatch', 'Order', 'Batch', e);
                    }
                }
            }
        } catch(Exception e) {
            ApplicationLogger.log('TEMP_SM_OrderBatch', 'Staging_Object__c', 'Batch', e);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // finish code
    }
}