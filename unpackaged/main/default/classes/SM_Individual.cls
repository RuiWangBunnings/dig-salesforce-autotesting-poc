/*******************************************************************************************************
* Class Name      	: SM_Individual
* @description		: Service layer - To create Individuals easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 03/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          03/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_Individual {
    
    /**
    * @description  buildNewIndividual - Build a new Individual
    * @author Juan Cutrera | 03/04/2025
    * @param currentEntity
    * @return Account
    **/
    public static Individual buildNewIndividual(Consent_ConsentManagerPayload.Entity currentEntity){
        SM_IndividualBuilder myIndividual = new SM_IndividualBuilder();
        if(currentEntity != null){
            if(currentEntity.getCountryCode() != null){
                // myIndividual.setCountry(currentEntity.getCountryCode());
                myIndividual.setCountry('AU');
            }
            //Do all the fields that are not null in here
            if(currentEntity.getPerson() != null){
                Consent_ConsentManagerPayload.Person currentPerson = currentEntity.getPerson();
                System.debug('### Person: ' + currentPerson);
                if(String.isNotBlank(currentPerson.getFirstName()) && String.isNotBlank(currentPerson.getLastName())){
                    myIndividual.setFirstName(currentPerson.getFirstName());
                }
                if(String.isNotBlank(currentPerson.getLastName())){
                    myIndividual.setLastName(currentPerson.getLastName());
                }else if(String.isNotBlank(currentPerson.getFullName())){
                    myIndividual.setLastName(currentPerson.getFullName());
                }

                //State
                if(currentPerson.getContactPoint('Address') != null){
                    Consent_ConsentManagerPayload.ContactPoint currentContactPoint = currentPerson.getContactPoint('Address');

                    if(currentContactPoint.getAddress() != null){
                        if(currentContactPoint.getAddress().getStateCode() != null){
                            myIndividual.setState(currentContactPoint.getAddress().getStateCode());
                        }
                    }
                }
            }

            //Capture section
            if(currentEntity.getCapture() != null){
                Consent_ConsentManagerPayload.Capture currentCapture = currentEntity.getCapture();
                if(currentCapture.getSource() != null){
                    myIndividual.setSourceSystem(currentCapture.getSource());
                }
                if(currentCapture.getSourceModule() != null){
                    myIndividual.setSourceSystemModule(currentCapture.getSourceModule());
                }
                if(currentCapture.getSourceReference() != null){
                    myIndividual.setSourceCustomerId(currentCapture.getSourceReference());
                }
            }
        }
        return myIndividual.build();
    }

    /**
     * @description insertIndividual Insert an Individual that is in memory
     * @author Juan M. Cutrera
     * @param  individualToInsert 
     * @return Individual
     */
    public static Individual upsertIndividual(Individual individualToUpsert){
        
        try{
            DataBase.upsert(individualToUpsert,true);
        }catch(Exception e){
            ApplicationLogger.log('SM_Individual.insertIndividual','Individual','Web Service',e);
            throw new DmlException('Individual could not be created: ' + e.getMessage());
        }
        return individualToUpsert;
    }

}