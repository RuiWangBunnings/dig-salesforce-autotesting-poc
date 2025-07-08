/*******************************************************************************************************
* Class Name      	: PricingAssignmentsTest
* Description		: PricingAssignment code coverage
* Author          	: Simplus - Francis Benzon
* Created On      	: 16/03/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Francis Benzon        16/03/2020		1000				Initial version
******************************************************************************************************/
@isTest
public class PricingAssignmentsTest {
    
    static testMethod void callAccountController() {
        //variables for returns
        List<Customer_Price_List__c>  customerPriceList = new List<Customer_Price_List__c>();
        List<Customer_Family_Tree_Discount__c> familyTreeDiscountLst = new List<Customer_Family_Tree_Discount__c>();
        
        //SPEND BAND Recs
        List<Spend_Band__c> spendBandList = new List<Spend_Band__c>();
        Spend_Band__c sb2 = new Spend_Band__c();
        sb2.Name = '2';
        sb2.Min_Amount__c = 25001;
        sb2.Max_Amount__c = 50000;
        spendBandList.add(sb2);
        
        Spend_Band__c sb3 = new Spend_Band__c();
        sb3.Name = '3';
        sb3.Min_Amount__c = 50001;
        sb3.Max_Amount__c = 100000;
        spendBandList.add(sb3);
        
        try {
            insert spendBandList;
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'SpendBandCreation', e);
        }
        
        //PRICE LISTS
        List<Price_List__c> plList = new List<Price_List__c>();
        Price_List__c pl = new Price_List__c();
        pl.Price_List_Name__c = 'Price List 1';
        pl.Spend_Band__c = spendBandList[0].ID;
        //pl.State__c = 'WA';
        plList.add(pl);
        
        Price_List__c pl2 = new Price_List__c();
        pl2.Price_List_Name__c = 'Price List 2';
        pl2.Spend_Band__c = spendBandList[1].ID;
        //pl2.State__c = 'VIC';
        plList.add(pl2);
        
        try {
            insert plList;
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'PriceListCreation', e);
        }
        
        //ACCOUNT Recs
        List<Account> acctList = TestDataFactory.createAccounts(2);
        //AU Account
        acctList[0].Country__c = 'Australia';
        acctList[0].Pricing_Assignment_Status__c = 'Pending Approval';
        acctList[0].Spend_Band__c = spendBandList[0].ID;    
        acctList[0].Proposed_Spend_Band__c = spendBandList[1].ID;
        acctList[0].RecordTypeId = CSUtils.getRecordTypeId('Account', 'AU Prospect');
        //NZ Account
        acctList[1].Country__c = 'New Zealand';
        acctList[1].RecordTypeId = CSUtils.getRecordTypeId('Account', 'NZ Prospect');
        
        try {
            upsert acctList;             
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'AccountQuery', e);
        }
        
        
        //CUSTOMER PRICE LISTS
        List<Customer_Price_List__c> cplList = new List<Customer_Price_List__c>();
        Customer_Price_List__c cpl = new Customer_Price_List__c();      
        cpl.Account__c = acctList[0].ID;
        cpl.Price_List__c = plList[0].ID;
        cpl.Status__c = 'Inactive';
        cpl.Pricing_Assignment_Status__c = 'Pending Assignment Approval';
        cplList.add(cpl);
        
        Customer_Price_List__c cpl2 = new Customer_Price_List__c(); 
        cpl2.Account__c = acctList[0].ID;
        cpl2.Price_List__c = plList[1].ID;
        cpl2.Status__c = 'Active';
        cpl2.Pricing_Assignment_Status__c = 'CPS Approved';
        cplList.add(cpl2);
        
        try {
            insert cplList;
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'PriceListCreation', e);
        }
                
        //FAMILY TREE DISCOUNTS
        List<Family_Tree_Discount__c> ftdList = new List<Family_Tree_Discount__c>();
        Family_Tree_Discount__c ftd1 = new Family_Tree_Discount__c();
        ftd1.Name = 'Oceania Retirement Villages';
        ftdList.add(ftd1);
        
        Family_Tree_Discount__c ftd2 = new Family_Tree_Discount__c();
        ftd2.Name = 'NZCPDG Pricefile';
        ftdList.add(ftd2);
        
        try {
            insert ftdList;
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'PriceListCreation', e);
        }
        
        //CUSTOMER FAMILY TREE DISCOUNTS
        List<Customer_Family_Tree_Discount__c> cftdList = new List<Customer_Family_Tree_Discount__c>();
        Customer_Family_Tree_Discount__c cftd1 = new Customer_Family_Tree_Discount__c();
        cftd1.Account__c = acctList[1].ID;
        cftd1.Family_Tree_Discount__c = ftdList[0].ID;
        cftd1.Status__c = 'Active';
        cftd1.Pricing_Assignment_Status__c = 'CPS Approved';
        cftdList.add(cftd1);
        
        Customer_Family_Tree_Discount__c cftd2 = new Customer_Family_Tree_Discount__c();
        cftd1.Account__c = acctList[1].ID;
        cftd1.Family_Tree_Discount__c = ftdList[1].ID;
        cftd1.Status__c = 'Inactive';
        cftd1.Pricing_Assignment_Status__c = 'Pending Assignment Approval';
        cftdList.add(cftd2);
        
        try {
            insert cftdList;
        }catch(Exception e){
            //ExceptionLogger.logException('callAccountController', 'PricingAssignmentsTest', 'PriceListCreation', e);
        }
        
        String auAcctID = String.valueOf(acctList[0].ID);
        String nzAcctID = String.valueOf(acctList[1].ID);
        String pendingApproval = 'Pending Assignment Approval';
        
        Test.StartTest();
        
        Account acct = AccountController.getAccountDetails(auAcctID);
        customerPriceList = AccountController.getCustomerPriceLists(auAcctID, pendingApproval);
        familyTreeDiscountLst = AccountController.getPendingCustomerPriceFiles(nzAcctID, pendingApproval);
        
        //for email templates
        AccountsPriceListsFamilyTree controllerclass = new AccountsPriceListsFamilyTree();
        //price lists
        controllerclass.accountId = auAcctID;
        Account acct2 = controllerclass.account;
        List<Price_List__c> inactivePriceLists = controllerclass.priceLists;
        List<Price_List__c> activePriceLists = controllerclass.currentPriceLists;
        
        //family tree discounts
        controllerclass.accountId = nzAcctID;
        List<Family_Tree_Discount__c> inactivefamTrees = controllerclass.famTreeDisc;
        List<Family_Tree_Discount__c> activefamTrees = controllerclass.activeFamTreeDisc;
        Test.StopTest();
    }
}