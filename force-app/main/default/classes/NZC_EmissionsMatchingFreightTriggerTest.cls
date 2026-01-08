/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingFreightTriggerTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupFreight('myFreight');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        FrgtHaulingEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createFreightEnergyUse( 'testInsertWithoutTrigger', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        FrgtHaulingEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createFreightEnergyUse( 'testInsertWithTrigger', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        FrgtHaulingEnrgyUse useWithoutTriggerAfter = [
                SELECT FrgtHaulingEmssnFctrId, Recalculate_Emissions__c
                FROM FrgtHaulingEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        FrgtHaulingEnrgyUse useWithriggerAfter = [
                SELECT FrgtHaulingEmssnFctrId, Recalculate_Emissions__c
                FROM FrgtHaulingEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.FrgtHaulingEmssnFctrId, useWithriggerAfter.FrgtHaulingEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        Scope3EmssnSrc asset = [
                SELECT Id, FrgtHaulingEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        FrgtHaulingEnrgyUse freightUse = NZC_EmissionsMatchingDatafactory.createFreightEnergyUse( 'testUpdate', asset.Id, Date.today(), Date.today());
        freightUse.Recalculate_Emissions__c = false;
        insert freightUse;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        freightUse.Recalculate_Emissions__c = true;

        Test.startTest();
        update freightUse;
        Test.stopTest();

        FrgtHaulingEnrgyUse freightUseTriggerAfter = [
                SELECT FrgtHaulingEmssnFctrId, Recalculate_Emissions__c
                FROM FrgtHaulingEnrgyUse
                WHERE Id =: freightUse.Id
        ];

        Assert.areNotEqual(freightUse.FrgtHaulingEmssnFctrId, freightUseTriggerAfter.FrgtHaulingEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(freightUse.Recalculate_Emissions__c, freightUseTriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(freightUseTriggerAfter.Recalculate_Emissions__c);
    }
}