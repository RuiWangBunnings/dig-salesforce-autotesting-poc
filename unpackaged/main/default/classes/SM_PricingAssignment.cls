/*******************************************************************************************************
* Class Name      	: SM_PricingAssignment
* Description		: Service layer for Account Price List Assignment flow
* Author          	: Simplus - John Paul Peñaflor
* Created On      	: 01/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* John Paul Peñaflor    01/07/2020		1000				Initial version
******************************************************************************************************/
public without sharing class SM_PricingAssignment {
    @InvocableMethod
    public static List<List<String>> getUmbrellaGroup(List<String> accountIds) {

        System.debug(accountIds);
        try {
            List<String> ownerIds = new List<String>();
            List<List<String>> umbrellaGroupOwnerIds = new List<List<String>>();
            Set<Id> activeUmbrellaGroupOwnerIds = new Set<Id>(SM_AccountTransfer.getActiveUmbrellaGroupOwnerIds(accountIds[0]));
            
            for(Id activeUmbrellaGroupOwnerId : activeUmbrellaGroupOwnerIds){
                ownerIds.add(activeUmbrellaGroupOwnerId);
            }

            umbrellaGroupOwnerIds.add(ownerIds);
            
            return umbrellaGroupOwnerIds.size() > 0 ? umbrellaGroupOwnerIds : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}