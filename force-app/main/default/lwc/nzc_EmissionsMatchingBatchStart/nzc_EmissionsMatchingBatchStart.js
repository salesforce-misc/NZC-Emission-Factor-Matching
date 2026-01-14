/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


import {LightningElement} from 'lwc';
import startBatch from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientAttemptMatchBatchStart'
import getBatchStatus from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientPollingMatchStatus'

export default class NzcEmissionsMatchingBatchStart extends LightningElement {

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
        // Note: setTimeout is required for polling batch status in LWC
        // This is a necessary async operation for status polling functionality
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
            const {batchesProcessed, batchStatus, totalBatches, isBatchedStarted} = this.serverBatchStatus;
            [this.batchesProcessed, this.batchStatus, this.totalBatches, this.isBatchedStarted] = [batchesProcessed, batchStatus, totalBatches, isBatchedStarted];
        }
    }
}