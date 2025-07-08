/*******************************************************************************************************
* Class Name      	: DM_ContractLineItem
* Description		: Data Layer - Selector for Sobject Contract_Line_Item__c
* Author          	: Simplus - Yi Zhang
* Created On      	: 2020-05-22
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              2020-05-22		1000				Initial version
* Jasper R Galapon      2023-08-08      1001                BUNDIG-23679 - Contract Amendments - A2 Approval Required for New Line Items
* Jasper R Galapon      2023-08-25      1002                BUNDIG-19094/19095 - New method added to get Contract Line Amendment Reviewer/Approver
* Jasper R Galapon      2024-09-05      1003                BUNDIG-35631 - Added a new criteria at getAmendmentItemsByReviewOrApprover method
* Jasper R Galapon      2024-09-06      1004                BUNDIG-35764 - Amendment Review Page - Update Line Items With Auto Approval Details
* Jasper R Galapon      2024-09-09      1005                BUNDIG-35762 - Amendment Review Page - Add New Auto Approval Alert

******************************************************************************************************/
public with sharing class DM_ContractLineItem {

    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param contractLineItemId 
    * @return Contract_Line_Item__c 
    **/
    public static Contract_Line_Item__c getItem(String contractLineItemId) {
        return getItems(new List<String>{contractLineItemId})[0];
    }

    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param contractLineItemIds 
    * @return List<Contract_Line_Item__c> 
    **/
    public static List<Contract_Line_Item__c> getItems(List<String> contractLineItemIds) {
        return [
            SELECT Id, Name, Contract__c, Contract__r.Contract_Locked__c, Line_Status__c,
            Price_CZ1__c,  // CZ1 Sell (Ex-GST)
            Price_CZ2__c,  // CZ2 Sell (Ex-GST) 
            Price_CZ3__c,  // CZ3 Sell (Ex-GST) 
            Price_CZ4__c,  // CZ4 Sell (Ex-GST) 
            Price_CZ5__c,  // CZ5 Sell (Ex-GST) 
            Price_CZ6__c,  // CZ6 Sell (Ex-GST) 
            Price_CZ7__c,  // CZ7 Sell (Ex-GST)
            Cost_CZ1__c,   // CZ1 Cost
            Cost_CZ2__c,   // CZ2 Cost
            Cost_CZ3__c,   // CZ3 Cost
            Cost_CZ4__c,   // CZ4 Cost
            Cost_CZ5__c,   // CZ5 Cost
            Cost_CZ6__c,   // CZ6 Cost
            Cost_CZ7__c,   // CZ7 Cost
            Previous_Margin_CZ1__c, // Previous CZ1 Margin %
            Previous_Margin_CZ2__c, // Previous CZ2 Margin % 
            Previous_Margin_CZ3__c, // Previous CZ3 Margin % 
            Previous_Margin_CZ4__c, // Previous CZ4 Margin % 
            Previous_Margin_CZ5__c, // Previous CZ5 Margin % 
            Previous_Margin_CZ6__c, // Previous CZ6 Margin % 
            Previous_Margin_CZ7__c, // Previous CZ7 Margin %
            Previous_Cost_CZ1__c,   // Previous CZ1 Cost
            Previous_Cost_CZ2__c,   // Previous CZ2 Cost
            Previous_Cost_CZ3__c,   // Previous CZ3 Cost
            Previous_Cost_CZ4__c,   // Previous CZ4 Cost
            Previous_Cost_CZ5__c,   // Previous CZ5 Cost
            Previous_Cost_CZ6__c,   // Previous CZ6 Cost
            Previous_Cost_CZ7__c,   // Previous CZ7 Cost
            Amendment_Type__c,
            Start_Date__c,
            Original_Start_Date__c
            FROM Contract_Line_Item__c
            WHERE Id IN :contractLineItemIds
        ];
    }

    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param contractId 
    * @return Integer 
    **/
    public static Integer getAmendmentItems(String contractId) {
        return [
            SELECT COUNT() 
            FROM Contract_Line_Item__c 
            WHERE Contract__c = :contractId
            AND Line_Type__c = 'Amendment'
            ];
    }

    /**
    * @description 
    * @author Yi Zhang | 22/05/2020 
    * @param contractId 
    * @return List<Contract_Line_Item__c> 
    **/
    public static List<Contract_Line_Item__c> getItemsForDynamicFiltering(String contractId) {
        return new List<Contract_Line_Item__c>([
            SELECT Id, 
            Item_Department__c,
            Item_Sub_Department__c,
            Item_Class__c
            FROM Contract_Line_Item__c
            WHERE Contract__c = :contractId
        ]);
    }

    /**
    * @description 
    * @author Yi Zhang | 11/06/2020 
    * @param contractId 
    * @param lineTypes 
    * @param lineStatuses 
    * @return List<Contract_Line_Item__c>
    **/
    public static List<Contract_Line_Item__c> getItemsWithSpecialBuyItems(String contractId, List<String> lineTypes, List<String> lineStatuses) {
        return new List<Contract_Line_Item__c>([
            SELECT Id, Contract__c, 
            // contract line item fields
            Name, 
            Special_Buy_Item__c, 
            Enabled__c, 
            Amendment_Type__c, 
            Start_Date__c, 
            End_Date__c, 
            Upload_Reason__c, 
            Approver__c, Approver__r.Name, Approver_Action__c, Approver_Action_Date__c, Approver_Comments__c, 
            Reviewer__c, Reviewer__r.Name, Reviewer_Action__c, Reviewer_Action_Date__c, Reviewer_Comments__c, 
            Price_CZ1__c, 
            Price_CZ2__c, 
            Price_CZ3__c, 
            Price_CZ4__c, 
            Price_CZ5__c, 
            Price_CZ6__c, 
            Price_CZ7__c, 
            Retail_Price_CZ1__c,
            Retail_Price_CZ2__c,
            Retail_Price_CZ3__c,
            Retail_Price_CZ4__c,
            Retail_Price_CZ5__c,
            Retail_Price_CZ6__c,
            Retail_Price_CZ7__c,
            R12_Sales__c, 
            Item_Department__c, 
            Item_Sub_Department__c,
            Item_Description__c,
            Item_Class__c, 
            Previous_Margin_CZ1__c, 
            Previous_Margin_CZ2__c, 
            Previous_Margin_CZ3__c, 
            Previous_Margin_CZ4__c, 
            Previous_Margin_CZ5__c, 
            Previous_Margin_CZ6__c, 
            Previous_Margin_CZ7__c, 
            Previous_Sales_CZ1__c, Previous_Sales_CZ2__c, Previous_Sales_CZ3__c,
            Previous_Sales_CZ4__c, Previous_Sales_CZ5__c, Previous_Sales_CZ6__c, 
            Previous_Sales_CZ7__c, Previous_COGS_CZ1__c, Previous_COGS_CZ2__c, 
            Previous_COGS_CZ3__c, Previous_COGS_CZ4__c, Previous_COGS_CZ5__c,Previous_COGS_CZ6__c,
            Previous_COGS_CZ7__c, Previous_Sales_Qty_CZ1__c,Previous_Sales_Qty_CZ2__c,
            Previous_Sales_Qty_CZ3__c,Previous_Sales_Qty_CZ4__c,
            Previous_Sales_Qty_CZ5__c,Previous_Sales_Qty_CZ6__c ,Previous_Sales_Qty_CZ7__c,
            Cost_CZ1__c,Cost_CZ2__c,Cost_CZ3__c,Cost_CZ4__c,Cost_CZ5__c,Cost_CZ6__c, Cost_CZ7__c,
            Previous_Price_CZ1__c, 
            Previous_Price_CZ2__c, 
            Previous_Price_CZ3__c, 
            Previous_Price_CZ4__c, 
            Previous_Price_CZ5__c, 
            Previous_Price_CZ6__c, 
            Previous_Price_CZ7__c,
            Previous_Cost_CZ1__c, 
            Previous_Cost_CZ2__c, 
            Previous_Cost_CZ3__c, 
            Previous_Cost_CZ4__c, 
            Previous_Cost_CZ5__c, 
            Previous_Cost_CZ6__c, 
            Previous_Cost_CZ7__c, 
            // special buy line item fields
            Special_Buy_Item__r.Id, 
            Special_Buy_Item__r.Name,                                   // Item Number
            Special_Buy_Item__r.Cost__c,                                // Special Buy Cost (Ex-GST) ($)
            //Special_Buy_Item__r.
            // special buy fields
            Special_Buy_Item__r.Special_Buy__r.Id,
            Special_Buy_Item__r.Special_Buy__r.Name,                    // supplier quote number
            Special_Buy_Item__r.Special_Buy__r.Requested_Date__c,       // start date
            Special_Buy_Item__r.Special_Buy__r.Expiry_Date__c,          // end date
            Special_Buy_Item__r.Special_Buy__r.Location_Type__c,        // location type
            Special_Buy_Item__r.Special_Buy__r.States__c               // states
            FROM Contract_Line_Item__c
            WHERE Contract__c = :contractId
            AND Line_Type__c IN :lineTypes
            AND Line_Status__c IN :lineStatuses
            ORDER BY Name ASC
        ]);
    }

    /**
    * @description 
    * @author Jasper R Galapon | BUNDIG-19094 | 21/08/2023
    * @param contractId 
    * @param lineTypes 
    * @param lineStatuses 
    * @param reviewerOrApprover
    * @return List<Contract_Line_Item__c>
    **/
    public static List<Contract_Line_Item__c> getAmendmentItemsByReviewOrApprover(String contractId, List<String> lineTypes, List<String> lineStatuses, String reviewerOrApprover) {

        List<Contract_Line_Item__c> cli = new List<Contract_Line_Item__c>();
        String query;
        String addWhereClause = '';

        if (reviewerOrApprover == 'Reviewer')
            addWhereClause = 'AND Reviewer_Action__c = \'' + '' + '\' ';
        if (reviewerOrApprover == 'Approver')
            addWhereClause = 'AND Approver_Action__c = \'' + '' + '\' ';

        System.debug(LoggingLevel.FINEST, '***addWhereClause: ' + addWhereClause);

        query = 'SELECT Id, Contract__c, Name, Special_Buy_Item__c, Enabled__c, Amendment_Type__c, Start_Date__c, End_Date__c, Upload_Reason__c, ';
        query += 'Approver__c, Approver__r.Name, Approver_Action__c, Approver_Action_Date__c, Approver_Comments__c, ';
        query += 'Reviewer__c, Reviewer__r.Name, Reviewer_Action__c, Reviewer_Action_Date__c, Reviewer_Comments__c, ';
        query += 'Price_CZ1__c, Price_CZ2__c, Price_CZ3__c, Price_CZ4__c, Price_CZ5__c, Price_CZ6__c, Price_CZ7__c, ';
        query += 'Retail_Price_CZ1__c, Retail_Price_CZ2__c, Retail_Price_CZ3__c, Retail_Price_CZ4__c, Retail_Price_CZ5__c, Retail_Price_CZ6__c, Retail_Price_CZ7__c, ';
        query += 'R12_Sales__c, Item_Department__c, Item_Sub_Department__c, Item_Description__c, Item_Class__c, ';
        query += 'Previous_Margin_CZ1__c, Previous_Margin_CZ2__c, Previous_Margin_CZ3__c, Previous_Margin_CZ4__c, Previous_Margin_CZ5__c, Previous_Margin_CZ6__c, Previous_Margin_CZ7__c, ';        
        query += 'Previous_Sales_CZ1__c, Previous_Sales_CZ2__c, Previous_Sales_CZ3__c, ';
        query += 'Previous_Sales_CZ4__c, Previous_Sales_CZ5__c, Previous_Sales_CZ6__c, '; 
        query += 'Previous_Sales_CZ7__c, Previous_COGS_CZ1__c, Previous_COGS_CZ2__c, '; 
        query += 'Previous_COGS_CZ3__c, Previous_COGS_CZ4__c, Previous_COGS_CZ5__c,Previous_COGS_CZ6__c, ';
        query += 'Previous_COGS_CZ7__c, Previous_Sales_Qty_CZ1__c,Previous_Sales_Qty_CZ2__c, ';
        query += 'Previous_Sales_Qty_CZ3__c,Previous_Sales_Qty_CZ4__c, ';
        query += 'Previous_Sales_Qty_CZ5__c,Previous_Sales_Qty_CZ6__c ,Previous_Sales_Qty_CZ7__c, ';
        query += 'Cost_CZ1__c,Cost_CZ2__c,Cost_CZ3__c,Cost_CZ4__c,Cost_CZ5__c,Cost_CZ6__c, Cost_CZ7__c, ';
        query += 'Previous_Price_CZ1__c, Previous_Price_CZ2__c, Previous_Price_CZ3__c, Previous_Price_CZ4__c, Previous_Price_CZ5__c, Previous_Price_CZ6__c, Previous_Price_CZ7__c, ';
        query += 'Previous_Cost_CZ1__c, Previous_Cost_CZ2__c, Previous_Cost_CZ3__c, Previous_Cost_CZ4__c, Previous_Cost_CZ5__c, Previous_Cost_CZ6__c, Previous_Cost_CZ7__c, '; 
        query += 'Auto_Approval_Eligibility__c, '; // BUNDIG-35631
        query += 'Auto_Approval_Date__c '; // BUNDIG-35764
        query += 'FROM Contract_Line_Item__c ';
        query += 'WHERE Contract__c = :contractId ';
        query += 'AND Line_Type__c IN :lineTypes ';
        query += 'AND Line_Status__c IN :lineStatuses ';
        query += 'AND Auto_Approved__c = false '; // BUNDIG-35631 - New criteria for Auto Approval
        query += addWhereClause;
        query += 'ORDER BY Name ASC ';

        cli = Database.query(query);

        System.debug(LoggingLevel.FINEST, '***query: ' + query);

        return cli;
    }

    /**
    * @description 
    * @author Jasper R Galapon | BUNDIG-35762 | 30/08/2024
    * @description Use to check if contract hsa amendment lines that are eligible for auto approval
    * @param contractId
    * @param lineStatus
    * @return List<Contract_Line_Item__c> - Amendment Lines
    **/
    @AuraEnabled
    public static List<Contract_Line_Item__c> countAmendmentLines(String contractId, String lineStatus) {
        return [
            SELECT Id, Name, Contract__c, Amendment_Type__c
            FROM Contract_Line_Item__c 
            WHERE Contract__c = :contractId
            AND Line_Status__c = :lineStatus
            AND Auto_Approval_Eligibility__c = true
            AND Auto_Approved__c = false
            AND Reviewer_Action__c = ''
            AND Line_Type__c = 'Amendment'
            ];
    }
    
}