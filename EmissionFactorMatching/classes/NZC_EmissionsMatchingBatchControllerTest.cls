/**
 * Created by mverigin on 6/26/23.
 */

@IsTest
private class NZC_EmissionsMatchingBatchControllerTest {

    @IsTest
    static void testClientAttemptBatchStart_matchBatch() {

        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientAttemptMatchBatchStart();

        System.assertEquals(true, results.isBatchedStarted, 'expected batch to be started');
        System.assertNotEquals(NZC_EmissionsMatchingConstants.STATUS_BATCH_COMPLETED, results.batchStatus, 'expected Non completed batch status');
    }

    @IsTest
    static void testcClientPollingStatus_matchBatch() {
        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientPollingMatchStatus();
        System.assert(!results.isBatchedStarted, 'expected no batch running');
    }

    @IsTest
    static void testClientAttemptBatchStart_recalcBatch() {

        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientAttemptEmissionsSetRecalcBatchStart();

        System.assertEquals(true, results.isBatchedStarted, 'expected batch to be started');
        System.assertNotEquals(NZC_EmissionsMatchingConstants.STATUS_BATCH_COMPLETED, results.batchStatus, 'expected Non completed batch status');
    }

    @IsTest
    static void testcClientPollingStatus_recalcBatch() {
        NZC_EmissionsMatchingBatchController.currentBatchStatus results = NZC_EmissionsMatchingBatchController.clientPollingEmissionRecalcStatus();
        System.assert(!results.isBatchedStarted, 'expected no batch running');
    }
}