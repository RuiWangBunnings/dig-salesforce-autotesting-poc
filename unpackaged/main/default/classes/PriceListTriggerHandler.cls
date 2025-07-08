/*******************************************************************************************************
* Trigger Name      : PriceListTriggerHandler
* Description       : Handler for PriceListTrigger
* Author            : Jasper R. Galapon
* Created On        : 19/12/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Jasper R. Galapon     19/12/2023      1000                BUNDIG-28056 - Initial Version
******************************************************************************************************/

public class PriceListTriggerHandler {
    
    public static void afterInsert(List<Price_List__c> newList) {
        countPriceList(newList);
    }

    public static void afterUpdate(List<Price_List__c> newList) {
        countPriceList(newList);
    }

    public static void afterDelete(List<Price_List__c> newList) {
        countPriceList(newList);
    }

    private static void countPriceList(List<Price_List__c> plList) {
        Set<Id> pldIds = new Set<Id>();
        Map<Id, Integer> parentRecordCountMap = new Map<Id, Integer>();

        for (Price_List__c pl : plList) {
            if (pl.Status__c == 'Active') {
                pldIds.add(pl.Price_List_Definition__c);
            }
        }

        for (AggregateResult aggregateResult : [SELECT Price_List_Definition__c, COUNT(Id) pldCount
            FROM Price_List__c WHERE Price_List_Definition__c IN :pldIds
            AND Status__c = 'Active'
            GROUP BY Price_List_Definition__c]) {
                Id parentId = (Id) aggregateResult.get('Price_List_Definition__c');
                Integer intCount = (Integer) aggregateResult.get('pldCount');

                // Don't count if only 1 Price List is present
                if (intCount > 1)
                    parentRecordCountMap.put(parentId, intCount);
        }

        List<Price_List_Definition__c> pldToUpdate = new List<Price_List_Definition__c>();
        for (Id pldId : pldIds) {
            Price_List_Definition__c pld = new Price_List_Definition__c(Id = pldId, Duplicate_Active_Price_List__c = parentRecordCountMap.get(pldId));
            pldToUpdate.add(pld);
        }
        update pldToUpdate;

    }

}