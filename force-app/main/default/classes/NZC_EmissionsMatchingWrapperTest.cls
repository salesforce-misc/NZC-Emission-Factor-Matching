/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('myStationary');
        NZC_EmissionsMatchingDatafactory.setupVehicle('vehicles');
    }

    @IsTest
    static void testVehicleWrapper() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, StartDate, VehicleAssetEmssnSrcId, FuelType
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper vehicleWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.VehicleAssetEmssnSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        vehicleWrapper.matchedId = useRecord.OtherEmssnFctrId;

        String parentAssetName = vehicleWrapper.getParentAssetObjName();
        String parentLookupName = vehicleWrapper.getObjectAssetLookupFieldName();
        String useLookupName = vehicleWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = vehicleWrapper.createRecordUpdate();

        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ASSET, parentAssetName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_OTHER_ASSET_EMISSIONS, parentLookupName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_OTHER_EMISSIONS, useLookupName);
        Assert.areEqual(useRecord.Id, (Id) recordUpdate.get('Id'));
        Assert.areEqual(useRecord.OtherEmssnFctrId, (Id) recordUpdate.get('OtherEmssnFctrId'));
        Assert.isNotNull(recordUpdate.get('OtherEmssnFctrId'));
    }

    @IsTest
    static void testOtherStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Diesel'
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        stationWrapper.matchedId = useRecord.OtherEmssnFctrId;

        String parentAssetName = stationWrapper.getParentAssetObjName();
        String parentLookupName = stationWrapper.getObjectAssetLookupFieldName();
        String useLookupName = stationWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = stationWrapper.createRecordUpdate();

        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET, parentAssetName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_OTHER_ASSET_EMISSIONS, parentLookupName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_OTHER_EMISSIONS, useLookupName);
        Assert.areEqual(useRecord.Id, (Id) recordUpdate.get('Id'));
        Assert.areEqual(useRecord.OtherEmssnFctrId, (Id) recordUpdate.get('OtherEmssnFctrId'));
        Assert.isNotNull(recordUpdate.get('OtherEmssnFctrId'));
    }

    @IsTest
    static void testElecStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Electricity'
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        stationWrapper.matchedId = useRecord.ElectricityEmissionFactorsId;

        String parentAssetName = stationWrapper.getParentAssetObjName();
        String parentLookupName = stationWrapper.getObjectAssetLookupFieldName();
        String useLookupName = stationWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = stationWrapper.createRecordUpdate();

        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET, parentAssetName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_ELECTRIC_EMISSIONS, parentLookupName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_ELECTRIC_EMISSIONS, useLookupName);
        Assert.areEqual(useRecord.Id, (Id) recordUpdate.get('Id'));
        Assert.areEqual(useRecord.ElectricityEmissionFactorsId, (Id) recordUpdate.get('ElectricityEmissionFactorsId'));
        Assert.isNotNull(recordUpdate.get('ElectricityEmissionFactorsId'));
    }

    @IsTest
    static void testRefrigStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Refrigerant'
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        stationWrapper.matchedId = useRecord.RefrigerantEmssnFctrId;

        String parentAssetName = stationWrapper.getParentAssetObjName();
        String parentLookupName = stationWrapper.getObjectAssetLookupFieldName();
        String useLookupName = stationWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = stationWrapper.createRecordUpdate();

        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET, parentAssetName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_REFRIGERANT_EMISSIONS, parentLookupName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_REFRIGERANT_EMISSIONS, useLookupName);
        Assert.areEqual(useRecord.Id, (Id) recordUpdate.get('Id'));
        Assert.areEqual(useRecord.RefrigerantEmssnFctrId, (Id) recordUpdate.get('RefrigerantEmssnFctrId'));
        Assert.isNotNull(recordUpdate.get('RefrigerantEmssnFctrId'));
    }

    @IsTest
    static void testWasteStationWrapper() {
        GeneratedWaste useRecord = [
                SELECT Id, StartDate, StnryAssetEnvrSrcId, WstDispoEmssnFctrId, DisposalType
                FROM GeneratedWaste
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.DisposalType);
        stationWrapper.matchedId = useRecord.WstDispoEmssnFctrId;

        String parentAssetName = stationWrapper.getParentAssetObjName();
        String parentLookupName = stationWrapper.getObjectAssetLookupFieldName();
        String useLookupName = stationWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = stationWrapper.createRecordUpdate();

        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET, parentAssetName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_WASTE_EMISSIONS, parentLookupName);
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_WASTE_EMISSIONS, useLookupName);
        Assert.areEqual(useRecord.Id, (Id) recordUpdate.get('Id'));
        Assert.areEqual(useRecord.WstDispoEmssnFctrId, (Id) recordUpdate.get('WstDispoEmssnFctrId'));
    }

    @IsTest
    static void testSecondaryMatchFields() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType =: 'Electricity'
                LIMIT 1
        ];

        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        stationWrapper.matchedId = useRecord.ElectricityEmissionFactorsId;

        String secondaryAssetFieldName = stationWrapper.getSecondaryLookupName();
        String secondaryEurFieldName = stationWrapper.getSecondaryEnergyUseLookupFieldName();

        Assert.isTrue(stationWrapper.requiresSecondaryLookup, 'expected secondary match for market based factor');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_MARKETBASED_ELECTRIC_EMISSIONS,
                secondaryAssetFieldName, 'should be looking for market based field');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_MARKETBASED_ELECTRIC_EMISSIONS,
                secondaryEurFieldName, 'expected lookup name for market based emissions field');
    }
}