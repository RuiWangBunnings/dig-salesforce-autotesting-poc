/*******************************************************************************************************
* Class Name      	: DM_EngagementModel
* Description		: Data Layer - Selector for custom metadata type Engagement_Model__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 20/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              20/07/2020		1000				Initial version
* Simplus MS            20/10/2021		2000				Added Logic for CCRM15-80
******************************************************************************************************/
public with sharing class DM_EngagementModel {
    public static final String MODEL_CUSTOMER_ENGAGEMENT = 'Top X from Customer Engagement Model';
    public static final String MODEL_FREQUENT = 'Top X frequent contact – to call every second month';
    public static final String MODEL_LESS_FREQUENT = 'Top X less frequent – to call every 4th month';

    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @return Map<String, Map<String, Integer>> 
    **/
    public static Map<String, Map<String, Integer>> limitMap {
        get {
            if(limitMap == null) {
                limitMap = new Map<String, Map<String, Integer>>();
                for(Engagement_Model__mdt em : models) {
                    if(limitMap.containsKey(em.Model__c) == false) {
                        limitMap.put(em.Model__c, new Map<String, Integer>());
                    }
                    limitMap.get(em.Model__c).put(em.Format__c + em.Store_Type__c + em.Country__c, Integer.valueOf(em.Limit__c));
                }
            }
            return limitMap;
        } set;
    }
    /**
    * @description 
    * @author Yi Zhang | 21/07/2020 
    * @return List<Engagement_Model__mdt> 
    **/
    public static List<Engagement_Model__mdt> models {
        get {
            if(models == null) {
                models = new List<Engagement_Model__mdt>([
                    SELECT Id, Format__c, Limit__c, Model__c, Store_Type__c, Country__c
                    FROM Engagement_Model__mdt
                ]);
            }
            return models;
        } set;
    }
}