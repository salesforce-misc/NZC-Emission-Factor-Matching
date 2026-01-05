/**
 * Created by mverigin on 10/24/24.
 */

public with sharing class NZC_EmissionsMatchingAdvancedMatchWpr {
    public static final String DEFAULT_SEPARATOR = ',';

    private final SObject originalRecord;
    public final String objectType;
    // a list of hashes created from each rule
    public final List<String> quickSearchHashes;
    // a list of booleans for what rules passed the flag check
    public final List<Boolean> updateScreening;
    public Boolean shouldQueryHashes;
    // map of field name to factor found during matching
    public final Map<String, String> factorMatched;

    public NZC_EmissionsMatchingAdvancedMatchWpr(SObject record) {
        originalRecord = record;
        objectType = record.getSObjectType() + '';
        quickSearchHashes = new List<String>();
        updateScreening = new List<Boolean>();
        shouldQueryHashes = false;
        factorMatched = new Map<String, String>();
    }

    public void screenRecordCreateQuickSearchHash() {
        NZC_EmissionsMatchingLog.log('screening wrappers and hashing');
        List<NZC_EmissionsMatchingAdvanceMatch__mdt> matchingRules = NZC_EmissionsMatchingMTD.advancedMatchingRules.get(objectType);
        if (matchingRules.size() < 1) return;

        for (NZC_EmissionsMatchingAdvanceMatch__mdt matchingRule : matchingRules) {
            // if lookup is populated we will query later
            shouldQueryHashes = String.isNotBlank(matchingRule.LookupToPopulate__c) || shouldQueryHashes;

            // create hash key
            List<String> hashingFields = new List<String>();
            if (String.isNotBlank(matchingRule.HashFields__c)) hashingFields = matchingRule.HashFields__c.split(DEFAULT_SEPARATOR);
            String hashKey = NZC_EmissionsMatchingUtil.hashRecordFields(originalRecord, hashingFields);

            // store screen boolean and hash for later for updating
            Boolean recordPassesFlagCheck = String.isBlank(matchingRule.ScreeningField__c) || originalRecord.get(matchingRule.ScreeningField__c) == true;
            updateScreening.add(recordPassesFlagCheck);

            NZC_EmissionsMatchingLog.log('hash created ' + hashKey + ' hash included ' + recordPassesFlagCheck);
            quickSearchHashes.add(recordPassesFlagCheck && hashKey != NZC_EmissionsMatchingUtil.DEFAULT_HASH? hashKey : null);
        }
    }

    public Boolean canMatchQuickSearch(Integer idx) {
        return quickSearchHashes[idx] != NZC_EmissionsMatchingUtil.DEFAULT_HASH;
    }

    public void updateOriginalRecord(String fieldName, Object updateValue) {
        if (String.isBlank(fieldName) || NZC_EmissionsMatchingUtil.isFormulaField(objectType, fieldName)) return;
        NZC_EmissionsMatchingLog.log('Adding update to original record ' + objectType
                + '.' + fieldName + ' = ' + updateValue);
        originalRecord.put(fieldName, updateValue);
    }

    public void addFactorMatchedValue(NZC_EmissionsMatchingAdvanceMatch__mdt matchRule, String value) {
        NZC_EmissionsMatchingLog.log('Adding factor ' + matchRule.LookupToPopulate__c + ' ' + value);
        factorMatched.put(matchRule.LookupToPopulate__c,value);
    }

    public String getSecondaryMatchValue(NZC_EmissionsMatchingAdvanceMatch__mdt matchRule) {
        NZC_EmissionsMatchingLog.log('getting secondary match value');
        if (String.isBlank(matchRule.SecondaryMatchSourceField__c)
                || originalRecord.get(matchRule.SecondaryMatchSourceField__c) == null) return '';
        return '' + originalRecord.get(matchRule.SecondaryMatchSourceField__c);
    }

}