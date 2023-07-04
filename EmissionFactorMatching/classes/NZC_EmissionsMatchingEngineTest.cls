/**
 * Created by mverigin on 6/26/23.
 */

@IsTest
private class NZC_EmissionsMatchingEngineTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('Enginestationary');
        NZC_EmissionsMatchingDatafactory.setupVehicle('EngineVehicle');
    }

    @IsTest
    static void testEngineRun() {
        List<NZC_EmissionsMatchingWrapper> emissionWrappers = new List<NZC_EmissionsMatchingWrapper>();
        Map<String, SObject> updateMap = new Map<String, SObject>();

        List<GeneratedWaste> wasteUseList = [
                SELECT Id,StartDate,StnryAssetEnvrSrcId, DisposalType, WstDispoEmssnFctrId
                FROM GeneratedWaste
        ];

        // all records should be using emissions master Set id so should have 1 unique Id
        Set<Id> wasteSetIdsFoundOnRecords = new Set<Id>();
        for (GeneratedWaste wasteUse : wasteUseList) {
            wasteSetIdsFoundOnRecords.add(wasteUse.WstDispoEmssnFctrId);
            emissionWrappers.add(new NZC_EmissionsMatchingWasteWrapper(wasteUse));
            updateMap.put(wasteUse.Id, wasteUse);
        }
        Assert.isTrue(wasteSetIdsFoundOnRecords.size() == 1, 'exepected all records to use same emissions factor');

        // all records should be using master emissions Set id, with 3 unique fuels should get 3 unique Ids
        Set<Id> stationSetIdsFoundOnRecords = new Set<Id>();
        List<StnryAssetEnrgyUse> stationUseList = [
                SELECT Id,StartDate,StnryAssetEnvrSrcId, FuelType, RefrigerantEmssnFctrId, OtherEmssnFctrId, ElectricityEmissionFactorsId
                FROM StnryAssetEnrgyUse
        ];
        for(StnryAssetEnrgyUse stationUse : stationUseList) {
            if (String.isNotBlank(stationUse.RefrigerantEmssnFctrId)) stationSetIdsFoundOnRecords.add(stationUse.RefrigerantEmssnFctrId);
            if (String.isNotBlank(stationUse.OtherEmssnFctrId)) stationSetIdsFoundOnRecords.add(stationUse.OtherEmssnFctrId);
            if (String.isNotBlank(stationUse.ElectricityEmissionFactorsId)) stationSetIdsFoundOnRecords.add(stationUse.ElectricityEmissionFactorsId);
            emissionWrappers.add(new NZC_EmissionsMatchingStationaryWrapper(stationUse));
            updateMap.put(stationUse.Id, stationUse);
        }
        Assert.areEqual(3, stationSetIdsFoundOnRecords.size(), 'expected all records to use master emission factor set for 3 emissions types');

        // all records should be using master emissions Set id and return 1 unique Ids
        Set<Id> vehicleSetIdsFoundOnRecords = new Set<Id>();
        List<VehicleAssetEnrgyUse> vehicleUseList = [
                SELECT Id,StartDate,VehicleAssetEmssnSrcId, FuelType, OtherEmssnFctrId
                FROM VehicleAssetEnrgyUse
        ];
        for(VehicleAssetEnrgyUse vehicleUse : vehicleUseList) {
            if (String.isNotBlank(vehicleUse.OtherEmssnFctrId)) vehicleSetIdsFoundOnRecords.add(vehicleUse.OtherEmssnFctrId);
            emissionWrappers.add(new NZC_EmissionsMatchingVehicleWrapper(vehicleUse));
            updateMap.put(vehicleUse.Id, vehicleUse);
        }
        Assert.areEqual(1, vehicleSetIdsFoundOnRecords.size(), 'expected all records to use master emission factor set');

        NZC_EmissionsMatchingEngine engine = new NZC_EmissionsMatchingEngine();
        engine.loadMatchTargets(emissionWrappers);

        Test.startTest();
        engine.process();
        engine.attachUpdatesToExistingRecord(updateMap);
        Test.stopTest();

        Set<Id> combinedMasterIdSet = new Set<Id>();
        combinedMasterIdSet.addAll(wasteSetIdsFoundOnRecords);
        combinedMasterIdSet.addAll(stationSetIdsFoundOnRecords);
        combinedMasterIdSet.addAll(vehicleSetIdsFoundOnRecords);

        for (SObject updatedRecord : updateMap.values()) {
            // verify the new Emissions Ids are not any of the old Master emissions sets
            if (String.valueOf(updatedRecord.getSObjectType()) == NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE) {
                Assert.isFalse(combinedMasterIdSet.contains((Id) updatedRecord.get('OtherEmssnFctrId')), 'Emissions did not get updated from master set');
            }

            if (String.valueOf(updatedRecord.getSObjectType()) == NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE) {
                Assert.isFalse(combinedMasterIdSet.contains((Id) updatedRecord.get('WstDispoEmssnFctrId')), 'Emissions did not get updated from master set');
            }

            if (String.valueOf(updatedRecord.getSObjectType()) == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE) {
                Boolean didUpdateEmissions = combinedMasterIdSet.contains((Id) updatedRecord.get('OtherEmssnFctrId'));
                if ((String) updatedRecord.get('FuelType') == NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY) {
                    didUpdateEmissions = combinedMasterIdSet.contains((Id) updatedRecord.get('ElectricityEmissionFactorsId'));
                }
                if ((String) updatedRecord.get('FuelType') == NZC_EmissionsMatchingConstants.FUEL_TYPE_REFRIGERANT) {
                    didUpdateEmissions = combinedMasterIdSet.contains((Id) updatedRecord.get('RefrigerantEmssnFctrId'));
                }
                Assert.isFalse(didUpdateEmissions, 'Emissions did not get updated from master set');
            }
        }
    }

    @IsTest
    static void testMatchFunctionality() {
        RefrigerantEmssnFctr masterSet = [
                SELECT Id, MasterEmissionsSet__c, EmissionsFactorUpdateYear__c
                FROM RefrigerantEmssnFctr
                ORDER BY EmissionsFactorUpdateYear__c ASC NULLS FIRST
                LIMIT 1
        ];

        List<RefrigerantEmssnFctr> childList = [
                SELECT Id, MasterEmissionsSet__c, EmissionsFactorUpdateYear__c
                FROM RefrigerantEmssnFctr
                WHERE MasterEmissionsSet__c =: masterSet.Id
                ORDER BY EmissionsFactorUpdateYear__c ASC
        ];

        // verify first factor is master
        Assert.isNull(masterSet.MasterEmissionsSet__c);
        Assert.isNull(masterSet.EmissionsFactorUpdateYear__c);
        Assert.isTrue(childList.size() > 1);

        String masterEmissionsId = masterSet.Id;
        for (Integer i = 0; i < childList.size(); i++) {
            Date dateThatWouldMatchThisFactor = childList.get(i).EmissionsFactorUpdateYear__c;
            String matchedId = NZC_EmissionsMatchingEngine.matchingLogic(masterEmissionsId, dateThatWouldMatchThisFactor, (List<SObject>) childList);
            Assert.areEqual(childList.get(i).Id, matchedId, 'Function should have matched This Date');
        }

        // verify that a date before matching List earliest date is defaulted to masterEmissions Id
        Date outOfBoundsDate = childList.get(0).EmissionsFactorUpdateYear__c;
        outOfBoundsDate = outOfBoundsDate.addMonths(-12);
        String outsideDateBoundsId = NZC_EmissionsMatchingEngine.matchingLogic(masterEmissionsId, outOfBoundsDate, childList);
        Assert.areEqual(masterEmissionsId, outsideDateBoundsId, 'Function should match master set by default');

        // verify that an empty matching list is defaulted to masterEmissions Id
        String emptyMatchId = NZC_EmissionsMatchingEngine.matchingLogic(masterEmissionsId, Date.today(), new List<SObject>());
        Assert.areEqual(masterEmissionsId, emptyMatchId, 'Function should match master set by default');
    }
}