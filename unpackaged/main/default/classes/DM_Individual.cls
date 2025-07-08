/*******************************************************************************************************
* Class Name        : DM_Individual
* Description       : Data Layer - Selector for Sobject Account
* Author            : Deloitte - Juan Cutrera
* Created On        : 2020-05-14
* Modification Log  : (Not needed for now)
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          2025-03-24      1000             	Initial version
******************************************************************************************************/
public class DM_Individual {

    /**
     * @description getIndividualsByIds get Individuals from IndividualIds
     * @author Juan M. Cutrera | 09/04/2025
     * @param  individualIds individualIds description
     * @return               return description
     */
    public static List<Individual> getIndividualsByIds(List<Id> individualIds){
        if(individualIds == null || individualIds.isEmpty()){
            return new List<Individual>();
        }
        return [SELECT Id FROM Individual WHERE Id IN :individualIds WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC];
    }
}