/*******************************************************************************************************
* Class Name      	: SM_ContactPointAddress
* @description		: Domain / Service layer for ContactPointAddress
* @author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class SM_ContactPointAddress {

    /**
    * @description  create - Build a new ContactPointAddress
    * @author Juan Cutrera | 08/04/2025
    * @param contactPoint
    * @return ContactPointAddress
    **/
    public static ContactPointAddress buildNewContactPointAddress(Consent_ConsentManagerPayload.ContactPoint contactPoint){
        SM_ContactPointAddressBuilder builder = new SM_ContactPointAddressBuilder();
        //null checks
        if(contactPoint != null){
            if(contactPoint.getAddress() != null){
                Consent_ConsentManagerPayload.Address currentMailingAddress = contactPoint.getAddress();
                
                   builder.setAddress(currentMailingAddress.getStreetAddress(),
                                    currentMailingAddress.getLocality(),
                                    currentMailingAddress.getStateCode(),
                                    currentMailingAddress.getPostCode(),
                                    currentMailingAddress.getCountryCode()
                                   );      
            }
        }
                           
        return builder.build();
    }


    /**
     * @description upsertContactPointAddresses upsert contactPointAddressList
     * @author Juan M. Cutrera | 08/04/2025
     * @param  contactPointAddressList
     */
    public static void upsertContactPointAddresses(List<ContactPointAddress> contactPointAddressList){
        try {
            Database.upsert(contactPointAddressList, true);
        } catch (Exception e) {
            throw new SM_ContactPointAddressException('ContactPointAddress could not be created: ' + e.getMessage());
        } 
    }

    private class SM_ContactPointAddressException extends Exception{}
}