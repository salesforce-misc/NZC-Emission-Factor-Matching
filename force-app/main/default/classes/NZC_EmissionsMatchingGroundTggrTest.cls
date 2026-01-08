/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingGroundTggrTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupGroundTravel('myGroundTravel');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        GroundTravelEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createGroundTravelEnergyUse( 'testInsertWithoutTrigger', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        GroundTravelEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createGroundTravelEnergyUse( 'testInsertWithTrigger', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        GroundTravelEnrgyUse useWithoutTriggerAfter = [
                SELECT GroundTravelEmssnFctrId, Recalculate_Emissions__c
                FROM GroundTravelEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        GroundTravelEnrgyUse useWithriggerAfter = [
                SELECT GroundTravelEmssnFctrId, Recalculate_Emissions__c
                FROM GroundTravelEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.GroundTravelEmssnFctrId, useWithriggerAfter.GroundTravelEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        Scope3EmssnSrc asset = [
                SELECT Id, GroundTravelEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        GroundTravelEnrgyUse groundTravelUse = NZC_EmissionsMatchingDatafactory.createGroundTravelEnergyUse( 'testUpdate', asset.Id, Date.today(), Date.today());
        groundTravelUse.Recalculate_Emissions__c = false;
        insert groundTravelUse;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        groundTravelUse.Recalculate_Emissions__c = true;

        Test.startTest();
        update groundTravelUse;
        Test.stopTest();

        GroundTravelEnrgyUse groundTravelUseTriggerAfter = [
                SELECT GroundTravelEmssnFctrId, Recalculate_Emissions__c
                FROM GroundTravelEnrgyUse
                WHERE Id =: groundTravelUse.Id
        ];

        Assert.areNotEqual(groundTravelUse.GroundTravelEmssnFctrId, groundTravelUseTriggerAfter.GroundTravelEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(groundTravelUse.Recalculate_Emissions__c, groundTravelUseTriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(groundTravelUseTriggerAfter.Recalculate_Emissions__c);
    }
}