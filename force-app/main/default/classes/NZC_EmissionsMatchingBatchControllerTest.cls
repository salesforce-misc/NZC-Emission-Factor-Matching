/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


@IsTest
private class NZC_EmissionsMatchingBatchControllerTest {

    @IsTest
    static void testClientAttemptBatchStartMatchBatch() {

        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientAttemptMatchBatchStart();

        System.assertEquals(true, results.isBatchedStarted, 'expected batch to be started');
        System.assertNotEquals(NZC_EmissionsMatchingConstants.STATUS_BATCH_COMPLETED, results.batchStatus, 'expected Non completed batch status');
    }

    @IsTest
    static void testClientPollingStatusMatchBatch() {
        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientPollingMatchStatus();
        System.assert(!results.isBatchedStarted, 'expected no batch running');
    }

    @IsTest
    static void testClientAttemptBatchStartRecalcBatch() {

        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientAttemptEmissionsSetRecalcBatchStart();

        System.assertEquals(true, results.isBatchedStarted, 'expected batch to be started');
        System.assertNotEquals(NZC_EmissionsMatchingConstants.STATUS_BATCH_COMPLETED, results.batchStatus, 'expected Non completed batch status');
    }

    @IsTest
    static void testClientPollingStatusRecalcBatch() {
        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientPollingEmissionRecalcStatus();
        System.assert(!results.isBatchedStarted, 'expected no batch running');
    }
}