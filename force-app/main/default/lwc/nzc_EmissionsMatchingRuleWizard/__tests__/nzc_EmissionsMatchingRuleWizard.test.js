/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { createElement } from 'lwc';
import NzcEmissionsMatchingRuleWizard from 'c/nzc_EmissionsMatchingRuleWizard';
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
const ShowToastEventName = 'lightning__showtoast';

jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.getSupportedObjects', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.getRecordFields', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.getSetFields', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.getSetObjectName', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.supportsMultipleFields', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.getExistingRules', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.validateRule', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.saveRule', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingRuleController.isRuleDeployed', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingBatchController.clientAttemptProcurementBatchStart', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/NZC_EmissionsMatchingBatchController.clientPollingProcurementStatus', () => ({ default: jest.fn() }), { virtual: true });

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

const FIELDS = [
    { label: 'Name (Name)', value: 'Name' },
    { label: 'Category (SpendingCategory1)', value: 'SpendingCategory1' }
];

function mockHappyPath() {
    getSupportedObjects.mockResolvedValue([
        { label: 'Procurement Item', value: 'Scope3PcmtItem' },
        { label: 'Stationary Energy Use', value: 'StnryAssetEnrgyUse' }
    ]);
    getExistingRules.mockResolvedValue([
        { developerName: 'Existing', objectName: 'HotelStayEnrgyUse', fuelType: null, recordFields: ['Name'], setFields: ['Name'] },
        { developerName: 'Fuel', objectName: 'StnryAssetEnrgyUse', fuelType: 'Electricity', recordFields: ['Name'], setFields: ['Name'] }
    ]);
    getSetObjectName.mockResolvedValue('PcmtEmssnFctrSetItem');
    supportsMultipleFields.mockResolvedValue(true);
    getRecordFields.mockResolvedValue(FIELDS);
    getSetFields.mockResolvedValue(FIELDS);
    validateRule.mockResolvedValue({ isValid: true, errors: [], warnings: ['Matching is off'], affectedRecords: 12 });
}

