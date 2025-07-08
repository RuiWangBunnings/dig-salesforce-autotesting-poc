/*******************************************************************************************************
* Class Name      	: DM_UserRole
* Description		: Data Layer - Selector for Sobject UserRole
* Author          	: Simplus - Philip Clark
* Created On      	: 24/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          24/06/2020		1000				Initial version
* Yi Zhang              03/09/2020		2000				Revamped existing method
* Simplus MS 			14/12/2021		3000				CCRM15-416 - Added new method getAllRoles
******************************************************************************************************/
public with sharing class DM_UserRole {
    
    /**
    * @description 
    * @author Yi Zhang | 03/09/2020 
    * @param names 
    * @return List<UserRole> 
    **/
    public static List<UserRole> getRolesByName(List<String> names) {
        System.debug('names '+names);
        return new List<UserRole>([
            SELECT Id, Name 
            FROM UserRole 
            WHERE Name IN :names]);
    }
    
    /**
    * @description 
    * @author Simplus MS | 14/12/2021 
    * @param  
    * @return List<UserRole> 
    **/
    public static List<UserRole> getAllRoles() {
        return new List<UserRole>([
            SELECT Id, Name 
            FROM UserRole ]);
    }
}