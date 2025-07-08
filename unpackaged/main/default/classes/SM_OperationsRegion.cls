/*******************************************************************************************************
* Class Name      	: SM_OperationsRegion
* Description		: Domain / Service layer for OperationsRegion
* Author          	: Simplus - Philip Clark
* Created On      	: 22/06/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          22/06/2020		1000				Initial version
* Yi Zhang    	        19/08/2020		2000				Revamp all resulted from requirement change
******************************************************************************************************/
public without sharing class SM_OperationsRegion {

    public static final String ERROR_ROLE_ASSIGNED = 'This role is already assigned for the Operations Region.';
    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param newList 
    **/
    public static void beforeInsert(List<Operations_Region__c> newList) {

        validateRoleAndTeamMember(newList);

    }

    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void beforeUpdate(Map<Id,Operations_Region__c> oldMap, Map<Id,Operations_Region__c> newMap) {

        validateRoleAndTeamMember(newMap.values());

    }
    
    /**
    * @description 
    * @author Philip Clark | 22/06/2020 
    * @param newMap
    **/
    public static void afterInsert(Map<Id,Operations_Region__c> newMap) {

        createStoreMembers(newMap.values());
    }

    /**
    * @description 
    * @author Philip Clark | 22/06/2020 
    * @param oldMap
    * @param newMap
    **/
    public static void afterUpdate(Map<Id,Operations_Region__c> oldMap, Map<Id,Operations_Region__c> newMap) {

        createUpdateStoreMembers(oldMap, newMap);
    }

    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param oldList 
    **/
    public static void afterDelete(List<Operations_Region__c> oldList) {

        // additional data screening
        List<Operations_Region__c> oldOpRegs = new List<Operations_Region__c>();
        for(Operations_Region__c opReg : oldList) {
            if(String.isNotBlank(opReg.Role__c) && String.isNotBlank(opReg.Team_Member__c)) {
                oldOpRegs.add(opReg);
            }
        }

        deactivateStoreMembers(oldOpRegs);
    }






    

    /**
    * @description      To validate that nly one user can be active in the role against a particular Operation Region at any one time
    * @author Yi Zhang | 19/08/2020 
    * @param newList 
    **/
    public static void validateRoleAndTeamMember(List<Operations_Region__c> newList) {
        List<Id> opRegIds = new List<Id>();
        for(Operations_Region__c opReg : newList) {
            if(String.isNotBlank(opReg.Id)) {
                opRegIds.add(opReg.Id);
            }
        }

        // Only one user can be active in the role against the Operation Region at any one time
        List<Operations_Region__c> allOtherOpRegs = DM_OperationsRegion.getOpRegsExcluding(opRegIds);
        Map<String, Integer> opRegRoleUserMap = new Map<String, Integer>();   // key : opReg Name + Role, val : Team Member Count
        for(Operations_Region__c opReg : allOtherOpRegs) {
            opRegRoleUserMap.put(opReg.Name + opReg.Role__c, 1);
        }
        for(Operations_Region__c opReg : newList) {
            if(opRegRoleUserMap.containsKey(opReg.Name + opReg.Role__c) == true) {
                opReg.addError(ERROR_ROLE_ASSIGNED);
            }
        }
    }

    /**
    * @description      Create / Update Store Members when OR record is updated
    * @author Yi Zhang | 19/08/2020 
    * @param oldMap 
    * @param newMap 
    **/
    public static void createUpdateStoreMembers(Map<Id, Operations_Region__c> oldMap, Map<Id, Operations_Region__c> newMap) {

        List<Operations_Region__c> newOpRegs = new List<Operations_Region__c>();
        List<Operations_Region__c> oldOpRegs = new List<Operations_Region__c>();
        // for OR update, only OR with Name / Role / Team Member change will trigger store member shift
        
        for(Operations_Region__c oldOpReg : oldMap.values()) {
            Operations_Region__c newOpReg = newMap.get(oldOpReg.Id);
            if(oldOpReg.Name != newOpReg.Name 
            || oldOpReg.Role__c != newOpReg.Role__c 
            || oldOpReg.Team_Member__c != newOpReg.Team_Member__c) {
                newOpRegs.add(newOpReg);
                oldOpRegs.add(oldOpReg);
            }
        }
        
        // need to devactivate both old & new record's Code+Role
        List<Operations_Region__c> combinedOpRegs = new List<Operations_Region__c>(oldOpRegs);
        combinedOpRegs.addAll(newOpRegs);
        deactivateStoreMembers(combinedOpRegs);
        createStoreMembers(newOpRegs);
    }

    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param opRegList 
    **/
    public static void createStoreMembers(List<Operations_Region__c> opRegList) {
        
        System.debug('Started createStoreMembers');
        System.debug('opRegList: ' + opRegList);
        if(opRegList.size() > 0) {

            Map<String, Map<String, Id>> codeRoleUserMap = new Map<String, Map<String, Id>>();  // key 1: opRegCode, key 2: Role, Id : user Id
            for(Operations_Region__c opReg : opRegList) {
                if(codeRoleUserMap.containsKey(opReg.Name) == false) {
                    codeRoleUserMap.put(opReg.Name, new Map<String, Id>());
                }
                codeRoleUserMap.get(opReg.Name).put(opReg.Role__c, opReg.Team_Member__c);
            }
        
            // System.debug('codeRoleUserMap: ' + codeRoleUserMap);

            // System.debug('stores: ' + DM_Store.getStoreByOpRegCodes(codeRoleUserMap.keySet()));
    
            List<Store_Member__c> members = new List<Store_Member__c>();
            for (Store__c store : DM_Store.getStoreByOpRegCodes(codeRoleUserMap.keySet())) {
                Map<String, Id> roleUserMap = codeRoleUserMap.get(store.Operations_Region_Code__c); 
                for(String role : roleUserMap.keySet()) {
                    members.add(new Store_Member__c(
                        Store__c = store.Id,
                        Role__c = role,
                        Status__c = Constants.STOREMEMBER_ACTIVE_STATUS,
                        Start_Date__c = Date.today(),
                        Team_Member__c = roleUserMap.get(role)
                    ));
                }
            }
            
            System.debug('members: ' + members);

            if(members.size() > 0) {
                try {
                    insert members;
                } catch(Exception e) {
                    System.debug('error: ' + e.getMessage());
                    ApplicationLogger.log('SM_OperationsRegion.createStoreMembers', 'Operations_Region__c', 'Trigger', e);
                }
            }
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 19/08/2020 
    * @param opRegList 
    **/
    public static void deactivateStoreMembers(List<Operations_Region__c> opRegList) {
        if(opRegList.size() > 0) {
            Set<String> opRegCodes = new Set<String>();
            Set<String> roles = new Set<String>();
            Set<String> opRegCodeRoles = new Set<String>();
            for(Operations_Region__c opReg : opRegList) {
                opRegCodes.add(opReg.Name);
                roles.add(opReg.Role__c);
                opRegCodeRoles.add(opReg.Name + opReg.Role__c);
            }
    
            List<Store_Member__c> members = new List<Store_Member__c>();
            for (Store_Member__c sm : DM_StoreMember.getStoreMembers(opRegCodes, roles, Constants.STOREMEMBER_ACTIVE_STATUS)) {
                // only end date when opRegCode + Role combination is the one in change
                if(opRegCodeRoles.contains(sm.Store__r.Operations_Region_Code__c + sm.Role__c) == true) {
                    sm.End_Date__c = Date.today();
                    sm.Status__c = Constants.STOREMEMBER_INACTIVE_STATUS;
                    members.add(sm);
                }
            }
    
            if(members.size() > 0) {
                try {
                    update members;
                } catch(Exception e) {
                    ApplicationLogger.log('SM_OperationsRegion.deactivateStoreMembers', 'Operations_Region__c', 'Trigger', e);
                }
            }
        }
    }
}