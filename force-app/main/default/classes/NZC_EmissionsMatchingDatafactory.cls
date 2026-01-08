/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
public class NZC_EmissionsMatchingDatafactory {

    private static final String WASTE_DISPOSAL_TYPE = 'Combusted';
    private static final String WASTE_WASTE_TYPE = 'Bread';
    private static final String WASTE_WASTE_UNIT = 'kg';
    private static final String OTHER_FUEL_TYPE = 'Diesel';
    private static final String OTHER_FUEL_UNIT = 'Liters';
    private static final String UNIT_LBS = 'Lbs';
    public static final String UNIT_KWH = 'kWH';

    public static void setupStationary(String name) {
        Integer yearsBack = 5;

        List<OtherEmssnFctrSet> otherSetList = createOtherSetMatrix(yearsBack, name + 'otherSet');
        List<RefrigerantEmssnFctr> refrigerantSetList = createRefrigerantSetMatrix(yearsBack, name + 'RefrigSet');
        List<ElectricityEmssnFctrSet> electSetList = createElecSetMatrix(yearsBack, name + 'ElecSet');
        List<WstDispoEmssnFctrSet> wasteSetList = createWasteSetMatrix(yearsBack, name + 'wasteSet');

        StnryAssetEnvrSrc asset = createStationaryAsset(name, otherSetList.get(yearsBack).Id, electSetList.get(yearsBack).Id, refrigerantSetList.get(yearsBack).Id, wasteSetList.get(yearsBack).Id);
        insert asset;

        List<String> fuelTypes = new List<String>{NZC_EmissionsMatchingConstants.FUEL_TYPE_REFRIGERANT, NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY, OTHER_FUEL_TYPE};
        List<String> fuelUnits = new List<String>{UNIT_LBS, UNIT_KWH, OTHER_FUEL_UNIT};

        List<StnryAssetEnrgyUse> useList = new List<StnryAssetEnrgyUse>();
        List<GeneratedWaste> wasteList = new List<GeneratedWaste>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);

