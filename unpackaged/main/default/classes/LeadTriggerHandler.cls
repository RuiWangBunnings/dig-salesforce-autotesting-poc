/*******************************************************************************************************
* Class Name        : LeadTriggerHandler
* Description       : Lead Trigger Handler
* Author            : Simplus - Yi Zhang
* Created On        : 15/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              15/06/2020      1000                Initial version
* Francis Benzon        15/06/2020      2000                added name auto capitalisation
******************************************************************************************************/
public without sharing class LeadTriggerHandler {
    public static final String ERROR_INVALID_GST_NUMBER = 'Please enter a valid GST Number';
    /**
    * @description 
    * @author Yi Zhang | 15/06/2020 
    * @param oldMap 
    * @param newMap 
    * Update : Francis Benzon name auto capitalisation
    **/
    public static void beforeInsert(List<Lead> lstNewLeads) {
        for(Lead ld : lstNewLeads) {
            if(ld.FirstName != null) {
                ld.FirstName = nameAutoCapitalisation(ld.FirstName);
            }
            if(ld.LastName != null) {
                ld.LastName = nameAutoCapitalisation(ld.LastName);
            }
            if(ld.ABN__c != null) {
                ld.ABN__c = SM_StringFormatter.abnFormat(ld.ABN__c);
            }
            if(ld.ACN__c != null) {
                ld.ACN__c = SM_StringFormatter.acnFormat(ld.ACN__c);
            }
            if(ld.GST_Number__c != null) {
                ld.GST_Number__c = SM_StringFormatter.gstFormat(ld.GST_Number__c);
            }
        }   

        // validate GST Number for NZ leads
        checkNZGSTNumber(lstNewLeads);
    }

    /**
    * @description 
    * @author Yi Zhang | 15/06/2020 
    * @param oldMap 
    * @param newMap 
    * Update : Francis Benzon name auto capitalisation
    **/
    public static void beforeUpdate(List<Lead> lstNewLeads, Map<Id, Lead> mapNewLeads,
                                    List<Lead> lstOldLeads, Map<Id, Lead> mapOldLeads) 
   {
        for(Lead ld : lstNewLeads) {
            if(ld.FirstName != mapOldLeads.get(ld.ID).FirstName) {
                ld.FirstName = nameAutoCapitalisation(ld.FirstName);
            }
            if(ld.LastName != mapOldLeads.get(ld.ID).LastName) {
                ld.LastName = nameAutoCapitalisation(ld.LastName);
            }
            if(ld.ABN__c != null && ld.ABN__c != mapOldLeads.get(ld.ID).ABN__c) {
                ld.ABN__c = SM_StringFormatter.abnFormat(ld.ABN__c);
            }
            if(ld.ACN__c != null && ld.ACN__c != mapOldLeads.get(ld.ID).ACN__c) {
                ld.ACN__c = SM_StringFormatter.acnFormat(ld.ACN__c);
            }
            if(ld.GST_Number__c != null && ld.GST_Number__c != mapOldLeads.get(ld.ID).GST_Number__c) {
                ld.GST_Number__c = SM_StringFormatter.gstFormat(ld.GST_Number__c);
            }
        }            
        
        // validate GST Number for NZ leads
        checkNZGSTNumber(mapOldLeads, mapNewLeads);           
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 07-30-2020 
    * @param Map<Id Lead> mapOldLeads 
    **/
    public static void afterDelete(Map<Id, Lead> mapOldLeads){
        List<String> profileExemptions = DM_Initialisation.getCCRMInitialisation().Admin_Validation_Exceptions__c.split(', ');
        User user = DM_User.getUser(UserInfo.getUserId());

        for(Lead leadRec : mapOldLeads.values()){
            System.debug('leadRec.MasterRecordId: ' + leadRec.MasterRecordId);
            if(leadRec.MasterRecordId == null && !profileExemptions.contains(user.Profile.Name)){
                leadRec.addError('You do not have permission to delete Leads. Please contact your system admin to delete this Lead');
            }
        }
        
    }

    /**
    * @description 
    * @author Francis Benzon | 15/06/2020 
    * @param name
    * @return String
    * Update : Francis Benzon name auto capitalisation logic
    **/
    public static String nameAutoCapitalisation(String name) {
        if(String.isBlank(name)) {
            return name;
        }
        String leadName = name;
        List<String> nameGroup = leadName.split(' '); 

        for(Integer i = 0; i < nameGroup.size(); i++) {
            if(nameGroup[i].contains('-')) {
                if (nameGroup[i].length() > 1) {
                	nameGroup[i] = nameGroup[i].substringBefore('-').subString(0,1).toUpperCase()
                    +  nameGroup[i].substringBefore('-').subString(1,nameGroup[i].substringBefore('-').length()).toLowerCase()
                    + '-' 
                    + nameGroup[i].substringAfter('-').subString(0,1).toUpperCase() 
                    + nameGroup[i].substringAfter('-').subString(1,nameGroup[i].substringAfter('-').length()).toLowerCase();    
                } else {
                    nameGroup[i] = nameGroup[i].toUpperCase();
                }
            }else {
                if (nameGroup[i].length() > 1) {
                	nameGroup[i] = nameGroup[i].subString(0,1).toUpperCase() + nameGroup[i].subString(1,nameGroup[i].length()).toLowerCase();    
                } else {
                    nameGroup[i] = nameGroup[i].toUpperCase();
                }
            }   
        }
        return leadName = String.join(nameGroup, ' ');
        //system.assertEquals('NAME: ' , ' ' + names);
    }

    /**
    * @description      Check if inserted GST Number is valid (for NZ Lead only)
    * @author           Yi Zhang | 20/07/2020 
    * @param            newList 
    **/
    public static void checkNZGSTNumber(List<Lead> newList) {
        
        for(Lead l : newList) {
            if(nzRecordTypeIds.contains(l.RecordTypeId) && String.isNotBlank(l.GST_Number__c)) {
                // remove all whitespaces
                l.GST_Number__c = l.GST_Number__c.trim().replaceAll( '\\s+', '');
                // validate
                if(SM_Validator.isValidNZGSTNumber(l.GST_Number__c) == false) {
                    l.addError(ERROR_INVALID_GST_NUMBER);
                }
            }
        }
    }
    /**
    * @description      Check if updated GST Number is valid (for NZ Lead only)
    * @author           Yi Zhang | 20/07/2020 
    * @param            oldMap 
    * @param            newMap 
    **/
    public static void checkNZGSTNumber(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
        
        for(Lead oldLead : oldMap.values()) {
            Lead newLead = newMap.get(oldLead.Id);

            if(nzRecordTypeIds.contains(newLead.RecordTypeId) && oldLead.GST_Number__c != newLead.GST_Number__c && String.isNotBlank(newLead.GST_Number__c)) {
                // remove all whitespaces
                newLead.GST_Number__c = newLead.GST_Number__c.trim().replaceAll( '\\s+', '');
                // validate
                if(SM_Validator.isValidNZGSTNumber(newLead.GST_Number__c) == false) {
                    newLead.addError(ERROR_INVALID_GST_NUMBER);
                }
            }
        }
    }

    /**
    * @description 
    * @author Yi Zhang | 20/07/2020 
    * @return List<Id> 
    **/
    public static List<Id> nzRecordTypeIds {
        get {
            if(nzRecordTypeIds == null) {
                nzRecordTypeIds = new List<Id>();
                if(String.isNotBlank(System.Label.Record_Types_NZ_Lead)) {
                    Map<String, Schema.RecordTypeInfo> leadRTMap = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();
                    for(String rtDevName : leadRTMap.keySet()) {
                        if(System.Label.Record_Types_NZ_Lead.containsIgnoreCase(rtDevName)) {
                            nzRecordTypeIds.add(leadRTMap.get(rtDevName).getRecordTypeId());
                        }
                    }    
                }
            }
            return nzRecordTypeIds;
        } set;
    }
}