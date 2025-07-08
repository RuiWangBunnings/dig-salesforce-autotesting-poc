/*******************************************************************************************************
* Class Name      	: SM_ContactPointPhone
* Description		: Domain / Service layer for ContactPointPhone
* Author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class SM_ContactPointPhone {

     /**
    * @description  createNewAccount - Build a new PersonAccount
    * @author Juan Cutrera | 02/04/2025
    * @param currentEntity
    * @return Account
    **/
    public static ContactPointPhone buildNewContactPointPhone(Consent_ConsentManagerPayload.ContactPoint contactPoint){
        
        SM_ContactPointPhoneBuilder builder = new SM_ContactPointPhoneBuilder();
        
        if(contactPoint != null){
            if(contactPoint.getPhone() != null){
                Consent_ConsentManagerPayload.Phone currentPhone = contactPoint.getPhone();
                if(contactPoint.getPhone().getPhoneNumber() != null){
                    builder.setTelephoneNumber(contactPoint.getPhone().getPhoneNumber());
                }
                if(currentPhone.isMobile()){
                    builder.setPhoneType('Mobile');
                }else{
                    builder.setPhoneType('Home');
                }
            }
        }
        return builder.build();
    }

    /**
     * @description upsertContactPointPhones Insert contactPointPhoneList
     * @author Juan M. Cutrera | 08/04/2025
     * @param  contactPointPhoneList contactPointPhoneList description
     */    
    public static void upsertContactPointPhones(List<ContactPointPhone> contactPointPhoneList){
        try {
            Database.upsert(contactPointPhoneList, true);
        } catch (Exception e) {
            throw new SM_ContactPointPhoneException('ContactPointPhones could not be created: ' + e.getMessage());
        } 

    }

    private class SM_ContactPointPhoneException extends Exception{}
}