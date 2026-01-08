/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsSetRecalcBatchTest {
    @IsTest
    static void testExecute() {
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        NZC_EmissionsMatchingDatafactory.setupStationary('BatchTest');

        Integer elligibleWasteSets = [
                SELECT COUNT()
                FROM WstDispoEmssnFctrSet
                WHERE Recalculate_Emissions__c = TRUE
        ];

        Test.startTest();
        Database.executeBatch(new NZC_EmissionsSetRecalcBatch());
        Test.stopTest();

        Integer elligibleWasteSetsAfter = [
                SELECT COUNT()
                FROM WstDispoEmssnFctrSet
                WHERE Recalculate_Emissions__c = TRUE
        ];

        Assert.isTrue(elligibleWasteSets > 0);
        Assert.isTrue(elligibleWasteSetsAfter == 0);
    }
}