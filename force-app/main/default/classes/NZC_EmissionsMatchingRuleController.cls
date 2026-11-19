/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * Backs the nzc_EmissionsMatchingRuleWizard LWC. Lets an admin pick the record type, the record fields
 * and the emissions set fields to match, then writes NZC_EmissionsMatchingCustomMatch__mdt through the
 * Metadata API instead of hand creating the metadata record.
 */
public with sharing class NZC_EmissionsMatchingRuleController {

    private static final String MDT_NAME = 'NZC_EmissionsMatchingCustomMatch';
    private static final Integer MAX_DEVELOPER_NAME_LENGTH = 40;
    private static final Set<Schema.DisplayType> UNSUPPORTED_TYPES = new Set<Schema.DisplayType>{
            Schema.DisplayType.ADDRESS, Schema.DisplayType.LOCATION, Schema.DisplayType.BASE64,
            Schema.DisplayType.ENCRYPTEDSTRING, Schema.DisplayType.TEXTAREA, Schema.DisplayType.COMPLEXVALUE
    };

    public class Option {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;

        public Option(String value, String label, String dataType) {
            this.value = value;
            this.label = label;
            this.dataType = dataType;
        }
    }

    public class RuleInfo {
        @AuraEnabled public String developerName;
        @AuraEnabled public String objectName;
        @AuraEnabled public String fuelType;
        @AuraEnabled public List<String> recordFields;
        @AuraEnabled public List<String> setFields;
    }

    public class ValidationResult {
        @AuraEnabled public Boolean isValid = true;
        @AuraEnabled public Boolean isUpdate = false;
        @AuraEnabled public List<String> errors = new List<String>();
        @AuraEnabled public List<String> warnings = new List<String>();
        @AuraEnabled public Integer affectedRecords;
    }

    @AuraEnabled
    public static List<Option> getSupportedObjects() {
        Set<String> objectNames = new Set<String>{
                NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE,
                NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE,
                NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM
        };
        objectNames.addAll(NZC_EmissionsMatchingConstants.EUR_ASSET_OBJ_LOOKUP.keySet());

        List<Option> options = new List<Option>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectName : new List<String>(objectNames)) {
            if (globalDescribe.containsKey(objectName) && globalDescribe.get(objectName).getDescribe().isAccessible()) {
                options.add(new Option(objectName, globalDescribe.get(objectName).getDescribe().getLabel(), null));
            }
        }
        options.sort(new OptionLabelComparator());
        return options;
    }

    @AuraEnabled
    public static List<Option> getRecordFields(String objectName) {
        assertSupported(objectName);
        return describeFields(objectName);
    }

    @AuraEnabled
    public static List<Option> getSetFields(String objectName, String fuelType) {
        assertSupported(objectName);
        return describeFields(getTargetObject(objectName, fuelType));
    }

    @AuraEnabled
    public static String getSetObjectName(String objectName, String fuelType) {
        assertSupported(objectName);
        return getTargetObject(objectName, fuelType);
    }

    @AuraEnabled
    public static Boolean supportsMultipleFields(String objectName) {
        return objectName == NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM;
    }

    @AuraEnabled
    public static List<RuleInfo> getExistingRules() {
        List<RuleInfo> rules = new List<RuleInfo>();
        for (NZC_EmissionsMatchingCustomMatch__mdt rule : [
                SELECT DeveloperName, ObjectAppliesTo__c, FuelType__c, EnergyUseFieldToMatch__c, EmissionsSetFieldToMatch__c
                FROM NZC_EmissionsMatchingCustomMatch__mdt
                ORDER BY DeveloperName
        ]) {
            RuleInfo info = new RuleInfo();
            info.developerName = rule.DeveloperName;
            info.objectName = rule.ObjectAppliesTo__c;
            info.fuelType = rule.FuelType__c;
            info.recordFields = NZC_EmissionsMatchingProcurementEngine.splitFields(rule.EnergyUseFieldToMatch__c);
            info.setFields = NZC_EmissionsMatchingProcurementEngine.splitFields(rule.EmissionsSetFieldToMatch__c);
            rules.add(info);
        }
        return rules;
    }

    @AuraEnabled
    public static ValidationResult validateRule(RuleInfo rule) {
        ValidationResult result = new ValidationResult();
        if (rule == null || String.isBlank(rule.objectName) || !isSupported(rule.objectName)) {
            return fail(result, 'Choose a supported record type.');
        }
        if (rule.recordFields == null || rule.recordFields.isEmpty() || rule.setFields == null
                || rule.recordFields.size() != rule.setFields.size()) {
            return fail(result, 'Every record field needs a matching emissions set field.');
        }
        if (rule.recordFields.size() > 1 && !supportsMultipleFields(rule.objectName)) {
            fail(result, 'This record type supports a single match field.');
        }

        Map<String, Schema.SObjectField> recordFieldMap = Schema.getGlobalDescribe().get(rule.objectName).getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> setFieldMap = Schema.getGlobalDescribe().get(getTargetObject(rule.objectName, rule.fuelType)).getDescribe().fields.getMap();
        for (Integer i = 0; i < rule.recordFields.size(); i++) {
            Schema.SObjectField recordField = recordFieldMap.get(rule.recordFields[i]);
            Schema.SObjectField setField = setFieldMap.get(rule.setFields[i]);
            if (recordField == null || !recordField.getDescribe().isAccessible()) {
                fail(result, 'Unknown or inaccessible record field: ' + rule.recordFields[i]);
            } else if (setField == null || !setField.getDescribe().isAccessible()) {
                fail(result, 'Unknown or inaccessible emissions set field: ' + rule.setFields[i]);
            } else if ((recordField.getDescribe().getType() == Schema.DisplayType.REFERENCE)
                    != (setField.getDescribe().getType() == Schema.DisplayType.REFERENCE)) {
                result.warnings.add(rule.recordFields[i] + ' and ' + rule.setFields[i] + ' are different kinds of field (lookup vs value), so they may never match.');
            }
        }

        result.isUpdate = String.isNotBlank(findDeveloperName(rule.objectName, rule.fuelType));
        if (result.isUpdate) {
            result.warnings.add('A rule already exists for this record type and fuel type. Saving replaces it.');
        }
        addSettingsWarnings(result, rule.objectName);
        if (result.isValid && rule.objectName == NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM) {
            result.affectedRecords = [SELECT COUNT() FROM Scope3PcmtItem WHERE PcmtEmssnFctrSetItemId = NULL];
        }
        return result;
    }

    @AuraEnabled
    public static String saveRule(RuleInfo rule) {
        ValidationResult validation = validateRule(rule);
        if (!validation.isValid) {
            throw new AuraHandledException(String.join(validation.errors, ' '));
        }

        String developerName = findDeveloperName(rule.objectName, rule.fuelType);
        if (String.isBlank(developerName)) {
            developerName = createDeveloperName(rule.objectName, rule.fuelType);
        }

        Metadata.CustomMetadata record = new Metadata.CustomMetadata();
        record.fullName = MDT_NAME + '.' + developerName;
        record.label = developerName.replace('_', ' ');
        record.values.add(createValue('ObjectAppliesTo__c', rule.objectName));
        record.values.add(createValue('FuelType__c', String.isBlank(rule.fuelType) ? null : rule.fuelType));
        record.values.add(createValue('EnergyUseFieldToMatch__c', String.join(rule.recordFields, NZC_EmissionsMatchingConstants.MATCH_FIELD_DELIMITER)));
        record.values.add(createValue('EmissionsSetFieldToMatch__c', String.join(rule.setFields, NZC_EmissionsMatchingConstants.MATCH_FIELD_DELIMITER)));

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(record);
        // Metadata deployments cannot be enqueued from a test context
        if (Test.isRunningTest()) {
            return 'testDeployId';
        }
        return Metadata.Operations.enqueueDeployment(container, new NZC_EmissionsMatchingRuleDeployCallback());
    }

    /**
     * The Metadata API gives no deploy status to Apex callers, so the wizard confirms the rule by reading it back.
     */
    @AuraEnabled
    public static Boolean isRuleDeployed(RuleInfo rule) {
        String fuel = String.isBlank(rule.fuelType) ? null : rule.fuelType;
        String objectName = rule.objectName;
        for (NZC_EmissionsMatchingCustomMatch__mdt saved : [
                SELECT EnergyUseFieldToMatch__c, EmissionsSetFieldToMatch__c
                FROM NZC_EmissionsMatchingCustomMatch__mdt
                WHERE ObjectAppliesTo__c = :objectName AND FuelType__c = :fuel
        ]) {
            if (saved.EnergyUseFieldToMatch__c == String.join(rule.recordFields, NZC_EmissionsMatchingConstants.MATCH_FIELD_DELIMITER)
                    && saved.EmissionsSetFieldToMatch__c == String.join(rule.setFields, NZC_EmissionsMatchingConstants.MATCH_FIELD_DELIMITER)) {
                return true;
            }
        }
        return false;
    }

    private static String getTargetObject(String objectName, String fuelType) {
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM) {
            return NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_SET_ITEM;
        }
        if (NZC_EmissionsMatchingConstants.EUR_OBJECT_EMISSIONS_SET_NAME_MAP.containsKey(objectName)) {
            return NZC_EmissionsMatchingConstants.EUR_OBJECT_EMISSIONS_SET_NAME_MAP.get(objectName);
        }
        String byFuel = NZC_EmissionsMatchingConstants.ENERGY_USE_EMISSIONS_SET_NAME_MAP.get(fuelType);
        return byFuel != null ? byFuel : NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET;
    }

    private static List<Option> describeFields(String objectName) {
        List<Option> options = new List<Option>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return options;
        }
        for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isAccessible() && !UNSUPPORTED_TYPES.contains(describe.getType())) {
                options.add(new Option(describe.getName(), describe.getLabel() + ' (' + describe.getName() + ')', String.valueOf(describe.getType())));
            }
        }
        options.sort(new OptionLabelComparator());
        return options;
    }

    private static void addSettingsWarnings(ValidationResult result, String objectName) {
        if (!NZC_EmissionsMatchingMTD.allowCustomTagMatching) {
            result.warnings.add('"Allow Custom Tag Matching" is off in NZC_EmissionsMatchingConfig, so this rule will not run until it is enabled.');
        }
        if (!NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert && !NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate) {
            result.warnings.add('Matching on insert and update are both off. Records are only matched by the batch.');
        }
    }

    private static String findDeveloperName(String objectName, String fuelType) {
        String fuel = String.isBlank(fuelType) ? null : fuelType;
        for (NZC_EmissionsMatchingCustomMatch__mdt rule : [
                SELECT DeveloperName FROM NZC_EmissionsMatchingCustomMatch__mdt
                WHERE ObjectAppliesTo__c = :objectName AND FuelType__c = :fuel LIMIT 1
        ]) {
            return rule.DeveloperName;
        }
        return null;
    }

    private static String createDeveloperName(String objectName, String fuelType) {
        String name = 'Match_' + objectName + (String.isBlank(fuelType) ? '' : '_' + fuelType);
        name = name.replaceAll('[^A-Za-z0-9]+', '_').replaceAll('_+$', '');
        return name.length() > MAX_DEVELOPER_NAME_LENGTH ? name.substring(0, MAX_DEVELOPER_NAME_LENGTH).replaceAll('_+$', '') : name;
    }

    private static Metadata.CustomMetadataValue createValue(String field, Object value) {
        Metadata.CustomMetadataValue customValue = new Metadata.CustomMetadataValue();
        customValue.field = field;
        customValue.value = value;
        return customValue;
    }

    private static Boolean isSupported(String objectName) {
        for (Option option : getSupportedObjects()) {
            if (option.value == objectName) {
                return true;
            }
        }
        return false;
    }

    private static void assertSupported(String objectName) {
        if (!isSupported(objectName)) {
            throw new AuraHandledException('Unsupported record type: ' + objectName);
        }
    }

    private static ValidationResult fail(ValidationResult result, String message) {
        result.isValid = false;
        result.errors.add(message);
        return result;
    }

    private class OptionLabelComparator implements System.Comparator<Option> {
        public Integer compare(Option first, Option second) {
            return first.label.compareTo(second.label);
        }
    }
}
