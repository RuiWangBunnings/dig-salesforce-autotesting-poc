/*******************************************************************************************************
* Class Name      	: AssistedSalesTemplateControllerTest
* Description		: Assisted Sales Template Test Class
* Author          	: Simplus - Francis Benzon
* Created On      	: 20/05/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        20/05/2020		1000				Initial version
******************************************************************************************************/
@isTest
private class AssistedSalesTemplateControllerTest {
	
	@isTest
	private static void TestAsstdSaleTemplateCtrl() {
		
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

		List<User> users = TestDataFactory.createUsers(1, p.Id);
		insert users;
		
		Test.StartTest();
			System.runAs(users[0]) {
				List<Account> acctList = TestDataFactory.createAccounts(1);
				acctList[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
				acctList[0].Country__c = 'Australia';
				insert acctList;
				
				List<Store__c> strLst = TestDataFactory.createStores(1);
				strLst[0].Country__c = acctList[0].Country__c;
				insert strLst;
				
				List<Product_Sub_Department__c>  psdLst = TestDataFactory.createProdSubDepartments(1);
				psdLst[0].Country__c = acctList[0].Country__c;
				insert psdLst;
				
				String storeID = String.valueOf(strLst[0].Id);
				String acctID = String.valueOf(acctList[0].Id);
				String psdId = String.valueOf(psdLst[0].Id);
				

				
				List<Assisted_Sales__c> asstdSaleList = TestDataFactory.createAssistedSales(acctID, 2);
				asstdSaleList[0].RecordTypeId = CSUtils.getRecordTypeId('Assisted_Sales__c', 'Category Assist');
				asstdSaleList[0].Country__c = acctList[0].Country__c;
				asstdSaleList[0].Team_Member__c = users[0].Id; 
				
				asstdSaleList[1].RecordTypeId = CSUtils.getRecordTypeId('Assisted_Sales__c', 'Store Assist');
				asstdSaleList[1].Country__c = acctList[0].Country__c;
				asstdSaleList[1].Team_Member__c = users[0].Id;
				insert asstdSaleList;
				
				String asstdSalesId1 = String.valueOf(asstdSaleList[0].Id);
				
				List<Store_Assist__c> strAsstList = TestDataFactory.createStoreAssists(asstdSalesId1, storeID, 1);
				strAsstList[0].Start_Date__c = Date.Today();
				strAsstList[0].End_Date__c = Date.Today() + 30;
				insert strAsstList;
				
				String asstdSalesId2 = String.valueOf(asstdSaleList[1].Id);
				
				List<Category_Assist__c> catAsstList = TestDataFactory.createCategoryAssists(asstdSalesId1, psdId, 1);
				catAsstList[0].Start_Date__c = Date.Today();
				catAsstList[0].End_Date__c = Date.Today() + 30;
				insert catAsstList;
			
				AssistedSalesTemplateController controllerclass  = new AssistedSalesTemplateController();
				controllerclass.assistedSaleId = String.valueOf(asstdSaleList[0].Id);
				List<Store_Assist__c> storeAssistList = controllerclass.storeAssistList;
				List<Category_Assist__c> categoryAssistList = controllerclass.categoryAssistList; 
			}
			
		
		Test.StopTest();
	}
	
		
}