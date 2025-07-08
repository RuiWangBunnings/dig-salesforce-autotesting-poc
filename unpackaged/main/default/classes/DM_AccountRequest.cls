/*******************************************************************************************************
* Class Name        : DM_AccountRequest
* Description       : Data Layer - Selector for Sobject Account Request
* Author            : Bunnings Developer
* Created On        : 20/07/2024
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Buunings Dev          20/07/2024      1000                Initial version
* Buunings Dev          30/10/2024      1001                Bug fix for Bulk Acc transfer
* -----------------------------------------------------------------------------------------------------*/
public with sharing class DM_AccountRequest {
    
    

    /**
    *  Method name  :  getPowerpassNumbers
    *  Description  :  Retrieve all the powerpass number from the triggered records
    *  Author       :  Sowjanya   
    * @param        :  newList 
    **/
    public static Set<String> getPowerPassNumbers(List<Account_Request__c> lstNewAccountRequest) {
        
        Set<String> powerpassNumberSet =new Set<String>();
        if(lstNewAccountRequest.size()> 0){
            for (Account_Request__c ar : lstNewAccountRequest) {
                powerpassNumberSet.add(ar.PowerPass_Account_Number__c);
                
            }
        }
        
        return powerpassNumberSet;
    }

    /**
    *  Method name  :  getpowerpassNewOwnerMap
    *  Description  :  Retrieve all the powerpass number from the triggered records
    *  Author       :  Sowjanya   
    * @param        :  newAccReqList 
    **/
    public static Map<String,String> getpowerpassNewOwnerMap(List<Account_Request__c> newAccReqList) {

        Map<String,String> powerpassNewOwnerMap = new Map<String,String>();
        
        for (Account_Request__c ar : newAccReqList) {
            powerpassNewOwnerMap.put(ar.PowerPass_Account_Number__c,(Id)ar.New_Owner__c);
            
        }
        
        return powerpassNewOwnerMap;
    }

    
    /**
    *  Method name  :  getUserStatus
    *  Description  :  Retrieve all the users status from the triggered records
    *  Author       :  Sowjanya   
    * @param        :  power pass set 
    **/
    public static Map<String,Boolean> getUserStatus(List<Account_Request__c> newAccReqList) {

        Map<String,String> powerpassNewOwnerStatusMap=getpowerpassNewOwnerMap(newAccReqList);
        List<String> newOwnerList = powerpassNewOwnerStatusMap.values();
        Map<String,Boolean> mapNewUserStatus = new Map<String,Boolean>();

        //Query user details using powerpass numbers
        List<User> userList = [
            SELECT id, isActive 
            FROM User 
            WHERE id in :newOwnerList ];
        
        if(!userList.IsEmpty()){
            for (User usr : userList) {
                mapNewUserStatus.put((ID)(usr.Id),usr.isActive);
                
            }
        }
        
        return mapNewUserStatus;
    }

    /**
    *  Method name  :  getSingleAccountTransferRequests
    *  Description  :  Retrieve all the Single Account Requestrecords that is been pending for approva;
    *  Author       :  Sowjanya   
    * @param        :  accountId,transferToUserId
    **/
    public static List<Account_Request__c> getSingleAccountTransferRequests(String accountId,String transferToUserId) {

        //Query to retrieve all existing Account Request Transfer details
        return new List<Account_Request__c>([
            SELECT id, Account__c,Transfer_to__c, Status__c ,Transfer_approval_status__c
            FROM Account_Request__c 
            WHERE Account__c = :accountId 
            AND Type__c = 'Single Account Transfer'
            AND Transfer_approval_status__c = 'Submitted for approval'
            ]);
        
        
    }

    /**
    *  Method name  :  getPendingSingleAccountTransferRequest
    *  Description  :  Retrieve all the Single Account Requestrecords that is been pending for approva;
    *  Author       :  Sowjanya   
    * @param        :  accountId,transferToUserId
    **/
    public static List<Account_Request__c> getPendingSingleAccountTransferRequest(String accountId) {

        //Query to retrieve all existing Account Request Transfer details
        return new List<Account_Request__c>([
            SELECT id, Account__c,Transfer_to__c, Transfer_to__r.Name,Status__c ,Transfer_approval_status__c,AM_to_TS_Transfer__c,
            Is_transferable__c,Transfer_comments__c,TransferInitiator__r.Name,Non_TS_Manager__r.Name,Account_Owner_Sales_Id__c,Account__r.Owner.Sales_Rep_ID__c
            FROM Account_Request__c 
            WHERE Account__c = :accountId 
            AND Type__c = 'Single Account Transfer'
            AND Status__c = 'Pending Transfer'
            ORDER BY LastModifiedDate LIMIT 1
            ]);
        
        
    }
 
    /**
    *  Method name  :  getBulkAccountTransferRequests
    *  Description  :  Retrieve all the Single Account Requestrecords that is been pending for approva;
    *  Author       :  Sowjanya   
    * @param        :  accountId,transferToUserId
    **/
    public static List<Account_Request__c> getBulkAccountTransferRequests(String accountId,String transferToUserId) {

        //Query to retrieve all existing Account Request Transfer details
        return new List<Account_Request__c>([
            SELECT id, Account__c,Transfer_to__c, Status__c ,Transfer_approval_status__c
            FROM Account_Request__c 
            WHERE Account__c = :accountId 
            AND Transfer_to__c = :transferToUserId 
            AND Type__c = 'Bulk Account Transfer'
            AND Status__c = 'Pending Transfer'
            ]);
        
        
    }
    /**
    *  Method name  :  getBulkAccountTransferRequests
    *  Description  :  Retrieve all the Single Account Requestrecords that is been pending for approva;
    *  Author       :  Sowjanya   
    * @param        :  idList
    **/
    public static List<Account_Request__c> getAccountTransferRequests(List<id> idList) {

        //Query to retrieve all existing Account Request Transfer details
        return new List<Account_Request__c>([
            SELECT id, Account__c,Transfer_to__c, Status__c ,Transfer_approval_status__c
            FROM Account_Request__c 
            WHERE id = :idList 
            ]);
        
        
    }
    
    /**
    *  Method name  :  getAccountTransferRequestsByAccid
    *  Description  :  Retrieve all the Single Account Requestrecords that is been pending for approva;
    *  Author       :  Sowjanya   
    * @param        :  idList
    **/
    public static List<Account_Request__c> getAccountTransferRequestsByAccid(Set<id> idList) {

        //Query to retrieve all existing Account Request Transfer details
        return new List<Account_Request__c>([
            SELECT id, Account__c,Transfer_to__c, Status__c ,Transfer_approval_status__c,Previous_Owner__c,Failed_Reason__c,New_Owner__c,PowerPass_Account_Number__c
            FROM Account_Request__c 
            WHERE Account__c IN :idList 
            ]);
        
        
    } 
}