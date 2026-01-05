/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingStationaryWpprTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('myStationary');
    }

    @IsTest
    static void testBaseConstructor() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Diesel'
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingStationaryWrapper(useRecord);

        Assert.areEqual(useRecord.StnryAssetEnvrSrcId, stationWrapper.assetId);
        Assert.areEqual(useRecord.Id, stationWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE, stationWrapper.objectName);
        Assert.areEqual(useRecord.FuelType, stationWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, stationWrapper.dateToMatch);
        Assert.areEqual(useRecord.OtherEmssnFctrId, stationWrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Diesel'
                LIMIT 1
        ];

        String generatedId = 'MyId';
        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingStationaryWrapper(useRecord, generatedId);

        Assert.areEqual(useRecord.StnryAssetEnvrSrcId, stationWrapper.assetId);
        Assert.areEqual(generatedId, stationWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE, stationWrapper.objectName);
        Assert.areEqual(useRecord.FuelType, stationWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, stationWrapper.dateToMatch);
        Assert.areEqual(useRecord.OtherEmssnFctrId, stationWrapper.masterEmissionsSetId);
    }
}