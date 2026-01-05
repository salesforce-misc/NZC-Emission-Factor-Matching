/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingWasteWrapperTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('myWaste');
    }

    @IsTest
    static void testBaseConstructor() {
        GeneratedWaste useRecord = [
                SELECT Id, StartDate, StnryAssetEnvrSrcId, DisposalType, WstDispoEmssnFctrId
                FROM GeneratedWaste
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper wasteWrapper = new NZC_EmissionsMatchingWasteWrapper(useRecord);

        Assert.areEqual(useRecord.StnryAssetEnvrSrcId, wasteWrapper.assetId);
        Assert.areEqual(useRecord.Id, wasteWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE, wasteWrapper.objectName);
        Assert.areEqual(useRecord.DisposalType, wasteWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wasteWrapper.dateToMatch);
        Assert.areEqual(useRecord.WstDispoEmssnFctrId, wasteWrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        GeneratedWaste useRecord = [
                SELECT Id, StartDate, StnryAssetEnvrSrcId, DisposalType, WstDispoEmssnFctrId
                FROM GeneratedWaste
                LIMIT 1
        ];

        String generatedId = 'MyId';

        NZC_EmissionsMatchingWrapper wasteWrapper = new NZC_EmissionsMatchingWasteWrapper(useRecord,generatedId);

        Assert.areEqual(useRecord.StnryAssetEnvrSrcId, wasteWrapper.assetId);
        Assert.areEqual(generatedId, wasteWrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE, wasteWrapper.objectName);
        Assert.areEqual(useRecord.DisposalType, wasteWrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wasteWrapper.dateToMatch);
        Assert.areEqual(useRecord.WstDispoEmssnFctrId, wasteWrapper.masterEmissionsSetId);
    }
}