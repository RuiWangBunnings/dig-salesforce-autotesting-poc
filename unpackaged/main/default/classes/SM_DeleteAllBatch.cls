//************************************************************************************************ */
// Important Note  - This class should not be deployed to Production. This is an interim solution
//                   to purge data as needed for regression testing.
//
// Notes for Admin - Have this as a class when ever you need to delete all data for testing. 
//                   Execute the batch job from developer console.
//                   Developer Console -> Execute Anonymous -> Paste the following :
//
//                   Id batchJobId = Database.executeBatch(new SM_DeleteAllBatch(), 2000);
//
// Author : Purba Ghosh | Date : 25-09-2020
//************************************************************************************************ */
global class SM_DeleteAllBatch implements Database.Batchable<sObject>, Schedulable {

    // Initialisations
	String countQuery;
    String query;
	String objName;
	Integer objectSerialNo;
	Integer totalRecords;
	Map<Integer,String> objectOrderMap = new Map<Integer,String>();

    // Constructor
    global SM_DeleteAllBatch() {
	
		this.objectSerialNo = 1;
        
        // Please include standalone objects as Detail object records 
        // get deleted when their Masters get deleted. Please remember 
        // dependency order while adding to the map as you can not  
        // delete a record which is deemed mandatory by another record.
		objectOrderMap.put(1,'Store__c');
		objectOrderMap.put(2,'Operations_Region__c');
		objectOrderMap.put(3,'Sales_Rep__c');
		objectOrderMap.put(4,'Sales_Rep_Sales_Summary__c');
		objectOrderMap.put(5,'Segment__c');
		objectOrderMap.put(6,'Pricing_Assignment_Visibility__c');
		objectOrderMap.put(7,'Price_List__c');
		objectOrderMap.put(8,'Price_List_Definition__c');
		objectOrderMap.put(9,'Family_Tree_Discount__c');
		objectOrderMap.put(10,'Special_Buy__c');
		objectOrderMap.put(11,'Project__c');
		objectOrderMap.put(12,'Contract__c');
		objectOrderMap.put(13,'Spend_Band_Review__c');
		objectOrderMap.put(14,'Spend_Band__c');
		objectOrderMap.put(15,'Umbrella_Group__c');
		objectOrderMap.put(16,'Campaign');
		objectOrderMap.put(17,'Call_Plan_Leave__c');
		objectOrderMap.put(18,'Call_Targets__c');
		objectOrderMap.put(19,'Assisted_Sales__c');
		objectOrderMap.put(20,'Product_Sub_Department__c');
		objectOrderMap.put(21,'Lead');
		objectOrderMap.put(22,'Post_Code__c');
		objectOrderMap.put(23,'Opportunity');
        objectOrderMap.put(24,'Case');
        objectOrderMap.put(25,'Task');
		objectOrderMap.put(26,'Event');
		objectOrderMap.put(27,'Contact');
		objectOrderMap.put(28,'Account_Group__c');
		objectOrderMap.put(29,'Account');
		objectOrderMap.put(30,'ApplicationLog__c');
		
		objName = objectOrderMap.get(objectSerialNo);
		query = 'SELECT Id FROM ' + objName;
    }
    
    // Parameterised Constructor for subsequent batch invocations
	global SM_DeleteAllBatch(Integer objectSerialNo, Map<Integer,String> objectOrderMap) {
        this.objectSerialNo = objectSerialNo;
        this.objectOrderMap = objectOrderMap;
        
		objName = objectOrderMap.get(objectSerialNo);
		query = 'SELECT Id FROM ' + objName;
	}

    // Batch start method to query scope
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    // Batch execute method to delete the queried scope of records
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
		Delete scope;
    }
 
    // Batch finish method to trigger any further invocations of the same
    public void finish(Database.BatchableContext BC) {
        countQuery = 'SELECT Count() FROM ' + objName;
        totalRecords = Database.countQuery(countQuery);
        
		if(totalRecords == 0 ) {
			objectSerialNo++;
        }
        
        if(objectOrderMap.containsKey(objectSerialNo)) {
            Database.executeBatch(new SM_DeleteAllBatch(objectSerialNo,objectOrderMap), 2000);
        }
    }

    // Batch execute method for scheduling if needed
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_DeleteAllBatch(), 2000);
    }
}