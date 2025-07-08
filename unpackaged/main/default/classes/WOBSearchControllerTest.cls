/**
 * @File Name          : WOBSearchControllerTest.cls
 * @Description        : Covers test coverage for WOBSearchController apex class
 * @Author             : Aldrin Rasdas
 * @Group              : MS-AU
 * @Last Modified By   : Aldrin Rasdas
 * @Last Modified On   : 24/11/2021
 * @Modification Log   : 
 * Ver		Date			Author      		    Modification
 * 1.0		24/11/2021		Aldrin Rasdas     		Initial Version
**/
@isTest
private class WOBSearchControllerTest {
    @testSetup static void setupmethod() {
        Project__c prj = new Project__c();
        prj.Name = 'Test';
        insert prj;
        
        
        Project__c prj2 = new Project__c();
        prj2.Name = 'Test1';
        prj2.Project_Address__c = '123 Test Street';
        prj2.Town__c = 'Test Suburb';
        prj2.State__c = 'NSW';
        prj2.Postcode__c = '123';
        //prj.Concatenated_Address__c = '123 Test Street, Test City';
        insert prj2;
        
        Project__c prj3 = new Project__c();
        prj3.Name = 'Test2';
        prj3.Project_Address__c = '123 Test Street';
        prj3.Town__c = 'Test Suburb2';
        prj3.State__c = 'NSW';
        prj3.Postcode__c = '1234';
        //prj.Concatenated_Address__c = '123 Test Street, Test City';
        insert prj3;
    }

    @isTest
    private static void searchTest() {
        //search(String objectName, 
        //List<String> searchFields, 
        //List<String> queryFields, 
        //String searchTerm, 
        //String whereClauseFilter, 
        //String whereClauseValue){   
        
        Task tsk = new Task(Subject='Test');
        insert tsk;
        String objectName = 'Task';
        List<String> searchFields = new List<String>{'Subject','Status'};
        List<String> queryFields = new List<String>{'Subject','Status'};
        String searchTerm = 'Test';
        String whereClauseFilter = 'Subject';
        String whereClauseValue = 'Test';
        
        List<Task> tasks = WOBSearchController.search(objectName, searchFields, queryFields, searchTerm, whereClauseFilter, whereClauseValue);
        System.assert(tasks.size()==1);
        tasks = WOBSearchController.search(objectName, searchFields, queryFields, searchTerm, null, null);
        System.assert(tasks.size()==1);
    }
    
    @isTest
    private static void findProjectDuplicateTest() {
        List<Project__c> projects = WOBSearchController.findProjectDuplicate('Test', null);
        System.assert(projects.size()>0);
    }
    
    @isTest
    private static void findProjectAddressDuplicateExactMatchTest() {
        
        Project__c projectRec = [SELECT Id, Concatenated_Address__c FROM Project__c WHERE Name = 'Test1' LIMIT 1];
        System.debug('SID Project Exact Address' + projectRec);
        

        Map<String, List<Project__c>> projects = WOBSearchController.findProjectAddressDuplicate(projectRec.Concatenated_Address__c, null);
        System.assert(projects.size()>0);        
    }
    
    @isTest
    private static void findProjectAddressDuplicateFuzzyMatchTest() {
        Test.startTest();
        Project__c projectRec = [SELECT Id, Concatenated_Address__c FROM Project__c WHERE Name = 'Test1' LIMIT 1];
        delete projectRec;
        
        Project__c prj4 = new Project__c();
        prj4.Name = 'Test3';
        prj4.Project_Address__c = '123 Test Street';
        prj4.Town__c = 'Test Suburb';
        prj4.State__c = 'NSW';
        prj4.Postcode__c = '123';
        //prj.Concatenated_Address__c = '123 Test Street, Test City';
        insert prj4;
        Project__c projectRecToCompare = [SELECT Id, Concatenated_Address__c FROM Project__c WHERE Name = 'Test3' LIMIT 1];
        Project__c projectRecToBeUpdated = [SELECT Id, Concatenated_Address__c FROM Project__c WHERE Name = 'Test2' LIMIT 1];
        
        projectRecToBeUpdated.Project_Address__c = '123 Test Street';
        projectRecToBeUpdated.Town__c = 'Test Suburb';
        projectRecToBeUpdated.State__c = 'SA';
        projectRecToBeUpdated.Postcode__c = '1234';
        update projectRecToBeUpdated;
        System.debug('SID Project Fuzzy' + projectRec);
        

        Map<String, List<Project__c>> projects = WOBSearchController.findProjectAddressDuplicate(projectRecToBeUpdated.Concatenated_Address__c, projectRecToCompare.Id);
        Test.stopTest();
        System.assert(projects.size()>0);        
    }
}