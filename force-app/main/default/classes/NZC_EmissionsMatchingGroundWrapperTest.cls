/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingGroundWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupGroundTravel('myGroundTravel');
    }

    @IsTest
    static void testBaseConstructor() {
        GroundTravelEnrgyUse useRecord = [
                SELECT Id, GroundTravelEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM GroundTravelEnrgyUse
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingGroundTravelWrapper wrapper = new NZC_EmissionsMatchingGroundTravelWrapper(useRecord);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(useRecord.Scope3EmssnSrcId, wrapper.assetId);
        Assert.areEqual(useRecord.Id, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_GROUND_TRAVEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wrapper.dateToMatch);
        Assert.areEqual(useRecord.GroundTravelEmssnFctrId, wrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        String testId = 'generatedId';

        Scope3EmssnSrc groundTravel = [
                SELECT Id, GroundTravelEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingGroundTravelWrapper wrapper = new NZC_EmissionsMatchingGroundTravelWrapper(new GroundTravelEnrgyUse(
                Scope3EmssnSrcId = groundTravel.Id,
                StartDate = Date.today(),
                GroundTravelEmssnFctrId = groundTravel.GroundTravelEmssnFctrId
        ),testId);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(groundTravel.Id, wrapper.assetId);
        Assert.areEqual(testId, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_GROUND_TRAVEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(Date.today(), wrapper.dateToMatch);
        Assert.areEqual(groundTravel.GroundTravelEmssnFctrId, wrapper.masterEmissionsSetId);
    }


}