/*******************************************************************************************************
* Class Name        : DM_FeatureToggle
* Description       : Data Layer - Selector for Custom Metadata Type Feature Toggle
* Author            : Bunnings Dev
* Created On        : 2024-10-05
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Bunnings Dev           2024-10-05     1000                Initial version
* Jasper R. Galapon      2025-02-06     1001                BUNDIG-40916 - Hide Amendment Auto Approval UI Changes   
******************************************************************************************************/
public with sharing class DM_FeatureToggle {

     /**
    * @description 
    * @author Bunnings Dev | 2024-10-05 
    * @return Feature_Toggle__mdt 
    **/
    @AuraEnabled    
    public static Boolean getFeatureToggleEnabled(String featureType) {
        Feature_Toggle__mdt featureEnabled = Feature_Toggle__mdt.getInstance(featureType);
        
        return featureEnabled.Enabled__c;
    }

   
}