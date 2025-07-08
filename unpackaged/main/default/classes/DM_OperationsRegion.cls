/*******************************************************************************************************
* Class Name      	: DM_OperationsRegion
* Description		: Data Layer - Selector for Sobject Operations_Region__c
* Author          	: Simplus - Philip Clark
* Created On      	: 23/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          23/06/2020		1000				Initial version
******************************************************************************************************/
public with sharing class DM_OperationsRegion {
    
    /**
    * @description  
    * @author       Philip Clark | 23/06/2020 
    * @return       list<Operations_Region__c> 
    **/
    public static list<Operations_Region__c> getAllOpRegs() {
        return new List<Operations_Region__c> ([
            SELECT Id, Name
            FROM Operations_Region__c
        ]);
    }
    
    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param excludedIds 
    * @return List<Operations_Region__c> 
    **/
    public static List<Operations_Region__c> getOpRegsExcluding(List<Id> excludedIds) {
        return new List<Operations_Region__c>([
            SELECT Id, Name, Role__c, Team_Member__c
            FROM Operations_Region__c
            WHERE Id NOT IN :excludedIds
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 20/08/2020 
    * @param opRegCodes 
    * @param roles 
    * @return List<Operations_Region__c> 
    **/
    public static List<Operations_Region__c> getOpRegs(List<String> opRegCodes, List<String> roles) {
        return new List<Operations_Region__c>([
            SELECT Id, Name, Role__c, Team_Member__c
            FROM Operations_Region__c
            WHERE Name IN :opRegCodes
            AND Role__c IN :roles
        ]);
    }
}