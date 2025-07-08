public with sharing class WOBFormFileUploadController {

    @AuraEnabled(cacheable=true)
    public static Map<Id, ContentVersion> getRelatedFilesByRecordId(String recordId) {

    try{
        // Get record file IDs        
        List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }

        List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title , ContentSize
            FROM ContentVersion WHERE ContentDocumentId IN : fileIDs];
        // Map<ID, String> mapIdTitle = new Map<ID, String>();
        // for (ContentVersion docLink : docs) {
        //     mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
        // }
        Map<Id, ContentVersion> mapFromList = new Map<Id, ContentVersion>(docs);
        return mapFromList;
    }catch(Exception e){
        throw new AuraHandledException(e.getMessage());
    }
    } 


    @AuraEnabled(cacheable=true)
    public static List<String> getAcceptedFileFormats(){
        try {
            List<String> acceptedFileFormatList = new List<String>();
            Initialisation__mdt wobAcceptedFileFormats = [SELECT Id, WoB_Accepted_File_Formats__c  FROM Initialisation__mdt LIMIT 1];
            

            acceptedFileFormatList = wobAcceptedFileFormats.WoB_Accepted_File_Formats__c.split(',');

            System.debug('acceptedFileFormatList '+ acceptedFileFormatList);

            return acceptedFileFormatList;
        } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
        }
    } 

    @AuraEnabled(cacheable=true)
    public static Double getAttachedDocumentFileLimit(){
        try {
            Initialisation__mdt wobDocumentSize = [SELECT Id, WOB_Document_Size__c  FROM Initialisation__mdt LIMIT 1];
            return (Double) wobDocumentSize.WOB_Document_Size__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } 

    @AuraEnabled
    public static Double getDocumentSize(String recordId){
        try {
            Map<Id,Integer> documentMap = new Map<Id,Integer>();
            // Get record file IDs        
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }

            List<ContentDocument> docSize = [select id,contentsize from ContentDocument where id IN : fileIDs];
            

            Long totalAttachmentsSize = 0L;
            for(ContentDocument doc : docSize) {
                totalAttachmentsSize = totalAttachmentsSize + doc.contentsize;
            }

            // converting file size to bytes to kb
            Double totalAttachmentsSizeKB = (totalAttachmentsSize / 1024);
            
            // converting file size to kb to mb
            Double totalAttachmentsSizeMB = (totalAttachmentsSizeKB / 1024);

            System.debug('totalAttachmentsSizeMB: '+totalAttachmentsSizeMB);

            return totalAttachmentsSizeMB;
            // if(totalAttachmentsSizeMB > wobDocumentSize.WOB_Document_Size__c){
            //     return wobDocumentSize.WOB_Document_Size__c + 'MB Restricted';
            // }else{
            //     return 'NotRestricted';
            // }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}