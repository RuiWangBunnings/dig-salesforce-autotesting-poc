/*******************************************************************************************************
* Class Name      	: DM_ContactPointEmail
* @description		: Selector for ContactPointEmail
* @author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class DM_ContactPointEmail {

    /**
     * @description getContactPointEmailsByParentId get ContactPointEmail by ParentId
     * @author Juan M. Cutrera | 09/04/2025
     * @param  parentId parentId description
     * @return List<ContactPointEmail> return
     */
    public static List<ContactPointEmail> getContactPointEmailsByParentId(Id parentId) {
        if (parentId == null) {
            return new List<ContactPointEmail>();
        }
        return [SELECT Id, EmailAddress 
                FROM ContactPointEmail 
                WHERE ParentId = :parentId 
                WITH SECURITY_ENFORCED];

    }
}