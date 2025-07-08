/*******************************************************************************************************
* Class Name      	: TestDataFactory
* Description		: Data for the test classes
* Author          	: Simplus - Haider Raza
* Created On      	: 10/02/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Haider Raza           10/02/2020		1000				Initial version
* Simplus MS            22/12/202       1001                CCRM-6890,6892 Changes
* Simplus MS            14/07/2021		1002    		 	modifications CCRM-13792
* Bunnings Dev           14/09/2024 	1003    		 	modifications CRMS -17
* Juan Cutrera			28/05/2025		2000				Added createConsentPayloadJSON
******************************************************************************************************/
public with sharing class TestDataFactory {
    /**
    * @description      Create Spend Brand Review
    * @date             05/03/2020
    * @author           Haider Raza
    * @param            accId - AccountId
    * @param            num - Number of records to be generated
    **/
    public static List<Spend_Band_Review__c> createSpendBandReviews(String accId, Integer num, String lvl1ApproverId, String lvl2ApproverId){
        List<Spend_Band_Review__c> returnVal = new List<Spend_Band_Review__c>();

        for(Integer i = 0; i < num ; i++){
            Spend_Band_Review__c newSpendBandReview = new Spend_Band_Review__c(
                    Account__c = accId,
//                    Current_Spend_Band_Level__c = 4,
//                    Proposed_Spend_Band_Level__c = 3,
                    Level_1_Approver__c = lvl1ApproverId,
                    Level_2_Approver__c = lvl2ApproverId
            );
            returnVal.add(newSpendBandReview);
        }

        return returnVal;
    }

    /**
    * @author       Haider Raza
    * @date         06/03/2020
    * @description  method for generating test User records
    **/
    public static List<User> createUsers(Integer num, Id profileId) {
        List<User> returnVal = new List<User>();
        for(Integer i = 0; i < num; i++) {
            User usr = new User(
                    Alias = 'emp'+i,
                    Email='employee@testorg.com',
                    EmailEncodingKey='UTF-8',
                    LastName='Testing',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    ProfileId = profileId,
                    TimeZoneSidKey='America/Los_Angeles',
                    UserName='employee'+ i + String.valueOf(Math.random()) +'@testorg.com',
                    isActive=true,
                    Country='Australia',
                    Country__c = 'Australia'
            );
            returnVal.add(usr);
        }
        return returnVal;
    }

    /**
    * @description 
    * @author John Paul Peñaflor | 08-21-2020 
    * @param Integer num 
    * @return List<Project__c> 
    **/
    public static List<Project__c> createProject(Integer num) {
        List<Project__c> returnVal = new List<Project__c>();
        for(Integer i = 0; i < num; i++) {
            Project__c project = new Project__c(
                    Name = 'Test Store',
                    Status__c = 'Design',
                    Source__c = 'Customer'
            );
            returnVal.add(project);
        }
        return returnVal;
    }

    /**
    * @author       Philip Clark
    * @date         30/06/2020
    * @description  method for generating test CalendarView records
    **/
    public static CalendarView createCalendarView(String CalendarViewName, Id UserId) {
        return new CalendarView(
            Name = CalendarViewName, 
            Color = '3a87ad',
            DisplayField = 'Subject',
            OwnerId = UserId,
            SobjectType = 'Task',
            StartField = 'ActivityDate'
        );
    }

    /**
    * @author       Philip Clark
    * @date         24/06/2020
    * @description  method for generating test Trade Specialist User Role records
    **/
    public static List<UserRole> createTSRoles(Integer num) {
        List<UserRole> returnVal = new List<UserRole>();
        for(Integer i = 0; i < num; i++) {
            UserRole r = new UserRole(
                DeveloperName = 'SRN_600'+string.valueOf(i),
                Name = '600'+string.valueOf(i)
            );
            returnVal.add(r);
        }
        return returnVal;
    }

    /**
   * @author        Haider Raza
   * @description   method for generating test Account records
   * @author        Haider Raza
   * @date          05/03/2020
   * @param         num - number of records to be generated
   **/
    public static List<Account> createAccounts(Integer num){
        
        List<Account> returnVal = new List<Account>();
        for(Integer i = 0; i < num; i++) {
            Account newAcc = new Account(
                    Name = 'TestCompany' + i,
                    BillingCity='Melbourne',
                    BillingCountry='AUS',
                    BillingPostalCode='3000',
                    BillingState='VIC',
                    BillingStreet='Collins St',
                    Country__c='Australia',
                    Account_Status__c = 'Active'
            );
            returnVal.add(newAcc);
        }
        return returnVal;
    }
    
   /**
   * @description   method for generating test Account records
   * @author        Juan Cutrera
   * @date          24/03/2025
   * @param         num - number of records to be generated
   * @param			recordTypeDeveloperName - the developerName
   **/
    public static List<Account> createPersonAccounts(Integer num){
        
        Id accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
        List<Account> returnVal = new List<Account>();
        for(Integer i = 0; i < num; i++) {
            Account newAcc = new Account(
                    LastName = 'TestCompany' + i,
                    BillingCity='Melbourne',
                    BillingCountry='AUS',
                    BillingPostalCode='3000',
                    BillingState='VIC',
                    BillingStreet='Collins St',
                    Country__c='Australia',
                    Account_Status__c = 'Active'
            );
            returnVal.add(newAcc);
        }
        return returnVal;
    }

    /**
    * @description  Method to generate a list of test Individual records
    * @author Juan Cutrera | 08/04/2025
    * @param num The number of Individual records to generate
    * @return List<Individual>
    **/
    public static List<Individual> createIndividuals(Integer num) {
        List<Individual> returnVal = new List<Individual>();
        for (Integer i = 0; i < num; i++) {
            Individual newInd = new Individual(
                LastName = 'TestIndividual' + i
            );
            returnVal.add(newInd);
        }
        insert returnVal;
        return returnVal;
    }

    /**
     * @description createContactPointAddress - Creates a test ContactPointAddress record
     * @author Juan M. Cutrera
     * @return    ContactPointAddress
     */
    public static ContactPointAddress createContactPointAddress(){
        ContactPointAddress contactPointAddress = new ContactPointAddress();
        contactPointAddress.Name = 'Test Contact Point Address';
        contactPointAddress.parentId = createIndividuals(1).get(0).Id;
        return contactPointAddress;

    }

    /**
     * @description createContactPointEmail - Creates a test ContactPointEmail record
     * @author Juan M. Cutrera
     * @return  ContactPointEmail
     */
    public static ContactPointEmail createContactPointEmail(){
        ContactPointEmail contactPointEmail = new ContactPointEmail();
        contactPointEmail.EmailAddress = 'test@test.com';
        contactPointEmail.ParentId = createIndividuals(1).get(0).Id;
        return contactPointEmail;
    }

    /**
     * @description createContactPointPhone - Creates a test ContactPointPhone record
     * @author Juan M. Cutrera
     * @return   ContactPointPhone
     */
    public static ContactPointPhone createContactPointPhone(){
        ContactPointPhone contactPointPhone = new ContactPointPhone();
        contactPointPhone.TelephoneNumber = '0451876567';
        contactPointPhone.ParentId = createIndividuals(1).get(0).Id;
        return contactPointPhone;
    }

    /**
     * @description createEntity 
     * @author Juan M. Cutrera
     * @return   return description
     */
    public static Consent_ConsentManagerPayload.Entity createEntity(){
        Consent_ConsentManagerPayload.Entity entity = new Consent_ConsentManagerPayload.Entity();
        entity.countryCode = 'AU';
        entity.person = TestDataFactory.createPayloadPerson();
        entity.capture = TestDataFactory.createPayloadCapture();
        return entity;
    }
    
    /**
     * @description createPayloadPerson 
     * @author Juan M. Cutrera
     * @return   return description
     */
    public static Consent_ConsentManagerPayload.Person createPayloadPerson(){
        Consent_ConsentManagerPayload.Person person = new Consent_ConsentManagerPayload.Person();
        person.firstName = 'TestFirstName';
        person.lastName = 'TestLastName';
        person.name = 'TestFirstName TestLastName';
        person.contactPoints = new List<Consent_ConsentManagerPayload.ContactPoint>();
        person.contactPoints.add(TestDataFactory.createPayloadContactPoint('Phone'));
        person.contactPoints.add(TestDataFactory.createPayloadContactPoint('Email'));
        person.contactPoints.add(TestDataFactory.createPayloadContactPoint('Mailing Address'));
        person.account = new Consent_ConsentManagerPayload.MyAccount();
        person.account.accountNumber = '12345';
        return person;
    }

    /**
     * @description createPayloadContactPoint 
     * @author Juan M. Cutrera
     * @param  type type description
     * @return      return description
     */
    public static Consent_ConsentManagerPayload.ContactPoint createPayloadContactPoint(String type){

        Consent_ConsentManagerPayload.ContactPoint contactPoint = new Consent_ConsentManagerPayload.ContactPoint();
        contactPoint.type = type;
        switch on type {
            when 'Phone' {
                contactPoint.usage = 'Mobile';
                contactPoint.phone = new Consent_ConsentManagerPayload.Phone();
                contactPoint.phone.phoneNumber = '0451876567';
            }
            when 'Email' {
                contactPoint.email = 'test@test.com';
            }
            when 'Mailing Address'{
                contactPoint.address = new Consent_ConsentManagerPayload.Address();
                contactPoint.address.streetName = 'Test Street';
                contactPoint.address.locality = 'Test City';
                contactPoint.address.stateCode = 'VIC';
                contactPoint.address.postCode = '3000';
                contactPoint.address.countryCode = 'Australia';
            }

        }
        return contactPoint;
    }

    public static Consent_ConsentManagerPayload.Capture createPayloadCapture(){
        Consent_ConsentManagerPayload.Capture capture = new Consent_ConsentManagerPayload.Capture();
        capture.captureDateTime = DateTime.now();
        capture.source = 'Test Source';
        capture.sourceModule = 'Test Source Module';
        return capture;
    }

    /**
    * @author        Francis Benzon
    * @description   method for generating test Contract records
    * @date          26/03/2020
    * @param         num - number of records to be generated
    **/
    public static List<Contract__c> createContracts(Integer num){
        List<Contract__c> returnVal = new List<Contract__c>();
        for(Integer i = 0; i < num; i++) {
            Contract__c newCon = new Contract__c(
                    Name = 'TestContract' + i,
                    Status__c = Constants.CONTRACT_STATUS_ACTIVE,
                    Start_Date__c = Date.Today()
            );
            returnVal.add(newCon);
        }
        return returnVal;
    }
    
    /**
    * @author        Francis Benzon
    * @description   method for generating test Contract Line Item records
    * @date          26/03/2020
    * @param         num - number of records to be generated
    **/
    public static List<Contract_Line_Item__c> createContractLineItems(Integer num){
        List<Contract_Line_Item__c> returnVal = new List<Contract_Line_Item__c>();
        for(Integer i = 0; i < num; i++) {
            Contract_Line_Item__c newCLI = new Contract_Line_Item__c(
                    Name = 'TestContractLineItem' + i
            );
            returnVal.add(newCLI);
        }
        return returnVal;
    }

    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test inactive contact
    * @date          03/04/2020
    **/
    public static Contact createInactiveContact(){
        Contact inactiveContact = createStandardContact();
        //Set Inactive to True
        inactiveContact.Status__c = System.Label.Inactive;
        
        update inactiveContact;
        
        return inactiveContact;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test contact
    * @date          03/04/2020
    **/
    public static Contact createStandardContact(){
        Contact inactiveContact = new Contact();
        // Add all required fields
        inactiveContact.FirstName = 'simplus-test';
        inactiveContact.LastName = 'contact';
        inactiveContact.Email = String.valueOf(Math.random()) + 'test@test.com';
        
        //Set Inactive to True
        inactiveContact.Status__c = System.Label.Active;
        
        insert inactiveContact;
        
        return inactiveContact;
    }
    
    /**
    * @author        Philip Clark
    * @description   method for generating and returning test leads
    * @date          06/07/2020
    **/
    public static list<Lead> createStandardLeads(Integer num){
        List<Lead> returnVal = new List<Lead>();
        for(Integer i = 0; i < num; i++) {
            Lead lead = new Lead(
                FirstName = 'simplus-test' + String.valueOf(i),
                LastName = 'lead',
                Company = 'Simplus' + String.valueOf(i),
                Email = String.valueOf(Math.random()) + 'test@test.com'
            );
            returnVal.add(lead);
        }
        
        return returnVal;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test lead
    * @date          03/04/2020
    **/
    public static Lead createStandardLead(){
        Lead lead = new Lead();
        lead.FirstName = 'simplus-test';
        lead.LastName = 'lead';
        lead.Company = 'Simplus';
        lead.Email = String.valueOf(Math.random()) + 'test@test.com';
        
        insert lead;
        
        return lead;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test lead with no Id
    * @date          03/04/2020
    **/
    public static Task getTaskRecordNoId(){
        Task task = new Task();
        
        task.Subject = 'Call';
        
        
        return task;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test task relation record with no Id
    * @date          03/04/2020
    **/
    public static TaskRelation getTaskRelationRecordNoId(){
        TaskRelation taskRelation = new TaskRelation();
        
        return taskRelation;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test event with no Id
    * @date          03/04/2020
    **/
    public static Event getEventRecordNoId(){
        Event event = new Event();
        
        event.Subject = 'Call';
        event.DurationInMinutes = 1;
        event.ActivityDateTime = Date.today();
        
        return event;
    }
    
    /**
    * @author        John Paul Peñaflor
    * @description   method for generating test event relation with no Id
    * @date          03/04/2020
    **/
    public static EventRelation getEventRelationRecordNoId(){
        EventRelation eventRelation = new EventRelation();
        
        return eventRelation;
    }

    private static Case createCase(String accountId, String ownerId, String subject, String status) {
        return new Case(
            Subject = subject, 
            Status = status, 
            AccountId = accountId, 
            OwnerId = ownerId);
    }

    public static List<Case> createOpenCases(String accountId, String ownerId, Integer num) {
        List<Case> records = new List<Case>();
        Integer index = 0;
        while (index < num) {
            index ++;
            records.add(createCase(accountId, ownerId, 'Case Subject ' + String.valueOf(index), 'New'));
        }
        return records;
    }

    public static List<Case> createClosedCases(String accountId, String ownerId, Integer num) {
        List<Case> records = new List<Case>();
        Integer index = 0;
        while (index < num) {
            index ++;
            records.add(createCase(accountId, ownerId, 'Closed Case Subject ' + String.valueOf(index), 'Done'));
        }
        return records;
    }

    private static Contact createContact(String lastName, String accountId, String ownerId) {
        return new Contact(
            FirstName = 'FN',
            Email = String.valueOf(Math.random()) + 'test@test.com',
            LastName = lastName,
            AccountId = accountId,
            OwnerId = ownerId
        );
    }

    public static List<Contact> createContacts(String accountId, String ownerId, Integer num) {
        List<Contact> records = new List<Contact>();
        Integer index = 0;
        while (index < num) {
            index ++;
            records.add(createContact('Last Name ' + String.valueOf(index), accountId, ownerId));
        }
        return records;
    }

    private static Opportunity createOpportunity(String name, String accountId, String ownerId, String stage, date closeDate) {
        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = stage,
            CloseDate = closeDate,
            OwnerId = ownerId
        );
    }

    public static List<Opportunity> createOpenOpportunities(String accountId, String ownerId, Integer opptyCount) {
        List<Opportunity> oppties = new List<Opportunity>();
        Integer index = 0;
        while (index < opptyCount) {
            index ++;
            oppties.add(createOpportunity('Open Opportunity ' + String.valueOf(index), accountId, ownerId, 'New', Date.today() + 10));
        }
        return oppties;
    }

    public static List<Opportunity> createClosedOpportunities(String accountId, String ownerId, Integer opptyCount) {
        List<Opportunity> oppties = new List<Opportunity>();
        Integer index = 0;
        while (index < opptyCount) {
            index ++;
            oppties.add(createOpportunity('Closed Opportunity ' + String.valueOf(index), accountId, ownerId, 'Closed Won', Date.today() + 10));
        }
        return oppties;
    }

    public static List<Supplier_Quote__c> createSupplierQuotes(String oppId, String supplierId, Integer num) {
        List<Supplier_Quote__c> returnVal = new List<Supplier_Quote__c>();
        for(Integer i = 0; i < num; i++) {
            Supplier_Quote__c sq = new Supplier_Quote__c(
                Category__c = 'test', 
                Opportunity__c = oppId, 
                Supplier__c = supplierId, 
                Status__c = 'New'
            );
            returnVal.add(sq);
        }
        
        return returnVal;
    }

    private static Event createEventWithWhatId(String subject, String whatId, String ownerId, DateTime activityDateTime, DateTime endDateTime) {
        return new Event(
            Subject = subject, 
            WhatId = whatId, 
            OwnerId = ownerId, 
            EndDateTime = endDateTime, 
            ActivityDateTime = activityDateTime
            );
    }

    public static List<Event> createOpenEventsWithWhatId(String whatId, String ownerId, Integer eventCount) {
        List<Event> events = new List<Event>();
        Integer index = 0;
        while (index < eventCount) {
            index ++;
            events.add(createEventWithWhatId('Open Event ' + String.valueOf(index), whatId, ownerId, DateTime.now().addDays(9), DateTime.now().addDays(10)));
        }
        return events;
    }

    public static List<Event> createClosedEventsWithWhatId(String whatId, String ownerId, Integer eventCount) {
        List<Event> events = new List<Event>();
        Integer index = 0;
        while (index < eventCount) {
            index ++;
            events.add(createEventWithWhatId('Closed Event ' + String.valueOf(index), whatId, ownerId, DateTime.now().addDays(-10), DateTime.now().addDays(-9)));
        }
        return events;
    }

    private static Task createTaskWithWhatId(String subject, String whatId, String ownerId, String status, Date activityDate) {
        return new Task(Subject = subject, WhatId = whatId, OwnerId = ownerId, Status = status, ActivityDate = activityDate);
    }
    public static List<Task> createOpenTasksWithWhatId(String whatId, String ownerId, Integer taskCount) {
        List<Task> tasks = new List<Task>();
        Integer index = 0;
        while (index < taskCount) {
            index ++;
            tasks.add(createTaskWithWhatId('Open Task ' + String.valueOf(index), whatId, ownerId, 'Open', Date.today() + 10));
        }
        return tasks;
    }
    public static List<Task> createClosedTasksWithWhatId(String whatId, String ownerId, Integer taskCount) {
        List<Task> tasks = new List<Task>();
        Integer index = 0;
        while (index < taskCount) {
            index ++;
            tasks.add(createTaskWithWhatId('Closed Task ' + String.valueOf(index), whatId, ownerId, 'Completed', Date.today() + 10));
        }
        return tasks;
    }

    private static Contract__c createContract(String ownerId, String name, String status, String country) {
        return new Contract__c(
            OwnerId = ownerId,
            Name = name,
            Status__c = status,
            Country__c = country
        );
    }

    public static List<Contract__c> createNoExpiredContracts(String ownerId, String country, Integer num) {
        List<Contract__c> records = new List<Contract__c>();
        Integer index = 0;
        while (index < num) {
            index ++;
            records.add(createContract(ownerId, 'Active Contract Name ' + String.valueOf(index), 'Active', country));
        }
        return records;
    }
    
    public static List<Contract__c> createExpiredContracts(String ownerId, String country, Integer num) {
        List<Contract__c> records = new List<Contract__c>();
        Integer index = 0;
        while (index < num) {
            index ++;
            records.add(createContract(ownerId, 'Expired Contract Name ' + String.valueOf(index), 'Expired', country));
        }
        return records;
    }

    public static List<Contract_Line_Item__c> createContractLineItems(String contractId, String lineType, String lineStatus, Date endDate, Integer num) {
        List<Contract_Line_Item__c> records = new List<Contract_Line_Item__c>();
        Integer index = 0;
        String rand = String.valueOf(Math.random());
        while (index < num) {
            index ++;
            records.add(new Contract_Line_Item__c(
                Contract__c = contractId, 
                Line_Type__c = lineType, 
                Line_Status__c = lineStatus, 
                End_Date__c = endDate,
                Contract_Item_ID__c = rand + ' ' + index
                ));
        }
        return records;
    }

    public static List<Customer_Contract__c> createCustomerContracts(String accountId, List<Id> contractIds) {
        List<Customer_Contract__c> records = new List<Customer_Contract__c>();
        for(Id contractId : contractIds) {
            records.add(new Customer_Contract__c(Customer__c = accountId, Contract__c = contractId, Customer_Contract_ID__c = String.valueOf(Math.random())));
        }
        return records;
    }

    public static List<Customer_Contract__c> createAccCustomerContracts(List<Id> accountIds, List<Id> contractIds) {
        List<Customer_Contract__c> records = new List<Customer_Contract__c>();
        for(Id accountId : accountIds){
            for(Id contractId : contractIds) {
                records.add(new Customer_Contract__c(Customer__c = accountId, Contract__c = contractId, Customer_Contract_ID__c = String.valueOf(Math.random())));
            }
        }
        return records;
    }

    private static Spend_Band__c createSpendBand(String name, Double maxAmount, String extId, String country) {
        return new Spend_Band__c(
            Name = name,
            Max_Amount__c = maxAmount,
            Spend_Band_ID__c = extId,
            Country__c = country
        );
    }

    public static List<Spend_Band__c> createSpendBands(List<Double> maxAmounts, List<String> extIds, String country) {
        List<Spend_Band__c> records = new List<Spend_Band__c>();
        for(Double maxAmount : maxAmounts) {
            Integer index = maxAmounts.indexOf(maxAmount);
            records.add(createSpendBand('Spend Band ' + String.valueOf(Math.random()), maxAmount, extIds[index], country));
        }
        return records;
    }

    public static Spend_Band_Review__c createSpendBandReview(String accountId, String currentSpendBandId, String proposedSpendBandId, String country) {
        return new Spend_Band_Review__c(
            Account__c = accountId,
            Current_Spend_Band__c = currentSpendBandId,
            Proposed_Spend_Band__c = proposedSpendBandId,
            Country__c = country
        );
    }
    
     //Assisted Sales Creation
    public static List<Assisted_Sales__c> createAssistedSales(String accountId, Integer num){
        List<Assisted_Sales__c> returnVal = new List<Assisted_Sales__c>();
        for(Integer i = 0; i < num; i++) {
            Assisted_Sales__c newAstSale = new Assisted_Sales__c(
                Account__c = accountId,
                Status__c = 'Pending Approval'
            );
            returnVal.add(newAstSale);
        }
        return returnVal;
    }
    
    //Store Creation
    public static List<Store__c> createStores(Integer num){
        List<Store__c> returnVal = new List<Store__c>();
        for(Integer i = 0; i < num; i++) {
            Store__c newStore = new Store__c(
                Name = 'Store' + String.valueOf(i),
                Location_Code__c = '10210' + String.valueOf(i),
                Sales_Rep_ID__c = '600'+ String.valueOf(i),
                Status__c = 'Active'                
            );
            returnVal.add(newStore);
        }
        return returnVal;
    }
    
    //Store Creation
    public static Store_Member__c createStoreMember(Id sId, Id uId, String role){
        Store_Member__c newSM = new Store_Member__c(
                Role__c = role,
                Start_Date__c = Date.today(),
                Status__c = 'Active',
                Store__c = sId,
                Team_Member__c = uId
            );
        return newSM;
    }
    
    //Operations Region Creation
    public static Operations_Region__c createOperationsRegion(String Name, String role, Id teamMemberId){
        Operations_Region__c newOR = new Operations_Region__c(
            Name = Name,
            Role__c = role,
            Team_Member__c = teamMemberId                
        );
        return newOR;
    }
    
    //Product Sub Department Creation
    public static List<Product_Sub_Department__c> createProdSubDepartments(Integer num){
        List<Product_Sub_Department__c> returnVal = new List<Product_Sub_Department__c>();
        for(Integer i = 0; i < num; i++) {
            Product_Sub_Department__c newDept = new Product_Sub_Department__c(
                Name = 'SubDept' + String.valueOf(i),
                Status__c = 'Active',
                Sub_Department_ID__c = '000' + String.valueOf(i)       
            );
            returnVal.add(newDept);
        }
        return returnVal;
    }
    
    //Store Assist Creation
    public static List<Store_Assist__c> createStoreAssists(String asstdSaleId, String storeId, Integer num){
        List<Store_Assist__c> returnVal = new List<Store_Assist__c>();
        for(Integer i = 0; i < num; i++) {
            Store_Assist__c newStoreAst = new Store_Assist__c(
                Assisted_Sale__c = asstdSaleId,
                Store__c = storeId                          
            );
            returnVal.add(newStoreAst);
        }
        return returnVal;
    }
        
    //Category Assist Creation
    public static List<Category_Assist__c> createCategoryAssists(String asstdSaleId, String subDeptId, Integer num){
        List<Category_Assist__c> returnVal = new List<Category_Assist__c>();
        for(Integer i = 0; i < num; i++) {
            Category_Assist__c newCatAst = new Category_Assist__c(
                Assisted_Sale__c = asstdSaleId,
                Category__c = subDeptId                             
            );
            returnVal.add(newCatAst);
        }
        return returnVal;
    }

    /**
    * @description 
    * @author Yi Zhang | 11/06/2020 
    * @param name 
    * @param expiryDate 
    * @return Special_Buy__c 
    **/
    public static Special_Buy__c createSpecialBuy(String name, Date expiryDate) {
        return new Special_Buy__c(
            Name = name,
            Expiry_Date__c = expiryDate
        );
    }

    /**
    * @description 
    * @author Bunnigs dev
    **/
    public static Account_Plan__c createAccountPlan(String accid, String conid) {
        return new Account_Plan__c(
            Account__c = accid,
            Contact__c = conid,
            Call_Cycle_Frequency__c = 'Weekly',
            Potential_Value_PA__c = 20.6,
            Target_Wallet_Share__c = 67.0,
            Target_Segment_A__c = 'Slab',
            Target_Product_A__c = 'Decking',
            Status__c = 'Active',
            Start_Date__c = System.today(),
            End_Date__c = System.today() + 2
        );
    }


    /**
    * @description 
    * @author Yi Zhang | 11/06/2020 
    * @param accountId 
    * @param specialBuyIds 
    * @return List<Customer_Special_Buy__c> 
    **/
    public static List<Customer_Special_Buy__c> createCustomerSpecialBuys(String accountId, List<Id> specialBuyIds) {
        List<Customer_Special_Buy__c> records = new List<Customer_Special_Buy__c>();
        for(Id sbId : specialBuyIds) {
            records.add(new Customer_Special_Buy__c(Account__c = accountId, Special_Buy__c = sbId));
        }
        return records;
    }

    /**
    * @description 
    * @author Yi Zhang | 11/06/2020 
    * @param specialBuyId 
    * @param specialBuyNames 
    * @return List<Special_Buy_Line_Item__c> 
    **/
    public static List<Special_Buy_Line_Item__c> createSpecialBuyLineItems(String specialBuyId, List<String> specialBuyNames) {
        List<Special_Buy_Line_Item__c> records = new List<Special_Buy_Line_Item__c>();
        for(String name : specialBuyNames) {
            records.add(new Special_Buy_Line_Item__c(Special_Buy__c = specialBuyId, Name = name));
        }
        return records;
    }
    
    //Umbrella Group Creation
    public static List<Umbrella_Group__c> createUmbrellaGroups(Integer num){
        List<Umbrella_Group__c> returnVal = new List<Umbrella_Group__c>();
        for(Integer i = 0; i < num; i++) {
            Umbrella_Group__c newUG = new Umbrella_Group__c(
                Umbrella_Group_Name__c = 'Umbrella Group ' + ' ' + String.valueOf(i)    
            );
            returnVal.add(newUG);
        }
        return returnVal;
    }
    
    //Umbrella Beneficiaries Creation
    public static List<Umbrella_Beneficiary__c> createUmbrellaBeneficiaries(String acctId, String ugId, Integer num){
        List<Umbrella_Beneficiary__c> returnVal = new List<Umbrella_Beneficiary__c>();
        for(Integer i = 0; i < num; i++) {
            Umbrella_Beneficiary__c newUB = new Umbrella_Beneficiary__c(
                Account__c = acctId,
                Umbrella_Group__c = ugId,
                Status__c = Label.Active                
            );
            returnVal.add(newUB);
        }
        return returnVal;
    }
    
    //Topic Creation
    public static List<Topic> createTopics(Integer num){
        List<Topic> returnVal = new List<Topic>();
        for(Integer i = 0; i < num; i++) {
            Topic newTopic = new Topic(
                Name = 'TEST'               
            );
            returnVal.add(newTopic);
        }
        return returnVal;
    }

    // Quotes
    public static List<Quote> createQuotes(String opptyId, String status, Integer count) {
        List<Quote> quotes = new List<Quote>();
        for(Integer i = 0; i < count; i++) {
            quotes.add(new Quote(
                OpportunityId = opptyId,
                Name = String.valueOf(Math.random()),
                Status = status,
                COS_Token__c = String.valueOf(Math.random()) // Added to cover CCRM-6890,6892 enhancement changes
            ));
        }
        return quotes;
    }

    /**
   * @author        Sowjanya
   * @description   method for generating test Account Request records
   *
   * @param         Map - Map of account request with powerpass numbers
   **/
    public static List<Account_Request__c> createBulkAccountRequests(Map<String,String> accReq){
        List<Account_Request__c> returnVal = new List<Account_Request__c>();
        for(String key : accReq.keyset()) {
            Account_Request__c newAccReq = new Account_Request__c(
                PowerPass_Account_Number__c =key,
                New_Owner__c=accReq.get(key),
                Type__c = 'Bulk Account Transfer'
                    
            );
            returnVal.add(newAccReq);
        }
        return returnVal;
    }

    /**
   * @author        Sowjanya
   * @description   method for generating test Single Account Request records
   * @param        newOwnerId,powerpassNumber,transferToId,transferToComments
   **/
  public static Account_Request__c createSingleAccountRequest(Id newOwnerId, String powerpassNumber,Id transferToId,String transferToComments){
   
        Account_Request__c newAccReq = new Account_Request__c(
            PowerPass_Account_Number__c = powerpassNumber,
            New_Owner__c    = newOwnerId,
            Type__c = 'Single Account Transfer',
            Transfer_to__c = transferToId,
            Transfer_comments__c = transferToComments
        );
        return newAccReq;
    
	}

    /**
     * @description createAuthorizationForm - Create a test Authorization Form
     * @author Juan M. Cutrera
     * @return   AuthorizationForm
     */
    public static AuthorizationForm createAuthorizationForm(){
        AuthorizationForm authForm = new AuthorizationForm();
        authForm.Name = 'Test Authorization Form';
        authForm.Country__c = 'AU';
        authForm.EffectiveFromDate = Date.today();
        authForm.EffectiveToDate = Date.today().addDays(30);
        return authForm;
    }
    
    /**
    * @description  crateConsentPayloadJSON - Create Json for ConsentPayload
    * @author Juan Cutrera | 25/03/2025 
    **/
    public static String createConsentPayloadJSON(){
        Map<String, Object> payload = new Map<String, Object>();

        // Add schema
        payload.put('$schema', 'csn.consent.json');

        // Add header
        Map<String, Object> header = new Map<String, Object>();
        header.put('domain', 'CSN');
        header.put('subDomain', 'Consent');
        header.put('version', '1.0.0');
        header.put('messageId', '12345678');
        header.put('publicationBatchId', '24681357');
        header.put('extractSequenceDateTime', '2023-11-01T07:12:50Z');
        header.put('requestId', '84729244');

        // Add metadata
        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('countryCode', 'AU');
        metadata.put('locationCode', '2010');
        metadata.put('dataUsePurposeCode', 'LegalHireShopPolicyEnglish');
        metadata.put('source', 'COS');
        metadata.put('sourceModule', 'HireShop');
        metadata.put('sourceReference', 'X12345');
        header.put('metadata', metadata);

        payload.put('header', header);

        // Add entity
        Map<String, Object> entity = new Map<String, Object>();
        entity.put('countryCode', 'AU');

        // Add consent
        Map<String, Object> consent = new Map<String, Object>();
        Map<String, Object> dataUsePurpose = new Map<String, Object>();
        dataUsePurpose.put('code', 'LegalHireShopPolicyEnglish');
        dataUsePurpose.put('name', 'Legal Hire');
        dataUsePurpose.put('version', '2023');
        dataUsePurpose.put('asOfDateTime', '2023-11-01T07:12:50Z');
        consent.put('dataUsePurpose', dataUsePurpose);

        Map<String, Object> effectivePeriod = new Map<String, Object>();
        effectivePeriod.put('startDateTime', '2023-11-01T07:12:50Z');
        effectivePeriod.put('endDateTime', '2023-11-01T07:12:50Z');
        consent.put('effectivePeriod', effectivePeriod);

        consent.put('consentStatus', 'Seen');
        entity.put('consent', consent);

        // Add person
        Map<String, Object> person = new Map<String, Object>();
        person.put('name', 'Test Tester');
        person.put('firstName', 'Test');
        person.put('lastName', 'Tester');

        // Add contact points
        List<Object> contactPoints = new List<Object>();

        // Phone contact point
        Map<String, Object> phoneContact = new Map<String, Object>();
        phoneContact.put('type', 'Phone');
        phoneContact.put('usage', 'Mobile');
        Map<String, Object> phone = new Map<String, Object>();
        phone.put('number', '+61451807708');
        phoneContact.put('phone', phone);
        contactPoints.add(phoneContact);

        // Address contact point
        Map<String, Object> addressContact = new Map<String, Object>();
        addressContact.put('type', 'Mailing Address');
        addressContact.put('usage', 'Mailing');
        addressContact.put('freeFormAddress', '');
        Map<String, Object> address = new Map<String, Object>();
        address.put('lotNumber', '');
        address.put('streetNumber', '13');
        address.put('streetName', 'Sample');
        address.put('streetType', 'Street');
        address.put('locality', 'Test City');
        address.put('postCode', '3030');
        address.put('stateCode', 'VIC');
        address.put('countryCode', 'Australia');
        addressContact.put('address', address);
        contactPoints.add(addressContact);

        // Email contact point
        Map<String, Object> emailContact = new Map<String, Object>();
        emailContact.put('type', 'email');
        emailContact.put('usage', 'Personal');
        emailContact.put('email', 'juancutrera@test.com');
        contactPoints.add(emailContact);

        person.put('contactPoints', contactPoints);

        // Add account
        Map<String, Object> account = new Map<String, Object>();
        account.put('accountNumber', '123455');
        Map<String, Object> card = new Map<String, Object>();
        card.put('cardSequenceNumber', 1);
        card.put('cardHolderName', 'Test Tester');
        account.put('card', card);

        Map<String, Object> user = new Map<String, Object>();
        user.put('id', 's');
        user.put('idp', 'x');
        user.put('reference', 'x');
        account.put('user', user);
        person.put('account', account);

        // Add team
        Map<String, Object> team = new Map<String, Object>();
        team.put('teamMemberNumber', '1234565');
        team.put('cardNumber', '1');
        team.put('isPrimary', true);
        person.put('team', team);

        entity.put('person', person);

        // Add capture
        Map<String, Object> capture = new Map<String, Object>();
        capture.put('dateTime', '2023-11-01T07:12:50Z');
        capture.put('engagementChannel', 'InStore');
        capture.put('source', 'COS');
        capture.put('sourceModule', 'HireShop');
        capture.put('sourceReference', 'X12345');
        capture.put('locationCode', '2010');
        capture.put('identifier', 'LegalHire|2025-04-16T01:54:00Z|COS|HireShop|32DA915CD7B284D9E06340041A0A714A|2010');
        entity.put('capture', capture);

        payload.put('Entity', entity);

        // Convert to JSON
        return JSON.serialize(payload);
    }

}