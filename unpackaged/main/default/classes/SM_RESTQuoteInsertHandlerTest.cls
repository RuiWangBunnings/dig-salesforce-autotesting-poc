/***************************************************************************************************
* Class Name      	: SM_RESTQuoteInsertHandlerTest
* Description		: Test Class for SM_RESTQuoteInsertHandler 
* Author          	: Simplus MS
* Created On      	: 17-March-2021
* Modification Log	:
*****************************************************************************************************
* Developer				Date			Modification ID		Description
*****************************************************************************************************
* Simplus MS         17-March-2021		1000				Initial version
*****************************************************************************************************/
@isTest
public class SM_RESTQuoteInsertHandlerTest {
    
    /**
    * @description - Test CreateQuotes with unique reference Id
    * @author Simplus MS | 17/03/2021
    **/
    @isTest
    static void testDoPostRefIdDifferent(){
        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        Store__c store = new Store__c(
                Name = 'Test Store',
                Location_Code__c = '1010',
                Sales_Rep_ID__c = '600',
                Status__c = 'Active'                
            );
        insert store;

        String json = '{ "records": [{ "AccountId": "878798787", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654321", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": '+store.Location_Code__c+' }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "ref0010012" } }, {"AccountId": "878798780", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654322", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "enquiry", "Assigned_Store__r": { "Location_Code__c": '+store.Location_Code__c+' }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "ref0010013" } }, { "AccountId": "878798787", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654321", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "pricing only quote", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "ref0010014" } } ] }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/Quote/createQuotes';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(json);

        RestContext.request = req;
        RestContext.response= res;

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_INTEGRATIONS_USER LIMIT 1];
		List<User> users = TestDataFactory.createUsers(1, p.Id);
        Test.startTest();
		System.runAs (users[0]){
            SM_Configs__c settings = SM_Configs__c.getOrgDefaults();
            settings.Integration_User__c = System.UserInfo.getUserName();
            System.debug(System.UserInfo.getUserName());
            upsert settings;
            SM_RESTQuoteInsertHandler.createQuotes_Patch();
            
        }
        Test.stopTest();
        List<Quote> quote = [SELECT Id FROM Quote];
        System.assert(quote.size()>0);
    }

    /**
    * @description - Test CreateQuotes with same reference Id
    * @author Simplus MS | 17/03/2021
    **/
    @isTest
    static void testDoPostRefIdEqual(){
        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        String json = '{ "records": [{ "AccountId": "878798787", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654321", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "ref0010012" } }, {"AccountId": "878798780", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654322", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "ref0010012" } } ] }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/Quote/createQuotes';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(json);

        RestContext.request = req;
        RestContext.response= res;

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_INTEGRATIONS_USER LIMIT 1];
		List<User> users = TestDataFactory.createUsers(1, p.Id);
        Test.startTest();
		System.runAs (users[0]){
            SM_Configs__c settings = SM_Configs__c.getOrgDefaults();
            settings.Integration_User__c = System.UserInfo.getUserName();
            System.debug(System.UserInfo.getUserName());
            upsert settings;
            SM_RESTQuoteInsertHandler.createQuotes_Patch();
            
        }
        Test.stopTest();
        List<Quote> quote = [SELECT Id FROM Quote];
        System.assert(quote.size()==0);
    } 

  	/**
    * @description - Test CreateQuotes with no reference Id
    * @author Simplus MS | 17/03/2021
    **/
    @isTest
    static void testDoPostRefIdNull(){
        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        String json = '{ "records": [{ "AccountId": "878798787", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654321", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "" } }, {"AccountId": "878798780", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654322", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "" } } ] }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/Quote/createQuotes';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(json);

        RestContext.request = req;
        RestContext.response= res;

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_INTEGRATIONS_USER LIMIT 1];
		List<User> users = TestDataFactory.createUsers(1, p.Id);
        Test.startTest();
		System.runAs (users[0]){
            SM_Configs__c settings = SM_Configs__c.getOrgDefaults();
            settings.Integration_User__c = System.UserInfo.getUserName();
            System.debug(System.UserInfo.getUserName());
            upsert settings;
            SM_RESTQuoteInsertHandler.createQuotes_Patch();
        }
        Test.stopTest();
        List<Quote> quote = [SELECT Id FROM Quote];
        System.assert(quote.size()==0);
    } 

    /**
    * @description - Test CreateQuotes if user is not Integration User
    * @author Simplus MS | 17/03/2021
    **/
    @isTest
    static void testDoPostIsIntegUserFalse(){
        List<Account> accounts = TestDataFactory.createAccounts(10);
        accounts[0].OwnerId = UserInfo.getUserId();
        insert accounts;

        String json = '{ "records": [{ "AccountId": "878798787", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654321", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "" } }, {"AccountId": "878798780", "Cancellation_Comments__c": "Other", "Cancellation_Reason__c": "Other", "Comments__c": "random comment", "Contact_Name__c": "A Man", "Phone": "0410333333", "COS_Date__c": "2021-02-09T08:48:16.096Z", "COS_ID__c": "987654322", "COS_Token__c": "589e5dcb-05bf-43f7-944a-fcff757d360a", "Name": "3453456", "Country__c": "Australia", "Contact__Name_c": "abs", "Created_by_TM_name__c": "A Person", "Created_by_TM_Number__c": "88888888", "Customer_Job_Address__c": "1 job st, job city", "Customer_Job_Number__c": "45637", "Customer_Order_Number__c": "9999", "Delivery_Collection_Date__c": "2021-02-09", "ShippingCity":"Austinmer", "ShippingName": "Del Man", "Discount_incl_GST__c": 0.0, "ExpirationDate": "2021-02-08", "Follow_Up_Date__c": "2021-02-09", "Tax": 10.0, "Insurance__c": true, "Owned_by_restricted_team__c":"restricted team", "Status": "Submitted", "Assigned_Store__r": { "Location_Code__c": "1010" }, "Total_Cost_Excl_GST__c": 10.0, "Total_Cost_Incl_GST__c": 11.0, "Total_Value_excl_GST__c": 10.0, "Total_Value_incl_GST__c": 11.0, "Type__c": "Quote", "Type_of_Delivery__c": "Pickup", "Updated_by_TM_Name__c": "B Man", "Updated_by_TM_Number__c": "76234", "attributes": { "type": "Quote", "referenceId": "" } } ] }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/Quote/createQuotes';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(json);

        RestContext.request = req;
        RestContext.response= res;

        Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_INTEGRATIONS_USER LIMIT 1];
		List<User> users = TestDataFactory.createUsers(1, p.Id);
        Test.startTest();
		System.runAs (users[0]){
            SM_RESTQuoteInsertHandler.createQuotes_Patch();
        }
        Test.stopTest();
        List<Quote> quote = [SELECT Id FROM Quote];
        System.assert(quote.size()==0);
    } 
}