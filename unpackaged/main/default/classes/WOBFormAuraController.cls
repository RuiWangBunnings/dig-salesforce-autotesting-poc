public with sharing class WOBFormAuraController {
    
    @AuraEnabled
    public static Project__c getInitialAccountId(String projectId){
        return [SELECT Id, Main_Account__c, Selected_Contact__c, Selected_Account__c FROM Project__c WHERE ID = :projectId] ;
    }
}