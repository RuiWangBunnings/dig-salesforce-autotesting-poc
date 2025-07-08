/*******************************************************************************************************
* Class Name      	: SM_AuthorizationFormConsent
* @description		: Domain / Service layer for AuthorizationFormConsent
* @author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class SM_AuthorizationFormConsent {
    
    /**
    * @description  buildNewAuthorizationFormConsent - Build a new buildNewAuthorizationFormConsent
    * @author Juan Cutrera | 08/04/2025
    * @param currentEntity
    * @return ContactPointEmail
    **/
    public static AuthorizationFormConsent buildNewAuthorizationFormConsent(Consent_ConsentManagerPayload.Entity currentEntity){
        SM_AuthorizationFormConsentBuilder builder = new SM_AuthorizationFormConsentBuilder();
        String AuthorizationFormConsentName;
        //null checks
        if(currentEntity == null){
            return null;
        }
        if(currentEntity.getPerson() != null){
            Consent_ConsentManagerPayload.Person currentPerson = currentEntity.getPerson();


            //Check that fullName, first Name and LastName exist
            //Concat of PersonName + Hireshop Agreement e.g. John Doe - Hire Shop Agreement 2023
            String personName = currentPerson.getFullName() == null ? currentPerson.getFirstName() + ' ' +   currentPerson.getLastName() : currentPerson.getFullName();
            AuthorizationFormConsentName = personName;
            //TODO where to get Agreement?
        
            builder.setName(personName);
            if(currentEntity.getCountryCode() != null){
                builder.setCountry(currentEntity.getCountryCode());
            }

            if(currentPerson.getAccount()!= null){
                Consent_ConsentManagerPayload.MyAccount currentAccount = currentPerson.getAccount();
                builder.setPowerPassAccountNumber(currentAccount.getAccountNumber());

                if(currentAccount.getCard() != null){
                    Consent_ConsentManagerPayload.Card currentCard = currentAccount.getCard();
                    if(currentCard.getCardSequenceNumber() != null){
                        builder.setPowerPassCardNumber(currentCard.getCardSequenceNumber().toString());
                    }
                }

                if(currentAccount.getUser() != null){
                    Consent_ConsentManagerPayload.MyUser currentUser = currentAccount.getUser();
                    if(currentUser.getId() != null){
                        builder.setSourceCustomerId(currentUser.getId());
                    }
                }
            }

            if(currentPerson.getTeam() != null){
                Consent_ConsentManagerPayload.Team currentTeam = currentPerson.getTeam();
                if(currentTeam.getTeamMemberNumber() != null){
                    builder.setTeamMemberEmployeeNumber(currentTeam.getTeamMemberNumber());
                }
                if(currentTeam.getCardNumber() != null){
                    builder.setTeamMemberCard(currentTeam.getCardNumber());
                }
            }
            
    
    
            if(currentEntity.getConsent() != null){
                    
                Consent_ConsentManagerPayload.Consent currentConsent = currentEntity.getConsent();
                if(currentConsent.getEffectivePeriod() != null){
                    Consent_ConsentManagerPayload.EffectivePeriod currentEffectivePeriod = currentConsent.getEffectivePeriod();
                    if(currentEffectivePeriod.getStartDateTime() != null){
                        builder.setConsentCaptureDateTime((currentEffectivePeriod.getStartDateTime()));
                    }
                }
                // if(currentConsent.getDataUsePurpose() != null){
                //     Consent_ConsentManagerPayload.DataUsePurpose currentDataUsePurpose = currentConsent.getDataUsePurpose();
                //     if(currentDataUsePurpose.getCode() != null){
                //         AuthorizationFormConsentName =  AuthorizationFormConsentName + ' - ' + currentDataUsePurpose.getCode();
                //         //Call DM_AuthorizationFormText to get Authorization Form Text Id where the ExternalId__c = DataUsePurpose.code
                //         //If nothing is found return error saying "Purpose Code not found" 
                //         try {
                //             //May be best to put it outside of this class
                //             builder.setAuthorizationFormTextId(DM_AuthorizationFormText.getAuthorizationFormTextByExternalId(currentDataUsePurpose.getCode()).Id);
                //         } catch (Exception e) {
                //             throw new SM_AuthorizatioFormConsentException('Authorization Form Text not found for ExternalId: ' + currentDataUsePurpose.getCode());
                //         }
                //     }
                    
                // }
            }
        }

        if(currentEntity.getCapture() != null){
            Consent_ConsentManagerPayload.Capture currentCapture = currentEntity.getCapture();
            if(currentCapture.getSource() != null){
                builder.setConsentCapturedSource(currentCapture.getSource());
            }
            //By default we set the source type to In Person
            if(currentCapture.getEngagementChannel() != null){
                if(currentCapture.getEngagementChannel().equalsIgnoreCase('InStore')){
                    builder.setConsentCapturedSourceType('InPerson');
                }
            }
            if(currentCapture.getSourceModule() != null){
                builder.setCreatedBySourceSystemModule(currentCapture.getSourceModule());
            }
            if(currentCapture.getSourceReference() != null){
                builder.setCreatedBySourceReferenceId(currentCapture.getSourceReference());
            }
            if(currentCapture.getLocationCode() != null){
                builder.setStoreLocationCode(currentCapture.getLocationCode());
            }
            if(String.isNotBlank(currentCapture.getIdentifier())){
                builder.setMessageId(currentCapture.getIdentifier());
            }
        }

        if(currentEntity.getConsent() != null){
            Consent_ConsentManagerPayload.Consent currentConsent = currentEntity.getConsent();
            if(currentConsent.getConsentStatus() != null){
                builder.setStatus(currentConsent.getConsentStatus());
            }
        }
        return builder.build();
    }


    /**
     * @description insertAuthorizationFormConsent Insert an AuthorizationFormConsent that is in memory
     * @author Juan M. Cutrera
     * @param  authorizationFormConsent authorizationFormConsent description
     */
    public static void insertAuthorizationFormConsent(AuthorizationFormConsent authorizationFormConsent){
        try {
            Database.insert(authorizationFormConsent, true);
        } catch (Exception e) {
            throw new SM_AuthorizatioFormConsentException('AuthorizationFormConsent could not be created: ' + e.getMessage());
        } 
    }

    /*******************************************************************************************************
    * Class Name      	: SM_AuthorizatioFormConsentException
    * @description		: Exception class for SM_AuthorizatioFormConsent
    * @author          	: Juan Manual Cutrera
    * Created On      	: 08/04/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer					Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera             	08/04/2025		1000				Initial version
    ******************************************************************************************************/
    private class SM_AuthorizatioFormConsentException extends Exception {}

}