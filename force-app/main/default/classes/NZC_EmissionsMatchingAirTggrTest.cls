/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingAirTggrTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupAirTravel('myAirTravel');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        AirTravelEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createAirTravelEnergyUse( 'testInsertWithoutTrigger', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        AirTravelEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createAirTravelEnergyUse( 'testInsertWithTrigger', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        AirTravelEnrgyUse useWithoutTriggerAfter = [
                SELECT AirTravelEmssnFctrId, Recalculate_Emissions__c
                FROM AirTravelEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        AirTravelEnrgyUse useWithriggerAfter = [
                SELECT AirTravelEmssnFctrId, Recalculate_Emissions__c
                FROM AirTravelEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.AirTravelEmssnFctrId, useWithriggerAfter.AirTravelEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        Scope3EmssnSrc asset = [
                SELECT Id, AirTravelEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        AirTravelEnrgyUse airTravelUse = NZC_EmissionsMatchingDatafactory.createAirTravelEnergyUse( 'testUpdate', asset.Id, Date.today(), Date.today());
        airTravelUse.Recalculate_Emissions__c = false;
        insert airTravelUse;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        airTravelUse.Recalculate_Emissions__c = true;

        Test.startTest();
        update airTravelUse;
        Test.stopTest();

        AirTravelEnrgyUse airTravelUseTriggerAfter = [
                SELECT AirTravelEmssnFctrId, Recalculate_Emissions__c
                FROM AirTravelEnrgyUse
                WHERE Id =: airTravelUse.Id
        ];

        Assert.areNotEqual(airTravelUse.AirTravelEmssnFctrId, airTravelUseTriggerAfter.AirTravelEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(airTravelUse.Recalculate_Emissions__c, airTravelUseTriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(airTravelUseTriggerAfter.Recalculate_Emissions__c);
    }
}