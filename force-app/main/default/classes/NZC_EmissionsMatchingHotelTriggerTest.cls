/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingHotelTriggerTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupHotel('myVehicle');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        HotelStayEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createHotelEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        HotelStayEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createHotelEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        HotelStayEnrgyUse useWithoutTriggerAfter = [
                SELECT HotelStayEmssnFctrId, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        HotelStayEnrgyUse useWithriggerAfter = [
                SELECT HotelStayEmssnFctrId, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.HotelStayEmssnFctrId, useWithriggerAfter.HotelStayEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        Scope3EmssnSrc asset = [
                SELECT Id, HotelStayEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        HotelStayEnrgyUse hotelUse = NZC_EmissionsMatchingDatafactory.createHotelEnergyUse( 'testUpdate', asset.Id, Date.today(), Date.today());
        hotelUse.Recalculate_Emissions__c = false;
        insert hotelUse;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        hotelUse.Recalculate_Emissions__c = true;

        Test.startTest();
        update hotelUse;
        Test.stopTest();

        HotelStayEnrgyUse hotelUseTriggerAfter = [
                SELECT HotelStayEmssnFctrId, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
                WHERE Id =: hotelUse.Id
        ];

        Assert.areNotEqual(hotelUse.HotelStayEmssnFctrId, hotelUseTriggerAfter.HotelStayEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(hotelUse.Recalculate_Emissions__c, hotelUseTriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(hotelUseTriggerAfter.Recalculate_Emissions__c);
    }
}