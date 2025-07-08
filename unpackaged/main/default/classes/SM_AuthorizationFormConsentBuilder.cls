/*******************************************************************************************************
* Class Name      	: SM_AuthorizationFormConsentBuilder
* @description		: Service layer - To create AuthorizationFormConsent records easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_AuthorizationFormConsentBuilder implements Builder {
    private AuthorizationFormConsent newAuthorizationFormConsent = new AuthorizationFormConsent();

    /**
    * @description  setName - Sets the name of the AuthorizationFormConsent
    * @author Juan Cutrera | 04/04/2025
    * @param name The name to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setName(String name) {
        newAuthorizationFormConsent.Name = name;
        return this;
    }

    /**
    * @description  setAuthorizationFormTextId - Sets the AuthorizationFormTextId
    * @author Juan Cutrera | 04/04/2025
    * @param authorizationFormText The AuthorizationFormTextId to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setAuthorizationFormTextId(String AuthorizationFormTextId) {
        newAuthorizationFormConsent.AuthorizationFormTextId = authorizationFormTextId;
        return this;
    }

    /**
    * @description  setConsentGiverIndividualOnly - Sets the Consent Giver Individual Only field
    * @author Juan Cutrera | 04/04/2025
    * @param consentGiverIndividualOnly The value to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setConsentGiverIndividualOnly(String consentGiverIndividualOnly) {
        newAuthorizationFormConsent.Consent_Consent_Giver_Individual_Only__c = consentGiverIndividualOnly;
        return this;
    }

    /**
    * @description  setConsentCaptureDateTime - Sets the Consent Capture DateTime field
    * @author Juan Cutrera | 04/04/2025
    * @param consentCaptureDateTime The DateTime to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setConsentCaptureDateTime(DateTime consentCaptureDateTime) {
        newAuthorizationFormConsent.ConsentCapturedDateTime = consentCaptureDateTime;
        return this;
    }

    /**
    * @description  setConsentCapturedSource - Sets the Consent Capture Source field
    * @author Juan Cutrera | 04/04/2025
    * @param consentCapturedSource The source to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setConsentCapturedSource(String consentCapturedSource) {
        newAuthorizationFormConsent.ConsentCapturedSource = consentCapturedSource;
        return this;
    }

    /**
    * @description  setConsentCapturedSourceType - Sets the Consent Captured Source Type field
    * @author Juan Cutrera | 04/04/2025
    * @param consentCapturedSourceType The source type to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setConsentCapturedSourceType(String consentCapturedSourceType) {
        newAuthorizationFormConsent.ConsentCapturedSourceType = consentCapturedSourceType;
        return this;
    }

    /**
    * @description  setCreatedBySourceSystemModule - Sets the Source System Module field
    * @author Juan Cutrera | 04/04/2025
    * @param createdBySourceSystemModule The module to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setCreatedBySourceSystemModule(String createdBySourceSystemModule) {
        newAuthorizationFormConsent.SourceSystemModule__c = createdBySourceSystemModule;
        return this;
    }

    /**
    * @description  setCreatedBySourceReferenceId - Sets the Source Reference ID field
    * @author Juan Cutrera | 04/04/2025
    * @param createdBySourceReferenceId The reference ID to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setCreatedBySourceReferenceId(String createdBySourceReferenceId) {
        newAuthorizationFormConsent.SourceReferenceId__c = createdBySourceReferenceId;
        return this;
    }

    /**
    * @description  setSourceCustomerId - Sets the Source Customer ID field
    * @author Juan Cutrera | 04/04/2025
    * @param sourceCustomerId The customer ID to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setSourceCustomerId(String sourceCustomerId) {
        newAuthorizationFormConsent.SourceCustomerId__c = sourceCustomerId;
        return this;
    }

    /**
    * @description  setStoreLocationCode - Sets the Store Location Code field
    * @author Juan Cutrera | 04/04/2025
    * @param storeLocationCode The location code to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setStoreLocationCode(String storeLocationCode) {
        newAuthorizationFormConsent.Location__c = storeLocationCode;
        return this;
    }

    /**
    * @description  setStatus - Sets the Status field after validating it against picklist values
    * @author Juan Cutrera | 04/04/2025
    * @param status The status to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setStatus(String status) {
        Set<String> validStatus = getPicklistValues('Status');
        if (validStatus.contains(status)) {
            newAuthorizationFormConsent.Status = status;
        } else {
            throw new IllegalArgumentException('Invalid Status: ' + status);
        }
        return this;
    }

    /**
    * @description  setPowerPassCardNumber - Sets the PowerPass Card Number field
    * @author Juan Cutrera | 04/04/2025
    * @param powerPassCardNumber The card number to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setPowerPassCardNumber(String powerPassCardNumber) {
        newAuthorizationFormConsent.Pp_Card_Number__c = powerPassCardNumber;
        return this;
    }

    /**
    * @description  setPowerPassAccountNumber - Sets the PowerPass Account Number field
    * @author Juan Cutrera | 04/04/2025
    * @param powerPassAccountNumber The account number to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setPowerPassAccountNumber(String powerPassAccountNumber) {
        newAuthorizationFormConsent.Pp_Account_Number__c = powerPassAccountNumber;
        return this;
    }

    /**
    * @description  setTeamMemberCard - Sets the Team Member Card field
    * @author Juan Cutrera | 04/04/2025
    * @param teamMemberCard The card number to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setTeamMemberCard(String teamMemberCard) {
        newAuthorizationFormConsent.Tm_Card_Number__c = teamMemberCard;
        return this;
    }

    /**
    * @description  setTeamMemberEmployeeNumber - Sets the Team Member Employee Number field
    * @author Juan Cutrera | 04/04/2025
    * @param teamMemberEmployeeNumber The employee number to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setTeamMemberEmployeeNumber(String teamMemberEmployeeNumber) {
        newAuthorizationFormConsent.Tm_Employee_Number__c = teamMemberEmployeeNumber;
        return this;
    }

    /**
    * @description  setCountry - Sets the Country field after validating it against picklist values
    * @author Juan Cutrera | 04/04/2025
    * @param country The country to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setCountry(String country) {
        Set<String> validCountry = getPicklistValues('Country__c');
        if (validCountry.contains(country)) {
            newAuthorizationFormConsent.Country__c = country;
        } else {
            throw new IllegalArgumentException('Invalid Country: ' + country);
        }
        return this;
    }

    /**
    * @description  setOwnerId - Sets the Owner ID field
    * @author Juan Cutrera | 04/04/2025
    * @param ownerId The owner ID to set
    * @return SM_AuthorizationFormConsentBuilder
    **/
    public SM_AuthorizationFormConsentBuilder setOwnerId(String ownerId) {
        newAuthorizationFormConsent.OwnerId = ownerId;
        return this;
    }

    /**
     * @description setMessageId - Sets the Message ID field
     * @author Juan M. Cutrera
     * @param  messageId messageId to set
     * @return SM_AuthorizationFormConsentBuilder
     */
    public SM_AuthorizationFormConsentBuilder setMessageId(String messageId){
        //check first its length is greater than 255 if so, then trim it
        if(messageId != null && messageId.length() > 255){
            messageId = messageId.substring(0, 255);
        }
        newAuthorizationFormConsent.Message_Id__c = messageId;
        return this;
    }

    /**
    * @description  getPicklistValues - Get valid picklist values dynamically for a given field
    * @author Juan Cutrera | 04/04/2025
    * @param fieldName The API name of the field
    * @return Set<String>
    **/
    private static Set<String> getPicklistValues(String fieldName) {
        Set<String> validValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.AuthorizationFormConsent.fields.getMap().get(fieldName).getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            validValues.add(entry.getValue());
        }
        return validValues;
    }

    /**
    * @description  build - Builds and returns the AuthorizationFormConsent object
    * @author Juan Cutrera | 04/04/2025
    * @return AuthorizationFormConsent
    **/
    public AuthorizationFormConsent build() {
        return newAuthorizationFormConsent;
    }
}