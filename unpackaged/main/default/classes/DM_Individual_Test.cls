/*******************************************************************************************************
* Class Name      	: DM_Individual_Test
* @description		: Test class for DM_Individual
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 08/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          08/04/2025		1000				Initial Version
******************************************************************************************************/
@isTest
private class DM_Individual_Test {


    @testSetup
    static void testSetup() {
        //TODO put it on test Data Factory
        Individual individual = new Individual();
        individual.FirstName = 'Test';
        individual.LastName = 'User'; 
        insert Individual;
    }


    /**
     * @description  Test method for getIndividualsByIds
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getIndividualsByIds(){
        // Arrange: Create test data
        Id individualId = [SELECT Id FROM Individual WHERE FirstName = 'Test' AND LastName = 'User'].Id;
        List<Id> individualIds = new List<Id>();
        individualIds.add(individualId);

        // Act: Query the inserted record
        List<Individual> queriedIndividuals = DM_Individual.getIndividualsByIds(individualIds);

        // Assert: Validate the record was inserted correctly
        Assert.areNotEqual(null, queriedIndividuals, 'The list should not be null.');
        Assert.areEqual(1, queriedIndividuals.size(), 'There should be one record.');
    }

    /**
     * @description  Test method for getIndividualsByIds with null individualIds
     * @author Juan Cutrera | 08/04/2025
     **/
    @isTest
    static void getIndividualsByIds_NullIndividualIds(){
        // Act: Call the method with null individualIds
        List<Individual> queriedIndividuals = DM_Individual.getIndividualsByIds(null);

        // Assert: Validate the result
        Assert.areNotEqual(null, queriedIndividuals, 'The list should not be null.');
        Assert.areEqual(0, queriedIndividuals.size(), 'There should be no records.');
    }
}