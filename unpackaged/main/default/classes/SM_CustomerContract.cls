/*******************************************************************************************************
* Class Name      	: SM_CustomerContract
* Description		: Domain / Service Layer for Sobject Customer Contract
* Author          	: Simplus - Yi Zhang
* Created On      	: 14/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              14/05/2020		1000				Initial version
******************************************************************************************************/
public with sharing class SM_CustomerContract {
    /**
    * @description 
    * @author       Yi Zhang | 15/05/2020 
    * @param        contracts 
    * @param        ownerId 
    * @return       Integer 
    **/
    public static Integer getNumberOfContractsBelongTo(List<Customer_Contract__c> contracts, Id ownerId) {
        Integer n = 0;
        for(Customer_Contract__c cc : contracts) {
            if(cc.Contract__c != null && cc.Contract__r.OwnerId == ownerId) {
                n ++;
            }
        }
        return n;
    }

    /**
    * @description  Count the numbers of contracts which are non-expired
    * @author       Yi Zhang | 14/07/2020 
    * @param        contracts 
    * @return       Integer 
    **/
    public static Integer countNonExpiredContracts(List<Customer_Contract__c> contracts) {
        Integer n = 0;
        for(Customer_Contract__c cc : contracts) {
            if(cc.Contract__r.Status__c != Constants.CONTRACT_STATUS_EXPIRED) {
                n ++;
            }
        }
        return n;
    }

    /**
    * @description  Count the number of contracts which are: 1) non-expired, 2) orignal reviewer = account owner
    * @author       Yi Zhang | 14/07/2020 
    * @param        contracts 
    * @param        accountOwnerId 
    * @return       Integer 
    **/
    public static Integer countNonExpiredContractsWithOriginalReviewerSameAsAccountOwner(List<Customer_Contract__c> contracts, Id accountOwnerId) {
        Integer n = 0;
        for(Customer_Contract__c cc : contracts) {
            if(cc.Contract__r.Status__c != Constants.CONTRACT_STATUS_EXPIRED && cc.Contract__r.Original_Reviewer__c == accountOwnerId) {
                n ++;
            }
        }
        return n;
    }
}