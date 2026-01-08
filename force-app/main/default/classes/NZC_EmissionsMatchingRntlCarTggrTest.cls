/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingRntlCarTggrTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupRentalCar('myRentalCar');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        RentalCarEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createRentalCarEnergyUse( 'testInsertWithoutTrigger', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        RentalCarEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createRentalCarEnergyUse( 'testInsertWithTrigger', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        RentalCarEnrgyUse useWithoutTriggerAfter = [
                SELECT RentalCarEmssnFctrId, Recalculate_Emissions__c
                FROM RentalCarEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        RentalCarEnrgyUse useWithriggerAfter = [
                SELECT RentalCarEmssnFctrId, Recalculate_Emissions__c
                FROM RentalCarEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.RentalCarEmssnFctrId, useWithriggerAfter.RentalCarEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        Scope3EmssnSrc asset = [
                SELECT Id, RentalCarEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        RentalCarEnrgyUse rentalCarUse = NZC_EmissionsMatchingDatafactory.createRentalCarEnergyUse( 'testUpdate', asset.Id, Date.today(), Date.today());
        rentalCarUse.Recalculate_Emissions__c = false;
        insert rentalCarUse;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        rentalCarUse.Recalculate_Emissions__c = true;

        Test.startTest();
        update rentalCarUse;
        Test.stopTest();

        RentalCarEnrgyUse rentalCarUseTriggerAfter = [
                SELECT RentalCarEmssnFctrId, Recalculate_Emissions__c
                FROM RentalCarEnrgyUse
                WHERE Id =: rentalCarUse.Id
        ];

        Assert.areNotEqual(rentalCarUse.RentalCarEmssnFctrId, rentalCarUseTriggerAfter.RentalCarEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(rentalCarUse.Recalculate_Emissions__c, rentalCarUseTriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(rentalCarUseTriggerAfter.Recalculate_Emissions__c);
    }
}