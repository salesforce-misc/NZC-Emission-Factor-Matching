/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingMTDTest {
    @IsTest
    static void testGetCustomMatch() {
        Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt> rules = NZC_EmissionsMatchingMTD.customMatchingRules;

        String fuelType1 = 'Electricity';
        String fuelType2 = 'Refrigerant';
        String objectName = 'StnryAssetEnrgyUse';
        String customTagField = 'Name';

        NZC_EmissionsMatchingMTD.customMatchingRules = new Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt>{
                NZC_EmissionsMatchingUtil.createHashKey(objectName,fuelType1) =>
                        NZC_EmissionsMatchingDatafactory.createCustomMatchingRule(objectName, fuelType1, customTagField, customTagField),
                NZC_EmissionsMatchingUtil.createHashKey(objectName,fuelType2) =>
                        NZC_EmissionsMatchingDatafactory.createCustomMatchingRule(objectName, fuelType2, customTagField, customTagField)
        };

        Assert.isNotNull(NZC_EmissionsMatchingMTD.customMatchingRules, 'no rules populated');
        Assert.isTrue(NZC_EmissionsMatchingMTD.customMatchingRules.size() > 0, 'no rules populated');
    }

    @IsTest
    static void testGetAdvanceMatch() {
        Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>> rules = NZC_EmissionsMatchingMTD.advancedMatchingRules;
        NZC_EmissionsMatchingAdvancedMatchTest.createAdvanceMatchRules();

        Assert.isNotNull(NZC_EmissionsMatchingMTD.advancedMatchingRules, 'no rules populated');
        Assert.isTrue(NZC_EmissionsMatchingMTD.advancedMatchingRules.size() > 0, 'no rules populated');
    }

    @IsTest
    static void testSetters() {
        NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert = true;
        NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate = true;
        NZC_EmissionsMatchingMTD.dateMatchingField = NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE;
        NZC_EmissionsMatchingMTD.doLog = true;
        NZC_EmissionsMatchingMTD.allowCustomTagMatching = true;
        NZC_EmissionsMatchingMTD.allowAdvancedMatching = true;
        NZC_EmissionsMatchingMTD.emissionsMatchBatchSize = NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE;
        NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize = NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert, 'Expecting insert to be true');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate, 'Expecting update to be true');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,NZC_EmissionsMatchingMTD.dateMatchingField, 'Expecting date field populated');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doLog, 'Expecting logging enabled');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsMatchBatchSize >= NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE, 'Expecting a match batch size set');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize >= NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE, 'Expecting a recalc batch size set');
        Assert.isTrue(NZC_EmissionsMatchingMTD.allowCustomTagMatching, 'expected custom tag matching');
        Assert.isTrue(NZC_EmissionsMatchingMTD.allowAdvancedMatching, 'expected Advanced matching');
    }

    @IsTest
    static void testSettingsFetch() {
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert, 'Expecting insert to be true');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate, 'Expecting update to be true');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,NZC_EmissionsMatchingMTD.dateMatchingField, 'Expecting date field populated');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doLog, 'Expecting logging enabled');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsMatchBatchSize > NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE, 'Expecting a match batch size set');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize > NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE, 'Expecting a recalc batch size set');
        Assert.isNotNull(NZC_EmissionsMatchingMTD.matchingConfig, 'no setting created');
        Assert.isTrue(NZC_EmissionsMatchingMTD.allowCustomTagMatching, 'expected custom tag matching');
        Assert.isTrue(NZC_EmissionsMatchingMTD.allowTDrecords, 'expected TD record creation');
    }

    @IsTest
    static void testSettingsDefaults() {
        Assert.isFalse(NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert, 'Expecting default false');
        Assert.isFalse(NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate, 'Expecting default false');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,NZC_EmissionsMatchingMTD.dateMatchingField, 'Expecting date field populated to default');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doLog, 'Expecting logging enabled by default');
        Assert.areEqual(NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE, NZC_EmissionsMatchingMTD.emissionsMatchBatchSize, 'Default not set correctly');
        Assert.areEqual(NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE, NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize, 'Default not set correctly');
        Assert.isFalse(NZC_EmissionsMatchingMTD.allowCustomTagMatching, 'expected custom tag matching default false');
        Assert.isFalse(NZC_EmissionsMatchingMTD.allowTDrecords, 'expected TD record default false');
    }

    @IsTest
    static void testMTDQueries() {

        Assert.areNotEqual(null, NZC_EmissionsMatchingMTD.customMatchingRules, 'expected a non null map to exist');
        Assert.areNotEqual(null, NZC_EmissionsMatchingMTD.customLookupRules, 'expected a non null map to exist');
        Assert.areNotEqual(null, NZC_EmissionsMatchingMTD.tdSplittingRules, 'expected a non null map to exist');
    }
}