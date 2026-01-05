/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsSetRecalcEngineTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupVehicle('vehicleRecalc');
        NZC_EmissionsMatchingDatafactory.setupStationary('stationaryRecalc');
        NZC_EmissionsMatchingDatafactory.setupHotel('HotelRecalc');
    }

    @IsTest
    static void testProcess_noUpdate() {
        Map<Id, OtherEmssnFctrSet> emissionSets = new Map<Id, OtherEmssnFctrSet>([
                SELECT Id, Recalculate_Emissions__c
                FROM OtherEmssnFctrSet
                WHERE Recalculate_Emissions__c = TRUE
        ]);

        Assert.isFalse(emissionSets.isEmpty());

        List<SObject> matchingEUR = new List<SObject>();
        matchingEUR.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE OtherEmssnFctrId IN: emissionSets.keySet()
        ]);
        matchingEUR.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                WHERE OtherEmssnFctrId IN: emissionSets.keySet()
        ]);

        Assert.isFalse(matchingEUR.isEmpty());
        // engine should turn the flag back after we set it
        for (SObject record : matchingEUR) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, false);
        }

        update matchingEUR;

        NZC_EmissionsSetRecalcEngine engine = new NZC_EmissionsSetRecalcEngine();

        Test.startTest();
        engine.loadSetIds(emissionSets.values());
        engine.processRecords();
        Test.stopTest();

        List<SObject> updatedEurs = new List<SObject>();
        updatedEurs.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE OtherEmssnFctrId IN: emissionSets.keySet()
        ]);
        updatedEurs.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                WHERE OtherEmssnFctrId IN: emissionSets.keySet()
        ]);

        for (SObject record : updatedEurs) {
            Assert.isTrue(Boolean.valueOf(record.get(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD)));
        }
    }

    @IsTest
    static void testProcessWithUpdateRefridge() {
        Map<Id, RefrigerantEmssnFctr> emissionSets = new Map<Id, RefrigerantEmssnFctr>([
                SELECT Id, Recalculate_Emissions__c
                FROM RefrigerantEmssnFctr
                WHERE Recalculate_Emissions__c = TRUE
        ]);

        Assert.isFalse(emissionSets.isEmpty());

        List<SObject> matchingEUR = new List<SObject>();
        matchingEUR.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE RefrigerantEmssnFctrId IN: emissionSets.keySet()
        ]);

        Assert.isFalse(matchingEUR.isEmpty());

        // engine should turn the flag back after we set it
        for (SObject record : matchingEUR) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, false);
        }

        update matchingEUR;

        NZC_EmissionsSetRecalcEngine engine = new NZC_EmissionsSetRecalcEngine(true);

        Test.startTest();
        engine.loadSetIds(emissionSets.values());
        engine.processRecords();
        Test.stopTest();

        List<SObject> updatedEurs = new List<SObject>();
        updatedEurs.addAll([
                SELECT Id, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE RefrigerantEmssnFctrId IN: emissionSets.keySet()
        ]);

        for (SObject record : updatedEurs) {
            Assert.isTrue(Boolean.valueOf(record.get(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD)));
        }

        for (SObject record : [
                SELECT Id, Recalculate_Emissions__c
                FROM RefrigerantEmssnFctr
                WHERE Id IN: emissionSets.keySet()
        ]) {
            // expecting engine to turn flag on sets off
            Assert.isFalse(Boolean.valueOf(record.get(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD)));
        }
    }

    @IsTest
    static void testHotelRecalc() {
        Map<Id, HotelStayEmssnFctr> hotelFactors = new Map<Id, HotelStayEmssnFctr>([
                SELECT Id, Recalculate_Emissions__c
                FROM HotelStayEmssnFctr
                WHERE Recalculate_Emissions__c = TRUE
        ]);

        Assert.isTrue(!hotelFactors.isEmpty(), 'no flagged emissions');

        List<HotelStayEnrgyUse> useRecords = new List<HotelStayEnrgyUse>();
        for (HotelStayEnrgyUse energyUse: [
                SELECT Id
                FROM HotelStayEnrgyUse
                WHERE HotelStayEmssnFctrId IN: hotelFactors.keySet()
        ]) {
            // this field should get flagged by engine
            energyUse.Recalculate_Emissions__c = false;
            useRecords.add(energyUse);
        }
        Assert.isTrue(!useRecords.isEmpty());

        //turn off auto matching
        NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate = false;

        update useRecords;

        NZC_EmissionsSetRecalcEngine engine = new NZC_EmissionsSetRecalcEngine(true);

        Test.startTest();
        engine.loadSetIds(hotelFactors.values());
        engine.processRecords();
        Test.stopTest();

        Map<Id, HotelStayEmssnFctr> factorsAfter = new Map<Id, HotelStayEmssnFctr>([
                SELECT Id
                FROM HotelStayEmssnFctr
                WHERE Id IN: hotelFactors.keySet() AND Recalculate_Emissions__c = FALSE
        ]);

        List<HotelStayEnrgyUse> useRecordsAfter = new List<HotelStayEnrgyUse>();
        for (HotelStayEnrgyUse energyUse: [
                SELECT Id, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
        ]) {
            Assert.isTrue(energyUse.Recalculate_Emissions__c, 'flag should be added');
            useRecordsAfter.add(energyUse);
        }

        Assert.isTrue(!useRecordsAfter.isEmpty());
        Assert.areEqual(useRecords.size(), useRecordsAfter.size());
        Assert.areEqual(hotelFactors.size(), factorsAfter.size(), 'did not un flag all emissions factors');
        Assert.isTrue(!factorsAfter.isEmpty());
    }
}