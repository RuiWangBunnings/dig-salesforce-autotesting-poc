/*******************************************************************************************************
* Class Name      	: SM_Task_Test
* @description		: Test class for SM_Task
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class SM_Task_Test {

    @TestSetup
    static void setupTestData() {
        // Create an Account
        List<Account> accounts = TestDataFactory.createAccounts(1);
        insert accounts;
    }

    /**
    * @description  Test method for createTask
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testCreateTask() {
        // Arrange: Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String whatId = testAccount.Id;
        String ownerId = UserInfo.getUserId();
        String subject = 'Test Task';
        String description = 'This is a test task';
        Date dueDate = Date.today().addDays(7);

        // Act: Call the method
        Task task = SM_Task.createTask(whatId, ownerId, subject, description, dueDate);

        // Assert: Validate the task fields
        Assert.areEqual(whatId, task.WhatId, 'WhatId should match');
        Assert.areEqual(ownerId, task.OwnerId, 'OwnerId should match');
        Assert.areEqual(subject, task.Subject, 'Subject should match');
        Assert.areEqual(description, task.Description, 'Description should match');
        Assert.areEqual(dueDate, task.ActivityDate, 'DueDate should match');
    }

    /**
     * @description testCreateCallCycleTask - Test method for createCallCycleTask
     * @author Juan M. Cutrera
     */
    @isTest 
    static void testCreateCallCycleTask() {
        // Arrange: Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String whatId = testAccount.Id;
        String ownerId = UserInfo.getUserId();
        String subject = 'Test Call Cycle Task';
        Date dueDate = Date.today().addDays(7);

        // Act: Call the method
        Task task = SM_Task.createCallCycleTask(whatId, ownerId, subject, dueDate);

        // Assert: Validate the task fields
        Assert.areEqual(DM_RecordType.rtId_Task_CallCycle, task.RecordTypeId, 'RecordTypeId should match');
        Assert.areEqual(whatId, task.WhatId, 'WhatId should match');
        Assert.areEqual(ownerId, task.OwnerId, 'OwnerId should match');
        Assert.areEqual(subject, task.Subject, 'Subject should match');
        Assert.areEqual('Engagement Call', task.Sub_type__c, 'Sub_type__c should match');
        Assert.areEqual('Phone', task.Type, 'Type should match');
        Assert.areEqual('Open', task.Status, 'Status should match');
        Assert.areEqual(dueDate, task.ActivityDate, 'DueDate should match');
    }

    /**
    * @description  Test method for insertTask
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testInsertTask() {
        // Arrange: Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task task = new Task(
            WhatId = testAccount.Id,
            OwnerId = UserInfo.getUserId(),
            Subject = 'Test Insert Task',
            Description = 'This is a test insert task',
            ActivityDate = Date.today().addDays(7),
            RecordTypeId = DM_RecordType.rtId_Task_Standard
        );

        // Act: Insert the task
        Task insertedTask = SM_Task.insertTask(task);

        // Assert: Validate the task was inserted
        Assert.areNotEqual(null, insertedTask.Id, 'Task should be inserted and have an Id');
    }

    /**
    * @description  Test method for createLifeCycleCallCycleTask
    * @author Juan Cutrera | 08/04/2025
    **/
    @isTest
    static void testCreateLifeCycleCallCycleTask() {
        // Arrange: Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String whatId = testAccount.Id;
        String ownerId = UserInfo.getUserId();
        String subject = 'Test Insert Task';
        Date dueDate = Date.today().addDays(7);
        String recordTypeId = DM_RecordType.rtId_Task_Standard;
        String subType = 'Engagement Call';

        // Act: Call the method
        Task insertedTask = SM_Task.createLifeCycleCallCycleTask(recordTypeId, whatId, ownerId, subject, subType, dueDate);

        // Assert: Validate the task fields
        Assert.areEqual(recordTypeId, insertedTask.RecordTypeId, 'RecordTypeId should match');
        Assert.areEqual(whatId, insertedTask.WhatId, 'WhatId should match');
        Assert.areEqual(ownerId, insertedTask.OwnerId, 'OwnerId should match');
        Assert.areEqual(subject, insertedTask.Subject, 'Subject should match');
        Assert.areEqual(subType, insertedTask.Sub_type__c, 'Sub_type__c should match');
        Assert.areEqual(dueDate, insertedTask.ActivityDate, 'DueDate should match');
    }

    @isTest 
    static void testCreateManualCallCycleTask(){
        // Arrange: Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String whatId = testAccount.Id;
        String ownerId = UserInfo.getUserId();
        String callReason = 'Test Call Reason';
        String recordTypeId = DM_RecordType.rtId_Task_Standard;

        // Act: Call the method
        Task task = SM_Task.createManualCallCycleTask(whatId, ownerId, callReason, recordTypeId);

        // Assert: Validate the task fields
        Assert.areEqual(whatId, task.WhatId, 'WhatId should match');
        Assert.areEqual(ownerId, task.OwnerId, 'OwnerId should match');
        Assert.areEqual('Business Determined - ' + callReason, task.Subject, 'Subject should match');
    }
}