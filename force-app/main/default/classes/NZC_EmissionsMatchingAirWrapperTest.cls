/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingAirWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupAirTravel('myAirTravel');
    }

    @IsTest
    static void testBaseConstructor() {
        AirTravelEnrgyUse useRecord = [
                SELECT Id, AirTravelEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM AirTravelEnrgyUse
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingAirTravelWrapper wrapper = new NZC_EmissionsMatchingAirTravelWrapper(useRecord);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(useRecord.Scope3EmssnSrcId, wrapper.assetId);
        Assert.areEqual(useRecord.Id, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_AIR_TRAVEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wrapper.dateToMatch);
        Assert.areEqual(useRecord.AirTravelEmssnFctrId, wrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        String testId = 'generatedId';

        Scope3EmssnSrc airTravel = [
                SELECT Id, AirTravelEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingAirTravelWrapper wrapper = new NZC_EmissionsMatchingAirTravelWrapper(new AirTravelEnrgyUse(
                Scope3EmssnSrcId = airTravel.Id,
                StartDate = Date.today(),
                AirTravelEmssnFctrId = airTravel.AirTravelEmssnFctrId
        ),testId);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(airTravel.Id, wrapper.assetId);
        Assert.areEqual(testId, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_AIR_TRAVEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(Date.today(), wrapper.dateToMatch);
        Assert.areEqual(airTravel.AirTravelEmssnFctrId, wrapper.masterEmissionsSetId);
    }


}