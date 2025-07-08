/*******************************************************************************************************
* Class Name      	: Consent_ConsentManagerHandler
* @description		: Handler - Handles the logic for Consent_ConsentManager
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 25/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          25/03/2025		1000				Initial Version
******************************************************************************************************/
public class Consent_ConsentManagerHandler {
    
    /*** Global variables ***/
    static Consent_ConsentManagerPayload wrapper;
    /*** End of Global Variables ***/

    
    /**
    * @description  createConsent() - Handles the business logic for Web Service Consent
    * @author Juan Cutrera | 25/03/2025
    * @param jsonString
    **/
    public static void createConsent(String jsonString){
        
        try{
           	wrapper = Consent_ConsentManagerPayload.parse(jsonString);
            if(wrapper.getEntity() == null){
                throw new Consent_ConsentManagerHandlerException('Entity could not be read');
            }
        }catch(Exception e){
            SM_WebServiceResponses.returnError(415, 'The entity in the request is in a format thats not supported by the specified method.', 'Consent_ConsentManagerHandler.createConsent()', e);
            return;
        }
        //System.debug('$$$ Wrapper: ' + wrapper);
        Consent_ConsentManagerPayload.Entity currentEntity = wrapper.getEntity();
               
            
        //Validation for minimum requirements
        if(hasMinimumRequirments(currentEntity)){
            
            try {
                    
                
                //create Variables
                List<Account> matchedAccounts = new List<Account>();
                entityToUpload newEntity;
                Map<String,List<Consent_ConsentManagerPayload.ContactPoint>> contactPointsByType = currentEntity.getPerson().getContactPointsByType();
                
                /**
                 * BUILD IN MEMORY
                 */
                    //BUILD IN MEMORY
                    newEntity = new EntityToUpload();
                    newEntity.personIndividual = SM_Individual.buildNewIndividual(currentEntity); //build Individual
                    newEntity.personAccount = SM_Account.buildNewAccount(currentEntity); //build Person Account

                    //Add Phones, Emails and Addresses
                    //Phone
                    //Email
                    //Address
                    
                    newEntity.listOfPhones = new List<ContactPointPhone>();
                if(contactPointsByType.get('Phone') != null && !contactPointsByType.get('Phone').isEmpty() ){
                    
                    ContactPointPhone newPhone;
                    
                    for(Consent_ConsentManagerPayload.ContactPoint currentPhone : contactPointsByType.get('Phone')){
                        newPhone = SM_ContactPointPhone.buildNewContactPointPhone(currentPhone);
                        if(newPhone != null){
                            newEntity.listOfPhones.add(newPhone);
                        }
                        
                    }
                }
                
                newEntity.listOfEmails = new List<ContactPointEmail>();
                if(contactPointsByType.get('Email') != null && !contactPointsByType.get('Email').isEmpty()){
                    
                    ContactPointEmail newEmail;
                    
                    for(Consent_ConsentManagerPayload.ContactPoint currentEmail : contactPointsByType.get('Email')){
                        newEmail = SM_ContactPointEmail.buildNewContactPointEmail(currentEmail);
                        if(newEmail != null){
                            newEntity.listOfEmails.add(newEmail);
                        }   
                    }
                }
                
                newEntity.listOfAddresses = new List<ContactPointAddress>();
                if(contactPointsByType.get('Address') != null && !contactPointsByType.get('Address').isEmpty()){
                    
                    ContactPointAddress newAddress;

                    
                    for(Consent_ConsentManagerPayload.ContactPoint currentAddress : contactPointsByType.get('Address')){
                        newAddress = SM_ContactPointAddress.buildNewContactPointAddress(currentAddress);
                        if(newAddress != null){
                            newEntity.listOfAddresses.add(newAddress);
                        }   
                    }
                }
                
                //Authorization FormConsent section
                newEntity.authFormConsent = SM_AuthorizationFormConsent.buildNewAuthorizationFormConsent(currentEntity);
                
                //Authorization Form Text ID
                if(currentEntity.getConsent() != null){
                    
                    Consent_ConsentManagerPayload.Consent currentConsent = currentEntity.getConsent();
                    if(currentConsent.getDataUsePurpose() != null){
                        Consent_ConsentManagerPayload.DataUsePurpose currentDataUsePurpose = currentConsent.getDataUsePurpose();
                        if(currentDataUsePurpose.getCode() != null){
                            //Call DM_AuthorizationFormText to get Authorization Form Text Id where the ExternalId__c = DataUsePurpose.code
                            //If nothing is found return error saying "Purpose Code not found" 
                                //May be best to put it outside of this class
                                newEntity.authorizationFormTextExternalId = currentDataUsePurpose.getCode();
                            }
                    }
                }
                
                /**
                 * End ofBUILD IN MEMORY
                 */
                
                //INSERT AND UPSERT SECTION METHOD
                //first Upsert Individual
                //iterate through person accounts in memory and update individualId
                //Iterate through contactPointPhone in memory and update individualId
                //Iterate through contactPointEmail in memory and update individualId
                //Iterate through contactPointAddress in memory and update individualId
                //Iterate through AuthorizationFormConsent in memory and update individualId
                //Iterate through the memory and update the IndividualID
                //INSERT AND UPSERT SECTION
                Savepoint sp;
                try {
                    sp = Database.setSavepoint();
                    newEntity.upsertEntityToUpload();
                } catch (Exception e) {
                    Database.rollback(sp);
                    SM_WebServiceResponses.returnError(403, 'The request has been refused. There was an error inserting the entity','Consent_ConsentManagerHandler.entityToUpload.upsertEntityToUpload()',e);
                    return; 
                }
        
                SM_WebServiceResponses.returnSuccess(201,'Successful operation.',DM_FeatureToggle.getFeatureToggleEnabled('Consent_Log_Successful_Payload'),'Consent_ConsentManagerHandler.createConsent()');
                return;  
            } catch (Exception e) {
                SM_WebServiceResponses.returnError(404,'The requested resource couldnt be found. Check the URI for errors, and verify that there are no sharing issues.','Consent_ConsentManagerHandler.createConsent()',e);
            } 
        }else{
            //Not sufficient minimum requirements!
            SM_WebServiceResponses.returnError(403, 'The request has been refused. No email or Mobile Phone found in payload','Consent_ConsentManagerHandler.createConsent()', null);
            return;
        }
        
    }
    
    
    /**
    * @description  hasMinimumRequirements - Checks that the currentEntity has the minimum requirments in order to continue.
    * 											It needs a minimum either a Mobile Phone or Email
    * @author Juan Cutrera | 27/03/2025
    * @param currentEntity
    * @return boolean
    **/
    @TestVisible
    private static boolean hasMinimumRequirments(Consent_ConsentManagerPayload.Entity currentEntity){
        
        
        boolean hasMobileOrEmail = false;
        //get contactPoints related to this Entity
        List<Consent_ConsentManagerPayload.ContactPoint> contactPointList = new List<Consent_ConsentManagerPayload.ContactPoint>();
        Consent_ConsentManagerPayload.Person currentPerson = currentEntity.getPerson();
        if(currentEntity.getPerson() == null){
            return false;
        }
        contactPointList = currentEntity?.getPerson()?.getContactPoints();
        
        
        if(contactPointList == null){
            return false;
        }
        
        //check if empty
        if(!contactPointList?.isEmpty()){
            //Iterate through the contactPoints 
            for(Consent_ConsentManagerPayload.ContactPoint currentContactPoint : contactPointList){
                String contactPointType = currentContactPoint.getType();
                if(contactPointType != null){
                    contactPointType = contactPointType.capitalize();
                    switch on contactPointType {  
                        when 'Phone' {
                            if(currentContactPoint.getPhone() != null && currentContactPoint?.getPhone().isMobile()){
                                if(currentContactPoint.getPhone().getPhoneNumber() != null){
                                    hasMobileOrEmail = true;
                                    break;
                                }
                            }
                        } 
                        when 'Email' {
                            if(currentContactPoint.getEmail() != null){
                                hasMobileOrEmail = true;
                                break;
                            }
                        }
                    } 
                }
                          
             }
        }
        
       	
        
        
        
        return hasMobileOrEmail;
    }
    
    
        
