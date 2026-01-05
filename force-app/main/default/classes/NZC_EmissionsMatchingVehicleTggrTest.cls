/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingVehicleTggrTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupVehicle('myVehicle');
    }

    @IsTest
    static void testInsert() {
        VehicleAssetEmssnSrc asset = [
                SELECT Id
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        VehicleAssetEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        VehicleAssetEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createVehicleEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        VehicleAssetEnrgyUse useWithoutTriggerAfter = [
                SELECT OtherEmssnFctrId, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        VehicleAssetEnrgyUse useWithriggerAfter = [
                SELECT OtherEmssnFctrId, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.OtherEmssnFctrId, useWithriggerAfter.OtherEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        VehicleAssetEnrgyUse usePreUpdate = [
                SELECT Id, OtherEmssnFctrId, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                LIMIT 1
        ];

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        update usePreUpdate;
        Test.stopTest();

        VehicleAssetEnrgyUse usePostUpdate = [
                SELECT Id, OtherEmssnFctrId, Recalculate_Emissions__c
                FROM VehicleAssetEnrgyUse
                WHERE Id =: usePreUpdate.Id
                LIMIT 1
        ];

        Assert.areNotEqual(usePreUpdate.OtherEmssnFctrId, usePostUpdate.OtherEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(usePreUpdate.Recalculate_Emissions__c, usePostUpdate.Recalculate_Emissions__c);
        Assert.isFalse(usePostUpdate.Recalculate_Emissions__c);
    }
}