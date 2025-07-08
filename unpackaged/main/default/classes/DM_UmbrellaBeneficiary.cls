/*******************************************************************************************************
* Class Name      	: DM_UmbrellaBeneficiary
* Description		: Data Layer - Selector for Sobject Umbrella_Beneficiary__c
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 24/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    24/06/2020		1000				Initial version
******************************************************************************************************/
public class DM_UmbrellaBeneficiary {
    public static List<Umbrella_Beneficiary__c> getActiveUmbrellaBeneficiariesWithGroupOwners(String accountId){
        return new List<Umbrella_Beneficiary__c>([
            SELECT Id, Umbrella_Group__r.OwnerId 
            FROM Umbrella_Beneficiary__c 
            WHERE Account__c =: accountId AND Status__c = 'Active'
        ]);
    }
}