    /*******************************************************************************************************
    * Class Name      	: entityToUpload
    * @description		: A Class containing the Entities that successfully need to be created
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 25/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          25/03/2025		1000				Initial Version
    ******************************************************************************************************/
    private class entityToUpload {
        Account personAccount;
        Individual personIndividual;
        List<ContactPointPhone> listOfPhones;
        List<ContactPointEmail> listOfEmails;
        List<ContactPointAddress> listOfAddresses;
        AuthorizationFormConsent authFormConsent;
        String authorizationFormTextExternalId;
        
        
        //Have methods so that you can add to PersonAccount for example all the fields needed without needing to repeat
        public void upsertEntityToUpload(){
            
                        
                    System.debug('### personAccount: ' + personAccount);
                    System.debug('### personIndividual: ' + personIndividual);
                    System.debug('### listOfPhones: ' + listOfPhones);
                    System.debug('### listOfEmails: ' + listOfEmails);
                    System.debug('### listOfAddresses: ' + listOfAddresses);
                    System.debug('### authFormConsent: ' + authFormConsent);
                    System.debug('### authorizationFormTextExternalId: ' + authorizationFormTextExternalId);

                    
                    // //Upsert the entity to upload
                    // //Iterate through person accounts in memory and update individualId
                    // //Iterate through contactPointPhone in memory and update individualId
                    // //Iterate through contactPointEmail in memory and update individualId
                    // //Iterate through contactPointAddress in memory and update individualId
                    // //Iterate through AuthorizationFormConsent in memory and update individualId
                    // //Iterate through the memory and update the IndividualID
                    // Id individualId = SM_Individual.upsertIndividual(personIndividual).Id;
                    //Upsert the entity to upload
                    handleConsentCapture(personAccount, personIndividual, listOfEmails, listOfPhones, listOfAddresses, authFormConsent, authorizationFormTextExternalId);
            }

