/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingUtilTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('stationaryStuff');
        NZC_EmissionsMatchingDatafactory.setupVehicle('vehicleStuff');
    }

    @IsTest
    static void testCachedGlobalDescribe() {
        Assert.isNotNull(NZC_EmissionsMatchingUtil.globalDescribe, 'no cached global describe exists');
    }

    @IsTest
    static void testIsFormulaField() {
        //Assert.isTrue(NZC_EmissionsMatchingUtil.isFormulaField('VehicleAssetEmssnSrc',''), 'expected formula field');
        Assert.isFalse(NZC_EmissionsMatchingUtil.isFormulaField('VehicleAssetEmssnSrc','Name'), 'expected formula field');
    }

    @IsTest
    static void hashRecordFields() {
        StnryAssetEnvrSrc asset = new StnryAssetEnvrSrc(
                Name = 'testName',
                PostalCode = 'Test123',
                Country = 'CA'
        );

        String result = NZC_EmissionsMatchingUtil.hashRecordFields(asset, new List<String>{
                'Name', 'PostalCode', 'Country', 'Description'
        });

        Assert.isNotNull(result, 'expected a non null hash');
        Assert.areNotEqual(NZC_EmissionsMatchingUtil.DEFAULT_HASH, result, 'expected a unique hash');
    }

    @IsTest
    static void testHashMatrixRecord() {
        NZC_EmissionsMatchingMatrix__c testMatrixRecord = new NZC_EmissionsMatchingMatrix__c(
                PrimaryHashkeys__c = '1,2,3,4, 5, 6',
                AliasHashkeys__c = '4,3,2,1'
        );

        String testHash = 'ABC'.hashCode() + '';

        NZC_EmissionsMatchingMatrix__c testMatrixSingle = new NZC_EmissionsMatchingMatrix__c(
                PrimaryHashkeys__c = ' abc',
                AliasHashkeys__c = 'cba'
        );

        NZC_EmissionsMatchingUtil.handleMatrixRecordHashing(new List<NZC_EmissionsMatchingMatrix__c>{
                testMatrixRecord, testMatrixSingle
        });

        Assert.isNotNull(testMatrixRecord.PrimaryHashStorage__c, 'did not create Hash');
        Assert.isNotNull(testMatrixRecord.AliasHashStorage__c, 'did not create Hash');
        Assert.isNotNull(testMatrixSingle.PrimaryHashStorage__c, 'did not create Hash');
        Assert.isNotNull(testMatrixSingle.AliasHashStorage__c, 'did not create Hash');

        Assert.areEqual(testHash, testMatrixSingle.PrimaryHashStorage__c, 'did not strip space from hash');
    }

    @IsTest
    static void testgetDateForWrapper() {
        VehicleAssetEnrgyUse testRecord = new VehicleAssetEnrgyUse(
                StartDate = Date.today(),
                EndDate = Date.today().addDays(2)
        );

        NZC_EmissionsMatchingMTD.dateMatchingField = NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE;
        Date result1 = NZC_EmissionsMatchingUtil.getDateForWrapper(testRecord);
        Assert.areEqual(testRecord.StartDate, result1);

        NZC_EmissionsMatchingMTD.dateMatchingField = NZC_EmissionsMatchingConstants.FIELD_EUR_ENDDATE;
        Date result2 = NZC_EmissionsMatchingUtil.getDateForWrapper(testRecord);
        Assert.areEqual(testRecord.EndDate, result2);

        NZC_EmissionsMatchingMTD.dateMatchingField = NZC_EmissionsMatchingConstants.FIELD_EUR_MIDPOINT;
        Date result3 = NZC_EmissionsMatchingUtil.getDateForWrapper(testRecord);
        Assert.areEqual(testRecord.StartDate.addDays(1), result3);
    }

    @IsTest
    static void testCreateMatchingWrapper() {
        List<SObject> incomingEnergyList = new List<SObject>();

        StnryAssetEnvrSrc asset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];
        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'testInsert', asset.Id, 'Electricity', 'kWH', Date.today(), Date.today()));
        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createWasteUse( 'testInsert', asset.Id, Date.today(), Date.today()));
        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', vehicleAsset.Id, Date.today(), Date.today()));
        insert incomingEnergyList;

        List<NZC_EmissionsMatchingWrapper> results = NZC_EmissionsMatchingUtil.createMatchingWrapper(incomingEnergyList);
        Assert.areEqual(incomingEnergyList.size(), results.size());
    }

    @IsTest
    static void testCreateWrapperWithGeneratedIds() {
        StnryAssetEnvrSrc asset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];
        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        StnryAssetEnrgyUse stnUse = NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'testInsert', asset.Id, 'Electricity', 'kWH', Date.today(), Date.today());
        GeneratedWaste wasteuse = NZC_EmissionsMatchingDatafactory.createWasteUse( 'testInsert', asset.Id, Date.today(), Date.today());
        VehicleAssetEnrgyUse vehicleUse = NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', vehicleAsset.Id, Date.today(), Date.today());

        Map<String, SObject> generatedIdMap = new Map<String, SObject>{
                'generatedId0' =>  stnUse,
                'generatedId0' =>  wasteuse,
                'generatedId0' =>  vehicleUse
        };

        Test.startTest();
        List<NZC_EmissionsMatchingWrapper> results = NZC_EmissionsMatchingUtil.createWrapperWithGeneratedIds(generatedIdMap);
        Test.stopTest();

        // verify generatedIds ended up on wrappers
        for (NZC_EmissionsMatchingWrapper wrapper : results) {
            Assert.isTrue(generatedIdMap.containsKey(wrapper.energyUseRecordId));
        }
        Assert.isFalse(generatedIdMap.isEmpty());
    }

    @IsTest
    static void testCreateInsertMatchingIdsMap() {
        List<SObject> incomingEnergyList = new List<SObject>();

        StnryAssetEnvrSrc asset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];
        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'testInsert', asset.Id, 'Electricity', 'kWH', Date.today(), Date.today()));
        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createWasteUse( 'testInsert', asset.Id, Date.today(), Date.today()));
        incomingEnergyList.add(NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', vehicleAsset.Id, Date.today(), Date.today()));

        Map<String, SObject> result = NZC_EmissionsMatchingUtil.createInsertMatchingIdsMap(incomingEnergyList);

        Assert.areEqual(result.size(), incomingEnergyList.size());
    }

    @IsTest
    static void testScreenRecordsBasedOnFlag() {
        List<SObject> records = new List<SObject>();

        for (Integer i = 0; i < 100; i++) {
            records.add(new VehicleAssetEnrgyUse(Recalculate_Emissions__c = false));
            records.add(new VehicleAssetEnrgyUse(Recalculate_Emissions__c = true));
        }

        List<SObject> results = NZC_EmissionsMatchingUtil.screenRecordsBasedOnFlag(records, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
        Assert.areEqual(records.size()/2, results.size());
    }

    @IsTest
    static void testTriggerOnInsertRun() {
        VehicleAssetEmssnSrc asset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        VehicleAssetEnrgyUse testInsert = NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());
        String emissionsId = testInsert.OtherEmssnFctrId;

        Test.startTest();
        NZC_EmissionsMatchingUtil.triggerOnInsertRun(new List<SObject>{testInsert}, 'Recalculate_Emissions__c');
        Test.stopTest();

        Assert.areNotEqual(emissionsId, testInsert.OtherEmssnFctrId);
        Assert.isFalse(testInsert.Recalculate_Emissions__c);
    }

    @IsTest
    static void testTriggerOnUpdateRun() {
        VehicleAssetEmssnSrc asset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        VehicleAssetEnrgyUse testUpdate = NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());
        insert testUpdate;
        String emissionsId = testUpdate.OtherEmssnFctrId;

        Test.startTest();
        NZC_EmissionsMatchingUtil.triggerOnUpdateRun(new List<SObject>{testUpdate}, 'Recalculate_Emissions__c');
        Test.stopTest();

        Assert.areNotEqual(emissionsId, testUpdate.OtherEmssnFctrId);
        Assert.isFalse(testUpdate.Recalculate_Emissions__c);
    }
}