/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingProcurementTest {

    private static Scope3PcmtSummary summary;
    private static PcmtEmssnFctrSetItem oldFactor;
    private static PcmtEmssnFctrSetItem newFactor;

    @IsTest
    static void buildKeyIsNullWhenAnyPartIsBlank() {
        Scope3PcmtItem item = new Scope3PcmtItem(Name = ' Acme ', SpendingCategory1 = null);

        Assert.isNull(NZC_EmissionsMatchingProcurementEngine.buildKey(item, new List<String>{'Name', 'SpendingCategory1'}));
        Assert.areEqual('ACME', NZC_EmissionsMatchingProcurementEngine.buildKey(item, new List<String>{'Name'}));
    }

    @IsTest
    static void splitFieldsTrimsAndSkipsBlanks() {
        Assert.areEqual(new List<String>{'Name', 'SpendingCategory1'},
                NZC_EmissionsMatchingProcurementEngine.splitFields(' Name , ,SpendingCategory1'));
        Assert.isTrue(NZC_EmissionsMatchingProcurementEngine.splitFields(null).isEmpty());
    }

    @IsTest
    static void pickClosestUsesLatestYearNotAfterItemYear() {
        List<SObject> candidates = new List<SObject>{
                setItemWithYear('A2020', '2020'), setItemWithYear('A2023', '2023'), setItemWithYear('UNDATED', null)
        };

        Assert.areEqual('A2020', (String) NZC_EmissionsMatchingProcurementEngine.pickClosest(candidates, 2022).get('Name'));
        Assert.areEqual('A2023', (String) NZC_EmissionsMatchingProcurementEngine.pickClosest(candidates, null).get('Name'));
        Assert.areEqual('UNDATED', (String) NZC_EmissionsMatchingProcurementEngine.pickClosest(candidates, 1999).get('Name'));
        Assert.isNull(NZC_EmissionsMatchingProcurementEngine.pickClosest(null, 2022));
    }

    @IsTest
    static void backfillsFactorUsingAllRuleFieldsAndDate() {
        setupData();
        enableRule('Name,SpendingCategory1', 'Name,EconomicSector');

        Scope3PcmtItem matching = createItem('acme', 'Steel', Date.newInstance(2022, 5, 1));
        Scope3PcmtItem otherCategory = createItem('acme', 'Paper', Date.newInstance(2022, 5, 1));
        Scope3PcmtItem recent = createItem('acme', 'Steel', Date.newInstance(2024, 1, 1));
        Scope3PcmtItem alreadySet = createItem('acme', 'Steel', Date.newInstance(2022, 5, 1));
        alreadySet.PcmtEmssnFctrSetItemId = newFactor.Id;

        NZC_EmissionsMatchingProcurementEngine.matchItems(new List<SObject>{matching, otherCategory, recent, alreadySet});

        Assert.areEqual(oldFactor.Id, matching.PcmtEmssnFctrSetItemId);
        Assert.isNull(otherCategory.PcmtEmssnFctrSetItemId);
        Assert.areEqual(newFactor.Id, recent.PcmtEmssnFctrSetItemId);
        Assert.areEqual(newFactor.Id, alreadySet.PcmtEmssnFctrSetItemId);
    }

    @IsTest
    static void doesNothingWhenCustomMatchingIsOff() {
        setupData();
        enableRule('Name', 'Name');
        NZC_EmissionsMatchingMTD.matchingConfig = new NZC_EmissionsMatchingConfig__c(allowCustomTagMatching__c = false);

        Scope3PcmtItem item = createItem('acme', 'Steel', Date.newInstance(2022, 5, 1));
        NZC_EmissionsMatchingProcurementEngine.matchItems(new List<SObject>{item});

        Assert.isNull(item.PcmtEmssnFctrSetItemId);
    }

    @IsTest
    static void ignoresRuleWithMismatchedFieldCounts() {
        setupData();
        enableRule('Name,SpendingCategory1', 'Name');

        Scope3PcmtItem item = createItem('acme', 'Steel', Date.newInstance(2022, 5, 1));
        NZC_EmissionsMatchingProcurementEngine.matchItems(new List<SObject>{item});

        Assert.isNull(item.PcmtEmssnFctrSetItemId);
    }

    @IsTest
    static void batchBackfillsItemsWithoutFactor() {
        setupData();
        enableRule('Name,SpendingCategory1', 'Name,EconomicSector');
        List<Scope3PcmtItem> items = new List<Scope3PcmtItem>();
        for (Integer i = 0; i < 150; i++) {
            items.add(createItem('acme', 'Steel', Date.newInstance(2022, 5, 1)));
        }
        insert items;

        Test.startTest();
        Database.executeBatch(new NZC_EmissionsMatchingProcurementBatch(), 200);
        Test.stopTest();

        Assert.areEqual(150, [SELECT COUNT() FROM Scope3PcmtItem WHERE PcmtEmssnFctrSetItemId = :oldFactor.Id]);
    }

    private static SObject setItemWithYear(String name, String year) {
        Map<String, Object> parent = new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => 'PcmtEmssnFctrSet'},
                'EmissionFactorUpdateYear' => year
        };
        return (SObject) JSON.deserialize(JSON.serialize(new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => 'PcmtEmssnFctrSetItem'},
                'Name' => name,
                'PcmtEmssnFctrSet' => parent
        }), SObject.class);
    }

    private static void setupData() {
        Scope3CrbnFtprnt footprint = new Scope3CrbnFtprnt(Name = 'FP', FootprintStage = 'Data Collection');
        insert footprint;
        Scope3EmssnSrc source = new Scope3EmssnSrc(Name = 'Source');
        insert source;
        summary = new Scope3PcmtSummary(Name = 'Summary', Scope3CrbnFtprntId = footprint.Id,
                Scope3EmssnSrcId = source.Id, CalendarYear = '2022');
        insert summary;

        PcmtEmssnFctrSet oldSet = new PcmtEmssnFctrSet(Name = 'Old', EmissionFactorUpdateYear = '2020');
        PcmtEmssnFctrSet newSet = new PcmtEmssnFctrSet(Name = 'New', EmissionFactorUpdateYear = '2023');
        insert new List<PcmtEmssnFctrSet>{oldSet, newSet};

        oldFactor = new PcmtEmssnFctrSetItem(Name = 'Acme', EconomicSector = 'Steel',
                PcmtEmssnFctrSetId = oldSet.Id, TotScpe3EmssnPerMillionSpent = 1);
        newFactor = new PcmtEmssnFctrSetItem(Name = 'Acme', EconomicSector = 'Steel',
                PcmtEmssnFctrSetId = newSet.Id, TotScpe3EmssnPerMillionSpent = 2);
        insert new List<PcmtEmssnFctrSetItem>{oldFactor, newFactor};
    }

    private static Scope3PcmtItem createItem(String name, String category, Date spentDate) {
        return new Scope3PcmtItem(Name = name, SpendingCategory1 = category, SpentAmount = 100,
                SpentDate = spentDate, ProcurementSummaryId = summary.Id);
    }

    private static void enableRule(String itemFields, String setItemFields) {
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        NZC_EmissionsMatchingMTD.customMatchingRules = new Map<String, NZC_EmissionsMatchingCustomMatch__mdt>{
                NZC_EmissionsMatchingUtil.createHashKey(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, null) =>
                        new NZC_EmissionsMatchingCustomMatch__mdt(
                                ObjectAppliesTo__c = NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM,
                                EnergyUseFieldToMatch__c = itemFields,
                                EmissionsSetFieldToMatch__c = setItemFields)
        };
    }
}
