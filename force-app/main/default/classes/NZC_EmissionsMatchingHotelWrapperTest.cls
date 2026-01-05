/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingHotelWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupHotel('myVehicle');
    }

    @IsTest
    static void testBaseConstructor() {
        HotelStayEnrgyUse useRecord = [
                SELECT Id, HotelStayEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM HotelStayEnrgyUse
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingHotelWrapper wrapper = new NZC_EmissionsMatchingHotelWrapper(useRecord);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(useRecord.Scope3EmssnSrcId, wrapper.assetId);
        Assert.areEqual(useRecord.Id, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wrapper.dateToMatch);
        Assert.areEqual(useRecord.HotelStayEmssnFctrId, wrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        String testId = 'generatedId';

        Scope3EmssnSrc hotel = [
                SELECT Id, HotelStayEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingHotelWrapper wrapper = new NZC_EmissionsMatchingHotelWrapper(new HotelStayEnrgyUse(
                Scope3EmssnSrcId = hotel.Id,
                StartDate = Date.today(),
                HotelStayEmssnFctrId = hotel.HotelStayEmssnFctrId
        ),testId);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(hotel.Id, wrapper.assetId);
        Assert.areEqual(testId, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(Date.today(), wrapper.dateToMatch);
        Assert.areEqual(hotel.HotelStayEmssnFctrId, wrapper.masterEmissionsSetId);
    }


}