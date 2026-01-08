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
        NZC_EmissionsMatchingDatafactory.setupFreight('freight');
        NZC_EmissionsMatchingDatafactory.setupAirTravel('airTravel');
        NZC_EmissionsMatchingDatafactory.setupGroundTravel('groundTravel');
        NZC_EmissionsMatchingDatafactory.setupRentalCar('rentalCar');
        NZC_EmissionsMatchingDatafactory.setupHotel('hotel');
    }

    // Helper method to reduce code duplication
    private static void assertWrapperBehavior(
        SObject useRecord,
        String assetIdField,
        String emissionsFactorIdField,
        String dateField,
        String fuelType,
        String expectedAssetObject,
        String expectedAssetLookupField,
        String expectedUseLookupField
    ) {
        Id assetId = (Id) useRecord.get(assetIdField);
        Date startDate = (Date) useRecord.get(dateField);
        Id emissionsFactorId = (Id) useRecord.get(emissionsFactorIdField);
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            assetId, useRecord.Id, startDate, fuelType);
        wrapper.matchedId = emissionsFactorId;
        
        String parentAssetName = wrapper.getParentAssetObjName();
        String parentLookupName = wrapper.getObjectAssetLookupFieldName();
        String useLookupName = wrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = wrapper.createRecordUpdate();
        Test.stopTest();
        
        Assert.areEqual(expectedAssetObject, parentAssetName, 'Parent asset object mismatch');
        Assert.areEqual(expectedAssetLookupField, parentLookupName, 'Asset lookup field mismatch');
        Assert.areEqual(expectedUseLookupField, useLookupName, 'Energy use lookup field mismatch');
        Assert.areEqual(useRecord.Id, recordUpdate.Id, 'Record ID mismatch');
        Assert.areEqual(emissionsFactorId, recordUpdate.get(emissionsFactorIdField), 'Emissions factor ID mismatch');
        Assert.isNotNull(recordUpdate.get(emissionsFactorIdField), 'Emissions factor should not be null');
    }

    @IsTest
    static void testVehicleWrapper() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, StartDate, VehicleAssetEmssnSrcId, FuelType
                FROM VehicleAssetEnrgyUse
                WHERE OtherEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'VehicleAssetEmssnSrcId',
            'OtherEmssnFctrId',
            'StartDate',
            useRecord.FuelType,
            NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_OTHER_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_OTHER_EMISSIONS
        );
    }

    @IsTest
    static void testOtherStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType = 'Diesel'
                AND OtherEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'StnryAssetEnvrSrcId',
            'OtherEmssnFctrId',
            'StartDate',
            useRecord.FuelType,
            NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_OTHER_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_OTHER_EMISSIONS
        );
    }

    @IsTest
    static void testElecStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType = 'Electricity'
                AND ElectricityEmissionFactorsId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'StnryAssetEnvrSrcId',
            'ElectricityEmissionFactorsId',
            'StartDate',
            useRecord.FuelType,
            NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_ELECTRIC_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_ELECTRIC_EMISSIONS
        );
    }

    @IsTest
    static void testRefrigStationWrapper() {
        StnryAssetEnrgyUse useRecord = [
                SELECT Id, OtherEmssnFctrId, RefrigerantEmssnFctrId, ElectricityEmissionFactorsId, StartDate, StnryAssetEnvrSrcId, FuelType
                FROM StnryAssetEnrgyUse
                WHERE FuelType = 'Refrigerant'
                AND RefrigerantEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'StnryAssetEnvrSrcId',
            'RefrigerantEmssnFctrId',
            'StartDate',
            useRecord.FuelType,
            NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_REFRIGERANT_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_REFRIGERANT_EMISSIONS
        );
    }

    @IsTest
    static void testWasteStationWrapper() {
        GeneratedWaste useRecord = [
                SELECT Id, StartDate, StnryAssetEnvrSrcId, WstDispoEmssnFctrId, DisposalType
                FROM GeneratedWaste
                WHERE WstDispoEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.DisposalType);
        stationWrapper.matchedId = useRecord.WstDispoEmssnFctrId;

        String parentAssetName = stationWrapper.getParentAssetObjName();
        String parentLookupName = stationWrapper.getObjectAssetLookupFieldName();
        String useLookupName = stationWrapper.getEnergyUseLookupFieldName();
        SObject recordUpdate = stationWrapper.createRecordUpdate();
        Test.stopTest();

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
                WHERE FuelType = 'Electricity'
                AND ElectricityEmissionFactorsId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingWrapper stationWrapper = new NZC_EmissionsMatchingWrapper(
                useRecord.StnryAssetEnvrSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        stationWrapper.matchedId = useRecord.ElectricityEmissionFactorsId;

        String secondaryAssetFieldName = stationWrapper.getSecondaryLookupName();
        String secondaryEurFieldName = stationWrapper.getSecondaryEnergyUseLookupFieldName();
        Test.stopTest();

        Assert.isTrue(stationWrapper.requiresSecondaryLookup, 'expected secondary match for market based factor');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_MARKETBASED_ELECTRIC_EMISSIONS,
                secondaryAssetFieldName, 'should be looking for market based field');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_MARKETBASED_ELECTRIC_EMISSIONS,
                secondaryEurFieldName, 'expected lookup name for market based emissions field');
    }

    // Tests for new Scope3 objects
    @IsTest
    static void testFreightWrapper() {
        FrgtHaulingEnrgyUse useRecord = [
                SELECT Id, FrgtHaulingEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM FrgtHaulingEnrgyUse
                WHERE FrgtHaulingEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'Scope3EmssnSrcId',
            'FrgtHaulingEmssnFctrId',
            'StartDate',
            null,
            NZC_EmissionsMatchingConstants.OBJECT_SCOPE3_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_FREIGHT_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_FREIGHT_EMISSIONS
        );
    }

    @IsTest
    static void testAirTravelWrapper() {
        AirTravelEnrgyUse useRecord = [
                SELECT Id, AirTravelEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM AirTravelEnrgyUse
                WHERE AirTravelEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'Scope3EmssnSrcId',
            'AirTravelEmssnFctrId',
            'StartDate',
            null,
            NZC_EmissionsMatchingConstants.OBJECT_SCOPE3_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_AIR_TRAVEL_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_AIR_TRAVEL_EMISSIONS
        );
    }

    @IsTest
    static void testGroundTravelWrapper() {
        GroundTravelEnrgyUse useRecord = [
                SELECT Id, GroundTravelEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM GroundTravelEnrgyUse
                WHERE GroundTravelEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'Scope3EmssnSrcId',
            'GroundTravelEmssnFctrId',
            'StartDate',
            null,
            NZC_EmissionsMatchingConstants.OBJECT_SCOPE3_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_GROUND_TRAVEL_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_GROUND_TRAVEL_EMISSIONS
        );
    }

    @IsTest
    static void testRentalCarWrapper() {
        RentalCarEnrgyUse useRecord = [
                SELECT Id, RentalCarEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM RentalCarEnrgyUse
                WHERE RentalCarEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'Scope3EmssnSrcId',
            'RentalCarEmssnFctrId',
            'StartDate',
            null,
            NZC_EmissionsMatchingConstants.OBJECT_SCOPE3_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_RENTAL_CAR_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_RENTAL_CAR_EMISSIONS
        );
    }

    @IsTest
    static void testHotelWrapper() {
        HotelStayEnrgyUse useRecord = [
                SELECT Id, HotelStayEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM HotelStayEnrgyUse
                WHERE HotelStayEmssnFctrId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        assertWrapperBehavior(
            useRecord,
            'Scope3EmssnSrcId',
            'HotelStayEmssnFctrId',
            'StartDate',
            null,
            NZC_EmissionsMatchingConstants.OBJECT_SCOPE3_ASSET,
            NZC_EmissionsMatchingConstants.FIELD_HOTEL_ASSET_EMISSIONS,
            NZC_EmissionsMatchingConstants.FIELD_EUR_HOTEL_EMISSIONS
        );
    }

    // Edge case tests
    @IsTest
    static void testWrapperWithGeneratedId() {
        Scope3EmssnSrc asset = [SELECT Id FROM Scope3EmssnSrc LIMIT 1];
        String generatedId = 'GEN_' + String.valueOf(DateTime.now().getTime());
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            asset.Id, 
            generatedId, 
            Date.today(), 
            null,
            NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE
        );
        Test.stopTest();
        
        Assert.areEqual(generatedId, wrapper.energyUseRecordId, 'Should preserve generated ID for before-insert scenario');
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE, wrapper.objectName, 'Object name should match provided value');
        Assert.isFalse(wrapper.requiresSecondaryLookup, 'Should not require secondary lookup');
    }

    @IsTest
    static void testWrapperWithNullFuelType() {
        Scope3EmssnSrc asset = [SELECT Id FROM Scope3EmssnSrc LIMIT 1];
        String generatedId = 'GENERATED_ID_123';
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            asset.Id, generatedId, Date.today(), null, 
            NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE);
        Test.stopTest();
        
        Assert.areEqual(generatedId, wrapper.energyUseRecordId, 'Generated ID should be preserved');
        Assert.isNull(wrapper.fuelType, 'Fuel type should be null');
        Assert.isFalse(wrapper.requiresSecondaryLookup, 'Should not require secondary lookup');
    }

    @IsTest
    static void testWrapperWithFutureDate() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, VehicleAssetEmssnSrcId, FuelType
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];
        
        Date futureDate = Date.today().addYears(1);
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            useRecord.VehicleAssetEmssnSrcId, useRecord.Id, futureDate, useRecord.FuelType);
        Test.stopTest();
        
        Assert.areEqual(futureDate, wrapper.dateToMatch, 'Future date should be preserved');
    }

    @IsTest
    static void testRecordUpdateWithNoMatchedId() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, VehicleAssetEmssnSrcId, FuelType, StartDate
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            useRecord.VehicleAssetEmssnSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        SObject recordUpdate = wrapper.createRecordUpdate();
        Test.stopTest();
        
        Assert.areEqual(useRecord.Id, recordUpdate.Id, 'Record ID should be set');
        Assert.isNull(wrapper.matchedId, 'Matched ID should be null when not set');
    }

    @IsTest
    static void testSecondaryLookupNotRequired() {
        VehicleAssetEnrgyUse useRecord = [
                SELECT Id, VehicleAssetEmssnSrcId, FuelType, StartDate
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];
        
        Test.startTest();
        NZC_EmissionsMatchingWrapper wrapper = new NZC_EmissionsMatchingWrapper(
            useRecord.VehicleAssetEmssnSrcId, useRecord.Id, useRecord.StartDate, useRecord.FuelType);
        Test.stopTest();
        
        Assert.isFalse(wrapper.requiresSecondaryLookup, 'Vehicle energy use should not require secondary lookup');
    }
}