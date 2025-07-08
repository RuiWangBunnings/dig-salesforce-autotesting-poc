public with sharing class WOBFormOppOfferRecordViewController {
    @AuraEnabled
    public static String getOpportunityOfferId(String opportunityId){
        String oppOfferId = [SELECT Id, Opportunity__c FROM Opportunity_Offer__c WHERE Opportunity__c = :opportunityId].Id ;
        return oppOfferId;
    }
}