/**
 * Created by mverigin on 6/20/23.
 */

public with sharing class NZC_EmissionsMatchingMTD {

    public static Boolean doEmissionsMatchOnInsert {
        get {
            if (doEmissionsMatchOnInsert == null
                    && matchingConfig.get('DoMatchEmissionsOnInsert__c') != null)
                doEmissionsMatchOnInsert = matchingConfig.DoMatchEmissionsOnInsert__c;

            return doEmissionsMatchOnInsert == true? doEmissionsMatchOnInsert : false;
        }

        set {
            doEmissionsMatchOnInsert = value;
        }
    }

    public static Boolean doEmissionsMatchOnUpdate {
        get {
            if (doEmissionsMatchOnUpdate == null
                    && matchingConfig.get('DoMatchEmissionsOnUpdate__c') != null)
                doEmissionsMatchOnUpdate = matchingConfig.DoMatchEmissionsOnUpdate__c;

            return doEmissionsMatchOnUpdate == true ? doEmissionsMatchOnUpdate : false;
        }

        set {
            doEmissionsMatchOnUpdate = value;
        }
    }

    public static String dateMatchingField {
        get {
            if (String.isBlank(dateMatchingField)) {
                dateMatchingField = NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE;
            }

            if (matchingConfig != null && String.isNotBlank(matchingConfig.DateMatchingField__c)) dateMatchingField = matchingConfig.DateMatchingField__c;

            return dateMatchingField;
        }

        set {
            if (Test.isRunningTest()) {
                dateMatchingField = value;
            }
        }
    }

    public static Boolean doLog {
        get {
            doLog = true;
            if (matchingConfig != null && matchingConfig.get('doLog__c') != null) doLog = matchingConfig.doLog__c;

            return doLog;
        }

        set {
            if (Test.isRunningTest()) doLog = value;
        }
    }

    public static Boolean allowCustomTagMatching {
        get {
            allowCustomTagMatching = false;
            if (matchingConfig != null && matchingConfig.get('allowCustomTagMatching__c') != null) allowCustomTagMatching = matchingConfig.allowCustomTagMatching__c;

            return allowCustomTagMatching;
        }

        set {
            allowCustomTagMatching = value;
        }
    }

    public static Boolean allowAdvancedMatching {
        get {
            allowAdvancedMatching = false;
            if (matchingConfig != null && matchingConfig.get('allowCustomTagMatching__c') != null) allowAdvancedMatching = matchingConfig.AllowAdvancedMatching__c;

            return allowAdvancedMatching;
        }

        set {
            if (Test.isRunningTest()) allowAdvancedMatching = value;
        }
    }

    public static Integer emissionsMatchBatchSize {
        get {
            emissionsMatchBatchSize = NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE;

            if (matchingConfig != null && matchingConfig.get('Emissions_Matching_Batch_Size__c') != null) emissionsMatchBatchSize = Integer.valueOf(matchingConfig.get('Emissions_Matching_Batch_Size__c'));

            return emissionsMatchBatchSize;
        }
        set;
    }

    public static Boolean allowTDrecords {
        get {
            allowTDrecords = false;
            if (matchingConfig != null && matchingConfig.get('AllowTransmissionDistribution__c') != null) allowTDrecords = matchingConfig.AllowTransmissionDistribution__c;

            return allowTDrecords;
        }
        set;
    }

    public static Integer emissionsRecalcBatchSize {
        get {
            emissionsRecalcBatchSize = NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE;

            if (matchingConfig != null && matchingConfig.get('Emissions_Recalc_Batch_Size__c') != null) emissionsRecalcBatchSize = Integer.valueOf(matchingConfig.get('Emissions_Recalc_Batch_Size__c'));

            return emissionsRecalcBatchSize;
        }
        set;
    }

    public static Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt> customMatchingRules {
        get {
            if (customMatchingRules == null) {
                customMatchingRules = getCustomMatchingRules();
            }
            return customMatchingRules;
        }
        set;
    }

    public static Map<Integer, String> customLookupRules {
        get {
            if (customLookupRules == null) {
                customLookupRules = getCustomLookupRules();
            }
            return customLookupRules;
        }
        set {
            if (Test.isRunningTest()) customLookupRules = value;
        }
    }

    public static Map<Integer, String> tdSplittingRules {
        get {
            if (tdSplittingRules == null) {
                tdSplittingRules = getTDSplittingRules();
            }
            return tdSplittingRules;
        }
        set {
            if (Test.isRunningTest()) tdSplittingRules = value;
        }
    }

    public static Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>> advancedMatchingRules {
        get {
            if (advancedMatchingRules == null) {
                advancedMatchingRules = getAdvancedMatchingRules();
            }
            return advancedMatchingRules;
        }
        set;
    }

    @TestVisible
    private static Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt> getCustomMatchingRules() {
        Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt> customMatchingInfo = new Map<Integer, NZC_EmissionsMatchingCustomMatch__mdt>();

        for (NZC_EmissionsMatchingCustomMatch__mdt rule : NZC_EmissionsMatchingCustomMatch__mdt.getAll().values()) {
            customMatchingInfo.put(NZC_EmissionsMatchingUtil.createHashKey(rule.ObjectAppliesTo__c,rule.FuelType__c), rule);
        }

        return customMatchingInfo;
    }

    @TestVisible
    private static Map<Integer, String> getCustomLookupRules() {
        Map<Integer, String> customLookupInfo = new Map<Integer, String>();

        for (NZC_EmissionsMatchingCustomLookups__mdt rule : NZC_EmissionsMatchingCustomLookups__mdt.getAll().values()) {
            customLookupInfo.put(NZC_EmissionsMatchingUtil.createHashKey(rule.ObjectAppliesFor__c,rule.FuelAppliesFor__c), rule.LookupToSearch__c);
        }

        return customLookupInfo;
    }

    @TestVisible
    private static Map<Integer, String> getTDSplittingRules() {
        Map<Integer, String> tdLookupInfo = new Map<Integer, String>();

        for (NZC_EmissionsMatchingTDCloning__mdt rule : NZC_EmissionsMatchingTDCloning__mdt.getAll().values()) {
            tdLookupInfo.put(NZC_EmissionsMatchingUtil.createHashKey(rule.ObjectName__c,rule.FuelType__c), rule.FieldsToClone__c);
        }

        return tdLookupInfo;
    }

    @TestVisible
    private static Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>> getAdvancedMatchingRules() {
        Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>> advanceMatchingInfo = new Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>>();

        for (NZC_EmissionsMatchingAdvanceMatch__mdt rule : NZC_EmissionsMatchingAdvanceMatch__mdt.getAll().values()) {
            if (!advanceMatchingInfo.containsKey(rule.ObjectAppliesTo__c)) {
                advanceMatchingInfo.put(rule.ObjectAppliesTo__c, new List<NZC_EmissionsMatchingAdvanceMatch__mdt>());
            }

            advanceMatchingInfo.get(rule.ObjectAppliesTo__c).add(rule);
        }

        return advanceMatchingInfo;
    }

    @TestVisible
    private static NZC_EmissionsMatchingConfig__c matchingConfig {
        get {
            if (matchingConfig == null) {
                try {
                    matchingConfig = NZC_EmissionsMatchingConfig__c.getOrgDefaults();
                } catch (Exception e) {
                    NZC_EmissionsMatchingLog.log('error getting custom settings',e.getMessage());
                }
            }
            return matchingConfig;
        }
        set {
            if (Test.isRunningTest()) matchingConfig = value;
        }
    }
}