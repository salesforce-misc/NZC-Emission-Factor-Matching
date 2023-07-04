/**
 * Created by mverigin on 6/27/23.
 */

@IsTest
private class NZC_EmissionsSetRecalcBatchTest {
    @IsTest
    static void testExecute() {
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        NZC_EmissionsMatchingDatafactory.setupStationary('BatchTest');

        Integer elligibleWasteSets = [
                SELECT COUNT()
                FROM WstDispoEmssnFctrSet
                WHERE Recalculate_Emissions__c = TRUE
        ];

        Test.startTest();
        Database.executeBatch(new NZC_EmissionsSetRecalcBatch(NZC_EmissionsMatchingConstants.OBJECT_REFRIGERANT_SET));
        Test.stopTest();

        Integer elligibleWasteSetsAfter = [
                SELECT COUNT()
                FROM WstDispoEmssnFctrSet
                WHERE Recalculate_Emissions__c = TRUE
        ];

        Assert.isTrue(elligibleWasteSets > 0);
        Assert.isTrue(elligibleWasteSetsAfter == 0);
    }
}