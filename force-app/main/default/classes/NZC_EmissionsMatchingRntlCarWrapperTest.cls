/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingRntlCarWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupRentalCar('myRentalCar');
    }

    @IsTest
    static void testBaseConstructor() {
        RentalCarEnrgyUse useRecord = [
                SELECT Id, RentalCarEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM RentalCarEnrgyUse
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingRentalCarWrapper wrapper = new NZC_EmissionsMatchingRentalCarWrapper(useRecord);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(useRecord.Scope3EmssnSrcId, wrapper.assetId);
        Assert.areEqual(useRecord.Id, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_RENTAL_CAR_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wrapper.dateToMatch);
        Assert.areEqual(useRecord.RentalCarEmssnFctrId, wrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        String testId = 'generatedId';

        Scope3EmssnSrc rentalCar = [
                SELECT Id, RentalCarEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingRentalCarWrapper wrapper = new NZC_EmissionsMatchingRentalCarWrapper(new RentalCarEnrgyUse(
                Scope3EmssnSrcId = rentalCar.Id,
                StartDate = Date.today(),
                RentalCarEmssnFctrId = rentalCar.RentalCarEmssnFctrId
        ),testId);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(rentalCar.Id, wrapper.assetId);
        Assert.areEqual(testId, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_RENTAL_CAR_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(Date.today(), wrapper.dateToMatch);
        Assert.areEqual(rentalCar.RentalCarEmssnFctrId, wrapper.masterEmissionsSetId);
    }


}