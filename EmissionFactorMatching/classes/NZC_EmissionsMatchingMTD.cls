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

    public static Integer emissionsMatchBatchSize {
        get {
            emissionsMatchBatchSize = NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE;

            if (matchingConfig != null && matchingConfig.get('Emissions_Matching_Batch_Size__c') != null) emissionsMatchBatchSize = Integer.valueOf(matchingConfig.get('Emissions_Matching_Batch_Size__c'));

            return emissionsMatchBatchSize;
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