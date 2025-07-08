/*******************************************************************************************************
* Class Name      	: DM_ContactPointPhone
* @description		: Selector for ContactPointPhone
* @author          	: Juan Manual Cutrera
* Created On      	: 09/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	09/04/2025		1000				Initial version
******************************************************************************************************/
public class DM_ContactPointPhone {

    /**
     * @description getContactPointPhonesByParentId get ContactPointPhone by ParentId
     * @author Juan M. Cutrera | 09/04/2025
     * @param  parentId parentId description
     * @return List<ContactPointPhone> return
     */
    public static List<ContactPointPhone> getContactPointPhonesByParentId(Id parentId) {
        if (parentId == null) {
            return new List<ContactPointPhone>();
        }
        return [SELECT Id, TelephoneNumber 
                FROM ContactPointPhone 
                WHERE ParentId = :parentId 
                WITH SECURITY_ENFORCED];
    }

}