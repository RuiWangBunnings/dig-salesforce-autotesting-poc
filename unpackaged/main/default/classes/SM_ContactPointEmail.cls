/*******************************************************************************************************
* Class Name      	: SM_ContactPointEmail
* @description		: Domain / Service layer for ContactPointEmail
* @author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class SM_ContactPointEmail {

    /**
    * @description  buildNewContactPointEmail - Build a new ContactPointEmail
    * @author Juan Cutrera | 08/04/2025
    * @param contactPoint
    * @return ContactPointEmail
    **/
    public static ContactPointEmail buildNewContactPointEmail(Consent_ConsentManagerPayload.ContactPoint contactPoint){
        SM_ContactPointEmailBuilder builder = new SM_ContactPointEmailBuilder();
        //null checks
        if(contactPoint != null){
            if(contactPoint.getEmail() != null){
                builder.setEmailAddress(contactPoint.getEmail());
            }
        }
        return builder.build();
    }

  
    /**
     * @description upsertContactPointEmails upsert contactPointEmailList
     * @author Juan M. Cutrera | 08/04/2025
     * @param  contactPointEmailList
     */
    public static void upsertContactPointEmails(List<ContactPointEmail> contactPointEmailList){
        try {
            Database.upsert(contactPointEmailList, true);
        } catch (Exception e) {
            throw new SM_ContactPointEmailException('ContactPointEmail could not be created: ' + e.getMessage());
        } 
    }
    private class SM_ContactPointEmailException extends Exception{}
}