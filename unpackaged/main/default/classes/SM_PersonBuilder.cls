/*******************************************************************************************************
* Class Name      	: SM_PersonBuilder
* @description		: Service layer - To create PersonAccounts easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 02/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          02/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_PersonBuilder implements Builder {
    private Account personAccount;
    
    
    //Constructor ensure the Account is Person Account RecordType
    public SM_PersonBuilder(){
        personAccount = new Account();
        personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
    }
    
    /**
     *  ACCOUNT INFORMATION
     */
    /**
     * @description setSalutation - Sets the salutation of the person account
     * @author Juan M. Cutrera
     * @param  salutation salutation - Sets the salutation of the person account
     * @return            SM_PersonBuilder description
     */
    public SM_PersonBuilder setSalutation(String salutation){
        personAccount.Salutation = salutation;
        return this;
    }
    
    /**
     * @description setFirstName - Sets the first name of the person account
     * @author Juan M. Cutrera
     * @param  firstName firstName - Sets the first name of the person account
     * @return           SM_PersonBuilder 
     */
    public SM_PersonBuilder setFirstName(String firstName) {
     	personAccount.firstName = firstName;
     	return this;
    }
    
    /**
     * @description setLastName - Sets the last name of the person account
     * @author Juan M. Cutrera
     * @param  lastName lastName - Sets the last name of the person account
     * @return          SM_PersonBuilder description
     */
    public SM_PersonBuilder setLastName(String lastName) {
         personAccount.lastName = lastName;
         return this;
    }
    
    /**
     * @description setAccountOwner - Sets the owner of the person account
     * @author Juan M. Cutrera
     * @param  ownerId ownerId - Sets the owner of the person account
     * @return         SM_PersonBuilder description
     */
    public SM_PersonBuilder setAccountOwner(String ownerId){
        personAccount.OwnerId = ownerId;
        return this;
    }
    
    /**
     * @description setPersonIndividual - Sets the person individual ID of the person account
     * @author Juan M. Cutrera
     * @param  personIndividualId personIndividualId - Sets the person individual ID of the person account
     * @return                    SM_PersonBuilder description
     */
    public SM_PersonBuilder setPersonIndividual(String personIndividualId){
        personAccount.PersonIndividualId = personIndividualId;
        return this;
    }
    /**
     * END OF ACCOUNT INFORMATION
     */
    
    /**
     *  CONTACT INFORMATION
     */
    /**
     * @description setEmail - Sets the email of the person account
     * @author Juan M. Cutrera
     * @param  email email - Sets the email of the person account
     * @return       SM_PersonBuilder description
     */
    public SM_PersonBuilder setEmail(String email){
        personAccount.personEmail = email;
        return this;
    }
    
    /**
     * @description setPersonMobilePhone - Sets the mobile phone of the person account
     * @author Juan M. Cutrera
     * @param  mobilePhone mobilePhone - Sets the mobile phone of the person account
     * @return             SM_PersonBuilder description
     */
    public SM_PersonBuilder setPersonMobilePhone(String mobilePhone){
        personAccount.personMobilePhone = mobilePhone;
        return this;
    }
    
    /**
     * @description setPersonOtherPhone - Sets the other phone of the person account
     * @author Juan M. Cutrera
     * @param  otherPhone otherPhone - Sets the other phone of the person account
     * @return            SM_PersonBuilder description
     */
    public SM_PersonBuilder setPersonOtherPhone(String otherPhone){
        personAccount.PersonOtherPhone = otherPhone;
        return this;
    }
    /**
     * END OF CONTACT INFORMATION
     */
    
    /**
     *  OTHER INFORMATION
     */
    /**
     * @description setPowerPassAccountNumber - Sets the power pass account number of the person account
     * @author Juan M. Cutrera
     * @param  powerPassAccountNumber powerPassAccountNumber - Sets the power pass account number of the person account
     * @return                        SM_PersonBuilder description
     */
    public SM_PersonBuilder setPowerPassAccountNumber(String powerPassAccountNumber){
        personAccount.Power_Pass_Account_Number__c = powerPassAccountNumber;
        return this;
    }
    
    /**
     * @description setDescription - Sets the description of the person account
     * @author Juan M. Cutrera
     * @param  description description - Sets the description of the person account
     * @return            SM_PersonBuilder description
     */
    public SM_PersonBuilder setDescription(String description){
        personAccount.Description__c = description;
        return this;
    }
    /**
     *  END OF OTHER INFORMATION
     */
    
    /**
     *  ADDRESS INFORMATION
     */
    /**
     * @description setAccountState - Sets the account state of the person account
     * @author Juan M. Cutrera
     * @param  accountState accountState - Sets the account state of the person account
     * @throws IllegalArgumentException if the account state is invalid
     * @return              SM_PersonBuilder description
     */
    public SM_PersonBuilder setAccountState(String accountState){
        // Get valid values for the Industry picklist
        Set<String> validAccountStates = getPicklistValues('Account_State__c');

        if (validAccountStates.contains(accountState)) {
            personAccount.Account_State__c = accountState;
        } else {
            //ENHANCEMENT make SM_PersonBuilderException and reference here
            throw new IllegalArgumentException('Invalid Account State: ' + accountState);
        }
        return this;
        
    }
    
    
    /**
     * @description setBillingAddress - Sets the billing address of the person account
     * @author Juan M. Cutrera
     * @param  street     street 
     * @param  city       city 
     * @param  state      state 
     * @param  postalCode postalCode 
     * @param  country    country 
     * @return            SM_PersonBuilder 
     */
    public SM_PersonBuilder setBillingAddress(String street, String city, String state, String postalCode, String country) {
        personAccount.BillingStreet = street;
        personAccount.BillingCity = city;
        personAccount.BillingState = state;
        personAccount.BillingPostalCode = postalCode;
        personAccount.BillingCountry = country;
        return this;
    }
    
    /**
     * @description setMailingAddress - Sets the mailing address of the person account
     * @author Juan M. Cutrera
     * @param  street     street 
     * @param  city       city 
     * @param  state      state 
     * @param  postalCode postalCode 
     * @param  country    country 
     * @return            SM_PersonBuilder description
     */
    public SM_PersonBuilder setMailingAddress(String street, String city, String state, String postalCode, String country) {
        personAccount.PersonMailingStreet = street;
        personAccount.PersonMailingCity = city;
        personAccount.PersonMailingState = state;
        personAccount.PersonMailingPostalCode = postalCode;
        personAccount.PersonMailingCountry = country;
        return this;
    }
    
   	/**
     * END OF ADDRESS INFORMATION
     */
    
    
    /**
     * @description setSourceSystem - Sets the source system of the person account
     * @author Juan M. Cutrera
     * @param  sourceSystem sourceSystem - Sets the source system of the person account
     * @return              SM_PersonBuilder description
     */
    public SM_PersonBuilder setSourceSystem(String sourceSystem){
        personAccount.SourceSystem__c = sourceSystem;
        return this;
    }
    
    /**
     * @description setSourceSystemModule - Sets the source system module of the person account
     * @author Juan M. Cutrera
     * @param  sourceSystemModule sourceSystemModule - Sets the source system module of the person account
     * @return                    SM_PersonBuilder description
     */
    public SM_PersonBuilder setSourceSystemModule(String sourceSystemModule){
        personAccount.SourceSystemModule__c = sourceSystemModule;
        return this;
    }
    /**
     *  END OF INFORMATION
     */
    
    

    /**
    * @description  getPicklistValues - Get valid picklist values dynamically
    * @author Juan Cutrera | 02/04/2025
    * @param fieldName
    * @return Set<String>
    **/
    private static Set<String> getPicklistValues(String fieldName) {
        Set<String> validValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Account.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            validValues.add(entry.getValue());
        }
        return validValues;
    }

    
    
    /**
    * @description  build - Build new Account
    * @author Juan Cutrera | 02/04/2025
    * @return Account
    **/
    public Account build(){
        return personAccount;  
    }

}