            wasteList.add(createWasteUse( name + i, asset.Id, start, endDate));
            for (Integer j = 0; j < fuelTypes.size(); j++) {
                useList.add(createStationaryEnergyUse( name + i+' '+j, asset.Id, fuelTypes.get(j), fuelUnits.get(j), start, endDate));
            }
        }

        insert useList;
        insert wasteList;
    }

    public static void setupVehicle(String name) {
        Integer yearsBack = 5;

        List<OtherEmssnFctrSet> otherSetList = createOtherSetMatrix(yearsBack, name + 'otherSet');
        VehicleAssetEmssnSrc asset = createVehiclAsset(name, otherSetList.get(otherSetList.size()-1).Id);
        insert asset;

        List<VehicleAssetEnrgyUse> vehicleList = new List<VehicleAssetEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            vehicleList.add(createVehicleEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert vehicleList;
    }

    public static void setupHotel(String name) {
        Integer yearsBack = 5;

        List<HotelStayEmssnFctr> otherSetList = createHotelEmissionsSetMatrix(yearsBack, name + 'otherSet');
        Scope3EmssnSrc asset = createHotelAsset(name, otherSetList.get(otherSetList.size()-1).Id);
        insert asset;

        List<HotelStayEnrgyUse> hotelUseList = new List<HotelStayEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            hotelUseList.add(createHotelEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert hotelUseList;
    }

        Scope3EmssnSrc asset = createFreightAsset(name, freightSetList.get(freightSetList.size()-1).Id);
        insert asset;

        List<FrgtHaulingEnrgyUse> freightUseList = new List<FrgtHaulingEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            freightUseList.add(createFreightEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert freightUseList;
    }

    public static void setupGroundTravel(String name) {
        Integer yearsBack = 5;

        List<GroundTravelEmssnFctr> groundTravelSetList = createGroundTravelEmissionsSetMatrix(yearsBack, name + 'groundTravelSet');
        Scope3EmssnSrc asset = createGroundTravelAsset(name, groundTravelSetList.get(groundTravelSetList.size()-1).Id);
        insert asset;

        List<GroundTravelEnrgyUse> groundTravelUseList = new List<GroundTravelEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            groundTravelUseList.add(createGroundTravelEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert groundTravelUseList;
    }

    public static void setupAirTravel(String name) {
        Integer yearsBack = 5;

        List<AirTravelEmssnFctr> airTravelSetList = createAirTravelEmissionsSetMatrix(yearsBack, name + 'airTravelSet');
        Scope3EmssnSrc asset = createAirTravelAsset(name, airTravelSetList.get(airTravelSetList.size()-1).Id);
        insert asset;

        List<AirTravelEnrgyUse> airTravelUseList = new List<AirTravelEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            airTravelUseList.add(createAirTravelEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert airTravelUseList;
    }

    public static void setupRentalCar(String name) {
        Integer yearsBack = 5;

        List<OtherEmssnFctrSet> otherSetList = createOtherSetMatrix(yearsBack, name + 'otherSet');
        List<RentalCarEmssnFctr> rentalCarSetList = createRentalCarEmissionsSetMatrix(yearsBack, name + 'rentalCarSet', otherSetList.get(yearsBack).Id);
        Scope3EmssnSrc asset = createRentalCarAsset(name, rentalCarSetList.get(rentalCarSetList.size()-1).Id);
        insert asset;

        List<RentalCarEnrgyUse> rentalCarUseList = new List<RentalCarEnrgyUse>();

        for (Integer i = 0; i < yearsBack; i++) {
            Date start = Date.today().addMonths((i+1) * -12);
            Date endDate = Date.today().addMonths((i+1) * -10);
            rentalCarUseList.add(createRentalCarEnergyUse( name + i, asset.Id, start, endDate));
        }

        insert rentalCarUseList;
    }

    public static OtherEmssnFctrSet createOtherEmissionSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new OtherEmssnFctrSet(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<OtherEmssnFctrSet> createOtherSetMatrix(Integer amount, String setName) {
        OtherEmssnFctrSet masterSet = createOtherEmissionSet(setName, null, null);
        insert masterSet;

        List<OtherEmssnFctrSet> childSets = new List<OtherEmssnFctrSet>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createOtherEmissionSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        List<OtherEmssnFctrSetItem> emissionsItems = new List<OtherEmssnFctrSetItem>();
        for (OtherEmssnFctrSet setItem : childSets) {
            emissionsItems.add(createOtherEmissionsItem(setItem.Id));
        }
        insert emissionsItems;

        return childSets;
    }

    public static OtherEmssnFctrSetItem createOtherEmissionsItem(String otherSetId) {
        return new OtherEmssnFctrSetItem(
                FuelType = OTHER_FUEL_TYPE,
                ParentEmissionFactorId = otherSetId,
                CalorificValue = 1
        );
    }

    public static RefrigerantEmssnFctr createRefrigerantEmissionSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new RefrigerantEmssnFctr(
                Name = name,
                GlblWarmingPotInKgCo2eKg = 100,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<RefrigerantEmssnFctr> createRefrigerantSetMatrix(Integer amount, String setName) {
        RefrigerantEmssnFctr masterSet = createRefrigerantEmissionSet(setName, null, null);
        insert masterSet;

        List<RefrigerantEmssnFctr> childSets = new List<RefrigerantEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createRefrigerantEmissionSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static HotelStayEmssnFctr createHotelEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new HotelStayEmssnFctr(
                Name = name,
                HotelStayEmssnInKgCo2eNight = 10,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<HotelStayEmssnFctr> createHotelEmissionsSetMatrix(Integer amount, String setName) {
        HotelStayEmssnFctr masterSet = createHotelEmissionsSet(setName, null, null);
        insert masterSet;

        List<HotelStayEmssnFctr> childSets = new List<HotelStayEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createHotelEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static FrgtHaulingEmssnFctr createFreightEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet, String otherEmissionsId) {
        return new FrgtHaulingEmssnFctr(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true,
                OtherEmssnFctrId = otherEmissionsId
        );
    }

    public static List<FrgtHaulingEmssnFctr> createFreightEmissionsSetMatrix(Integer amount, String setName, String otherEmissionsId) {
        FrgtHaulingEmssnFctr masterSet = createFreightEmissionsSet(setName, null, null, otherEmissionsId);
        insert masterSet;

        List<FrgtHaulingEmssnFctr> childSets = new List<FrgtHaulingEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createFreightEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id, otherEmissionsId));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static GroundTravelEmssnFctr createGroundTravelEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new GroundTravelEmssnFctr(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<GroundTravelEmssnFctr> createGroundTravelEmissionsSetMatrix(Integer amount, String setName) {
        GroundTravelEmssnFctr masterSet = createGroundTravelEmissionsSet(setName, null, null);
        insert masterSet;

        List<GroundTravelEmssnFctr> childSets = new List<GroundTravelEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createGroundTravelEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static AirTravelEmssnFctr createAirTravelEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new AirTravelEmssnFctr(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<AirTravelEmssnFctr> createAirTravelEmissionsSetMatrix(Integer amount, String setName) {
        AirTravelEmssnFctr masterSet = createAirTravelEmissionsSet(setName, null, null);
        insert masterSet;

        List<AirTravelEmssnFctr> childSets = new List<AirTravelEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createAirTravelEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static RentalCarEmssnFctr createRentalCarEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet, String otherEmissionsId) {
        return new RentalCarEmssnFctr(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true,
                OtherEmssnFctrId = otherEmissionsId
        );
    }

    public static List<RentalCarEmssnFctr> createRentalCarEmissionsSetMatrix(Integer amount, String setName, String otherEmissionsId) {
        RentalCarEmssnFctr masterSet = createRentalCarEmissionsSet(setName, null, null, otherEmissionsId);
        insert masterSet;

        List<RentalCarEmssnFctr> childSets = new List<RentalCarEmssnFctr>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createRentalCarEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id, otherEmissionsId));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static ElectricityEmssnFctrSet createElectricityEmissionSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new ElectricityEmssnFctrSet(
                Name = name,
                LocationBasedHydroMixPct = 100,
                MarketBasedHydroMixPct = 100,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<ElectricityEmssnFctrSet> createElecSetMatrix(Integer amount, String setName) {
        ElectricityEmssnFctrSet masterSet = createElectricityEmissionSet(setName, null, null);
        insert masterSet;

        List<ElectricityEmssnFctrSet> childSets = new List<ElectricityEmssnFctrSet>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createElectricityEmissionSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        return childSets;
    }

    public static WstDispoEmssnFctrSet createWasteEmissionsSet(String name, Date relevanceDate, String masterEmissionsSet) {
        return new WstDispoEmssnFctrSet(
                Name = name,
                EmissionsFactorUpdateYear__c = relevanceDate,
                MasterEmissionsSet__c = masterEmissionsSet,
                Recalculate_Emissions__c = true
        );
    }

    public static List<WstDispoEmssnFctrSet> createWasteSetMatrix(Integer amount, String setName) {
        WstDispoEmssnFctrSet masterSet = createWasteEmissionsSet(setName, null, null);
        insert masterSet;

        List<WstDispoEmssnFctrSet> childSets = new List<WstDispoEmssnFctrSet>();
        for (Integer i = 0; i < amount; i++) {
            childSets.add(createWasteEmissionsSet(setName + 'child' + i,Date.today().addMonths((i+1) * -12), masterSet.Id));
        }
        insert childSets;
        childSets.add(masterSet);

        List<WstDispoEmssnFctrSetItm> emissionsItems = new List<WstDispoEmssnFctrSetItm>();
        for (WstDispoEmssnFctrSet setItem : childSets) {
            emissionsItems.add(createWasteItem(setItem.Id, setItem.Name + 'Item'));
        }
        insert emissionsItems;

        return childSets;
    }

    public static WstDispoEmssnFctrSetItm createWasteItem(String wasteSetId, String name) {
        return new WstDispoEmssnFctrSetItm(
                ParentEmissionFactorId = wasteSetId,
                Name = name,
                DisposalType = WASTE_DISPOSAL_TYPE,
                WasteType = WASTE_WASTE_TYPE,
                EmissionsFactorValue = 34
        );
    }

    public static StnryAssetEnvrSrc createStationaryAsset(String name, String otherEmissionsId, String electricityEmissionsId, String refrigerantEmissionsId, String wasteSetId) {
        Id recordTypeId = StnryAssetEnvrSrc.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial_Building')?.getRecordTypeId();

        StnryAssetEnvrSrc createdRecord = new StnryAssetEnvrSrc(
                Name = name,
                OtherEmssnFctrId = otherEmissionsId,
                ElectricityEmssnFctrId = electricityEmissionsId,
                RefrigerantEmssnFctrId = refrigerantEmissionsId,
                WstDispoEmssnFctrSetId = wasteSetId
        );

        if (recordTypeId != null)  createdRecord.put('RecordTypeId', recordTypeId);

        return createdRecord;
    }

    public static StnryAssetEnrgyUse createStationaryEnergyUse( String name, String assetId, String fuelType, String fuelUnit, Date startDate, Date endDate) {
        return new StnryAssetEnrgyUse(
                Name = name,
                StnryAssetEnvrSrcId = assetId,
                FuelConsumption = 150,
                FuelConsumptionUnit = fuelUnit,
                FuelType = fuelType,
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static GeneratedWaste createWasteUse( String name, String assetId, Date startDate, Date endDate) {
        return new GeneratedWaste(
                Name = name,
                StnryAssetEnvrSrcId = assetId,
                DisposedWasteQuantity = 150,
                DisposedWasteQuantityUnit = WASTE_WASTE_UNIT,
                DisposalType = WASTE_DISPOSAL_TYPE,
                WasteType = WASTE_WASTE_TYPE,
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static VehicleAssetEmssnSrc createVehiclAsset(String name, String otherEmissionsId) {
        Id recordTypeId = VehicleAssetEmssnSrc.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Fleet_Vehicle')?.getRecordTypeId();
        VehicleAssetEmssnSrc createdRecord = new VehicleAssetEmssnSrc(
                Name = name,
                OtherEmssnFctrId =  otherEmissionsId
        );

        if (recordTypeId != null) createdRecord.put('RecordTypeId', recordTypeId);

        return createdRecord;
    }

    public static Scope3EmssnSrc createHotelAsset(String name, String hotelEmissionsId) {
        Scope3EmssnSrc createdRecord = new Scope3EmssnSrc(
                Name = name,
                HotelStayEmssnFctrId = hotelEmissionsId
        );

        return createdRecord;
    }

    public static Scope3EmssnSrc createFreightAsset(String name, String freightEmissionsId) {
        Scope3EmssnSrc createdRecord = new Scope3EmssnSrc(
                Name = name,
                FrgtHaulingEmssnFctrId = freightEmissionsId
        );

        return createdRecord;
    }

    public static Scope3EmssnSrc createGroundTravelAsset(String name, String groundTravelEmissionsId) {
        Scope3EmssnSrc createdRecord = new Scope3EmssnSrc(
                Name = name,
                GroundTravelEmssnFctrId = groundTravelEmissionsId
        );

        return createdRecord;
    }

    public static Scope3EmssnSrc createAirTravelAsset(String name, String airTravelEmissionsId) {
        Scope3EmssnSrc createdRecord = new Scope3EmssnSrc(
                Name = name,
                AirTravelEmssnFctrId = airTravelEmissionsId
        );

        return createdRecord;
    }

    public static Scope3EmssnSrc createRentalCarAsset(String name, String rentalCarEmissionsId) {
        Scope3EmssnSrc createdRecord = new Scope3EmssnSrc(
                Name = name,
                RentalCarEmssnFctrId = rentalCarEmissionsId
        );

        return createdRecord;
    }

    public static VehicleAssetEnrgyUse createVehicleEnergyUse( String name, String vehicleAssetId, Date startDate, Date endDate) {
        return new VehicleAssetEnrgyUse(
                Name = name,
                VehicleAssetEmssnSrcId = vehicleAssetId,
                FuelConsumption = 150,
                FuelConsumptionUnit = OTHER_FUEL_UNIT,
                FuelType = OTHER_FUEL_TYPE,
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static HotelStayEnrgyUse createHotelEnergyUse( String name, String scope3AssetId, Date startDate, Date endDate) {
        return new HotelStayEnrgyUse(
                Name = name,
                Scope3EmssnSrcId = scope3AssetId,
                StayNightsCount = 5,
                RoomCount = 5,
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static FrgtHaulingEnrgyUse createFreightEnergyUse( String name, String scope3AssetId, Date startDate, Date endDate) {
        return new FrgtHaulingEnrgyUse(
                Name = name,
                Scope3EmssnSrcId = scope3AssetId,
                Distance = 100,
                DistanceUnit = 'Kilometers',
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static GroundTravelEnrgyUse createGroundTravelEnergyUse( String name, String scope3AssetId, Date startDate, Date endDate) {
        return new GroundTravelEnrgyUse(
                Name = name,
                Scope3EmssnSrcId = scope3AssetId,
                Distance = 100,
                DistanceUnit = 'Kilometers',
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static AirTravelEnrgyUse createAirTravelEnergyUse( String name, String scope3AssetId, Date startDate, Date endDate) {
        return new AirTravelEnrgyUse(
                Name = name,
                Scope3EmssnSrcId = scope3AssetId,
                SegmentDistance = 1000,
                SegmentDistanceUnit = 'Kilometers',
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static RentalCarEnrgyUse createRentalCarEnergyUse( String name, String scope3AssetId, Date startDate, Date endDate) {
        return new RentalCarEnrgyUse(
                Name = name,
                Scope3EmssnSrcId = scope3AssetId,
                Distance = 172,
                DistanceUnit = 'Kilometers',
                FuelType = 'Gasoline',
                StartDate = startDate,
                EndDate = endDate,
                Recalculate_Emissions__c = true
        );
    }

    public static void createEmissionsSettings() {
        NZC_EmissionsMatchingMTD.matchingConfig = new NZC_EmissionsMatchingConfig__c(
                DoMatchEmissionsOnInsert__c = true,
                DoMatchEmissionsOnUpdate__c = true,
                DateMatchingField__c = NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,
                doLog__c = true,
                Emissions_Matching_Batch_Size__c = NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE + 1,
                Emissions_Recalc_Batch_Size__c = NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE + 1,
                allowCustomTagMatching__c = true
        );
    }

    public static NZC_EmissionsMatchingCustomMatch__mdt createCustomMatchingRule(String objectName, String fuelType, String eurField, String emissionsField) {
        return new NZC_EmissionsMatchingCustomMatch__mdt(
                ObjectAppliesTo__c = objectName,
                FuelType__c = fuelType,
                EnergyUseFieldToMatch__c = eurField,
                EmissionsSetFieldToMatch__c = emissionsField
        );
    }
}