@isTest
private class PowerPassSignUp_Ctrl_Test {
    
    @isTest
    private static void test_getAccountDetails() {
        Account acc = TestDataFactory.createAccounts(1)[0];
        insert acc;

        Contact cont = TestDataFactory.createContacts(acc.Id, UserInfo.getUserId(), 1)[0];
        insert cont;

        Test.startTest();
        PowerPassSignUp_Ctrl.getEncodedAccountInfo(acc.Id);
        System.assertEquals(1, PowerPassSignUp_Ctrl.getAccountDetails(acc.Id).size());
        System.assertEquals(1, PowerPassSignUp_Ctrl.getAccountDetails(acc.Id)[0].Contacts.size());
        Test.stopTest();
    }

}