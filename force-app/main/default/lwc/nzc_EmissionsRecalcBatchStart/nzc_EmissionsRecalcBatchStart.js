/**
 * Created by mverigin on 12/16/22.
 */

import {LightningElement} from 'lwc';
import startBatch from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientAttemptEmissionsSetRecalcBatchStart'
import getBatchStatus from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientPollingEmissionRecalcStatus'

export default class NzcEmissionsRecalcBatchStart extends LightningElement {

    pollingInterval;
    serverBatchStatus;

    cachedError;
    get errorMsg() {
        return this.cachedError
    }
    set errorMsg(value) {
        this.cachedError = value;
    }

    batchStatus;
    batchesProcessed;
    totalBatches;
    isBatchedStarted;

    get loadingWidth() {
        let width = 0;
        if (this.batchesProcessed && this.totalBatches && this.batchesProcessed <= this.totalBatches) {
            width = (this.batchesProcessed / this.totalBatches) * 100;
        }
        return `width: ${width}%;`;
    }

    handleBatchStart = () => {
        this.serverCallBatchStart();
    }

    serverCallBatchStart = () => {
        this.isBatchedStarted = true;
        startBatch()
            .then(res=>{
                console.log('res matching',res)
                this.handlePolling()
            })
            .catch(err=>{
                console.log(err)
            })
    }

    handlePolling = () => {
        setTimeout(async ()=>{
            await this.serverCallPollServer();
            if (this.serverBatchStatus && this.serverBatchStatus.batchStatus !== 'Completed') {
                this.handlePolling();
            }
        }, 1000);
    }

    serverCallPollServer = async () => {
        this.serverBatchStatus = await getBatchStatus();
        if (this.serverBatchStatus) {
            let {batchesProcessed, batchStatus, totalBatches, isBatchedStarted} = this.serverBatchStatus;
            [this.batchesProcessed, this.batchStatus, this.totalBatches, this.isBatchedStarted] = [batchesProcessed, batchStatus, totalBatches, isBatchedStarted];
        }
    }
}