        /**
         * @description Create/Update Person Account, Individual, and Contact Point records based on matching data. Create consent records against the matched records.
         * @param a Person Account record to be created/updated - all data staged except for record Id and PersonIndividualId.
         * @param i Individual record to be created/updated - all data staged except for record Id.
         * @param cpes Contact Point Email records to be created - all data staged except for record IDs and ParentId.
         * @param cpps Contact Point Phone records to be created - all data staged except for record IDs and ParentId.
         * @param cpas Contact Point Address records to be created - all data staged except for record IDs and ParentId.
         * @param afc Authorization form consent record to be created - all data staged except for record ID and ConsentGiverId.
         * @param authorizationFormTextExternalId Unique identifier of an authorization form text record (External_ID__c)
         */
        private void handleConsentCapture(Account a, Individual i, List<ContactPointEmail> cpes, List<ContactPointPhone> cpps, List<ContactPointAddress> cpas, AuthorizationFormConsent afc, String authorizationFormTextExternalId){
            
            // CREATE/MODIFY PERSON ACCOUNT AND INDIVIDUAL RECORDS
            // ----------------------------------------------------------------------------------------------------------------------------------------------------------
            // Get matching person accounts by mobile phone or email - ordered so that the last modified Person Account is first in the list.
            String email = String.isNotBlank(a.personEmail) ? a.personEmail.toString() : null;
            String mobile = String.isNotBlank(a.personMobilePhone) ? a.personMobilePhone.toString() : null;
            List<Account> matchingPersonAccounts = SM_MatchingRulesHelper.getPersonAccountsBasedOnEmailOrMobile(email, mobile);
            System.debug('### matchingPersonAccounts: ' + matchingPersonAccounts);
            List<Account> accountsToUpdate = new List<Account>();
            Individual individualToUpdate = new Individual();

            /**
             * go through the person accounts list from above
             * create a new list which either contains all of them or maybe is empty (which is the ACTUAL matching person accounts)
             * Really its 2.a and 2.c that add to the matching Rules
             * Exact match (mobile and email address)
             * Mobile matches and email is blank
             * Email matches and mobile is blank
             * matchingPersonAccounts = newList that was updated
             */
            List<Account> refinedMatchedPersonAccounts = new List<Account>();
            
            for(Account currentAccount : matchingPersonAccounts){
                //Check first what is not blank from the account
                Boolean isAccountPersonMobilePhoneNotBlank = String.isNotBlank(currentAccount.personMobilePhone);
                Boolean isAccountPersonEmailNotBlank = String.isNotBlank(currentAccount.personEmail);

                //Then based on the above compare to the values from payload
                if(isAccountPersonMobilePhoneNotBlank && isAccountPersonEmailNotBlank){ /* verify Both Mobile and Email */
                    if(currentAccount.personMobilePhone.equalsIgnoreCase(mobile) &&
                        currentAccount.personEmail.equalsIgnoreCase(email))
                        {
                            refinedMatchedPersonAccounts.add(currentAccount); 
                        }
                }else if(isAccountPersonMobilePhoneNotBlank && !isAccountPersonEmailNotBlank){/* Check Mobile only */
                    if(currentAccount.personMobilePhone.equalsIgnoreCase(mobile)){
                        refinedMatchedPersonAccounts.add(currentAccount);
                    }
                }else if(!isAccountPersonMobilePhoneNotBlank && isAccountPersonEmailNotBlank){/* Check Email only */
                    if(currentAccount.personEmail.equalsIgnoreCase(email)){
                        refinedMatchedPersonAccounts.add(currentAccount);
                    }
                }
            }
            
            System.debug('#### refinedMatchedPersonAccouns: ' + refinedMatchedPersonAccounts);
            

            matchingPersonAccounts = refinedMatchedPersonAccounts;

            // Based on the matching person accounts (or no matches) found, create/update Person Account and Individual records.
            if(matchingPersonAccounts.size() > 1){
                
                // If more than one matching Person Account is found
                List<Id> individualIds = new List<Id>();
                for(Account acc : matchingPersonAccounts){
                    individualIds.add(acc.PersonIndividualId);

                    // Construct an Account record to update
                    Account updatedAccount = new Account();
                    updatedAccount.Id = acc.Id;
                    updatedAccount.FirstName = a.FirstName;
                    updatedAccount.LastName = a.LastName;
                    updatedAccount.PersonMobilePhone = String.isNotBlank(a.PersonMobilePhone) ? a.PersonMobilePhone : updatedAccount.PersonMobilePhone;
                    updatedAccount.PersonEmail = String.isNotBlank(updatedAccount.PersonEmail) ? a.PersonEmail : updatedAccount.PersonEmail;


                    System.debug('### updatedAccount: ' + updatedAccount);
                    System.debug('### a.PersonEmail: ' + String.isNotEmpty(a.PersonEmail));
                    accountsToUpdate.add(updatedAccount);
                }

                // If at least one matching Person account has an Individual, get a list of all Individuals with the last modified Individual at the start of the list
                if(individualIds.size() > 0){
                    List<Individual> matchingPersonAccountIndividuals = SM_MatchingRulesHelper.getIndividualsByIds(individualIds);
                    // Only update the FirstName and LastName of the primary individual
                    // Hardcoding to get the first item of the array should be safe because we have already previously checked that at least one Individual should exist in the list
                    individualToUpdate.Id = matchingPersonAccountIndividuals[0].Id;
                    individualToUpdate.FirstName = i.FirstName;
                    individualToUpdate.LastName = i.LastName;
                    if(matchingPersonAccountIndividuals.size() > 1){
                        // If more than one Individual is found, create a task for an admin to clean up duplicates
                        Task t = new Task();
                        t.OwnerId = Consent_Setting__mdt.getInstance('Consent_Setting').Duplicate_Individual_Alert_User_ID__c;
                        t.Subject = 'Duplicate Individuals - ' + a.FirstName + ' ' + a.LastName;
                        t.Description = 'Duplicate Individuals detected for ' + a.FirstName + ' ' + a.LastName + '\n\n' +
                                        'Parent Individual ID: ' + individualToUpdate.Id + '\n\n' +
                                        'Duplicate Individual IDs:\n';
                        for(Individual ind : matchingPersonAccountIndividuals){
                            if(ind.Id != individualToUpdate.Id){
                                t.Description += ind.Id + '\n';
                            }
                        }
                        SM_Task.insertTask(t);
                    }
                }
                else{
                    // No individuals exist - create a new Individual
                    individualToUpdate = i;
                }
            }
            else if(matchingPersonAccounts.size() == 1){
                Account updatedAccount = new Account();
                Account matchedPersonAccount = matchingPersonAccounts[0];
                System.debug('#### In Matching accounts = 1');
                updatedAccount.Id = matchedPersonAccount.Id;
                updatedAccount.FirstName = a.FirstName;
                updatedAccount.LastName = a.LastName;
                updatedAccount.PersonEmail = String.isNotBlank(a.PersonEmail) ? a.PersonEmail : matchedPersonAccount.PersonEmail;
                updatedAccount.PersonMobilePhone = String.isNotBlank(a.PersonMobilePhone)  ? a.PersonMobilePhone : matchedPersonAccount.PersonMobilePhone;
                if(matchedPersonAccount.PersonIndividualId != null){
                                // If an Individual already exists, update only FirstName and LastName
                                individualToUpdate.Id = matchedPersonAccount.PersonIndividualId;
                                individualToUpdate.FirstName = i.FirstName;
                                individualToUpdate.LastName = i.LastName;
                            }
                            else{
                                // If no Individual exists, create a new one
                                individualToUpdate = i;
                }
                accountsToUpdate.add(updatedAccount);
                            
            }
            else{
                // 0 match found
                accountsToUpdate.add(a);
                individualToUpdate = i;
            }
            

            SM_Individual.upsertIndividual(individualToUpdate);

            // Link the upserted account(s) to the same parent Individual
            for(Account acc : accountsToUpdate){
                acc.PersonIndividualId = individualToUpdate.Id;
            }

            if(!accountsToUpdate.isEmpty()){
                SM_Account.upsertAccountList(accountsToUpdate);
            }



            // CREATE CONTACTPOINTEMAIL RECORDS FOR THE INDIVIDUAL WITHOUT CREATING DUPLICATES
            // ----------------------------------------------------------------------------------------------------------------------------------------------------------
            List<ContactPointEmail> individualCpes = SM_MatchingRulesHelper.getContactPointEmailsByParentId(individualToUpdate.Id);
            // Map of ContactPointEmails using EmailAddress as a key. It is assumed that for an Individual, all child ContactPointEmails will have unique emails
            Map<String, ContactPointEmail> individualCpesMap = new Map<String, ContactPointEmail>();
            for(ContactPointEmail cpe : individualCpes){
                individualCpesMap.put(cpe.EmailAddress.toLowerCase(), cpe);
            }
            for(ContactPointEmail cpe : cpes){
                if(individualCpesMap.get(cpe.EmailAddress.toLowerCase()) != null){
                    // If there is an existing ContactPointEmail with the same email address, use the existing record
                    cpe.Id = individualCpesMap.get(cpe.EmailAddress.toLowerCase()).Id;
                }
                cpe.ParentId = individualToUpdate.Id;
            }
            SM_ContactPointEmail.upsertContactPointEmails(cpes);

            

            // CREATE CONTACTPOINTPHONE RECORDS FOR THE INDIVIDUAL WITHOUT CREATING DUPLICATES
            // ----------------------------------------------------------------------------------------------------------------------------------------------------------
            List<ContactPointPhone> individualCpps = SM_MatchingRulesHelper.getContactPointPhonesByParentId(individualToUpdate.Id);
            // Map of ContactPointPhones using TelephoneNumber as a key. It is assumed that for an Individual, all child ContactPointPhone will have unique numbers
            Map<String, ContactPointPhone> individualCppsMap = new Map<String, ContactPointPhone>();
            for(ContactPointPhone cpp : individualCpps){
                individualCppsMap.put(cpp.TelephoneNumber, cpp);
            }
            for(ContactPointPhone cpp : cpps){
                if(individualCppsMap.get(cpp.TelephoneNumber) != null){
                    // If there is an existing ContactPointPhone with the same phone number, use the existing record
                    cpp.Id = individualCppsMap.get(cpp.TelephoneNumber).Id;
                }
                cpp.ParentId = individualToUpdate.Id;
            }
            SM_ContactPointPhone.upsertContactPointPhones(cpps);



            // CREATE CONTACTPOINTADDRESS RECORDS FOR THE INDIVIDUAL WITHOUT CREATING DUPLICATES
            // ----------------------------------------------------------------------------------------------------------------------------------------------------------
            List<ContactPointAddress> individualCpas = SM_MatchingRulesHelper.getContactPointAddressesByParentId(individualToUpdate.Id);
            // Map of ContactPointAddress using a combination of Address values as a key. It is assumed that for an Individual, all child ContactPointAddress will have unique address values
            Map<String, ContactPointAddress> individualCpasMap = new Map<String, ContactPointAddress>();
            for(ContactPointAddress cpa : individualCpas){
                String cpaKey = (cpa.Street != null ? cpa.Street.trim() : '') + '-' +
                                (cpa.City != null ? cpa.City.trim() : '') + '-' +
                                (cpa.State != null ? cpa.State.trim() : '') + '-' +
                                (cpa.Country != null ? cpa.Country.trim() : '') + '-' +
                                (cpa.PostalCode != null ? cpa.PostalCode.trim() : '');
                individualCpasMap.put(cpaKey, cpa);
            }
            
            for(ContactPointAddress cpa : cpas){
                String cpaKey = (cpa.Street != null ? cpa.Street.trim() : '') + '-' +
                                (cpa.City != null ? cpa.City.trim() : '') + '-' +
                                (cpa.State != null ? cpa.State.trim() : '') + '-' +
                                (cpa.Country != null ? cpa.Country.trim() : '') + '-' +
                                (cpa.PostalCode != null ? cpa.PostalCode.trim() : '');
                if(individualCpasMap.get(cpaKey) != null){
                    // If there is an existing ContactPointAddress with the same key, use the existing record
                    cpa.Id = individualCpasMap.get(cpaKey).Id;
                }
                cpa.ParentId = individualToUpdate.Id;
                if(cpa.Name == null){
                    // If the ContactPointAddress record doesn't have a Name explicitly set, construct one
                    cpa.Name = '';
                    cpa.Name = String.isNotBlank(a.FirstName) ? a.FirstName : cpa.Name;
                    cpa.Name = String.isNotBlank(a.LastName) ? cpa.Name + ' ' + a.LastName : cpa.Name;
                    cpa.Name = String.isNotBlank(cpa.Street) ? cpa.Name + ' - ' + cpa.Street : cpa.Name;
                }
            }
            SM_ContactPointAddress.upsertContactPointAddresses(cpas);



            // CREATE AUTHORIZATIONFORMCONSENT RECORD
            // ----------------------------------------------------------------------------------------------------------------------------------------------------------
            // Get AuthorizationFormText record by External ID
            AuthorizationFormText aft = SM_MatchingRulesHelper.getAuthorizationFormTextByExternalId(authorizationFormTextExternalId);
            if(aft == null){
                throw new Consent_ConsentManagerHandlerException('Authorization Form Text not found for ExternalId: ' + authorizationFormTextExternalId);
            }
            afc.AuthorizationFormTextId =  aft.Id;
            afc.ConsentGiverId = individualToUpdate.Id;
            afc.Consent_Consent_Giver_Individual_Only__c = individualToUpdate.Id;
            if(afc.Name == null){
                // If the AuthorizationFormConsent does not already have an explicit name, construct one
                afc.Name = (a.FirstName + ' ' + a.LastName + ' - ' + aft.Name + ' - ' + afc.ConsentCapturedDateTime.format()).left(255);
            }
            SM_AuthorizationFormConsent.insertAuthorizationFormConsent(afc);

        }
    }
    
    private class Consent_ConsentManagerHandlerException extends Exception{}
}