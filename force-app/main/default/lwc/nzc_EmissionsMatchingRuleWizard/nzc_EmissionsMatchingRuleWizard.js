/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSupportedObjects from '@salesforce/apex/NZC_EmissionsMatchingRuleController.getSupportedObjects';
import getRecordFields from '@salesforce/apex/NZC_EmissionsMatchingRuleController.getRecordFields';
import getSetFields from '@salesforce/apex/NZC_EmissionsMatchingRuleController.getSetFields';
import getSetObjectName from '@salesforce/apex/NZC_EmissionsMatchingRuleController.getSetObjectName';
import supportsMultipleFields from '@salesforce/apex/NZC_EmissionsMatchingRuleController.supportsMultipleFields';
import getExistingRules from '@salesforce/apex/NZC_EmissionsMatchingRuleController.getExistingRules';
import validateRule from '@salesforce/apex/NZC_EmissionsMatchingRuleController.validateRule';
import saveRule from '@salesforce/apex/NZC_EmissionsMatchingRuleController.saveRule';
import isRuleDeployed from '@salesforce/apex/NZC_EmissionsMatchingRuleController.isRuleDeployed';
import startProcurementBackfill from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientAttemptProcurementBatchStart';
import pollProcurementBackfill from '@salesforce/apex/NZC_EmissionsMatchingBatchController.clientPollingProcurementStatus';

const PROCUREMENT_OBJECT = 'Scope3PcmtItem';
const FUEL_OBJECTS = ['StnryAssetEnrgyUse', 'VehicleAssetEnrgyUse'];
const FUEL_TYPE_OPTIONS = [
    { label: 'Any / not applicable', value: '' },
    { label: 'Electricity', value: 'Electricity' },
    { label: 'Refrigerant', value: 'Refrigerant' }
];
const POLL_INTERVAL_MS = 2000;
const MAX_DEPLOY_POLLS = 30;
const STEP_OBJECT = '1';
const STEP_FIELDS = '2';
const STEP_REVIEW = '3';
const STEP_SAVE = '4';

export default class NzcEmissionsMatchingRuleWizard extends LightningElement {
    currentStep = STEP_OBJECT;
    isLoading = false;
    hasError = false;

    objectOptions = [];
    recordFieldOptions = [];
    setFieldOptions = [];
    existingRules = [];
    fuelTypeOptions = FUEL_TYPE_OPTIONS;

    objectName = '';
    fuelType = '';
    setObjectName = '';
    allowMultiple = false;
    pairs = [];
    nextPairId = 1;

    validation;
    isDeployed = false;
    isTimedOut = false;
    backfillStarted = false;
    backfillStatus = '';

    async connectedCallback() {
        await this.run(async () => {
            this.objectOptions = await getSupportedObjects();
            this.objectOptions = this.objectOptions.map((option) => ({ label: option.label, value: option.value }));
            await this.loadExistingRules();
        });
    }

    get isStepOne() { return this.currentStep === STEP_OBJECT; }
    get isStepTwo() { return this.currentStep === STEP_FIELDS; }
    get isStepThree() { return this.currentStep === STEP_REVIEW; }
    get isStepFour() { return this.currentStep === STEP_SAVE; }
    get showFuelType() { return FUEL_OBJECTS.includes(this.objectName); }
    get hasExistingRules() { return this.existingRules.length > 0; }
    get canRemovePair() { return this.pairs.length > 1; }
    get showBack() { return this.isStepTwo || this.isStepThree; }
    get showNext() { return this.isStepOne || this.isStepTwo; }
    get showSave() { return this.isStepThree; }
    get showBackfill() { return this.objectName === PROCUREMENT_OBJECT; }
    get showAffected() { return this.validation && this.validation.affectedRecords !== undefined && this.validation.affectedRecords !== null; }
    get isNextDisabled() { return this.isLoading || (this.isStepOne ? !this.objectName : !this.pairsAreComplete()); }
    get isSaveDisabled() { return this.isLoading || !this.validation || !this.validation.isValid; }

    get ruleSummary() {
        const pairText = this.pairs.map((pair) => `${pair.recordField} = ${pair.setField}`).join(' AND ');
        const fuel = this.fuelType ? ` (fuel: ${this.fuelType})` : '';
        return `${this.objectName}${fuel}: ${pairText}`;
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
        this.fuelType = '';
    }

