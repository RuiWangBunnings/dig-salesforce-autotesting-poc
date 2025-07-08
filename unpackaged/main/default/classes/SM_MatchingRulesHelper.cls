/*******************************************************************************************************
* Class Name      	: SM_MatchingRulesHelper
* @description		: Service Layer - A help classs to assist with Matching rules
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 21/03/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          21/03/2025		1000				Initial Version
******************************************************************************************************/

public class SM_MatchingRulesHelper {

    /**
     * @description getPersonAccountsBasedOnEmailOrMobile Get All Person accounts where email or mobile Phone matches
     * @author Juan M. Cutrera | 08/04/2025
     * @param  matchingEmail       matchingEmail description
     * @param  matchingMobilePhone matchingMobilePhone description
     * @return                     return description
     */
    public static List<Account> getPersonAccountsBasedOnEmailOrMobile(String matchingEmail, String matchingMobilePhone){
        return DM_Account.getPersonAccountsBasedOnEmailOrMobile(matchingEmail, matchingMobilePhone);
    }


    /**
     * @description getIndividualsByIds Get All Individuals where Ids match
     * @author Juan M. Cutrera | 8/04/2025
     * @param  individualIds individualIds description
     * @return               return description
     */
    public static List<Individual> getIndividualsByIds(List<Id> individualIds){
        return  DM_Individual.getIndividualsByIds(individualIds);
    }

    /**
     * @description getContactPointEmailsByParentId Get All ContactPointEmails where ParentId match
     * @author Juan M. Cutrera | 8/04/2025
     * @param  parentId parentId description
     * @return          return description
     */
    public static List<ContactPointEmail> getContactPointEmailsByParentId(Id parentId){
        return DM_ContactPointEmail.getContactPointEmailsByParentId(parentId);
    }

    /**
     * @description getContactPointPhonesByParentId Get All ContactPointPhones where ParentId match
     * @author Juan M. Cutrera | 8/04/2025
     * @param  parentId parentId description
     * @return          return description
     */
    public static List<ContactPointPhone> getContactPointPhonesByParentId(Id parentId){
        return DM_ContactPointPhone.getContactPointPhonesByParentId(parentId);
    }

    /**
     * @description getContactPointAddressesByParentId Get All ContactPointAddresses where ParentId match
     * @author Juan M. Cutrera | 8/04/2025
     * @param  parentId parentId description
     * @return          return description
     */
    public static List<ContactPointAddress> getContactPointAddressesByParentId(Id parentId){
        return DM_ContactPointAddress.getContactPointAddressesByParentId(parentId);
    }

    /**
     * @description getAuthorizationFormTextByExternalId Get All AuthorizationFormText where ExternalId match
     * @author Juan M. Cutrera | 8/04/2025
     * @param  externalId externalId description
     * @return            return description
     */
    public static AuthorizationFormText getAuthorizationFormTextByExternalId(String externalId){
        return DM_AuthorizationFormText.getAuthorizationFormTextByExternalId(externalId);
    }

}