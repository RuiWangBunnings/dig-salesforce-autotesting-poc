/*******************************************************************************************************
* Class Name      	: SM_ResponseBatch
* Description		: Batch class to update Account Id of Responses
* Author          	: Simplus - MS
* Created On      	: 23/12/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            23/12/2021		1000				Initial version [CCRM15-542]
* Bunnings Team			8/7/2022		1100				SFSUP-771 
******************************************************************************************************/
public class SM_ResponseBatch implements Database.Batchable<sObject>, Schedulable {

    String query;
    
    public SM_ResponseBatch() {
        
        query = 'SELECT Id, Name, Power_Pass_Account_Number__c, medallia_xm__Account_Id__c, medallia_xm__Contact_Id__c, medallia_xm__Medallia_Feedback_Header__c, ' + 
            ' Is_Owned_By_Dummy_Account__c, medallia_xm__Medallia_Feedback_Header__r.Name ' +
            ' FROM medallia_xm__Medallia_Feedback__c ' +  
            ' WHERE Power_Pass_Account_Number__c != null and Is_Owned_By_Dummy_Account__c = TRUE ';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('***query: '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<medallia_xm__Medallia_Feedback__c> scope) {
        // execute code
        System.debug('***scope: '+scope);
        
        if(scope.isEmpty()) {
            return;
        }
        
        Boolean check = False;
        List<sObject> lResponsesAndHeadersToReturn = new List<sObject>();
        List<sObject> newHeaderToReturn = new List<sObject>();
        List<sObject> medalliaFeedback = new List<sObject>();
        List<Id> headerIds = new List<Id>();
        
        //comment out for SFSUP-771. Replace
        //lResponsesAndHeadersToReturn = setAccountIds(scope);
        newHeaderToReturn = createNewHeader(scope);//for SFSUP-771
        
        /*comment out for SFSUP-771
        try {
            if (!lResponsesAndHeadersToReturn.isEmpty()){
                System.debug('lResponsesAndHeadersToReturn '+lResponsesAndHeadersToReturn);
                update lResponsesAndHeadersToReturn;
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_ResponseBatch', 'medallia_xm__Medallia_Feedback__c', 'Batch', e);
        }*/
        //SFSUP-771
        try {
            if (!newHeaderToReturn.isEmpty()){
                System.debug('newHeaderToReturn '+newHeaderToReturn);
                Database.SaveResult[] srList = Database.insert(newHeaderToReturn);
                System.debug('srList '+srList);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        check = true;
                        System.debug('Successfully inserted ID: ' + sr.getId());
                        headerIds.add(sr.getId());
                    }
                }
                System.debug('headerIds ' + headerIds);
                if (!headerIds.isEmpty()){
                    medalliaFeedback = updateMFeedBack(scope, headerIds);
                    update medalliaFeedback;
                }    
            }
        } catch(Exception e) {
            ApplicationLogger.log('SM_ResponseBatch', 'medallia_xm__Medallia_Feedback_Header__c', 'Batch', e);
        }
        //End of SFSUP-771
        
    }
    
    //For SFSUP-771
    //Find existing Medallia Header per Powerpass Number
    //If it exists, associate the new feedback to the existing header
    //Otherwise, create new header for the new feedback and assosicate to the account
    private static List<sObject> createNewHeader (list<medallia_xm__Medallia_Feedback__c> lResponse){
        List<String> acctPowerPassAccountNo = new List<String>();
        List<sObject> insertFeedBackHeaderList = new List<sObject>();
        List<medallia_xm__Medallia_Feedback__c> listFeedBackToUpdate = new List<medallia_xm__Medallia_Feedback__c>();
        Map<Id,Id> accountAndHeaderId = new Map<Id,Id>();
        Map<String,Id> accountPowerPassNoAndId = new Map<String,Id>();
        Map<String, List<medallia_xm__Medallia_Feedback__c>> mapAcctPowerPassAccountNo = New Map<String, List<medallia_xm__Medallia_Feedback__c>>();
        
		Initialisation__mdt dummyAccount = Initialisation__mdt.getAll().values();			

        for(medallia_xm__Medallia_Feedback__c mf : lResponse) {
            System.debug('mf '+mf.Power_Pass_Account_Number__c);
            System.debug('mf.Power_Pass_Account_Number__c:'+ mf.Power_Pass_Account_Number__c);
            System.debug('mf.medallia_xm__Account_Id__c :'+ mf.medallia_xm__Account_Id__c );
            System.debug('dummyAccount.CCRM_Dummy_Account_Id__c :'+ dummyAccount.CCRM_Dummy_Account_Id__c );
            
            //
            if(mf.Power_Pass_Account_Number__c != null) {
                acctPowerPassAccountNo.add(mf.Power_Pass_Account_Number__c);                
                if(!mapAcctPowerPassAccountNo.containsKey(mf.Power_Pass_Account_Number__c)){
                    List<medallia_xm__Medallia_Feedback__c> listTempMF = new List<medallia_xm__Medallia_Feedback__c>();
                    listTempMF.add(mf);
                	mapAcctPowerPassAccountNo.put(mf.Power_Pass_Account_Number__c, listTempMF);    
                }
                else{
                    List<medallia_xm__Medallia_Feedback__c> listTempMF = new List<medallia_xm__Medallia_Feedback__c>();
                    listTempMF = mapAcctPowerPassAccountNo.get(mf.Power_Pass_Account_Number__c);
                    listTempMF.add(mf);
                    mapAcctPowerPassAccountNo.put(mf.Power_Pass_Account_Number__c, listTempMF); 
                }                
            }
        }
        
        system.debug('acctPowerPassAccountNo:' + acctPowerPassAccountNo);
        
        List<Account> acctRecords = [Select Id, Power_Pass_Account_Number__c From Account Where Power_Pass_Account_Number__c IN :mapAcctPowerPassAccountNo.keyset()];
        System.debug('acctRecords '+acctRecords);
        
        for (medallia_xm__Medallia_Feedback_Header__c feedBackH: [Select Id, medallia_xm__Account__c From medallia_xm__Medallia_Feedback_Header__c]) {
            if(feedBackH.medallia_xm__Account__c != dummyAccount.CCRM_Dummy_Account_Id__c){
                accountAndHeaderId.put(feedBackH.medallia_xm__Account__c, feedBackH.Id);
            }
        }
        
        System.debug('accountAndHeaderId '+accountAndHeaderId);
        
        for(Account acct: acctRecords) {
            System.debug('acct: '+acct);
            System.debug('mapAcctPowerPassAccountNo.containsKey(acct.Power_Pass_Account_Number__c):' + mapAcctPowerPassAccountNo.containsKey(acct.Power_Pass_Account_Number__c));
            
            //Check if the account has existing Medallia header
            //If no match, create new header
            //If yes, associate the existing header to new feedback response
            if(!accountAndHeaderId.containsKey(acct.Id)) {
                System.debug('new header to create for:'+ acct.Id);
                accountPowerPassNoAndId.put(acct.Power_Pass_Account_Number__c, acct.Id);
                medallia_xm__Medallia_Feedback_Header__c newHeaderRecord = new medallia_xm__Medallia_Feedback_Header__c();
                newHeaderRecord.medallia_xm__Account__c = acct.Id;
                insertFeedBackHeaderList.add(newHeaderRecord);
            }
            else if(mapAcctPowerPassAccountNo.containsKey(acct.Power_Pass_Account_Number__c)){
                System.debug('existing header to asosciate for:' + acct.Power_Pass_Account_Number__c);
                List<medallia_xm__Medallia_Feedback__c> listTempMF = mapAcctPowerPassAccountNo.get(acct.Power_Pass_Account_Number__c);
                for(medallia_xm__Medallia_Feedback__c mfTemp :listTempMF){
                    System.debug('mfTemp:' + mfTemp);
                    mfTemp.medallia_xm__Medallia_Feedback_Header__c = accountAndHeaderId.get(acct.Id);
                    listFeedBackToUpdate.add(mfTemp);                    
                }
            }
        }
        System.debug('insertFeedBackHeaderList '+insertFeedBackHeaderList);
        System.debug('listFeedBackToUpdate:' + listFeedBackToUpdate);
        
        //Update feedback with existing Medallia header
        if(!listFeedBackToUpdate.isEmpty()){
            try{
            	Database.SaveResult[] srList = Database.update(listFeedBackToUpdate, false);
                for (Database.SaveResult result : srList) {
                  if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                      System.debug('Error: '+ result.getId() + ' ' + err.getStatusCode() + ' ' + err.getMessage()); 
                    }
                  }
                }
            }catch(Exception e) {
            	ApplicationLogger.log('SM_ResponseBatch', 'createNewHeader Update listFeedBackToUpdate', 'Batch', e);
            }
        }
        
        return insertFeedBackHeaderList;
    }
    
    //SFSUP-771
    private static List<medallia_xm__Medallia_Feedback__c> updateMFeedBack (list<medallia_xm__Medallia_Feedback__c> scope, list<Id> headerIds){
        
        Map<Id,Id> headerAndAccountId = new Map<Id,Id>();
        Map<String,Id> accountAndPowerPassNo = new Map<String,Id>();
        Map<String,Id> headerAndPowerPass = new Map<String,Id>();
        Map<String,String> accountPowerPassNo = new Map<String,String>();
        List<medallia_xm__Medallia_Feedback__c> updateMedalliaFeedback = new List<medallia_xm__Medallia_Feedback__c>();
        
        for (medallia_xm__Medallia_Feedback_Header__c mFHRecord: [Select Id, medallia_xm__Account__c From medallia_xm__Medallia_Feedback_Header__c Where ID IN: headerIds]) {
            headerAndAccountId.put(mFHRecord.medallia_xm__Account__c, mFHRecord.Id);
        }
        System.debug('headerAndAccountId '+headerAndAccountId);
        
        for (Account acc : [Select Id, Power_Pass_Account_Number__c From Account Where ID IN: headerAndAccountId.KeySet()]) {
            accountAndPowerPassNo.put(acc.Power_Pass_Account_Number__c, acc.Id);
            accountPowerPassNo.put(acc.Power_Pass_Account_Number__c, acc.Power_Pass_Account_Number__c);
            headerAndPowerPass.put(acc.Power_Pass_Account_Number__c,headerAndAccountId.get(acc.Id));
        }
        System.debug('accountAndPowerPassNo '+accountAndPowerPassNo);
        System.debug('headerAndPowerPass '+headerAndPowerPass);
        System.debug('accountPowerPassNo '+accountPowerPassNo);
        
        for (medallia_xm__Medallia_Feedback__c mF : scope) {
            if(mF.Power_Pass_Account_Number__c == accountPowerPassNo.get(mF.Power_Pass_Account_Number__c)) {
                mF.medallia_xm__Account_Id__c = accountAndPowerPassNo.get(mF.Power_Pass_Account_Number__c);
                mf.medallia_xm__Medallia_Feedback_Header__c = headerAndPowerPass.get(mF.Power_Pass_Account_Number__c);
                updateMedalliaFeedback.add(mf);
            }
        }
        System.debug('updateMedalliaFeedback '+updateMedalliaFeedback);
        return updateMedalliaFeedback;
        
    }
    
    
    public void finish(Database.BatchableContext BC) {
        AsyncApexJob asyncJob = [SELECT 
                                    Id, 
                                    Status, 
                                    NumberOfErrors, 
                                    JobItemsProcessed,
                                    TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =:BC.getJobId()];
                        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {asyncJob.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('SM_ResponseBatch ' + asyncJob.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + asyncJob.TotalJobItems +
        ' batches with '+ asyncJob.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }


    public void execute(SchedulableContext SC) {
        Database.executeBatch(new SM_ResponseBatch(), 10);
    }
}