/*******************************************************************************************************
* Class Name      	: SM_ContactPointEmailBuilder
* @description		: Service layer - To create ContactPointEmail records easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_ContactPointEmailBuilder implements Builder {
    
    private ContactPointEmail newContactPointEmail = new ContactPointEmail();
    
    /**
    * @description  setParentId - Sets the parent ID of the ContactPointEmail
    * @author Juan Cutrera | 04/04/2025
    * @param parentId The parent ID to set
    * @return SM_ContactPointEmailBuilder
    **/
    public SM_ContactPointEmailBuilder setParentId(String parentId) {
        newContactPointEmail.ParentId = parentId;
        return this;
    }
    
    /**
    * @description  setEmailAddress - Sets the email address of the ContactPointEmail
    * @author Juan Cutrera | 04/04/2025
    * @param emailAddress The email address to set
    * @return SM_ContactPointEmailBuilder
    **/
    public SM_ContactPointEmailBuilder setEmailAddress(String emailAddress) {
        newContactPointEmail.EmailAddress = emailAddress;
        return this;
    }
    
    /**
    * @description  build - Builds and returns the configured ContactPointEmail instance
    * @author Juan Cutrera | 04/04/2025
    * @return ContactPointEmail
    **/
    public ContactPointEmail build() {
        return newContactPointEmail;
    }

}