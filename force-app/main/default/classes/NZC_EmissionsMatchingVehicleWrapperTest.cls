/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingVehicleWrapperTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupVehicle('myVehcile');
    }

    @IsTest
    static void testBaseConstructor() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, StartDate, VehicleAssetEmssnSrcId, FuelType
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper vehicleWrapper = new NZC_EmissionsMatchingVehicleWrapper(useRecord);

        Assert.areEqual(useRecord.VehicleAssetEmssnSrcId, vehicleWrapper.assetId);
        Assert.areEqual(useRecord.Id, vehicleWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE, vehicleWrapper.objectName);
        Assert.areEqual(useRecord.FuelType, vehicleWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, vehicleWrapper.dateToMatch);
        Assert.areEqual(useRecord.OtherEmssnFctrId, vehicleWrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, StartDate, VehicleAssetEmssnSrcId, FuelType
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];

        String generatedId = 'MyId';
        NZC_EmissionsMatchingWrapper vehicleWrapper = new NZC_EmissionsMatchingVehicleWrapper(useRecord, generatedId);

        Assert.areEqual(useRecord.VehicleAssetEmssnSrcId, vehicleWrapper.assetId);
        Assert.areEqual(generatedId, vehicleWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE, vehicleWrapper.objectName);
        Assert.areEqual(useRecord.FuelType, vehicleWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, vehicleWrapper.dateToMatch);
        Assert.areEqual(useRecord.OtherEmssnFctrId, vehicleWrapper.masterEmissionsSetId);
    }
}