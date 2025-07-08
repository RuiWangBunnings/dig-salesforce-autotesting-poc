/*******************************************************************************************************
* Class Name        : TopicAssignmentTriggerHandler
* Description       : Topic Assignment Trigger Handler
* Author            : Simplus - Francis Benzon
* Created On        : 22/06/2020
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        22/06/2020      1000                Initial version
* Bob Alicante			26/11/2020		BMPSP-2 			CCRM-8524 - Fix for unable to add topic to some Umbrella Groups
* Bob Alicante			27/11/2020							CCRM-7804 - Topic updation and deletion for stores
******************************************************************************************************/
public without sharing class TopicAssignmentTriggerHandler {
    /**
    * @description 
    * @author Francis Benzon | 22/06/2020 
    * @param trigger.new 
    * @param newMap 
    * Update : Francis Benzon name auto capitalisation
    **/
    public static void afterInsert(List<TopicAssignment> lstNewTopicAssignment, Map<Id, TopicAssignment> mapNewTopicAssignment) {
        //system.assertEquals('TOPIC ASSIGNMENT NEW: ' , ' ' + lstNewTopicAssignment);
        Map<ID, ID> ugID_topicIDMap = new Map<ID, ID>();
        Map<ID, ID> opRegionID_topicIDMap = new Map<ID, ID>();
        
        for(TopicAssignment ta : lstNewTopicAssignment) {
            if(ta.EntityType == Label.Umbrella_Group_Api) {
                ugID_topicIDMap.put(ta.EntityId, ta.TopicId);               
            }
            
            if(ta.EntityType == Label.Op_Region_Api) {
                opRegionID_topicIDMap.put(ta.EntityId, ta.TopicId);
            }
        }
        
        if(!ugID_topicIDMap.isEmpty())
            createTopicsForAccounts(ugID_topicIDMap);
        
        if(!opRegionID_topicIDMap.isEmpty())
            createTopicsForStores(opRegionID_topicIDMap);
    }

    /**
    * @description 
    * @author Francis Benzon | 22/06/2020 
    * @param oldMap 
    * @param newMap 
    * Update : Francis Benzon name auto capitalisation
    **/
    public static void afterDelete(List<TopicAssignment> lstOldTopicAssignment, Map<Id, TopicAssignment> mapOldTopicAssignment) {
        //system.assertEquals('TOPIC ASSIGNMENT OLD: ' , ' ' + lstOldTopicAssignment);  

        Map<ID, ID> ugID_topicIDMap = new Map<ID, ID>();
        Map<ID, ID> opRegionID_topicIDMap = new Map<ID, ID>();
        
        for(TopicAssignment ta : lstOldTopicAssignment) {
            if(ta.EntityType == Label.Umbrella_Group_Api) {
                ugID_topicIDMap.put(ta.EntityId, ta.TopicId);               
            }
            
            if(ta.EntityType == Label.Op_Region_Api) {
                opRegionID_topicIDMap.put(ta.EntityId, ta.TopicId);
            }
        }
        
        if(!ugID_topicIDMap.isEmpty())
            deleteTopicsForAccounts(ugID_topicIDMap);
        if(!opRegionID_topicIDMap.isEmpty())
            deleteTopicsForStores(opRegionID_topicIDMap);
    }

    /**
    *   BMPSP-2 - CCRM-8524 Fix added in the below method.
    **/
    public static void createTopicsForAccounts(Map<ID, ID> ugID_topicIDMap) {
        //Map<ID, ID> acctID_ugIDMap = new Map<ID, ID>();
        List<TopicAssignment> topicAssignmentsToCreateList = new List<TopicAssignment>();
        Map<Id,Id> topicAssignmentMap = new Map<Id,Id>();
        for(Umbrella_Beneficiary__c ub : [SELECT ID, Account__c, Umbrella_Group__c FROM Umbrella_Beneficiary__c 
                                            WHERE Umbrella_Group__c IN :ugID_topicIDMap.keySet()]) 
        {
            if(ub.Account__c != null) {
                // CCRM-8524
                topicAssignmentMap.put(ub.Account__c, ugID_topicIDMap.get(ub.Umbrella_Group__c)); 
            } 
        }
        //system.AssertEquals('topicAssignmentsToCreateList : ' , ' ' + topicAssignmentsToCreateList);
        try {
            	// CCRM-8524 Issue Fix Start
                for(Id key: topicAssignmentMap.keySet()){
                    TopicAssignment ta = new TopicAssignment();
                    ta.EntityId = key;
                    ta.TopicID = topicAssignmentMap.get(key);
                    topicAssignmentsToCreateList.add(ta);
                }
            	
            	
            if(!topicAssignmentsToCreateList.isEmpty()){
                insert topicAssignmentsToCreateList;
            } 
            // CCRM-8524 Issue Fix End
        }catch(Exception e) {
            //logger here
        }               
    }
    
    public static void deleteTopicsForAccounts(Map<ID, ID> ugID_topicIDMap) {
        //system.AssertEquals('topicAssignmentsToCreateList : ' , ' ' + topicAssignmentsToCreateList);
        List<TopicAssignment> deleteTopicAssignmentList = new List<TopicAssignment>();
        //Set<ID> acctIDSet = new Set<ID>();
        Map<ID, ID> acctID_topicIDMap = new Map<ID, ID>();
        
        for(Umbrella_Beneficiary__c ub : [SELECT ID, Account__c, Umbrella_Group__c FROM Umbrella_Beneficiary__c 
                                            WHERE Umbrella_Group__c IN :ugID_topicIDMap.keySet()]) 
        {
            if(ub.Account__c != null) 
                acctID_topicIDMap.put(ub.Account__c, ugID_topicIDMap.get(ub.Umbrella_Group__c));
        }
        
        if(!acctID_topicIDMap.isEmpty()) {
            for(TopicAssignment ta : [SELECT ID, EntityId, TopicId FROM TopicAssignment 
                                        WHERE EntityId IN :acctID_topicIDMap.keySet()]) {
                if(acctID_topicIDMap.get(ta.EntityId) == ta.TopicId) {
                    deleteTopicAssignmentList.add(ta);
                }
            }
        }
        
        try {
            if(!deleteTopicAssignmentList.isEmpty()) delete deleteTopicAssignmentList;
        }catch(Exception e) {
            //logger here
        }               
    }
    
    public static void createTopicsForStores(Map<ID, ID> opRegionID_topicIDMap) {
        Map<String, ID> orName_orIDMap = new Map<String, ID>();
        List<TopicAssignment> topicAssignmentsToCreateList = new List<TopicAssignment>();
        
        
        for(Operations_Region__c opReg : [SELECT ID, Name FROM Operations_Region__c WHERE ID IN :opRegionID_topicIDMap.keySet()])
        {
            orName_orIDMap.put(opReg.Name, opReg.ID);
        }
        
        for(Store__c st : [SELECT ID, Operations_Region_Code__c FROM Store__c 
                            WHERE Operations_Region_Code__c IN :orName_orIDMap.keySet()]) 
        {
            TopicAssignment ta = new TopicAssignment();
            ta.EntityId = st.ID;
            ta.TopicID = opRegionID_topicIDMap.get(orName_orIDMap.get(st.Operations_Region_Code__c));
            
            topicAssignmentsToCreateList.add(ta);
        }
        
        try {
            if(!topicAssignmentsToCreateList.isEmpty()) insert topicAssignmentsToCreateList;
        }catch(Exception e) {
            //logger here
        }       
    }
    
    public static void deleteTopicsForStores(Map<ID, ID> opRegionID_topicIDMap) {
        //system.AssertEquals('topicAssignmentsToCreateList : ' , ' ' + topicAssignmentsToCreateList);
        List<TopicAssignment> deleteTopicAssignmentList = new List<TopicAssignment>();
        Map<String, ID> orName_orIDMap = new Map<String, ID>();
        
        for(Operations_Region__c opReg : [SELECT ID, Name FROM Operations_Region__c WHERE ID IN :opRegionID_topicIDMap.keySet()])
        {
            orName_orIDMap.put(opReg.Name, opReg.ID);
        }
        
        for(TopicAssignment ta : [SELECT ID FROM TopicAssignment 
                                    WHERE EntityId IN  
                                    (SELECT ID FROM Store__c WHERE Operations_Region_Code__c IN :orName_orIDMap.keySet()) 
                                    AND TopicId IN : opRegionID_topicIDMap.values()]) 
        {
            deleteTopicAssignmentList.add(ta);
        }
        
        try {
            if(!deleteTopicAssignmentList.isEmpty()) delete deleteTopicAssignmentList;
        }catch(Exception e) {
            //logger here
        }       
    }

    /**
    * @description Ths method validates the user who is inserting the topic on store record
		and if store location does not match user location then it will throw an error message.
	// Added this method for ticket [CCRM-7804]
    * @author bob.alicante | 19/11/2020
    * @param trigger.new
    **/
    public static void beforeInsert(List<TopicAssignment> listTopicAssignments) {
		System.debug('inside beforeInsert');
		verifyUserBeforeDML(listTopicAssignments, true);
	}

	/**
    * @description Ths method validates the user who is deleting the topic on store record
		and if store location does not match user location then it will throw an error message.
	// Added this method for ticket [CCRM-7804]
    * @author bob.alicante | 27/11/2020
    * @param trigger.new
    **/
    public static void beforeDelete(List<TopicAssignment> listTopicAssignments) {
		verifyUserBeforeDML(listTopicAssignments, false);
    }

    /**
    * @description Ths method validates the user who is performing DML on the topic on store record
		and if store location does not match user location then it will throw an error message.
	// Added this method for ticket [CCRM-7804]
    * @author bob.alicante | 19/11/2020
    * @param trigger.new
    **/
	public static void verifyUserBeforeDML(
		List<TopicAssignment> listTopicAssignments,
		Boolean isInsert
	) {
		Set<Id> setEntityId = new set<Id>();
        Map<Id, Store__c> mapStores = new Map<Id, Store__c>();
        User objUser = [
            SELECT
                Id,
                Location_Code__c,
                Is_TS__c
            FROM
                User
            WHERE
                Id = :UserInfo.getUserId()
            LIMIT
                1
		];

        for (TopicAssignment objTopic : listTopicAssignments) {
            if (getSobjectName(objTopic.EntityId)  == System.Label.Topic_Assignment_Entity) {
                setEntityId.add(objTopic.EntityId);
            }
            System.debug(setEntityId);
        }

        if (!setEntityId.isEmpty()) {
            for (Store__c objStore : [
                SELECT
                    Id,
                    Location_Code__c
                FROM
                    Store__c
                WHERE
                    Id
                IN
                    :setEntityId
            ]) {
                mapStores.put(objStore.Id, objStore);
            }

            for (TopicAssignment objTopic : listTopicAssignments) {
                if (
                    mapStores.containsKey(objTopic.EntityId)
                    && mapStores.get(objTopic.EntityId).Location_Code__c != objUser.Location_Code__c
                    && objUser.Is_TS__c
                ) {
					if (isInsert) {
						objTopic.addError('You do not have permission to edit the topics');
					}
					else {
						objTopic.addError('You do not have permission to delete the topics');
					}
                }
            }
        }
	}

    /**
	* @description This method takes record Id and returns its Object name.
	// Added this method for ticket [CCRM-7804]
    * @author bob.alicante | 27/11/2020
    * @param Id
    **/
	public static String getSobjectName(Id recordId) {
        return recordId.getSObjectType().getDescribe().getName();
	}
}