/*******************************************************************************************************
* Class Name      	: DM_ContactPointAddress
* @description		: Selector for ContactPointAddress
* @author          	: Juan Manual Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera             	08/04/2025		1000				Initial version
******************************************************************************************************/
public class DM_ContactPointAddress {

    /**
     * @description getContactPointAddressesByParentId get ContactPointAddress by ParentId
     * @author Juan M. Cutrera | 09/04/2025
     * @param  parentId parentId description
     * @return List<ContactPointAddress> return
     */
    public static List<ContactPointAddress> getContactPointAddressesByParentId(Id parentId) {
        if (parentId == null) {
            return new List<ContactPointAddress>();
        }
        return [SELECT Id, Name, Street, City, State, PostalCode, Country 
                FROM ContactPointAddress 
                WHERE ParentId = :parentId 
                WITH SECURITY_ENFORCED];
    }

}