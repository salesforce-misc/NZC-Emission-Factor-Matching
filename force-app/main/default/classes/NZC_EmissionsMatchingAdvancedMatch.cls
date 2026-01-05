/**
 * Created by mverigin on 10/24/24.
 */

public with sharing class NZC_EmissionsMatchingAdvancedMatch {

    private static final Map<String, String> lookupObjectHelper {
        get {
            if (lookupObjectHelper == null) {
                lookupObjectHelper = new Map<String, String>();
            }
            return lookupObjectHelper;
        }
        set{}
    }

    // Map of objects and the fields to filter on for each object
    private static final Map<String, Set<String>> queryHelper = new Map<String, Set<String>>();
    // Map of objects and extra fields to pull for each object
    private static final Map<String, Set<String>> queryHelperExtraFields = new Map<String, Set<String>>();
    // Map of object + hash key and the factor it tags
    private final Map<String, List<SObject>> factorFinderHelper;


    private final List<SObject> originalRecords;
    private final List<NZC_EmissionsMatchingAdvancedMatchWpr> matchWrappers;
    private final Set<String> hashesToSearch;
    private final Map<String, String> matrixMatchOverRide;
    private final Map<String, String> matrixMatchDefaultMatch;
    private final Map<String, String> matrixAliases;
    private final Boolean doUpdateRecords;
    private Boolean shouldNotProceed;

    public NZC_EmissionsMatchingAdvancedMatch(List<SObject> triggeringRecords, Boolean shouldUpdateRecords) {
        originalRecords = triggeringRecords;
        hashesToSearch = new Set<String>();
        matchWrappers = new List<NZC_EmissionsMatchingAdvancedMatchWpr>();
        factorFinderHelper = new Map<String, List<SObject>>();
        matrixMatchOverRide = new Map<String, String>();
        matrixMatchDefaultMatch = new Map<String, String>();
        matrixAliases = new Map<String, String>();
        doUpdateRecords = shouldUpdateRecords;
        shouldNotProceed = false;
    }

    public void process() {
        createWrappers();

        // used to prevent running on object without rules
        if (shouldNotProceed) return;

        queryMemoryRecords();

        queryRecords();

        matchRecords();

        // update phase
        processUpdates();
    }

    public static void fireAdvancedMatching(List<SObject> recordsTriggering, Boolean shouldUpdate) {
        if (!NZC_EmissionsMatchingMTD.allowAdvancedMatching) return;
        NZC_EmissionsMatchingLog.log('Advanced Match fire');
        NZC_EmissionsMatchingAdvancedMatch engine = new NZC_EmissionsMatchingAdvancedMatch(recordsTriggering, shouldUpdate);
        engine.process();
    }

    public void createWrappers() {
        NZC_EmissionsMatchingLog.log('creating wrappers and screening');
        Boolean isFirstRun = true;

        // exit trigger if no rules exist for object
        shouldNotProceed = originalRecords.size() < 1
                || NZC_EmissionsMatchingMTD.advancedMatchingRules.get(originalRecords[0].getSObjectType() + '') == null;

        if (shouldNotProceed) return;

        for (SObject record : originalRecords) {
            NZC_EmissionsMatchingAdvancedMatchWpr wrapper = new NZC_EmissionsMatchingAdvancedMatchWpr(record);

            // used to extract rules to add to query helper
            if (isFirstRun) {
                addRuleToQueryHelper(NZC_EmissionsMatchingMTD.advancedMatchingRules.get(wrapper.objectType));
                isFirstRun = false;
            }

            wrapper.screenRecordCreateQuickSearchHash();
            if (wrapper.shouldQueryHashes) {
                hashesToSearch.addAll(wrapper.quickSearchHashes);
                NZC_EmissionsMatchingLog.log(wrapper.quickSearchHashes);
            }

            matchWrappers.add(wrapper);
        }
    }

    private static void addRuleToQueryHelper(List<NZC_EmissionsMatchingAdvanceMatch__mdt> matchingRules) {
        NZC_EmissionsMatchingLog.log('Adding to query helper ');
        for (NZC_EmissionsMatchingAdvanceMatch__mdt rule : matchingRules) {
            // no lookup to match
            if (String.isBlank(rule.LookupToPopulate__c)) continue;

            NZC_EmissionsMatchingLog.log('rule', rule);
            String targetObject = getObjectToSearch(rule.ObjectAppliesTo__c, rule.LookupToPopulate__c);

            if (!queryHelper.containsKey(targetObject)) {
                queryHelper.put(targetObject, new Set<String>());
                queryHelperExtraFields.put(targetObject, new Set<String>());
            }

            if(String.isBlank(rule.LookupDestination__c)) continue;
            // add base search field
            queryHelper.get(targetObject).add(rule.LookupDestination__c);

            // add secondary search field for later
            if (String.isNotBlank(rule.SecondaryMatchFieldTarget__c)) queryHelperExtraFields.get(targetObject).add(rule.SecondaryMatchFieldTarget__c);
        }
        NZC_EmissionsMatchingLog.log('query helper ' + queryHelper);
        NZC_EmissionsMatchingLog.log('query helper Extra fields' + queryHelperExtraFields);
    }

    private void addFactorToFactorHelper(SObject factor) {
        NZC_EmissionsMatchingLog.log('creating emissions hashkey');
        String objectType = factor.getSObjectType() + '';
        Set<String> fieldsNeeded = queryHelper.get(objectType);
        for (String field : fieldsNeeded) {
            String valueExtracted = factor.get(field) + '';
            String hashKey = '' + NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectType, valueExtracted});
            NZC_EmissionsMatchingLog.log('key ' + hashKey);

            if (!factorFinderHelper.containsKey(hashKey)) {
                factorFinderHelper.put(hashKey, new List<SObject>());
            }
            factorFinderHelper.get(hashKey).add(factor);
        }
    }

    private static String getObjectToSearch(String currentObject, String lookupField) {
        NZC_EmissionsMatchingLog.log('Dynamically getting object ' + currentObject + ' ' + lookupField);
        String objectName = lookupObjectHelper.get(currentObject + lookupField);
        if (objectName == null) {
            objectName = '' + NZC_EmissionsMatchingUtil.globalDescribe.get(currentObject).getDescribe().fields.getMap().get(lookupField).getDescribe().referenceTo[0];
            lookupObjectHelper.put(currentObject + lookupField, objectName);
        }
        NZC_EmissionsMatchingLog.log('object ' + objectName);

        return objectName;
    }

    private void queryRecords() {
        Set<String> searchHash = hashesToSearch;
        searchHash.remove(null);
        NZC_EmissionsMatchingLog.log('Querying keyset size ' + searchHash.size());
        if (searchHash.size() < 1) return;
        NZC_EmissionsMatchingLog.log('Query keys ', searchHash);
        for (String objectToQuery : queryHelper.keySet()) {
            // skip if no fields will be queried
            if (queryHelper.get(objectToQuery).size() < 1) continue;
            List<String> query = new List<String>{
                    'SELECT ' + String.join(queryHelper.get(objectToQuery),', ')
            };

            // get second level search as extra fields
            if (queryHelperExtraFields.get(objectToQuery).size() > 0) {
                String additionalFields = String.join(queryHelperExtraFields.get(objectToQuery), ', ');
                query.add(', ' + additionalFields);
            }

            query.add(' FROM ' + objectToQuery + ' WHERE ');

            // exclude sets that are not master sets if applicable
            if (NZC_EmissionsMatchingConstants.EXCLUDE_MASTER_SET_LIST.contains(objectToQuery)) {
                query.add(' MasterEmissionsSet__c = NULL AND ');
            }

            // we can't get here unless query helper is populated, can assume exists
            query.add(String.join(queryHelper.get(objectToQuery),' IN: searchHash OR '));
            query.add('  IN: searchHash ORDER BY CreatedDate DESC');

            NZC_EmissionsMatchingLog.log('Query ' + String.join(query, ''));
            for (SObject record : Database.query(String.join(query, ''))) {
                addFactorToFactorHelper(record);
            }
            NZC_EmissionsMatchingLog.log('Factor helper size ' + factorFinderHelper.size());
        }
    }

    private void queryMemoryRecords() {
        Set<String> aliasesToInclude = new Set<String>();
        Set<String> objectsNeeded = queryHelper.keySet();
        NZC_EmissionsMatchingLog.log('Getting memory records', objectsNeeded);

        for (NZC_EmissionsMatchingMatrix__c matrixRecord : [
                SELECT Id, AliasHashStorage__c, ApplicableObject__c, PrimaryHashStorage__c, LookupOverride__c
                FROM NZC_EmissionsMatchingMatrix__c
                WHERE (PrimaryHashStorage__c IN: hashesToSearch OR PrimaryHashStorage__c = NULL)
                AND ApplicableObject__c IN: objectsNeeded
                ORDER BY CreatedDate ASC
        ]) {
            // record with hash
            if (String.isNotBlank(matrixRecord.PrimaryHashStorage__c)) {
                // has override lookup
                if (String.isNotBlank(matrixRecord.LookupOverride__c)) {
                    String lookupKey = NZC_EmissionsMatchingUtil.hashListOfStrings(new List<String>{
                            matrixRecord.ApplicableObject__c,
                            matrixRecord.PrimaryHashStorage__c
                    });
                    matrixMatchOverRide.put(lookupKey, matrixRecord.LookupOverride__c);
                    continue;
                }

                // has match alias
                if (String.isNotBlank(matrixRecord.AliasHashStorage__c)) {
                    // add to alias to search in query
                    aliasesToInclude.add(matrixRecord.AliasHashStorage__c);

                    String lookupKey = NZC_EmissionsMatchingUtil.hashListOfStrings(new List<String>{
                            matrixRecord.ApplicableObject__c,
                            matrixRecord.PrimaryHashStorage__c
                    });
                    matrixAliases.put(lookupKey, matrixRecord.AliasHashStorage__c);
                }

            } else {
                // has override lookup
                if (String.isNotBlank(matrixRecord.LookupOverride__c)) {
                    matrixMatchDefaultMatch.put(matrixRecord.ApplicableObject__c, matrixRecord.LookupOverride__c);
                }
            }
        }

        NZC_EmissionsMatchingLog.log('Adding Aliases to Query ' + aliasesToInclude.size());
        NZC_EmissionsMatchingLog.log('Aliases for matching ' + matrixAliases.size());
        hashesToSearch.addAll(aliasesToInclude);
    }

    private void matchRecords() {
        NZC_EmissionsMatchingLog.log('Matching');
        for (NZC_EmissionsMatchingAdvancedMatchWpr wrapper : matchWrappers) {
            // record doesn't need to find any factor because its not populating lookup
            if (!wrapper.shouldQueryHashes) continue;

            List<NZC_EmissionsMatchingAdvanceMatch__mdt> matchingRules = NZC_EmissionsMatchingMTD.advancedMatchingRules.get(wrapper.objectType);
            for (Integer i = 0; i < matchingRules.size()
                    && i < wrapper.quickSearchHashes.size()
                    && i < wrapper.updateScreening.size(); i++) {

                // no lookup to populate for this specific rule or record did not pass screening for this field
                if (String.isBlank(matchingRules[i].LookupToPopulate__c) || !wrapper.updateScreening[i]) continue;
                NZC_EmissionsMatchingLog.log('Wrapper not excluded, matching: ' + matchingRules[i].LookupToPopulate__c);

                String targetObject = getObjectToSearch(matchingRules[i].ObjectAppliesTo__c, matchingRules[i].LookupToPopulate__c);
                NZC_EmissionsMatchingLog.log('Has quick search ' + wrapper.canMatchQuickSearch(i));
                if (wrapper.canMatchQuickSearch(i)) {

                    if (wrapper.quickSearchHashes[i] == null) {
                        // use default matrix match based on object type
                        NZC_EmissionsMatchingLog.log('Matrix default match ' + targetObject + ' ' + matrixMatchDefaultMatch);
                        attachDefaultMatrixRecord(wrapper, matchingRules[i],targetObject);
                        continue;
                    }

                    String overRideSearchKey = NZC_EmissionsMatchingUtil.hashListOfStrings(new List<String>{ targetObject, wrapper.quickSearchHashes[i] });
                    if (matrixMatchOverRide.containsKey(overRideSearchKey)) {
                        // direct match provided don't keep searching
                        NZC_EmissionsMatchingLog.log('Matrix override match ' + targetObject + ' ' + matrixMatchDefaultMatch);
                        wrapper.addFactorMatchedValue(matchingRules[i], matrixMatchOverRide.get(overRideSearchKey));
                        continue;
                    }

                    // No Direct match then we search for match in returned records
                    List<SObject> factorsFound = handleBaseEmissionsSearching(targetObject, wrapper.quickSearchHashes[i]);

                    String matchedFactor;
                    NZC_EmissionsMatchingLog.log('factors found ' + factorsFound.size() + ' ' + targetObject);
                    // no record found
                    if (factorsFound.size() > 0) {
                        matchedFactor = (String) factorsFound[0].get('Id');
                        // second level matching on matched record and second level field has a value
                        String secondLevelValue = wrapper.getSecondaryMatchValue(matchingRules[i]);
                        NZC_EmissionsMatchingLog.log(secondLevelValue + ' secondary value ' + matchingRules[i].SecondaryMatchFieldTarget__c);
                        if (String.isNotBlank(matchingRules[i].SecondaryMatchFieldTarget__c) && String.isNotBlank(secondLevelValue)) {
                            matchedFactor = null;
                            matchedFactor = handleSecondLevelSearch(secondLevelValue, matchingRules[i].SecondaryMatchFieldTarget__c, factorsFound);
                        }
                    }

                    // attach a default if still nothing is matched
                    if (matchedFactor == null) matchedFactor = attachDefaultMatrixRecord(wrapper, matchingRules[i],targetObject);

                    wrapper.addFactorMatchedValue(matchingRules[i], matchedFactor);
                }
            }
        }
    }

    private String attachDefaultMatrixRecord(NZC_EmissionsMatchingAdvancedMatchWpr wrapper, NZC_EmissionsMatchingAdvanceMatch__mdt matchingRule, String emissionsObjectName) {
        NZC_EmissionsMatchingLog.log('providing default factor from matrix ' + emissionsObjectName);
        String defaultedFactor = matrixMatchDefaultMatch.get(emissionsObjectName);
        wrapper.addFactorMatchedValue(matchingRule, defaultedFactor);
        return defaultedFactor;
    }

    private List<SObject> handleBaseEmissionsSearching(String objectName, String currentHash) {
        List<SObject> factorsFound = new List<SObject>();
        String searchHash;
        NZC_EmissionsMatchingLog.log('searching factors');

        // search with base hash key
        searchHash = '' + NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectName, currentHash});
        if (factorFinderHelper.containsKey(searchHash)) factorsFound = factorFinderHelper.get(searchHash);

        // search with object + hash key alias
        String objectHashSearch = NZC_EmissionsMatchingUtil.hashListOfStrings(new List<String>{ objectName, currentHash });
        if (matrixAliases.containsKey(objectHashSearch)) {
            NZC_EmissionsMatchingLog.log('searching Object alias factors');
            searchHash = '' + NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectName, matrixAliases.get(objectHashSearch)});
            if (factorFinderHelper.containsKey(searchHash)) factorsFound = factorFinderHelper.get(searchHash);
        }

        return factorsFound;
    }

    private String handleSecondLevelSearch(String valueToCompare, String fieldToLook, List<SObject> emissionsFactors) {
        NZC_EmissionsMatchingLog.log('Trying second level match');
        if (String.isBlank(valueToCompare) || String.isBlank(fieldToLook)) return null;
        for (SObject record : emissionsFactors) {
            NZC_EmissionsMatchingLog.log('Matching');
            String emissionsRecordValue = record.get(fieldToLook) + '';
            if (emissionsRecordValue.contains(valueToCompare)) return (String) record.get('Id');
        }
        NZC_EmissionsMatchingLog.log('No match');
        return null;
    }

    private void processUpdates() {
        NZC_EmissionsMatchingLog.log('Updating records');
        for (NZC_EmissionsMatchingAdvancedMatchWpr wrapper : matchWrappers) {
            List<NZC_EmissionsMatchingAdvanceMatch__mdt> matchingRules = NZC_EmissionsMatchingMTD.advancedMatchingRules.get(wrapper.objectType);
            for (Integer i = 0; i < matchingRules.size()
                    && i < wrapper.quickSearchHashes.size()
                    && i < wrapper.updateScreening.size(); i++) {
                if (String.isNotBlank(matchingRules[i].Hash_Destination__c) && wrapper.updateScreening[i]) {
                    NZC_EmissionsMatchingLog.log('Saving hash ' + matchingRules[i].Hash_Destination__c + ' ' + wrapper.quickSearchHashes[i]);
                    // save hash
                    wrapper.updateOriginalRecord(matchingRules[i].Hash_Destination__c, wrapper.quickSearchHashes[i]);
                    // remove record flag
                    wrapper.updateOriginalRecord(matchingRules[i].ScreeningField__c, false);
                }

                if (String.isNotBlank(matchingRules[i].LookupToPopulate__c) && wrapper.updateScreening[i]) {
                    NZC_EmissionsMatchingLog.log('Saving lookup ' + matchingRules[i].LookupToPopulate__c + ' '
                            + wrapper.factorMatched.get(matchingRules[i].LookupToPopulate__c));
                    // save lookup
                    wrapper.updateOriginalRecord(matchingRules[i].LookupToPopulate__c, wrapper.factorMatched.get(matchingRules[i].LookupToPopulate__c));
                    // remove record flag
                    wrapper.updateOriginalRecord(matchingRules[i].ScreeningField__c, false);
                }
            }
        }

        //do update
        if (doUpdateRecords) {
            update originalRecords;
        }
    }

}