/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingFreightWrapperTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupFreight('myFreight');
    }

    @IsTest
    static void testBaseConstructor() {
        FrgtHaulingEnrgyUse useRecord = [
                SELECT Id, FrgtHaulingEmssnFctrId, StartDate, Scope3EmssnSrcId
                FROM FrgtHaulingEnrgyUse
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingFreightWrapper wrapper = new NZC_EmissionsMatchingFreightWrapper(useRecord);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(useRecord.Scope3EmssnSrcId, wrapper.assetId);
        Assert.areEqual(useRecord.Id, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(useRecord.StartDate, wrapper.dateToMatch);
        Assert.areEqual(useRecord.FrgtHaulingEmssnFctrId, wrapper.masterEmissionsSetId);
    }

    @IsTest
    static void testGeneratedConstructor() {
        String testId = 'generatedId';

        Scope3EmssnSrc freight = [
                SELECT Id, FrgtHaulingEmssnFctrId
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        Test.startTest();
        NZC_EmissionsMatchingFreightWrapper wrapper = new NZC_EmissionsMatchingFreightWrapper(new FrgtHaulingEnrgyUse(
                Scope3EmssnSrcId = freight.Id,
                StartDate = Date.today(),
                FrgtHaulingEmssnFctrId = freight.FrgtHaulingEmssnFctrId
        ),testId);
        Test.stopTest();

        System.debug(wrapper);

        Assert.areEqual(freight.Id, wrapper.assetId);
        Assert.areEqual(testId, wrapper.energyUseRecordId);
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE, wrapper.objectName);
        Assert.areEqual(null, wrapper.fuelType);
        Assert.areEqual(Date.today(), wrapper.dateToMatch);
        Assert.areEqual(freight.FrgtHaulingEmssnFctrId, wrapper.masterEmissionsSetId);
    }


}