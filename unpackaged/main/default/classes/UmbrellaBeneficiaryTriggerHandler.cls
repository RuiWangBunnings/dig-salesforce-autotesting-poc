/*******************************************************************************************************
* Class Name      	: UmbrellaBeneficiaryTriggerHandler
* Description		: Trigger Handler for UmbrellaBeneficiaryTrigger
* Author          	: Simplus MS
* Created On      	: 17/01/2022
* Modification Log	: 
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            17/01/2022		1000				Initial version
******************************************************************************************************/
public with sharing class UmbrellaBeneficiaryTriggerHandler {
    
    public static final String ERROR_AVOID_DUPLICATE_UMBRELLA_BENEFICIARIES = System.Label.Avoid_Duplicate_Umbrella_Beneficiaries;

    /**
    * @description 
    * @author Simplus MS | 17/01/2022 
    * @param newList 
    **/
    public static void beforeInsert(List<Umbrella_Beneficiary__c> newList) {
        System.debug('beforeInsert Umbrella Beneficiary** ');
        avoidDuplicateUmbrellaBeneficiaries(newList);
    }

    
    /**
    * @description 
    * @author Simplus MS | 17/01/2022 
    * @param oldMap 
    * @param newMap
    **/
    public static void beforeUpdate(Map<Id, Umbrella_Beneficiary__c> oldMap, Map<Id, Umbrella_Beneficiary__c> newMap) {
        System.debug('beforeUpdate Umbrella Beneficiary** ');
        avoidDuplicateUmbrellaBeneficiaries(newMap.values());
    }


    /**
    * @description Added for CCRM15-205
    * @author Simplus MS | 17/01/2022 
    * @param umbrellaBeneficiarys List
    **/
    public static void avoidDuplicateUmbrellaBeneficiaries(List<Umbrella_Beneficiary__c> umbrellaBeneficiaries) {
        system.debug('avoidDuplicateUmbrellaBeneficiaries'+umbrellaBeneficiaries);
        
        if(umbrellaBeneficiaries.isEmpty()) {
            return;
        }
        
        Set<Id> accounts = new Set<Id>();
        Set<Id> umgroups = new Set<Id>();
        Set<Id> umbs = new Set<Id>();

        for (Umbrella_Beneficiary__c umb : umbrellaBeneficiaries){
            umbs.add(umb.Id);
            accounts.add(umb.Account__c);
            umgroups.add(umb.Umbrella_Group__c);
        }
        
        Map<Id, Umbrella_Beneficiary__c> mapOfUmbrellaBeneficiary = new Map<Id, Umbrella_Beneficiary__c>();
        for (Umbrella_Beneficiary__c umbrellaBeneficiary : [SELECT Id, Name, Account__c, Umbrella_Group__c, Status__c 
                                                            FROM Umbrella_Beneficiary__c 
                                                            WHERE Account__c In :accounts 
                                                            AND Umbrella_Group__c IN :umgroups
                                                            AND Status__c =: Constants.STATUS_ACTIVE
                                                            AND Id NOT IN :umbs]){
            if (umbrellaBeneficiary.Status__c == Constants.STATUS_ACTIVE){
                mapOfUmbrellaBeneficiary.put(umbrellaBeneficiary.Account__c, umbrellaBeneficiary);  
            }
        }

        for(Umbrella_Beneficiary__c umbrellaBeneficiary : umbrellaBeneficiaries) {
            if((umbrellaBeneficiary.Status__c == Constants.STATUS_ACTIVE)
               && (mapOfUmbrellaBeneficiary.containsKey(umbrellaBeneficiary.Account__c)) 
               && (mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Umbrella_Group__c == umbrellaBeneficiary.Umbrella_Group__c)
               && (mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Account__c == umbrellaBeneficiary.Account__c)) {
                    umbrellaBeneficiary.addError(ERROR_AVOID_DUPLICATE_UMBRELLA_BENEFICIARIES +' Umbrella Beneficiary: '+ mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Name);

                    //umbrellaBeneficiary.addError('ERROR TRM100: There is already an identical record: <a href=\'https://bunnings--buildsb.lightning.force.com/lightning/r/Umbrella_Beneficiary__c/' + mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Id + '/view'+'>'+ mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Name +'</a>',  false);

                    //https://bunnings--buildsb.lightning.force.com/lightning/r/Umbrella_Beneficiary__c/a0F9D000004vehGUAQ/view

                    //String link = ' <a href="https://bunnings--buildsb.lightning.force.com/lightning/r/Umbrella_Beneficiary__c/'+ mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Id +'/view" target="_blank">'+ mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Name + '</a>';

                    //umbrellaBeneficiary.addError(ERROR_AVOID_DUPLICATE_UMBRELLA_BENEFICIARIES + link, false);

                    //umbrellaBeneficiary.addError('Same Combination of Record already Inserted in System: <a href=\'/'+ mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Id +'\'>'+mapOfUmbrellaBeneficiary.get(umbrellaBeneficiary.Account__c).Name+'</a>', false);
               }
        }        
    }
}