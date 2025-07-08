/*******************************************************************************************************
* Class Name      	: SM_ContactPointPhoneBuilder
* @description		: Service layer - To create ContactPointPhone records easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_ContactPointPhoneBuilder implements Builder {

    private ContactPointPhone newContactPointPhone = new ContactPointPhone();

    /**
    * @description  setParentId - Sets the parent ID of the ContactPointPhone
    * @author Juan Cutrera | 04/04/2025
    * @param parentId The parent ID to set
    * @return SM_ContactPointPhoneBuilder
    **/
    public SM_ContactPointPhoneBuilder setParentId(String parentId) {
        newContactPointPhone.ParentId = parentId;
        return this;
    }

    /**
    * @description  setPhoneNumber - Sets the phone number of the ContactPointPhone
    * @author Juan Cutrera | 04/04/2025
    * @param phoneNumber The phone number to set
    * @return SM_ContactPointPhoneBuilder
    **/
    public SM_ContactPointPhoneBuilder setTelephoneNumber(String phoneNumber) {
        newContactPointPhone.telephoneNumber = phoneNumber;
        return this;
    }

    /**
    * @description  setPhoneType - Sets the phone type of the ContactPointPhone (e.g., Mobile, Home, Work, etc.)
    * @author Juan Cutrera | 04/04/2025
    * @param phoneType The phone type to set
    * @return SM_ContactPointPhoneBuilder
    **/
    public SM_ContactPointPhoneBuilder setPhoneType(String phoneType) {
        newContactPointPhone.PhoneType = phoneType;
        return this;
    }

    /**
    * @description  build - Builds and returns the configured ContactPointPhone instance
    * @author Juan Cutrera | 04/04/2025
    * @return ContactPointPhone
    **/
    public ContactPointPhone build() {
        return newContactPointPhone;
    }

}