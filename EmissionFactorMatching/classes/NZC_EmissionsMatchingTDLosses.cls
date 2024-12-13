/**
 * Created by mverigin on 10/23/24.
 */

public with sharing class NZC_EmissionsMatchingTDLosses {
    public static final String ALLOCATION_NAME = 'Transmissions and Distribution Scope Allocation';
    public static final String RECORD_NAME = 'Transmissions and Distribution Losses';
    public static final String ALLOCATION_CATEGORY = 'SCP3FuelEnergyRelatedActv';
    public static final String T_D_FUEL_TYPE = 'custom_T_D_losses';
    public static final String T_D_LOOKUP_NAME = 'T_D_losses_emissions_set__c';

    public static void handleT_DLossRecords(List<SObject> currentEurRecords) {
        if (!NZC_EmissionsMatchingMTD.allowTDrecords) return;
        NZC_EmissionsMatchingLog.log('Creating TD loss records');
        List<SObject> clonedRecords = new List<SObject>();

        for (SObject record : screenRecords(currentEurRecords)) {
            Integer objectFuelTypeHash = NZC_EmissionsMatchingUtil.createHashKey(record.getSObjectType() + '', (String)record.get('fuelType'));
            if (NZC_EmissionsMatchingMTD.tdSplittingRules.containsKey(objectFuelTypeHash)) {
                // this record needs to be cloned
                NZC_EmissionsMatchingLog.log('creating TD record');
                SObject newRecord = record.getSObjectType().newSObject();
                newRecord.put('StartDate', record.get('StartDate'));
                newRecord.put('EndDate', record.get('EndDate'));
                newRecord.put('FuelConsumption', record.get('FuelConsumption'));
                newRecord.put('FuelConsumptionUnit', record.get('FuelConsumptionUnit'));
                newRecord.put('Name', record.get('Name') + ' ' + RECORD_NAME);
                newRecord.put('StnryAssetEnvrSrcId', record.get('StnryAssetEnvrSrcId'));
                newRecord.put('TDLossParent__c', record.get('Id'));
                newRecord.put('Recalculate_Emissions__c', true);
                newRecord.put('FuelType', T_D_FUEL_TYPE);

                if (String.isNotBlank(NZC_EmissionsMatchingMTD.tdSplittingRules.get(objectFuelTypeHash))) {
                    NZC_EmissionsMatchingLog.log('Stamping extra fields');
                    for (String field : NZC_EmissionsMatchingMTD.tdSplittingRules.get(objectFuelTypeHash).split(',')) {
                        newRecord.put(field, record.get(field));
                    }
                }
                clonedRecords.add(newRecord);
            }
        }

        if (clonedRecords.size() > 0) {
            try {
                NZC_EmissionsMatchingLog.log('Inserting TD records');
                insert clonedRecords;
            } catch (Exception e ) {
                NZC_EmissionsMatchingLog.log('Error inserting TD records ' + e.getMessage());
            }
        }
        NZC_EmissionsMatchingLog.log('Creating TD loss records complete');
    }

    private static List<SObject> screenRecords(List<SObject> currentEurRecords) {
        NZC_EmissionsMatchingLog.log('Screening records');
        Set<String> recordIds = new Set<String>();
        Set<String> assetIds = new Set<String>();
        List<SObject> passingRecord = new List<SObject>();

        for (SObject record : currentEurRecords) {
            recordIds.add((String) record.get('Id'));
            assetIds.add((String) record.get('StnryAssetEnvrSrcId'));
        }

        Set<String> seenIds = new Set<String>();
        for (StnryAssetEnrgyUse eur : [
                SELECT Id, TDLossParent__c
                FROM StnryAssetEnrgyUse
                WHERE TDLossParent__c IN :recordIds
        ]) {
            seenIds.add(eur.TDLossParent__c);
        }

        // get scope allocations to screen out assets that don't need TD losses
        Set<String> allocationsWithTDLosses = new Set<String>();
        for (CrbnEmssnScopeAllocVal scopeAllocation : [
                SELECT Id, CrbnEmssnScopeAllocId
                FROM CrbnEmssnScopeAllocVal
                WHERE FuelType =: T_D_FUEL_TYPE
        ]) {
            allocationsWithTDLosses.add(scopeAllocation.CrbnEmssnScopeAllocId);
        }

        Set<String> assetsWithTDAllocations = new Set<String>();
        for (StnryAssetEnvrSrc asset : [
                SELECT Id
                FROM StnryAssetEnvrSrc
                WHERE Id IN: assetIds
                AND CrbnEmssnScopeAllocId IN: allocationsWithTDLosses
        ]) {
            assetsWithTDAllocations.add(asset.Id);
        }

        for (SObject record : currentEurRecords) {
            if (!seenIds.contains((String) record.get('Id')) && assetsWithTDAllocations.contains((String) record.get('StnryAssetEnvrSrcId'))) {
                passingRecord.add(record);
            }
        }

        NZC_EmissionsMatchingLog.log('records passed ' + passingRecord.size());
        return passingRecord;
    }

    public static void createAllocationsForT_DFuel() {
        List<CrbnEmssnScopeAlloc> existingAllocation = [
                SELECT Id
                FROM CrbnEmssnScopeAlloc
                WHERE Name =: ALLOCATION_NAME
                LIMIT 1
        ];

        if (existingAllocation.size() < 1) {
            // create allocation
            CrbnEmssnScopeAlloc newAllocation = new CrbnEmssnScopeAlloc(Name = ALLOCATION_NAME);
            insert newAllocation;
            existingAllocation.add(newAllocation);
        }

        List<CrbnEmssnScopeAllocVal> fuelAllocations = [
                SELECT Id
                FROM CrbnEmssnScopeAllocVal
                WHERE CrbnEmssnScopeAllocId =: existingAllocation[0].Id
                AND FuelTypeAllocation =: ALLOCATION_CATEGORY
                AND FuelType =: T_D_FUEL_TYPE
        ];

        if (fuelAllocations.size() < 1) {
            // create allocation value
            CrbnEmssnScopeAllocVal newAllocationValue = new CrbnEmssnScopeAllocVal(
                    CrbnEmssnScopeAllocId = existingAllocation[0].Id,
                    FuelTypeAllocation = ALLOCATION_CATEGORY,
                    FuelType = T_D_FUEL_TYPE
            );
            insert newAllocationValue;
        }


        List<StnryAssetEnvrSrc> orgAssets = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                WHERE CrbnEmssnScopeAllocId = NULL
                LIMIT 5000
        ];

        for (StnryAssetEnvrSrc asset : orgAssets) {
            asset.CrbnEmssnScopeAllocId = existingAllocation[0].Id;
        }

        update orgAssets;
    }
}