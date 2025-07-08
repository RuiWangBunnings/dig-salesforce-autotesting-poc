public with sharing class WOBFormProjectLWCController {
    
    @AuraEnabled(cacheable=true)
    public static Project__c getProjectRecordDetails(String projectId){
        
        try {
            Project__c projectRecord = [SELECT Id, Name, TECH_WOB_Lot_No__c, TECH_WOB_Street_No__c,
            TECH_WOB_Street_Name__c,TECH_WOB_Street_Type__c, Project_Address__c, Build_Stage__c, Development_Type__c, Status__c,
                                    Project_Type__c, Project_Value__c,Floors__c, Number_of_Units_Buildings__c, 
                                    Tender_Due_Date__c, Town__c, State__c, Postcode__c,
                                    Concatenated_Address__c, House_Type__c, Shared_Document_Password__c,
                                    Construction_Start__c, Construction_End__c , Selected_Contact__c, Document_Library_URL__c, Selected_Account__c,
                                    TECH_WOB_Construction_End_Formatted__c,TECH_WOB_Construction_Start_Formatted__c, Main_Account__c, OwnerId
                                    FROM Project__c WHERE Id = :projectId];
        
            return projectRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //to refactor
    @AuraEnabled
    public static Boolean checkExistingProjectParticipant(String projectId, String accountId){
        try {
            Boolean existingSameProjectAndAccount;
            Project_Participant__c projectParticipant = [SELECT Id, Project__c, Account__c FROM Project_Participant__c 
                                                         WHERE Project__c = :projectId 
                                                         AND Account__c = :accountId];
            System.debug('Sid ' + projectParticipant);
            if(projectParticipant.Id != null){
                existingSameProjectAndAccount = true;
            }else{
                existingSameProjectAndAccount = false;
            }

            return existingSameProjectAndAccount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}