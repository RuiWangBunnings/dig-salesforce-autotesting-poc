public with sharing class WOBSearchController {
    @AuraEnabled
    public static List<sObject> search(String objectName, List<String> searchFields, List<String> queryFields, String searchTerm, String whereClauseFilter, String whereClauseValue){   
        try{
            String searchKeyword ='*'+ searchTerm + '*';
            String returningQuery = '';
            System.debug('whereClauseFilter ' + whereClauseFilter);
            System.debug('whereClauseValue ' + whereClauseValue);
            String query = '';

            

            if(whereClauseFilter == null){
                query = 'SELECT ID, ' + String.join(queryFields, ', ') + ' FROM ' + objectName;
            }else{
                query = 'SELECT ID, ' + String.join(queryFields, ', ') + ' FROM ' + objectName + ' WHERE ' + whereClauseFilter;
            }

            if(whereClauseValue != null){
                query += ' =\'' + whereClauseValue + '\'';
            }
            
            if(searchTerm.length() >= 3){
                String andClause = '(';
                Integer index = 1;
                for(String field : searchFields){
                    andClause += field + ' LIKE \'' + searchTerm + '%\' ';
                    if(index < searchFields.size()){
                        andClause += 'OR ';
                    }
                    index++;
                }
                andClause += ')';
                if(whereClauseFilter != null){
                    query += ' AND ';
                }else{
                    query += ' WHERE ';
                }
                query += andClause;
            }

            query += ' LIMIT 5';
            List<sObject> sobjList = Database.query(query);
            return sobjList;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Project__c> findProjectDuplicate(String nameField, String projectId){
        try {
            List<Project__c> projectList = new List<Project__c>();
            Project__c projectRec = new Project__c();
            projectRec.Name = nameField;
            projectList.add(projectRec);

            List<Project__c> duplicateProjectListToDisplay = new List<Project__c>();

            List<Project__c> duplicateProjectRecordList = new List<Project__c>();

            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(projectList);
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                system.debug('WOBSearchController.findProjectDuplicate->Datacloud.FindDuplicatesResult: result found' );
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    system.debug('WOBSearchController.findProjectDuplicate->Datacloud.DuplicateResult: duplicate found' );
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        system.debug('WOBSearchController.findProjectDuplicate->Datacloud.MatchResult: match found' );
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            System.debug('Duplicate Record: ' + matchRecord.getRecord());
                            if(matchRecord.getRecord().Id != projectId){
                                system.debug('WOBSearchController.findProjectDuplicate->different id: ' + projectId );
                                duplicateProjectRecordList.add((Project__c) matchRecord.getRecord());
                            }
                        }
                    }
                }
            }

            
            Set<Id> projectIdSet = new Set<Id>();
            if(duplicateProjectRecordList.size() > 0){
                for(Project__c p : duplicateProjectRecordList){
                    projectIdSet.add(p.Id);
                }

                duplicateProjectListToDisplay = [SELECT Id, Name, Status__c, Project_Address__c, Build_Stage__c FROM Project__c WHERE Id IN :projectIdSet];
            }
            System.debug('duplicateProjectListToDisplay ' + duplicateProjectListToDisplay);
            return duplicateProjectListToDisplay;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    @AuraEnabled
    public static  Map<String, List<Project__c>> findProjectAddressDuplicate(String concatenatedAddress, String projectId){
        try {
            Map<Double, List<Project__c>> matchConfidenceProjectListMap = new Map<Double,List<Project__c>>();
            Map<String, List<Project__c>> matchAlgoProjectListMap = new Map<String,List<Project__c>>();
            List<Project__c> projectList = new List<Project__c>();
            List<Project__c> duplicateProjectListToDisplay = new List<Project__c>();
            Project__c projectRec = new Project__c();
            projectRec.Concatenated_Address__c = concatenatedAddress;
            projectList.add(projectRec);

            List<Project__c> duplicateProjectRecordList = new List<Project__c>();

            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(projectList);
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                system.debug('WOBSearchController.findProjectAddressDuplicate->Datacloud.FindDuplicatesResult: result found' );
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    system.debug('WOBSearchController.findProjectAddressDuplicate->Datacloud.DuplicateResult: duplicate found' );
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        system.debug('WOBSearchController.findProjectAddressDuplicate->Datacloud.MatchResult: match found' );
                        if(matchResult.getSize() > 0){
                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                System.debug('Duplicate Record: ' + matchRecord.getRecord());
                                if(matchRecord.getRecord().Id != projectId){
                                    system.debug('WOBSearchController.findProjectDuplicate->different id: ' + projectId );
                                    duplicateProjectRecordList.add((Project__c) matchRecord.getRecord());
                                    matchConfidenceProjectListMap.put(matchRecord.getMatchConfidence(), duplicateProjectRecordList);
                                }
                            }
                        }
                    }
                }
            }

            Set<Id> projectIdSet = new Set<Id>();
            Double exactMatchConfidence = 100.0;
            if(matchConfidenceProjectListMap.size() > 0){
                system.debug('WOBSearchController.findProjectAddressDuplicate: matchConfidenceProjectListMap.size()>0' );
                if(matchConfidenceProjectListMap.containsKey(exactMatchConfidence)){
                    system.debug('WOBSearchController.findProjectAddressDuplicate: containsKey ' + exactMatchConfidence );
                    if(matchConfidenceProjectListMap.get(exactMatchConfidence).size() > 0){
                        system.debug('WOBSearchController.findProjectAddressDuplicate: matchConfidenceProjectListMap size > 0' );
                        List<Project__c> exactMatchProjectList = matchConfidenceProjectListMap.get(exactMatchConfidence);
                        for(Project__c p : exactMatchProjectList){
                            projectIdSet.add(p.Id);
                        }
        
                        duplicateProjectListToDisplay = [SELECT Id, Name, Status__c, Project_Address__c, Build_Stage__c, Concatenated_Address__c FROM Project__c WHERE Id IN :projectIdSet];
        
                        matchAlgoProjectListMap.put('ExactMatch', duplicateProjectListToDisplay);
        
                    }
                }
                else{
                    system.debug('WOBSearchController.findProjectAddressDuplicate: does not contain key ' + exactMatchConfidence );
                    system.debug('WOBSearchController.findProjectAddressDuplicate: matchConfidenceProjectListMap ' + JSON.serialize(matchConfidenceProjectListMap.keySet()) );
                    Set<Double> fuzzyMatchConfidenceSet = new Set<Double>();
                    for(Double matchConfidence : matchConfidenceProjectListMap.keySet()){
                        if(matchConfidence != exactMatchConfidence){
                            fuzzyMatchConfidenceSet.add(matchConfidence);
                        }
                    }
    
                    List<Project__c> fuzzyMatchProjectListTemp = new List<Project__c>();
                    
                    system.debug('WOBSearchController.findProjectAddressDuplicate: fuzzyMatchConfidenceSet ' + JSON.serialize(fuzzyMatchConfidenceSet) );
                    for(Double fuzzyMatchConfidence : fuzzyMatchConfidenceSet){
                        if(matchConfidenceProjectListMap.get(fuzzyMatchConfidence).size() > 0){
                            fuzzyMatchProjectListTemp.addAll(matchConfidenceProjectListMap.get(fuzzyMatchConfidence));
                        }
                    }
    
                    List<Project__c> fuzzyMatchProjectList = new List<Project__c>(new Set<Project__c>(fuzzyMatchProjectListTemp));

                    system.debug('WOBSearchController.findProjectAddressDuplicate: fuzzyMatchProjectList ' + JSON.serialize(fuzzyMatchProjectList) );
                    for(Project__c p : fuzzyMatchProjectList){
                        projectIdSet.add(p.Id);
                    }
                    
                    duplicateProjectListToDisplay = [SELECT Id, Name, Status__c, Project_Address__c, Build_Stage__c, Concatenated_Address__c FROM Project__c WHERE Id IN :projectIdSet];
                    system.debug('WOBSearchController.findProjectAddressDuplicate: duplicateProjectListToDisplay ' + JSON.serialize(duplicateProjectListToDisplay) );
                    if(duplicateProjectListToDisplay.size() > 0){
                        matchAlgoProjectListMap.put('FuzzyMatch', duplicateProjectListToDisplay);
                    }
                }
            }else{
                system.debug('WOBSearchController.findProjectAddressDuplicate: no duplicate' );
                matchAlgoProjectListMap.put('NoDups', duplicateProjectListToDisplay);
            }
            
            return matchAlgoProjectListMap;
        } catch (Exception e) {
            System.debug('sid error ' + e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}