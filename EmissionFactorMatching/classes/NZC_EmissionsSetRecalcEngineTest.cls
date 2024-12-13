/**
 * Created by mverigin on 6/27/23.
 */

@IsTest
private class NZC_EmissionsSetRecalcEngineTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupVehicle('vehicleRecalc');
        NZC_EmissionsMatchingDatafactory.setupStationary('stationaryRecalc');
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
        engine.loadSetIds(emissionSets.values());
        engine.processRecords();

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
        engine.loadSetIds(emissionSets.values());
        engine.processRecords();

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
}