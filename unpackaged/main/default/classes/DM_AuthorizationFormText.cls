/*******************************************************************************************************
* Class Name      	: DM_AuthorizationFormText
* @description		: Domain layer - To Query AuthorizationFormText records easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
public with sharing class DM_AuthorizationFormText {
    
    /**
     * @description getAuthorizationFormTextByExternalId get AuthorizationFormText by ExtrenalId
     * @author Juan M. Cutrera
     * @param  externalId externalId 
     * @return AuthorizationFormText return description
     */
    public static AuthorizationFormText getAuthorizationFormTextByExternalId(String externalId){
        return [SELECT Id, Name, AuthorizationFormId, External_Id__c 
                FROM AuthorizationFormText 
                WHERE External_Id__c =:externalId 
                ORDER BY LastModifiedDate DESC 
                LIMIT 1]; 
    }
}