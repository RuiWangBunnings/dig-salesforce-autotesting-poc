/*******************************************************************************************************
* Class Name      	: Consent_ConsentManager
* @description		: The WebService for Consent
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 25/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          25/03/2025		1000				Initial Version
******************************************************************************************************/
@RestResource(urlMapping='/bunningsconsent/*')
global with sharing class Consent_ConsentManager {
    
    /**
    * @description  createConsent() - runs the business logic for HTTPPost
    * @author Juan Cutrera | 25/03/2025 
    **/
    @HttpPost
    global static void createConsent(){
        RestRequest request = RestContext.request;
        Consent_ConsentManagerHandler.createConsent(request.requestBody.toString());
    } 
    
    
}