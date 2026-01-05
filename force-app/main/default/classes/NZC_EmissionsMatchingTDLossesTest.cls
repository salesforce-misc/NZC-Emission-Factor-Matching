/**
 * Created by mverigin on 10/23/24.
 */

@IsTest
private class NZC_EmissionsMatchingTDLossesTest {


    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('Enginestationary');
    }

    @IsTest
    static void testCreateStationaryTDRecords() {
        // set trigger to fire
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        // create scope allocations
        NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel();
        // create rule to trigger TD fuel creation
        NZC_EmissionsMatchingTDCloning__mdt rule = NZC_EmissionsMatchingDatafactory.createTDCloningRule('StnryAssetEnrgyUse',
                'Electricity','SuplScope1Emissions');
        NZC_EmissionsMatchingMTD.tdSplittingRules = new Map<Integer, String>{
                NZC_EmissionsMatchingUtil.createHashKey(rule.ObjectName__c,rule.FuelType__c) => rule.FieldsToClone__c
        };
        // create custom lookup for TD fuel to find emissions factor
        NZC_EmissionsMatchingCustomLookups__mdt lookupRule = NZC_EmissionsMatchingDatafactory.createCustomLookupRule('StnryAssetEnrgyUse',
                NZC_EmissionsMatchingTDLosses.T_D_FUEL_TYPE,NZC_EmissionsMatchingTDLosses.T_D_LOOKUP_NAME);
        NZC_EmissionsMatchingMTD.customLookupRules = new Map<Integer, String>{
                NZC_EmissionsMatchingUtil.createHashKey(lookupRule.ObjectAppliesFor__c,lookupRule.FuelAppliesFor__c) => lookupRule.LookupToSearch__c
        };
        // give asset a TD fuel emissions factor
        OtherEmssnFctrSet tdFuelSet = NZC_EmissionsMatchingDatafactory.createOtherEmissionSet('TD fuel set', null, null);
        insert tdFuelSet;
        OtherEmssnFctrSetItem setItem = NZC_EmissionsMatchingDatafactory.createOtherEmissionsItem(tdFuelSet.Id);
        setItem.FuelType = NZC_EmissionsMatchingTDLosses.T_D_FUEL_TYPE;
        insert setItem;

        SObject existingAsset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];
        existingAsset.put(NZC_EmissionsMatchingTDLosses.T_D_LOOKUP_NAME, tdFuelSet.Id);
        update existingAsset;

        Integer eurCount = [
                SELECT COUNT()
                FROM StnryAssetEnrgyUse
        ];

        StnryAssetEnrgyUse energyUse = NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'TD fuel test', existingAsset.Id, 'Electricity', 'kWh', Date.today(), Date.today().addMonths(1));
        energyUse.SuplScope1Emissions = 50;

        Test.startTest();
        insert energyUse;
        Test.stopTest();
        System.debug(JSON.serializePretty(NZC_EmissionsMatchingMTD.customLookupRules));

        Integer eurCountAfter = [
                SELECT COUNT()
                FROM StnryAssetEnrgyUse
        ];

        StnryAssetEnrgyUse TDFuelRecord = [
                SELECT Id, FuelType, FuelConsumption, FuelConsumptionUnit,
                        StartDate, EndDate, SuplScope1Emissions, StnryAssetEnvrSrcId
                FROM StnryAssetEnrgyUse
                WHERE TDLossParent__c =: energyUse.Id
        ];

        Assert.areEqual(eurCount + 2, eurCountAfter, 'expected to create elec record and TD record');
        Assert.areEqual(energyUse.StartDate, TDFuelRecord.StartDate, 'did not clone fields correctly');
        Assert.areEqual(energyUse.EndDate, TDFuelRecord.EndDate, 'did not clone fields correctly');
        Assert.areEqual(energyUse.FuelConsumption, TDFuelRecord.FuelConsumption, 'did not clone fields correctly');
        Assert.areEqual(NZC_EmissionsMatchingTDLosses.T_D_FUEL_TYPE, TDFuelRecord.FuelType, 'did not clone fields correctly');
        Assert.areEqual(energyUse.FuelConsumptionUnit, TDFuelRecord.FuelConsumptionUnit, 'did not clone fields correctly');
        Assert.areEqual(energyUse.StnryAssetEnvrSrcId, TDFuelRecord.StnryAssetEnvrSrcId, 'did not clone fields correctly');
        Assert.areEqual(energyUse.SuplScope1Emissions, TDFuelRecord.SuplScope1Emissions, 'did not clone extra rule fields correctly');
    }

    @IsTest
    static void testCreateScopeAllocations() {
        Integer scopeAllocationCount = [
                SELECT COUNT()
                FROM CrbnEmssnScopeAlloc
        ];

        Assert.areEqual(0, scopeAllocationCount, 'expected no allocation at start');

        Test.startTest();
        NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel();
        Test.stopTest();

        Integer scopeAllocationCountAfter = [
                SELECT COUNT()
                FROM CrbnEmssnScopeAlloc
        ];

        Assert.areNotEqual(0, scopeAllocationCountAfter, 'expected Allocations created');
    }

    @IsTest
    static void testCreateAllocationForAssetsWithAllocationAlready() {
        CrbnEmssnScopeAlloc existingAllocation = new CrbnEmssnScopeAlloc(Name = 'existingAllocation');
        insert existingAllocation;

        StnryAssetEnvrSrc existingAsset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];

        existingAsset.CrbnEmssnScopeAllocId = existingAllocation.Id;
        update existingAsset;

        Integer scopeAllocationCount = [
                SELECT COUNT()
                FROM CrbnEmssnScopeAlloc
        ];

        Assert.areEqual(1, scopeAllocationCount, 'expected single allocation at start');

        Test.startTest();
        NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel();
        Test.stopTest();

        Integer scopeAllocationCountAfter = [
                SELECT COUNT()
                FROM CrbnEmssnScopeAlloc
        ];

        StnryAssetEnvrSrc existingAssetAfter = [
                SELECT Id, CrbnEmssnScopeAllocId
                FROM StnryAssetEnvrSrc
                WHERE Id =: existingAsset.Id
        ];

        Assert.areEqual(scopeAllocationCount + 1, scopeAllocationCountAfter, 'expected to create allocation');
        Assert.areEqual(existingAllocation.Id, existingAssetAfter.CrbnEmssnScopeAllocId, 'expected to not overwrite existing allocations');
    }
}