async function createWizard() {
    const element = createElement('c-nzc-emissions-matching-rule-wizard', { is: NzcEmissionsMatchingRuleWizard });
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

function buttonByLabel(element, label) {
    return Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((button) => button.label === label);
}

function comboByName(element, name) {
    return Array.from(element.shadowRoot.querySelectorAll("lightning-combobox")).find((combo) => combo.name === name) || null;
}

function change(element, selector, value) {
    const target = selector.startsWith("name:") ? comboByName(element, selector.slice(5)) : element.shadowRoot.querySelector(selector);
    target.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    return flushPromises();
}

async function chooseObject(element, value) {
    await change(element, 'name:objectName', value);
}

async function goToFieldsStep(element) {
    await chooseObject(element, 'Scope3PcmtItem');
    buttonByLabel(element, 'Next').click();
    await flushPromises();
}

async function fillFirstPair(element) {
    await change(element, 'lightning-combobox[data-side="record"]', 'Name');
    await change(element, 'lightning-combobox[data-side="set"]', 'Name');
}

async function goToReviewStep(element) {
    await goToFieldsStep(element);
    await fillFirstPair(element);
    buttonByLabel(element, 'Next').click();
    await flushPromises();
}

describe('c-nzc-emissions-matching-rule-wizard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.resetAllMocks();
    });

    it('lists existing rules and keeps Next disabled until a record type is chosen', async () => {
        mockHappyPath();
        const element = await createWizard();

        expect(element.shadowRoot.textContent).toContain('HotelStayEnrgyUse: Name');
        expect(element.shadowRoot.textContent).toContain('StnryAssetEnrgyUse (Electricity)');
        expect(buttonByLabel(element, 'Next').disabled).toBe(true);

        await chooseObject(element, 'Scope3PcmtItem');
        expect(buttonByLabel(element, 'Next').disabled).toBe(false);
    });

    it('shows the fuel type picker only for fuel based record types', async () => {
        mockHappyPath();
        const element = await createWizard();
        expect(comboByName(element, 'fuelType')).toBeNull();

        await chooseObject(element, 'StnryAssetEnrgyUse');
        const fuel = comboByName(element, 'fuelType');
        expect(fuel).not.toBeNull();
        await change(element, 'name:fuelType', 'Electricity');
        expect(comboByName(element, 'fuelType').value).toBe('Electricity');
    });

    it('lets the admin add and remove field pairs when multiple fields are supported', async () => {
        mockHappyPath();
        const element = await createWizard();
        await goToFieldsStep(element);

        expect(getSetObjectName).toHaveBeenCalledWith({ objectName: 'Scope3PcmtItem', fuelType: '' });
        expect(element.shadowRoot.querySelectorAll('lightning-combobox[data-side="record"]')).toHaveLength(1);
        expect(element.shadowRoot.querySelector('lightning-button-icon')).toBeNull();

        buttonByLabel(element, 'Add another field pair').click();
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('lightning-combobox[data-side="record"]')).toHaveLength(2);

        element.shadowRoot.querySelector('lightning-button-icon').click();
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('lightning-combobox[data-side="record"]')).toHaveLength(1);
    });

    it('hides the add pair button for single field record types and supports going back', async () => {
        mockHappyPath();
        supportsMultipleFields.mockResolvedValue(false);
        const element = await createWizard();
        await goToFieldsStep(element);

        expect(buttonByLabel(element, 'Add another field pair')).toBeUndefined();
        expect(buttonByLabel(element, 'Next').disabled).toBe(true);

        buttonByLabel(element, 'Back').click();
        await flushPromises();
        expect(comboByName(element, 'objectName')).not.toBeNull();
    });

    it('walks to the review step and shows warnings and the affected record count', async () => {
        mockHappyPath();
        const element = await createWizard();
        await goToReviewStep(element);

        expect(validateRule).toHaveBeenCalledWith({
            rule: { objectName: 'Scope3PcmtItem', fuelType: null, recordFields: ['Name'], setFields: ['Name'] }
        });
        expect(element.shadowRoot.textContent).toContain('Scope3PcmtItem: Name = Name');
        expect(element.shadowRoot.textContent).toContain('Matching is off');
        expect(element.shadowRoot.textContent).toContain('12 record(s)');
        expect(buttonByLabel(element, 'Save rule').disabled).toBe(false);

        buttonByLabel(element, 'Back').click();
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('lightning-combobox[data-side="record"]')).toHaveLength(1);
    });

    it('disables saving and shows errors when validation fails', async () => {
        mockHappyPath();
        validateRule.mockResolvedValue({ isValid: false, errors: ['Duplicate rule'], warnings: [], affectedRecords: null });
        const element = await createWizard();
        await goToReviewStep(element);

        expect(element.shadowRoot.textContent).toContain('Duplicate rule');
        expect(element.shadowRoot.textContent).not.toContain('record(s)');
        expect(buttonByLabel(element, 'Save rule').disabled).toBe(true);
    });

    it('saves the rule, confirms the deployment, backfills and restarts', async () => {
        mockHappyPath();
        saveRule.mockResolvedValue('0Af000000000001');
        isRuleDeployed.mockResolvedValue(true);
        startProcurementBackfill.mockResolvedValue({ isBatchedStarted: true, batchStatus: 'Queued' });
        pollProcurementBackfill.mockResolvedValue({ isBatchedStarted: false, batchStatus: null });
        const element = await createWizard();
        await goToReviewStep(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        buttonByLabel(element, 'Save rule').click();
        await wait(2200);
        await flushPromises();

        expect(saveRule).toHaveBeenCalledTimes(1);
        expect(isRuleDeployed).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.textContent).toContain('The rule was saved.');
        expect(toastHandler).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');

        buttonByLabel(element, 'Backfill procurement items now').click();
        await wait(2200);
        await flushPromises();
        expect(startProcurementBackfill).toHaveBeenCalledTimes(1);
        expect(pollProcurementBackfill).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.textContent).toContain('Backfill started: Completed');

        buttonByLabel(element, 'Create another rule').click();
        await flushPromises();
        expect(comboByName(element, 'objectName')).not.toBeNull();
        expect(getExistingRules).toHaveBeenCalledTimes(2);
    }, 15000);

    it('shows an error toast when saving fails', async () => {
        mockHappyPath();
        saveRule.mockRejectedValue({ body: { message: 'Deploy refused' } });
        const element = await createWizard();
        await goToReviewStep(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        buttonByLabel(element, 'Save rule').click();
        await flushPromises();

        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Deploy refused');
        expect(isRuleDeployed).not.toHaveBeenCalled();
        expect(buttonByLabel(element, 'Save rule')).toBeTruthy();
    });

    it('shows an error toast when polling the deployment fails', async () => {
        mockHappyPath();
        saveRule.mockResolvedValue('0Af000000000001');
        isRuleDeployed.mockRejectedValue(new Error('Poll failed'));
        const element = await createWizard();
        await goToReviewStep(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        buttonByLabel(element, 'Save rule').click();
        await wait(2200);
        await flushPromises();

        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Poll failed');
    }, 10000);

    it('shows an error toast when the supported objects cannot be loaded', async () => {
        getExistingRules.mockResolvedValue([]);
        getSupportedObjects.mockRejectedValue({ body: { message: 'No access' } });
        const element = createElement('c-nzc-emissions-matching-rule-wizard', { is: NzcEmissionsMatchingRuleWizard });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('No access');
    });

    it('falls back to a generic message for unknown errors', async () => {
        getSupportedObjects.mockRejectedValue(undefined);
        const element = createElement('c-nzc-emissions-matching-rule-wizard', { is: NzcEmissionsMatchingRuleWizard });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Unexpected error');
    });
});

