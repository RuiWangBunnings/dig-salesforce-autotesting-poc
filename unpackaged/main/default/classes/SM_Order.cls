/*******************************************************************************************************
* Class Name      	: SM_Order
* Description		: Domain / Service layer for Order
* Author          	: Simplus - Yi Zhang
* Created On      	: 08/10/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              08/10/2020		1000				Initial version (replacing Order Update Actions pb)
* Bunnings dev          03/10/2024      1001				Adding Before Insert Trigger logic
******************************************************************************************************/
public with sharing class SM_Order {
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_INVOICED  = 'Invoiced';
    

    /**
    * @description 
    * @author Yi Zhang | 08/10/2020 
    * @param newList 
    **/
    public static void afterInsert(List<Order> newList) {
	
        
        
        // Update 2 amount fields on related opportunities
        // When newly created order is Invoiced / Submitted
        List<Order> invoicedOrSubmittedOrders = new List<Order>();
        for(Order order : newList) {
            if(order.Status == STATUS_SUBMITTED || order.Status == STATUS_INVOICED) {
                invoicedOrSubmittedOrders.add(order);
            }
        }
        updateOrderAmountsOnOppties(invoicedOrSubmittedOrders);
    }
    /**
    * @description 
    * @author Bunnings dev  || 3/10/2024
    * @param newList 
    **/
    public static void beforeInsert(List<Order> newList) {
		System.debug('beforeInsert');
        System.debug('DM_FeatureToggle.getFeatureToggleEnabled():'+DM_FeatureToggle.getFeatureToggleEnabled('Order_Oppty_Association_on_Creation'));
        System.debug('Trigger.new:'+Trigger.new);
        System.debug('newList:'+newList);
       Set<Id> quoteIds = new Set<Id>();

    // Collect Quote IDs from the Orders
    for (Order order : newList) {
        // Check if the Order has a Quote associated
        if (order.QuoteId != null) {
            quoteIds.add(order.QuoteId);
        }
    }
        System.debug('quoteIds:' +quoteIds);
        
// Create a map to hold Quote records
    Map<Id, Quote> quoteMap = new Map<Id, Quote>();

    // Query Quotes based on the collected Quote IDs
    if (!quoteIds.isEmpty()) {
        // Select Id and Name (or other fields as needed)
        for (Quote quote : [SELECT Id, Name, OpportunityId FROM Quote WHERE Id IN :quoteIds]) {
            quoteMap.put(quote.Id, quote);
        }
    }

        System.debug('quoteMap:'+quoteMap);
        
        // Update Opportunity ID on Order
        if(DM_FeatureToggle.getFeatureToggleEnabled('Order_Oppty_Association_on_Creation')){
            for(Order order : newList) {
                if(quoteMap.get(order.quoteid)!=null){
                    String quoteOpptyid = quoteMap.get(order.quoteid).OpportunityId;
                System.debug('quoteOpptyid:'+quoteOpptyid);
                System.debug('order.COS_ID__c:'+order.COS_ID__c);
                System.debug('order.QuoteId:'+order.QuoteId);
                System.debug('order.Quote.OpportunityId:'+order.Quote.OpportunityId);
                if(!String.isBlank(order.COS_ID__c) && !String.isBlank(order.QuoteId)&& !String.isBlank(quoteOpptyid)) {
                    order.OpportunityId = quoteOpptyid;
                } 
                }
               
            }
        }
       
        
    }

    /**
    * @description 
    * @author Yi Zhang | 08/10/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void afterUpdate(Map<Id, Order> oldMap, Map<Id, Order> newMap) {

        // Update 2 amount fields on related opportunities
        List<Order> invoicedOrSubmittedOrders = new List<Order>();
        for(Order newOrder : newMap.values()) {
            Order oldOrder = oldMap.get(newOrder.Id);
            
            // scenario 1: status changed, include new order
            if(newOrder.Status != oldOrder.Status && changedFromOrToInvoicedOrSubmitted(oldOrder, newOrder)) {
                invoicedOrSubmittedOrders.add(newOrder);
            }
            
            // scenario 2: opportunity id changed, include both orders
            if(oldOrder.OpportunityId != newOrder.OpportunityId && changedFromOrToInvoicedOrSubmitted(oldOrder, newOrder)) {
                invoicedOrSubmittedOrders.add(oldOrder);
                invoicedOrSubmittedOrders.add(newOrder);
            }
            if(newOrder.Total_Value_excl_GST__c  != oldOrder.Total_Value_excl_GST__c){
                invoicedOrSubmittedOrders.add(newOrder);
            }
        }
        updateOrderAmountsOnOppties(invoicedOrSubmittedOrders);
    }

    /**
    * @description 
    * @author Yi Zhang | 08/10/2020 
    * @param orders 
    **/
    public static void updateOrderAmountsOnOppties(List<Order> orders) {
        // Opportunity.Order_Fulfilment_Amount__c (orders which are Invoiced)
        // Opportunity.Pending_Order_Amount__c (orders which are Submitted)

        // requery opportunities with orders
        List<Id> opptyIds = new List<Id>();
        for(Order order : orders) {
            if(String.isNotBlank(order.OpportunityId)) {
                opptyIds.add(order.OpportunityId);
            }
        }
        if(opptyIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        // move to DM_Opportunity
        for(Opportunity opp : [SELECT Id, (SELECT Id, Status, Total_Value_excl_GST__c FROM Orders WHERE Status IN (:STATUS_SUBMITTED, :STATUS_INVOICED)) FROM Opportunity WHERE Id IN :opptyIds]) {
            Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
            oppToUpdate.Order_Fulfilment_Amount__c = 0;
            oppToUpdate.Pending_Order_Amount__c = 0;
            for(Order order : opp.Orders) {
                if(order.Status == STATUS_SUBMITTED) {
                    oppToUpdate.Pending_Order_Amount__c += (order.Total_Value_excl_GST__c == null) ? 0 : order.Total_Value_excl_GST__c;
                } else {
                    oppToUpdate.Order_Fulfilment_Amount__c += (order.Total_Value_excl_GST__c == null) ? 0 : order.Total_Value_excl_GST__c;
                }
            }
            oppMap.put(opp.Id, oppToUpdate);
        }
        update oppMap.values();
    }

    private static Boolean changedFromOrToInvoicedOrSubmitted(Order oldOrder, Order newOrder) {
        return newOrder.Status == STATUS_INVOICED  ||
        newOrder.Status == STATUS_SUBMITTED ||
        oldOrder.Status == STATUS_INVOICED  ||
        oldOrder.Status == STATUS_SUBMITTED;
    }
}