/*******************************************************************************************************
* Class Name      	: DM_ProjectParticipant
* Description		: Data Layer - Selector for Sobject Project Participant
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 17/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    17/08/2020		1000				Initial version
******************************************************************************************************/
public class DM_ProjectParticipant {
	
    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020
    * @param contractIds 
    * @return List<Project_Participant__c> 
    **/
    public static List<Project_Participant__c> getProjectParticipants(Set<String> contractIds){
        
        return new List<Project_Participant__c>([SELECT Id, Name, Contract__c, Project__c, Status__c, Relationship_Type__c, Account__c 
                                                                                                    FROM Project_Participant__c 
                                                                                                    WHERE Contract__c IN: contractIds]);                                                 
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020
    * @param projectIds 
    * @param accountIds 
    * @return List<Project_Participant__c> 
    **/
    public static List<Project_Participant__c> getProjectParticipants(Set<String> projectIds, Set<String> accountIds){
        return new List<Project_Participant__c>([SELECT Id, Name, Contract__c, Project__c, Status__c, Relationship_Type__c, Account__c 
                                                                                                    FROM Project_Participant__c 
                                                                                                    WHERE Project__c IN: projectIds AND Account__c IN: accountIds]);
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 17/08/2020
    * @param projectIds 
    * @param accountIds 
    * @return List<Project_Participant__c> 
    **/
    public static List<Project_Participant__c> getNoContractProjectParticipants(Set<String> projectIds, Set<String> accountIds){
        return new List<Project_Participant__c>([SELECT Id, Name, Contract__c, Project__c, Status__c, Relationship_Type__c, Account__c 
                                                                                                    FROM Project_Participant__c 
                                                                                                    WHERE Project__c IN: projectIds AND Account__c IN: accountIds AND Contract__c = null]);
    }
}