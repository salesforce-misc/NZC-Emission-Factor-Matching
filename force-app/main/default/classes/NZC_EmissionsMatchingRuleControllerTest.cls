/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

@IsTest
private class NZC_EmissionsMatchingRuleControllerTest {

    @IsTest
    static void listsSupportedObjectsAndFields() {
        List<NZC_EmissionsMatchingRuleController.Option> objects = NZC_EmissionsMatchingRuleController.getSupportedObjects();
        Set<String> names = new Set<String>();
        for (NZC_EmissionsMatchingRuleController.Option option : objects) {
            names.add(option.value);
        }

        Assert.isTrue(names.contains(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM));
        Assert.isTrue(names.contains(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE));
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_SET_ITEM,
                NZC_EmissionsMatchingRuleController.getSetObjectName(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, null));
        Assert.areEqual(NZC_EmissionsMatchingConstants.OBJECT_ELECTRICITY_SET,
                NZC_EmissionsMatchingRuleController.getSetObjectName(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE, 'Electricity'));
        Assert.isFalse(NZC_EmissionsMatchingRuleController.getRecordFields(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM).isEmpty());
        Assert.isFalse(NZC_EmissionsMatchingRuleController.getSetFields(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, null).isEmpty());
    }

    @IsTest
    static void rejectsUnsupportedObject() {
        try {
            NZC_EmissionsMatchingRuleController.getRecordFields('Account');
            Assert.fail('expected an exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e);
        }
    }

    @IsTest
    static void validatesProcurementRule() {
        NZC_EmissionsMatchingRuleController.ValidationResult valid = NZC_EmissionsMatchingRuleController.validateRule(
                rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>{'Name', 'SpendingCategory1'}, new List<String>{'Name', 'EconomicSector'}));
        NZC_EmissionsMatchingRuleController.ValidationResult unknownField = NZC_EmissionsMatchingRuleController.validateRule(
                rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>{'Nope__c'}, new List<String>{'Name'}));
        NZC_EmissionsMatchingRuleController.ValidationResult unevenPairs = NZC_EmissionsMatchingRuleController.validateRule(
                rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>{'Name'}, new List<String>{'Name', 'EconomicSector'}));

        Assert.isTrue(valid.isValid, String.join(valid.errors, ','));
        Assert.isFalse(valid.warnings.isEmpty(), 'settings are off in tests, so a warning is expected');
        Assert.isNotNull(valid.affectedRecords);
        Assert.isFalse(unknownField.isValid);
        Assert.isFalse(unevenPairs.isValid);
    }

    @IsTest
    static void onlyProcurementAllowsMultipleFields() {
        NZC_EmissionsMatchingRuleController.ValidationResult result = NZC_EmissionsMatchingRuleController.validateRule(
                rule(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE, new List<String>{'Name', 'Id'}, new List<String>{'Name', 'Id'}));

        Assert.isFalse(result.isValid);
        Assert.isFalse(NZC_EmissionsMatchingRuleController.supportsMultipleFields(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE));
    }

    @IsTest
    static void saveRuleEnqueuesDeployment() {
        Test.startTest();
        String deployId = NZC_EmissionsMatchingRuleController.saveRule(
                rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>{'Name'}, new List<String>{'Name'}));
        Test.stopTest();

        Assert.isNotNull(deployId);
    }

    @IsTest
    static void saveRuleRejectsInvalidRule() {
        try {
            NZC_EmissionsMatchingRuleController.saveRule(rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>(), new List<String>()));
            Assert.fail('expected an exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e);
        }
    }

    @IsTest
    static void ruleIsNotDeployedUntilSaved() {
        Assert.isFalse(NZC_EmissionsMatchingRuleController.isRuleDeployed(
                rule(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, new List<String>{'Name'}, new List<String>{'Name'})));
        Assert.isNotNull(NZC_EmissionsMatchingRuleController.getExistingRules());
    }

    @IsTest
    static void callbackHandlesSuccessAndFailure() {
        NZC_EmissionsMatchingRuleDeployCallback callback = new NZC_EmissionsMatchingRuleDeployCallback();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        callback.handleResult(result, new Metadata.DeployCallbackContext());

        result.status = Metadata.DeployStatus.Failed;
        result.details = new Metadata.DeployDetails();
        callback.handleResult(result, new Metadata.DeployCallbackContext());

        Assert.isNotNull(result);
    }

    private static NZC_EmissionsMatchingRuleController.RuleInfo rule(String objectName, List<String> recordFields, List<String> setFields) {
        NZC_EmissionsMatchingRuleController.RuleInfo info = new NZC_EmissionsMatchingRuleController.RuleInfo();
        info.objectName = objectName;
        info.recordFields = recordFields;
        info.setFields = setFields;
        return info;
    }
}
