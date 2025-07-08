/*******************************************************************************************************
* Class Name      	: DM_PriceList
* Description		: Data Layer - Selector for Sobject Price_List__c
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 27/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    27/07/2020		1000				Initial version
* Bunnings Dev          24/10/2022      2000                BUNDIG-11664 - Allow to move next if Base Spend Band is selected
******************************************************************************************************/
public without sharing class DM_PriceList {

    @InvocableMethod
    public static List<List<Price_List__c>> getAvailablePriceList(List<String> profileName){

        List<List<Price_List__c>> availablePriceList = new List<List<Price_List__c>>();

        try {
            List<Price_List__c> priceLists = new List<Price_List__c>();

            //get all associated Pricing Visibility Record
            List<Pricing_Assignment_Visibility__c> pricingAssignmentVisibilityList = new List<Pricing_Assignment_Visibility__c>([Select Id, Price_List_Definition__c, Profile__c 
                                                                                                                                FROM Pricing_Assignment_Visibility__c 
                                                                                                                                WHERE Profile__c =: profileName[0]]);

            Set<Id> priceListDefinitionIds = new Set<Id>();                                                                                                          
            //Iterate to get Price List Definition Ids
            for(Pricing_Assignment_Visibility__c pricingAssignmentVisibility : pricingAssignmentVisibilityList){
                if(pricingAssignmentVisibility.Price_List_Definition__c != null){
                    priceListDefinitionIds.add(pricingAssignmentVisibility.Price_List_Definition__c);
                }
            }

            //Get all Price List definition Ids with Child Price List
            List<Price_List_Definition__c> priceListDefinitions = new List<Price_List_Definition__c>([Select Id, (Select Id, Name, CreatedById, CreatedDate, Description__c, End_Date__c, OwnerId, Price_List_Header_ID__c, Region__c, Spend_Band__c, Start_Date__c, Status__c, Cost_Zone__c, Country__c, Primary_Segment__c, Secondary_Segment__c, Price_List_Name__c, State__c
                                                                                                                    FROM Price_Lists__r
                                                                                                                    WHERE Status__c = 'Active')
                                                                                                        FROM Price_List_Definition__c
                                                                                                        WHERE Id IN: priceListDefinitionIds]);

            // iterate to get all children

            for(Price_List_Definition__c priceListDefinition : priceListDefinitions){
                List<Price_List__c> tempPL = new List<Price_List__c>(priceListDefinition.Price_Lists__r);
                if(!tempPL.isEmpty()){
                    priceLists.addAll(tempPL);
                }
            }

            availablePriceList.add(priceLists);
            
            return priceLists.size() > 0 ? availablePriceList : null; 
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // BUNDIG-11664
    @AuraEnabled
    public static Spend_Band__c getSpendBandCurrent(String spendBandId) {
        return [
            SELECT Id, Name, Status__c
            FROM Spend_Band__c
            WHERE Id =:spendBandId
        ];
    }
}