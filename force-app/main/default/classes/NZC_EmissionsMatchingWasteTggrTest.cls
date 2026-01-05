/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingWasteTggrTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('myStationary');
    }

    @IsTest
    static void testInsert() {
        StnryAssetEnvrSrc asset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];
        GeneratedWaste useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createWasteUse( 'testInsert', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        GeneratedWaste useWithTrigger = NZC_EmissionsMatchingDatafactory.createWasteUse( 'testInsert', asset.Id, Date.today(), Date.today());

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        GeneratedWaste useWithoutTriggerAfter = [
                SELECT Id, WstDispoEmssnFctrId, Recalculate_Emissions__c
                FROM GeneratedWaste
                WHERE Id =: useWithoutTrigger.Id
        ];

        GeneratedWaste useWithriggerAfter = [
                SELECT Id, WstDispoEmssnFctrId, Recalculate_Emissions__c
                FROM GeneratedWaste
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.WstDispoEmssnFctrId, useWithriggerAfter.WstDispoEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        GeneratedWaste usePreUpdate = [
                SELECT Id, WstDispoEmssnFctrId, Recalculate_Emissions__c
                FROM GeneratedWaste
                LIMIT 1
        ];

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        update usePreUpdate;
        Test.stopTest();

        GeneratedWaste usePostUpdate = [
                SELECT Id, WstDispoEmssnFctrId, Recalculate_Emissions__c
                FROM GeneratedWaste
                WHERE Id =: usePreUpdate.Id
        ];

        Assert.areNotEqual(usePreUpdate.WstDispoEmssnFctrId, usePostUpdate.WstDispoEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(usePreUpdate.Recalculate_Emissions__c, usePostUpdate.Recalculate_Emissions__c);
        Assert.isFalse(usePostUpdate.Recalculate_Emissions__c);
    }
}