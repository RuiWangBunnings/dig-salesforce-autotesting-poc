/*******************************************************************************************************
* Class Name      	: DM_CZMapping
* Description		: Data Layer - Selector for Custom Metadata Type CZ Mapping
* Author          	: Simplus - Yi Zhang
* Created On      	: 22/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              22/05/2020		1000				Initial version
* Yi Zhang              28/07/2020		2000				Added static variable
******************************************************************************************************/
public with sharing class DM_CZMapping {
    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param country 
    * @param state 
    * @param costZone 
    * @return String 
    **/
    public static String getApplicableCZs(String country, String state, String costZone) {
        List<CZ_Mapping__mdt> mappings = [
            SELECT Applicable_Cost_Zones__c
            FROM CZ_Mapping__mdt
            WHERE Country__c = :country
            AND State__c = :state
            AND Cost_Zone__c = :costZone
        ];
        if(mappings.isEmpty() == true) {
            return null;
        }
        
        return mappings[0].Applicable_Cost_Zones__c;
    }

    /**
    * @description 
    * @author Yi Zhang | 28/07/2020 
    * @return Map<String, String> 
    **/
    public static Map<String, String> costZoneMap {
        get {
            if(costZoneMap == null) {
                costZoneMap = new Map<String, String>();
                for(CZ_Mapping__mdt czm : [SELECT Country__c, State__c, Cost_Zone__c, Applicable_Cost_Zones__c FROM CZ_Mapping__mdt]) {
                    costZoneMap.put(czm.Country__c + czm.State__c + czm.Cost_Zone__c, czm.Applicable_Cost_Zones__c);
                }
            }
            return costZoneMap;
        } set;
    }
}