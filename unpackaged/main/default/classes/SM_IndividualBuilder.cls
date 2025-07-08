/*******************************************************************************************************
* Class Name      	: SM_IndividualBuilder
* @description		: Service layer - To create Individuals easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 03/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          03/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_IndividualBuilder implements Builder {

    private Individual newIndividual = new Individual();

    /**
    * @description  setFirstName - Sets the first name of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param firstName The first name to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setFirstName(String firstName) {
        newIndividual.firstName = firstName;
        return this;
    }

    /**
    * @description  setLastName - Sets the last name of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param lastName The last name to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setLastName(String lastName) {
        newIndividual.lastName = lastName;
        return this;
    }

    /**
    * @description  setAccountOwner - Sets the account owner of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param ownerId The ID of the owner to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setAccountOwner(String ownerId) {
        newIndividual.OwnerId = ownerId;
        return this;
    }

    /**
    * @description  setCountry - Sets the country of the Individual and validates it
    * @author Juan Cutrera | 03/04/2025
    * @param country The country to set
    * @return SM_IndividualBuilder
    * @throws IllegalArgumentException if the country is invalid
    **/
    public SM_IndividualBuilder setCountry(String country) {
        Set<String> validCountries = getPicklistValues('Country__c');
        System.debug('### Country: ' + country);
        System.debug('### Valid Countries: ' + validCountries);
        if (validCountries.contains(country)) {
            newIndividual.Country__c = country;
        } else {
            throw new IllegalArgumentException('Invalid Individual Country: ' + country);
        }
        return this;
    }

    /**
    * @description  setState - Sets the state of the Individual and validates it
    * @author Juan Cutrera | 03/04/2025
    * @param state The state to set
    * @return SM_IndividualBuilder
    * @throws IllegalArgumentException if the state is invalid
    **/
    public SM_IndividualBuilder setState(String state) {
        Set<String> validStates = getPicklistValues('State__c');
        if (validStates.contains(state)) {
            newIndividual.State__c = state;
        } else {
            throw new IllegalArgumentException('Invalid Individual State: ' + state);
        }
        return this;
    }

    /**
    * @description  setSourceSystem - Sets the source system of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param sourceSystem The source system to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setSourceSystem(String sourceSystem) {
        newIndividual.SourceSystem__c = sourceSystem;
        return this;
    }

    /**
    * @description  setSourceSystemModule - Sets the source system module of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param sourceSystemModule The source system module to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setSourceSystemModule(String sourceSystemModule) {
        newIndividual.SourceSystemModule__c = sourceSystemModule;
        return this;
    }

    /**
    * @description  setSourceCustomerId - Sets the source customer ID of the Individual
    * @author Juan Cutrera | 03/04/2025
    * @param sourceCustomerId The source customer ID to set
    * @return SM_IndividualBuilder
    **/
    public SM_IndividualBuilder setSourceCustomerId(String sourceCustomerId) {
        newIndividual.SourceCustomerId__c = sourceCustomerId;
        return this;
    }

    /**
    * @description  getPicklistValues - Get valid picklist values dynamically
    * @author Juan Cutrera | 02/04/2025
    * @param fieldName The API name of the field
    * @return Set<String>
    **/
    private static Set<String> getPicklistValues(String fieldName) {
        Set<String> validValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Individual.fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            validValues.add(entry.getValue());
        }
        return validValues;
    }

    /**
    * @description  build - Build and return the configured Individual instance
    * @author Juan Cutrera | 03/04/2025
    * @return Individual
    **/
    public Individual build() {
        return newIndividual;
    }
}