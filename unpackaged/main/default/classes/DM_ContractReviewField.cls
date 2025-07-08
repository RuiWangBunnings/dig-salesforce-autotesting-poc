/*******************************************************************************************************
* Class Name      	: DM_ContractReviewField
* Description		: Data Layer - Selector for custom metadata Contract_Review_Field__mdt
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-05-25
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-25		1000				Initial version
******************************************************************************************************/
public with sharing class DM_ContractReviewField {
    /**
    * @description 
    * @author Yi Zhang | 25/05/2020 
    * @param costZones 
    * @return List<Contract_Review_Field__mdt> 
    **/
    public static List<Contract_Review_Field__mdt> getSpecialBuyFields(List<String> costZones) {
        costZones.add('ALL');
        return [
            SELECT Id, Field_Name__c, Label__c, Field_Type__c, Price_Field_Name__c, Field_Order__c 
            FROM Contract_Review_Field__mdt
            WHERE Cost_Zone__c IN :costZones
            AND Table_Type__c = 'Special Buy Line'
            ORDER BY Field_Order__c ASC
        ];
    }

    
    /**
    * @description 
    * @author Yi Zhang | 26/05/2020 
    * @param costZones 
    * @param country 
    * @param contractType 
    * @return List<Contract_Review_Field__mdt> 
    **/
    public static List<Contract_Review_Field__mdt> getContractLineFields(List<String> costZones, String country, String contractType) {
        costZones.add('ALL');
        return [
            SELECT Id, Field_Name__c, Label__c, Field_Type__c, Field_Order__c, Editable__c, Is_Retail__c, Additional_Field_Name__c 
            FROM Contract_Review_Field__mdt
            WHERE Cost_Zone__c IN :costZones
            AND Table_Type__c = 'Contract Line'
            AND Country__c = :country
            AND Contract_Type__c = :contractType
            ORDER BY Field_Order__c ASC
        ];
    }
}