/**
 * Created by mverigin on 6/26/23.
 */

@IsTest
private class NZC_EmissionsMatchingBatchTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('Batch stationary');
    }

    @IsTest
    static void testExecute() {
        Map<Id, StnryAssetEnrgyUse> validationMap = new Map<Id, StnryAssetEnrgyUse>([
                SELECT Id, Recalculate_Emissions__c, FuelType, ElectricityEmissionFactorsId, OtherEmssnFctrId, RefrigerantEmssnFctrId
                FROM StnryAssetEnrgyUse
        ]);

        Assert.isFalse(validationMap.isEmpty());

        Test.startTest();
        Database.executeBatch(new NZC_EmissionsMatchingBatch());
        Test.stopTest();

        for (StnryAssetEnrgyUse use : [
                SELECT Id, Recalculate_Emissions__c, FuelType, ElectricityEmissionFactorsId, OtherEmssnFctrId, RefrigerantEmssnFctrId
                FROM StnryAssetEnrgyUse
        ]) {
            Boolean emissionsDidChange = use.OtherEmssnFctrId != validationMap.get(use.Id).OtherEmssnFctrId;

            if (use.FuelType == NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY) {
                emissionsDidChange = use.ElectricityEmissionFactorsId != validationMap.get(use.Id).ElectricityEmissionFactorsId;
            }

            if (use.FuelType == NZC_EmissionsMatchingConstants.FUEL_TYPE_REFRIGERANT) {
                emissionsDidChange = use.RefrigerantEmssnFctrId != validationMap.get(use.Id).RefrigerantEmssnFctrId;
            }

            Assert.isTrue(emissionsDidChange, 'Emissions did not update');
            Assert.isFalse(use.Recalculate_Emissions__c, 'Recalculate field was not updated');
        }
    }
}