    handleFuelChange(event) {
        this.fuelType = event.detail.value;
    }

    handlePairChange(event) {
        const { id, side } = event.target.dataset;
        const key = side === 'record' ? 'recordField' : 'setField';
        this.pairs = this.pairs.map((pair) => (pair.id === id ? { ...pair, [key]: event.detail.value } : pair));
    }

    handleAddPair() {
        this.pairs = [...this.pairs, this.createPair()];
    }

    handleRemovePair(event) {
        const { id } = event.target.dataset;
        this.pairs = this.pairs.filter((pair) => pair.id !== id);
    }

    async handleNext() {
        if (this.isStepOne) {
            await this.run(async () => {
                this.setObjectName = await getSetObjectName({ objectName: this.objectName, fuelType: this.fuelType });
                this.allowMultiple = await supportsMultipleFields({ objectName: this.objectName });
                this.recordFieldOptions = await getRecordFields({ objectName: this.objectName });
                this.setFieldOptions = await getSetFields({ objectName: this.objectName, fuelType: this.fuelType });
                this.pairs = [this.createPair()];
                this.currentStep = STEP_FIELDS;
            });
        } else if (this.isStepTwo) {
            await this.run(async () => {
                this.validation = await validateRule({ rule: this.buildRule() });
                this.hasError = !this.validation.isValid;
                this.currentStep = STEP_REVIEW;
            });
        }
    }

    handleBack() {
        this.hasError = false;
        this.currentStep = this.isStepThree ? STEP_FIELDS : STEP_OBJECT;
    }

    async handleSave() {
        await this.run(async () => {
            await saveRule({ rule: this.buildRule() });
            this.isDeployed = false;
            this.isTimedOut = false;
            this.currentStep = STEP_SAVE;
        });
        if (this.currentStep === STEP_SAVE) {
            await this.waitForDeployment();
        }
    }

    async handleBackfill() {
        await this.run(async () => {
            let status = await startProcurementBackfill();
            this.backfillStarted = true;
            this.backfillStatus = status.batchStatus || 'Queued';
            while (status.isBatchedStarted) {
                await this.sleep(POLL_INTERVAL_MS);
                status = await pollProcurementBackfill();
                this.backfillStatus = status.batchStatus || 'Completed';
            }
        });
    }

    async handleRestart() {
        this.objectName = '';
        this.fuelType = '';
        this.pairs = [];
        this.validation = undefined;
        this.isDeployed = false;
        this.isTimedOut = false;
        this.backfillStarted = false;
        this.hasError = false;
        this.currentStep = STEP_OBJECT;
        await this.run(() => this.loadExistingRules());
    }

    async waitForDeployment() {
        for (let attempt = 0; attempt < MAX_DEPLOY_POLLS && !this.isDeployed; attempt++) {
            await this.sleep(POLL_INTERVAL_MS);
            try {
                this.isDeployed = await isRuleDeployed({ rule: this.buildRule() });
            } catch (error) {
                this.showError(error);
                return;
            }
        }
        this.isTimedOut = !this.isDeployed;
        if (this.isDeployed) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Matching rule saved', variant: 'success' }));
        }
    }

    async loadExistingRules() {
        const rules = await getExistingRules();
        this.existingRules = rules.map((rule) => ({
            ...rule,
            summary: `${rule.objectName}${rule.fuelType ? ` (${rule.fuelType})` : ''}: ${rule.recordFields.join(', ')} → ${rule.setFields.join(', ')}`
        }));
    }

    buildRule() {
        return {
            objectName: this.objectName,
            fuelType: this.fuelType || null,
            recordFields: this.pairs.map((pair) => pair.recordField),
            setFields: this.pairs.map((pair) => pair.setField)
        };
    }

    createPair() {
        const id = `pair-${this.nextPairId++}`;
        return { id, recordField: '', setField: '' };
    }

    pairsAreComplete() {
        return this.pairs.length > 0 && this.pairs.every((pair) => pair.recordField && pair.setField);
    }

    async run(work) {
        this.isLoading = true;
        try {
            await work();
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    sleep(milliseconds) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        return new Promise((resolve) => setTimeout(resolve, milliseconds));
    }

    showError(error) {
        const message = (error && error.body && error.body.message) || (error && error.message) || 'Unexpected error';
        this.dispatchEvent(new ShowToastEvent({ title: 'Matching rule wizard', message, variant: 'error' }));
    }
}
