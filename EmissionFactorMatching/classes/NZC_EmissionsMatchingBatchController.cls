/**
 * Created by mverigin on 6/22/23.
 */

public with sharing class NZC_EmissionsMatchingBatchController {

    public class currentBatchStatus {
        public currentBatchStatus(Integer processedCount, Integer totalToProcess, Boolean batchStarted, String status) {
            batchesProcessed = processedCount;
            totalBatches = totalToProcess;
            isBatchedStarted = batchStarted;
            batchStatus = status;
        }

        @AuraEnabled
        public Integer batchesProcessed;
        @AuraEnabled
        public Integer totalBatches;
        @AuraEnabled
        public Boolean isBatchedStarted;
        @AuraEnabled
        public String batchStatus;
    }

    @AuraEnabled
    public static currentBatchStatus clientAttemptMatchBatchStart() {
        currentBatchStatus batchStatus = canStartBatch(NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_NAME);
        NZC_EmissionsMatchingLog.log('can batch start', batchStatus);
        if (!batchStatus.isBatchedStarted) {
            startMatchBatchProcessing();
            batchStatus = new currentBatchStatus(0,1,true, NZC_EmissionsMatchingConstants.STATUS_BATCH_HOLDING);
        }
        return batchStatus;
    }

    @AuraEnabled
    public static currentBatchStatus clientAttemptEmissionsSetRecalcBatchStart() {
        currentBatchStatus batchStatus = canStartBatch(NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_NAME);
        NZC_EmissionsMatchingLog.log('can batch start', batchStatus);
        if (!batchStatus.isBatchedStarted) {
            startEmissionRecalcBatchProcessing();
            batchStatus = new currentBatchStatus(0,1,true, NZC_EmissionsMatchingConstants.STATUS_BATCH_HOLDING);
        }
        return batchStatus;
    }

    @AuraEnabled
    public static currentBatchStatus clientPollingMatchStatus() {
        return canStartBatch(NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_NAME);
    }

    @AuraEnabled
    public static currentBatchStatus clientPollingEmissionRecalcStatus() {
        return canStartBatch(NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_NAME);
    }

    private static currentBatchStatus canStartBatch(String jobName) {
        currentBatchStatus currentStatus = new currentBatchStatus(0,1,false, null);
        // if no records prevent run
        List<AsyncApexJob> jobInfo = [
                SELECT ApexClass.Name, JobType, Status, JobItemsProcessed, TotalJobItems
                FROM AsyncApexJob
                WHERE ApexClass.Name =: jobName
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (jobInfo != null && jobInfo.size() > 0) {
            
            Boolean isBatchRunning = jobInfo.get(0).Status != NZC_EmissionsMatchingConstants.STATUS_BATCH_COMPLETED;
            currentStatus = new currentBatchStatus(jobInfo.get(0).JobItemsProcessed, jobInfo.get(0).TotalJobItems, isBatchRunning, jobInfo.get(0).Status);
        }

        return currentStatus;
    }

    private static void startMatchBatchProcessing() {
        NZC_EmissionsMatchingLog.log('starting batch');
        Database.executeBatch(new NZC_EmissionsMatchingBatch(), NZC_EmissionsMatchingMTD.emissionsMatchBatchSize);
    }

    private static void startEmissionRecalcBatchProcessing() {
        NZC_EmissionsMatchingLog.log('starting batch');
        Database.executeBatch(new NZC_EmissionsSetRecalcBatch(), NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize);
    }
}