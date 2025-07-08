/*******************************************************************************************************
* Class Name      	: Consent_ConsentManagerPayload
* @description		: Wrapper for the ConsentPayload
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 27/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          27/03/2025		1000				Initial Version
******************************************************************************************************/
global class Consent_ConsentManagerPayload {

    // global Header header;
	global Entity entity;

    // global class Header {
    //     global string identifier;

    //     global string getIdentifier(){
    //         return identifier;
    //     }

    // }
    // global Header getHeader() {
    //     return header;
    // }

    /*******************************************************************************************************
    * Class Name      	: Entity
    * @description		: Inner Object class for Entity
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Entity {
        global string countryCode;
        global Consent consent;
        global Person person;
        global Capture capture;

        
        //Getter methods
        /**
        * @description  getCountryCode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return countryCode value
        **/
        global string getCountryCode(){
            return countryCode;
        }
        
        /**
        * @description  getConsent - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return consent value
        **/
        global Consent getConsent(){
            return consent;
        }
        
        /**
        * @description  getCapture - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return capture value
        **/
        global Capture getCapture(){
            return capture;
        }
        
        /**
        * @description  getPerson - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return person Object 
        **/
        global Person getPerson(){
            return person;
        }
        //End of Getter Methods
    }
    
    /*******************************************************************************************************
    * Class Name      	: Consent
    * @description		: Inner Object class for Consent
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Consent {
        global DataUsePurpose dataUsePurpose;
        global EffectivePeriod effectivePeriod;
		global string consentStatus;
        
        
        //Getter Methods
        /**
        * @description  getDataUsePurpose - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return DataUsePurpose object
        **/
        global DataUsePurpose getDataUsePurpose(){
            return dataUsePurpose;
        }
        
        /**
        * @description  getEffectivePeriod - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return EffectivePeriod object
        **/
        global EffectivePeriod getEffectivePeriod(){
            return effectivePeriod;
        }
        
        /**
        * @description  getConsentStatus - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return consentStatus value
        **/
        global String getConsentStatus(){
            return consentStatus;
        }
        //End of Getter Methods
    }
    
    /*******************************************************************************************************
    * Class Name      	: DataUsePurpose
    * @description		: Inner Object class for DataUsePurpose
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class DataUsePurpose {
        global string code;
        global string name;
        global string version;
        global DateTime asOfDateTime;
        
        //getter methods
        /**
        * @description  getCode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return code value
        **/
        global string getCode(){
        	return code;    
        }
        
        /**
        * @description  getName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return name value
        **/
        global string getName(){
            return name;
        }
        
        /**
        * @description  getVersion - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return version value
        **/
        global string getVersion(){
            return version;
        }
        
        /**
        * @description  getAsOfDateTime - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return asOfDateTime value
        **/
        global DateTime getAsOfDateTime(){
            return asOfDateTime;
        }
        //end of getter methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: EffectivePeriod
    * @description		: Inner Object class for EffectivePeriod
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class EffectivePeriod {
        global DateTime startDateTime;
        global DateTime endDateTime;
        
        //getter methods
        /**
        * @description  getStartDateTime - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return startDateTime value
        **/
        global DateTime getStartDateTime(){
            return startDateTime;
        }
        
        /**
        * @description  getEndDateTime - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return endDateTime value
        **/
        global DateTime getEndDateTime(){
            return endDateTime;
        }
        //end of getter methods
    }

    
    
    /*******************************************************************************************************
	* Class Name      	: Person
    * @description		: Inner Object class for Person
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Person { 
        global string name;
        global string firstName;
        global string lastName;
        global List<ContactPoint> contactPoints; 
        global MyAccount account;
        global Team team;
        
        
        //start of Getter Methods
        /**
        * @description  getFullName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return fullName value
        **/
        global String getFullName(){
            return name;
        }
        
        /**
        * @description  getFirstName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return firstName value
        **/
        global String getFirstName(){
            return firstName;
        }
        
        /**
        * @description  getLastName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return lastName value
        **/
        global String getLastName(){
            return lastName;
        }
        
        /**
        * @description  getContactPoints - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return list of ContactPoints 
        **/
        global List<ContactPoint> getContactPoints(){
            return contactPoints;
        }
        
        /**
        * @description  getContactPointsByType - get ContactPointsByType()
        * @author Juan Cutrera | 07/04/2025 
        * @return list of Map<String,List<ContactPoint>> 
        **/
        global Map<String,List<ContactPoint>> getContactPointsByType(){
            Map<String,List<ContactPoint>> contactPointsByTypeMap = new Map<String, List<ContactPoint>>();
            List<ContactPoint> contactPointList = getContactPoints();
            List<ContactPoint> contactPointTypeList;
            if(contactPointList != null){
               for(ContactPoint currentContactPoint : contactPointList){
                   String contactPointType = currentContactPoint.getType() != null ? currentContactPoint.getType().capitalize() : null;
                   switch on contactPointType {
                       when 'Phone'{
                           //Check if the map already contains the key
                           if(!contactPointsByTypeMap.containsKey('Phone')){
                               contactPointsByTypeMap.put('Phone', new List<ContactPoint>());
                           }
                           contactPointTypeList = contactPointsByTypeMap.get('Phone');
                            contactPointTypeList.add(currentContactPoint);  
                       }
                       
                       when 'Email'{
                            
                            //Check if the map already contains the key
                            if(!contactPointsByTypeMap.containsKey('Email')){
                                 contactPointsByTypeMap.put('Email', new List<ContactPoint>());
                            }
                            contactPointTypeList = contactPointsByTypeMap.get('Email');
                             contactPointTypeList.add(currentContactPoint);  
                          }
                       
                       
                       when else {
                           //Add all remaining in here
                            //Check if the map already contains the key
                            //check address here
                            if(contactPointType.contains('Address')){
                                if(!contactPointsByTypeMap.containsKey('Address')){
                                    contactPointsByTypeMap.put('Address', new List<ContactPoint>());
                                }
                                contactPointTypeList = contactPointsByTypeMap.get('Address');
                                contactPointTypeList.add(currentContactPoint);
                            }else{
                                if(!contactPointsByTypeMap.containsKey(contactPointType)){
                                    contactPointsByTypeMap.put(contactPointType, new List<ContactPoint>());
                                }
                                contactPointTypeList = contactPointsByTypeMap.get(contactPointType);
                                contactPointTypeList.add(currentContactPoint);
                            }
                       }
                   }
               } 
            }
            return contactPointsByTypeMap;
        }
        
         /**
        * @description  getContactPoint - get ContactPoint based on the Type given and Usage
        * @author Juan Cutrera | 1/04/2025 
        * @param contactPointType 
        * @param contactPointUsage
        * @return ContactPoint 
        **/
        global ContactPoint getContactPoint(String contactPointType, String contactPointUsage) {
            ContactPoint foundContactPoint = null;
            String capitalizedContactPointType;
            String capitalizedContactPointUsage;
            for(ContactPoint currentContactPoint: getContactPoints()){
                capitalizedContactPointType = currentContactPoint.getType() != null ? currentContactPoint.getType().capitalize() : null;
                capitalizedContactPointUsage = currentContactPoint.getUsage() != null ? currentContactPoint.getUsage().capitalize() : null;
                if(capitalizedContactPointType != null && capitalizedContactPointUsage != null ){
                    if(capitalizedContactPointType.equals(contactPointType?.capitalize()) && capitalizedContactPointUsage.equals(contactPointUsage?.capitalize())){
                        foundContactPoint = currentContactPoint;
                        break;
                    }
                }
            }
            return foundContactPoint;
        }
        
        /**
        * @description  getContactPoint - get ContactPoint based on the Type given
        * @author Juan Cutrera | 1/04/2025 
        * @param contactPointType 
        * @return ContactPoint 
        **/
        global ContactPoint getContactPoint(String contactPointType) {
            ContactPoint foundContactPoint = null;
            String capitalizedContactPointType;
            for(ContactPoint currentContactPoint: getContactPoints()){
                System.debug('### currentContactPoint.getType() : ' + currentContactPoint.getType());
                System.debug('### contactPointType : ' + contactPointType);
                capitalizedContactPointType = currentContactPoint.getType() != null ? currentContactPoint.getType().capitalize() : null;
                if(capitalizedContactPointType.equals(contactPointType?.capitalize())){
                    foundContactPoint = currentContactPoint;
                    System.debug('### foundContactPoint : ' + foundContactPoint);
                    break;
                }
            }
            return foundContactPoint;
        }
        
        /**
        * @description  getAccount - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return MyAccount object
        **/
        global MyAccount getAccount(){
            return account; //may confuse
        }
        
        /**
        * @description  getTeam - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return Team object
        **/
        global Team getTeam(){
            return team;
        }
        //end of Getter Methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: ContactPoint
    * @description		: Inner Object class for ContactPoint
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class ContactPoint {
        global string type;
        global string usage;
        global string email;
        global Phone  phone;
        global string freeformAddress;
        global Address address;
        
        
        
        //Start of Getter Methods
        /**
        * @description  getType - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return type value
        **/
        global String getType(){
            return type;
        }
        
        /**
        * @description  getUsage - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return usage value
        **/
        global String getUsage(){
            return usage;
        }
        
        /**
        * @description  getEmail - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return email value
        **/
        global string getEmail(){
            return email;
        }
        
        /**
        * @description  getPhone - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return phone value
        **/
        global Phone getPhone(){
            return phone;
        }
        
        /**
        * @description  getFreeFormAddress - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return freeformAddress value
        **/
        global String getFreeFormAddress(){
            return freeFormAddress;
        }
        
        /**
        * @description  getAddress - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return Address object
        **/
        global Address getAddress(){
            return address;
        }
        //End of Getter Methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: Phone
    * @description		: Inner Object class for Phone
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Phone {
        global string phoneNumber;
        
        
        //Start of setter methods
        /**
         * @description setPhoneNumber - setterMethod for phoneNumber that removes all special characters
         * @author Juan M. Cutrera
         * @param  phoneNumber value to set
         */
        global void setPhoneNumber(String phoneNumber) {
            if (phoneNumber != null) {
                // Remove all non-numeric characters
                this.phoneNumber = phoneNumber.replaceAll('[^0-9]', '');
            } else {
                this.phoneNumber = null;
            }
        }
        //End of setter methods
        //start of getter methods
        /**
        * @description  getPhoneNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return phoneNumber value
        **/
        global string getPhoneNumber() {
            return phoneNumber;
        }
        //end of getter methods

        /**
         * @description isMobile check if PhoneNumber is a mobile number
         * @author Juan M. Cutrera
         * @return   return returns true if the phone number is a mobile number
         */
        global boolean isMobile() {
            //Regex pattern for Australian Mobile numbers
            String phoneNumberPattern = '^(04|614)[0-9]{8}$';
            //Check if the phone number matches the pattern
            if (phoneNumber != null && pattern.matches(phoneNumberPattern,phoneNumber)) {
                return true;
            } else {
                return false;
            }
        }
    }
    
    /*******************************************************************************************************
	* Class Name      	: Address
    * @description		: Inner Object class for Address
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Address {
        global string lotNumber;
        global string streetNumber;
        global string streetName;
        global string streetType;
        global string suburb;
        global string locality;
        global string postCode;
        global string stateCode;
        global string countryCode;
        
        //getter methods
        /**
        * @description  getLotNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return lotNumber value
        **/
        global string getLotNumber(){
            return lotNumber;
        }
        
        /**
        * @description  getStreetNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return streetNumber value
        **/
        global string getStreetNumber(){
            return streetNumber;
        }
        
        /**
        * @description  getStreetName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return streetName value
        **/
        global string getStreetName(){
            return streetName;
        }
        
        /**
        * @description  getStreetType - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return stretType value
        **/
        global string getStreetType(){
            return streetType;
        }
        
        /**
        * @description  getSuburb - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return suburb value
        **/
        global string getSuburb(){
            return suburb;
        }
        
        /**
        * @description  getLocality - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return locality value
        **/
        global string getLocality(){
            return locality;
        }
        
        /**
        * @description  getPostCode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return postCode value
        **/
        global string getPostCode(){
            return postCode;
        }
        
        /**
        * @description  getStateCode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return stateCode value
        **/
        global string getStateCode(){
            return stateCode;
        }
        
        /**
        * @description  getCountryCode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return countryCode value
        **/
        global string getCountryCode(){
            return countryCode;
        }
        //end of getter methods
        
        /**
         * @description getStreetAddress - Build a street address
         * @author Juan M. Cutrera
         * @return   return description
         */
        global string getStreetAddress(){
            String streetAddress = '';
            if(String.isNotBlank(lotNumber)){
                streetAddress += lotNumber + ' ';
            }
            if(String.isNotBlank(streetNumber)){
                streetAddress += streetNumber + ' ';
            }
            if(String.isNotBlank(streetName)){
                streetAddress += streetName;
            }
            if(String.isNotBlank(streetType)){
                streetAddress += ' ' + streetType;
            }
            return streetAddress;
        }
    }
    
    /*******************************************************************************************************
	* Class Name      	: MyAccount
    * @description		: Inner Object class for MyAccount
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class MyAccount {
        global string accountNumber;
        global Card card;
        global MyUser user;
        
 
        
        //start of getter methods
        
        /**
        * @description  getAccountNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return getAccountNumber value
        **/
        global string getAccountNumber(){
            return accountNumber;
        }

		/**
        * @description  getCard - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return card object
        **/   
        global Card getCard(){
            return card;
        }
        
        /**
        * @description  getUser - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return MyUser object
        **/
        global MyUser getUser(){
            return user;
        }
        //end of getter methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: Card
    * @description		: Inner Object class for Card
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global Class Card {
        global Integer cardSequenceNumber;
        global string cardHolderName; 
        
        //start of getter methods
        /**
        * @description  getCardSequenceNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return cardSequenceNumber value
        **/
        global Integer getCardSequenceNumber(){
            return cardSequenceNumber;
        }
        
        /**
        * @description  getCardHolderName - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return cardHolderName value
        **/
        global string getCardHolderName(){
            return cardHolderName;
        }
        //end of getter methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: MyUser
    * @description		: Inner Object class for MyUser
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class MyUser {
        global string id;
        global string idp;
        global string reference;
        
        //start of getter methods
        /**
        * @description  getId - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return Id value
        **/
        global string getId(){
            return id;
        }
        
        /**
        * @description  getIdp - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return idp value
        **/
        global string getIdp(){
            return idp;
        }
        
        /**
        * @description  getReference - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return reference value
        **/
        global string getReference(){
            return reference;
        }
        //end of getter methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: Team
    * @description		: Inner Object class for Team
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Team {
        global string teamMemberNumber;
        global string cardNumber;
        global boolean isPrimary;
        
        //start of getter methods
        /**
        * @description  getTeamMemberNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return teamMemberNumber value
        **/
        global string getTeamMemberNumber(){
            return teamMemberNumber;
        }
        
        /**
        * @description  getCardNumber - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return cardNumber value
        **/
        global string getCardNumber(){
            return cardNumber;
        }
        
        /**
        * @description  getIsPrimary - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return isPrimary value
        **/
        global boolean isPrimary(){
            return isPrimary;
        }
        //end of getter methods
    }
    
    /*******************************************************************************************************
	* Class Name      	: Capture
    * @description		: Inner Object class for Capture
    * @author          	: Deloitte - Juan Cutrera
    * Created On      	: 27/03/2025
    * Modification Log	:
    * -----------------------------------------------------------------------------------------------------
    * Developer				Date			Modification ID		Description
    * -----------------------------------------------------------------------------------------------------
    * Juan Cutrera          27/03/2025		1000				Initial Version
    ******************************************************************************************************/
    global class Capture {
        global datetime captureDateTime;
        global string engagementChannel;
        global string source;
        global string sourceModule;
        global string sourceReference;
        global string locationCode;
        global string identifier;
        
        //Start of Getter Methods
        /**
        * @description  getCaptureDateTime - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return captureDateTime value
        **/
        global datetime getCaptureDateTime(){
            return captureDateTime;
        }
        
        /**
        * @description  getEngagementChannel - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return engagementChannel value
        **/
        global string getEngagementChannel(){
            return engagementChannel;
        }
        
        /**
        * @description  getSource - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return source value
        **/
        global string getSource(){
            return source;
        }
        
        /**
        * @description  getSourceModule - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return sourceModule value
        **/
        global string getSourceModule(){
            return sourceModule;
        }
        
        /**
        * @description  getSourceReference - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return sourceReference value
        **/
        global string getSourceReference(){
            return sourceReference;
        }
        
        /**
        * @description  getLocationcode - getterMethod for related variable
        * @author Juan Cutrera | 27/03/2025 
        * @return locationCode value
        **/
        global string getLocationCode(){
            return locationCode;
        }

        /**
         * @description getIdentifier - getterMethod for related variable
         * @author Juan M. Cutrera
         * @return  string identifier
         */
        global string getIdentifier(){
            return identifier;
        }
        //End of Getter Methods
    }
    
    //Getter Method
    /**
    * @description  getEntity - getterMethod for related variable
    * @author Juan Cutrera | 27/03/2025 
    * @return List of Entities 
    **/
    global Entity getEntity(){
        return Entity;
    }
    //End of Getter Method
    
    
    /**
    * @description  parse - Parse jsonString to return the wrapperPayload
    * @author Juan Cutrera | 27/03/2025
    * @param jsonString
    * @return  Consent_ConsentManagerPayload
    **/	
    global static Consent_ConsentManagerPayload parse(String jsonString) {
        // Deserialize into untyped object for flexibility
        Object raw = JSON.deserializeUntyped(jsonString);
    
        // Recursively replace keys
        Object updated = replaceReservedKeys(raw);
    
        // Re-serialize and deserialize into the strongly-typed object
        String updatedJson = JSON.serialize(updated);
        return (Consent_ConsentManagerPayload) JSON.deserialize(updatedJson, Consent_ConsentManagerPayload.class);
    }
    
    /**
    * @description  replaceReservedKeys - Recursively walks through maps and lists to rename reserved keys
    * @author Juan Cutrera | 08/04/2025
    * @param jsonString
    * @return  Consent_ConsentManagerPayload
    **/	
    private static Object replaceReservedKeys(Object input) {
        if (input instanceof Map<String, Object>) {
            Map<String, Object> mapInput = (Map<String, Object>) input;
            Map<String, Object> newMap = new Map<String, Object>();
    
            for (String key : mapInput.keySet()) {
                String newKey = key;
                if (key == 'number'){
                    //Set the new key and update number to remove characters that are not numerical
                    newKey = 'phoneNumber';
                    Object value = mapInput.get(key);
                    if(value instanceof String){
                        Phone phone = new Phone();
                        phone.setPhoneNumber((String)value);
                        mapInput.put(key, phone.getPhoneNumber());
                    }
                } 
                    
                if (key == 'dateTime') newKey = 'captureDateTime';
                newMap.put(newKey, replaceReservedKeys(mapInput.get(key)));
            }
            return newMap;
    
        } else if (input instanceof List<Object>) {
            List<Object> listInput = (List<Object>) input;
            List<Object> newList = new List<Object>();
    
            for (Object item : listInput) {
                newList.add(replaceReservedKeys(item));
            }
            return newList;
    
        } else {
            return input; // primitive type, return as-is
        }
	}

}