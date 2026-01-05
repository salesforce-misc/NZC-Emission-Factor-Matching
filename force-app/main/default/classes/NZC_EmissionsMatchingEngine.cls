/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

public with sharing class NZC_EmissionsMatchingEngine {

    // Asset object to query
    private final Map<String, Set<String>> masterSetAssetObjectTypeAndFieldsMap;
    // targeted records to date match
    private final List<NZC_EmissionsMatchingWrapper> matchTargets;
    // asset Ids to query for master emissions set Ids
    private final Set<String> assetIdsSet;
    // objects we need to query for emissions sets
    private final Set<String> emissionsSetObjectNames;
    // master Set ids we need to look for child records for
    private final Map<Integer, String> masterEmissionsSetIdsByAssetHash;
    // sorted emissions date ranges by Master set Id => List<child emissions sets date ordered>
    private Map<String, List<SObject>> dateSortedEmissionsSetsMap;

    // custom matching values on EUR to try find ( example value would be country code or ZIP code )
    private final Set<String> customMatchingKeys;
    // used to keep track of what emissions objects we need to query for custom key matching and the hash keys to link it to custom MTD
    private final Map<String, Set<Integer>> customMatchingEmissionsObjectNames;
    // used for custom key matching emissions sets
    private final Map<Integer, String> customMatchingKeyToMasterSetIdMap;

    public NZC_EmissionsMatchingEngine() {
        masterSetAssetObjectTypeAndFieldsMap = new Map<String, Set<String>>();
        matchTargets = new List<NZC_EmissionsMatchingWrapper>();
        assetIdsSet = new Set<String>();
        emissionsSetObjectNames = new Set<String>();
        masterEmissionsSetIdsByAssetHash = new Map<Integer, String>();
        customMatchingKeys = new Set<String>();
        customMatchingEmissionsObjectNames = new Map<String, Set<Integer>>();
        customMatchingKeyToMasterSetIdMap = new Map<Integer, String>();
        NZC_EmissionsMatchingLog.log('starting engine');
    }

    public void loadMatchTargets(List<NZC_EmissionsMatchingWrapper> matchingWrappers) {
        matchTargets.addAll(matchingWrappers);
        NZC_EmissionsMatchingLog.log('loading targets', matchingWrappers.size());

        for (NZC_EmissionsMatchingWrapper matchWrapper : matchingWrappers) {
            extractRequiredInfoFromLoadedWrapper(matchWrapper);
        }
    }

    public void process() {
        // get each master emissions set from asset and add to hashmap of assetId + field name : masterSetId
        loadAssetDataExtractMasterSetIds();

        // if custom key matching is present load get the master set Ids
        getCustomMatchingMasterSets();

        // add master set to each record
        attachMasterEmissionsSetToWrapper();

        // gets all emissions sets date ordered from loadAssetDataExtractMasterSetIds master Set ids
        getDateSortedEmissionFactorSets();

        // uses master set Id connected to wrapper to find a closer date match if possible
        matchClosestEmission();
    }

    public void attachUpdatesToExistingRecord(Map<String, SObject> recordsMap) {
        NZC_EmissionsMatchingLog.log('attach updates', matchTargets.size());
        for (NZC_EmissionsMatchingWrapper wrapper : matchTargets) {
            if (recordsMap.containsKey(wrapper.energyUseRecordId)) {
                recordsMap.get(wrapper.energyUseRecordId).put(wrapper.getEnergyUseLookupFieldName(), wrapper.matchedId);
            }
        }
    }

    private void extractRequiredInfoFromLoadedWrapper(NZC_EmissionsMatchingWrapper matchWrapper) {
        if (matchWrapper.assetId != null) {
            assetIdsSet.add(matchWrapper.assetId);
        }

        if (String.isNotBlank(matchWrapper.objectName)) {
            if (!masterSetAssetObjectTypeAndFieldsMap.containsKey(matchWrapper.getParentAssetObjName())) {
                masterSetAssetObjectTypeAndFieldsMap.put(matchWrapper.getParentAssetObjName(), new Set<String>());
            }

            masterSetAssetObjectTypeAndFieldsMap.get(matchWrapper.getParentAssetObjName()).add(matchWrapper.getObjectAssetLookupFieldName());
        }

        if (String.isNotBlank(matchWrapper.customMatchingValue)) {
            if (!customMatchingEmissionsObjectNames.containsKey(matchWrapper.getEmissionsFactorObjectName())) {
                customMatchingEmissionsObjectNames.put(matchWrapper.getEmissionsFactorObjectName(), new Set<Integer>());
            }

            customMatchingKeys.add(matchWrapper.customMatchingValue);

            customMatchingEmissionsObjectNames.get(matchWrapper.getEmissionsFactorObjectName()).add(
                    NZC_EmissionsMatchingUtil.createHashKey(
                            new List<String>{matchWrapper.objectName, matchWrapper.fuelType
            }));
        }
    }

    private void loadAssetDataExtractMasterSetIds() {
        // queries required assets and pulls emissions set Ids from lookup fields required
        // example {"StnryAssetEnvrSrc" : [ "WstDispoEmssnFctrSetId", "RefrigerantEmssnFctrId", "ElectricityEmssnFctrId", "OtherEmssnFctrId" ]}
        NZC_EmissionsMatchingLog.log('query assets with ', masterSetAssetObjectTypeAndFieldsMap);
        for (String objectName : masterSetAssetObjectTypeAndFieldsMap.keySet()) {
            String query = 'SELECT Id, ' + String.join(new List<String>(masterSetAssetObjectTypeAndFieldsMap.get(objectName)), ',')
                    + ' FROM ' + objectName+ ' WHERE Id IN:assetIdsSet';
            for (SObject returnedAsset : Database.query(query)) {
                NZC_EmissionsMatchingLog.log(returnedAsset);
                for (String fieldName : masterSetAssetObjectTypeAndFieldsMap.get(objectName)) {
                    if (returnedAsset.get(fieldName) != null) {
                        Integer hashKey = NZC_EmissionsMatchingUtil.createHashKey(returnedAsset.Id, fieldName);
                        // grab each emissions Id from asset
                        masterEmissionsSetIdsByAssetHash.put(hashKey, (String) returnedAsset.get(fieldName));
                        // get name of emissions set object
                        emissionsSetObjectNames.add(((Id) returnedAsset.get(fieldName)).getSobjectType() + '');
                    }
                }
            }
        }
        NZC_EmissionsMatchingLog.log('emissions set by hash', masterEmissionsSetIdsByAssetHash);
    }

    private void getCustomMatchingMasterSets() {
        if (customMatchingEmissionsObjectNames.isEmpty()) return;
        NZC_EmissionsMatchingLog.log('custom matching by field key object names:', customMatchingEmissionsObjectNames.keySet());
        Set<String> customMatchValues = customMatchingKeys;

        for (String objectName : customMatchingEmissionsObjectNames.keySet()) {
            List<String> fieldsNeeded = new List<String>();
            List<String> whereClauses = new List<String>();
            for (Integer hashKey : customMatchingEmissionsObjectNames.get(objectName)) {
                // get fields needed from custom MTD
                fieldsNeeded.add(NZC_EmissionsMatchingMTD.customMatchingRules.get(hashKey).EmissionsSetFieldToMatch__c);
                whereClauses.add(NZC_EmissionsMatchingMTD.customMatchingRules.get(hashKey).EmissionsSetFieldToMatch__c + ' IN: customMatchValues');
            }
            String query = 'SELECT Id, ' +
                    String.join(fieldsNeeded, ',') + ' FROM ' + objectName+ ' WHERE ' +
                    String.join(whereClauses, ' OR') + ' AND MasterEmissionsSet__c = NULL';
            for (SObject emissionSetQueried : Database.query(query)) {
                // for later query we add emissions set to assetId emissionId map for date matching
                masterEmissionsSetIdsByAssetHash.put(
                        NZC_EmissionsMatchingUtil.createHashKey(new List<String>{emissionSetQueried.Id}),
                        emissionSetQueried.Id);
                for (String field : fieldsNeeded) {
                    String recordsValue = (String) emissionSetQueried.get(field);
                    if (String.isNotBlank(recordsValue)) {
                        // store emissions sets by object by field value : emission set Id
                        customMatchingKeyToMasterSetIdMap.put(
                                NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectName, recordsValue}),
                                emissionSetQueried.Id
                                );
                    }
                }

            }
            NZC_EmissionsMatchingLog.log('custom key emissions matched ',customMatchingKeyToMasterSetIdMap);
        }
    }

    private void attachMasterEmissionsSetToWrapper() {
        NZC_EmissionsMatchingLog.log('attaching master set to wrapper');
        for (NZC_EmissionsMatchingWrapper wrapper : matchTargets) {
            Integer hashKey = NZC_EmissionsMatchingUtil.createHashKey(wrapper.assetId, wrapper.getObjectAssetLookupFieldName());
            wrapper.masterEmissionsSetId = masterEmissionsSetIdsByAssetHash.get(hashKey);
            wrapper.matchedId = wrapper.masterEmissionsSetId;
            if (wrapper.doesUseCustomEmissionsMatching()) {
                NZC_EmissionsMatchingLog.log('custom key match used', wrapper.customMatchingValue);
                Integer customKeyMatchingHash = NZC_EmissionsMatchingUtil.createHashKey(new List<String>{
                        wrapper.getEmissionsFactorObjectName(), wrapper.customMatchingValue
                });
                if (customMatchingKeyToMasterSetIdMap.containsKey(customKeyMatchingHash)) {
                    wrapper.masterEmissionsSetId = customMatchingKeyToMasterSetIdMap.get(customKeyMatchingHash);
                    // add key as matched Id. if a better date match is found later it will overwrite this
                    wrapper.matchedId = wrapper.masterEmissionsSetId;
                    NZC_EmissionsMatchingLog.log('custom key match added', wrapper.matchedId);
                }
            }
        }
    }

    private void getDateSortedEmissionFactorSets() {
        dateSortedEmissionsSetsMap = new Map<String, List<SObject>>();
        NZC_EmissionsMatchingLog.log('get date sorted sets', emissionsSetObjectNames);
        // example value of emissionsSetObjectNames values [ "WstDispoEmssnFctrSet", "RefrigerantEmssnFctr", "ElectricityEmssnFctrSet", "OtherEmssnFctrSet" ]
        Set<String> masterEmissionsSetIds = new Set<String>(masterEmissionsSetIdsByAssetHash.values());
        for (String objectName : emissionsSetObjectNames) {
            String currentQuery = 'SELECT Id, EmissionsFactorUpdateYear__c, MasterEmissionsSet__c FROM ' + objectName
                    +' WHERE EmissionsFactorUpdateYear__c != NULL' +
                    ' AND MasterEmissionsSet__c IN: masterEmissionsSetIds' +
                    ' ORDER BY EmissionsFactorUpdateYear__c ASC, CreatedDate ASC';

            for (SObject emissionsSet : Database.query(currentQuery)) {
                if (!dateSortedEmissionsSetsMap.containsKey((String) emissionsSet.get('MasterEmissionsSet__c'))) {
                    dateSortedEmissionsSetsMap.put((String) emissionsSet.get('MasterEmissionsSet__c'), new List<SObject>());
                }
                dateSortedEmissionsSetsMap.get((String) emissionsSet.get('MasterEmissionsSet__c')).add(emissionsSet);
            }
        }
        NZC_EmissionsMatchingLog.log('got sets', dateSortedEmissionsSetsMap);
    }

    private void matchClosestEmission() {
        for (NZC_EmissionsMatchingWrapper emissionsWrapper : matchTargets) {
            matchClosestEmission(emissionsWrapper);
        }
    }

    private void matchClosestEmission(NZC_EmissionsMatchingWrapper emissionsWrapper) {
        Boolean canStart = emissionsWrapper.dateToMatch != null
                && emissionsWrapper.masterEmissionsSetId != null
                && dateSortedEmissionsSetsMap.containsKey(emissionsWrapper.masterEmissionsSetId);
        NZC_EmissionsMatchingLog.log('can start date matching', canStart);
        if (canStart) {
            List<SObject> dateSortedList = dateSortedEmissionsSetsMap.get(emissionsWrapper.masterEmissionsSetId);
            emissionsWrapper.matchedId = matchingLogic(emissionsWrapper.masterEmissionsSetId, emissionsWrapper.dateToMatch, dateSortedList);
        }
    }

    @TestVisible
    private static String matchingLogic(String currentMatchingId, Date matchDate, List<SObject> dateSortedList) {
        Integer startIdx = 0;
        Integer endIdx = dateSortedList.size() - 1;

        while (startIdx <= endIdx) {
            Integer mid = (endIdx + startIdx)/2;
            NZC_EmissionsMatchingLog.log(String.valueOf((dateSortedList.get(mid) + ' ' + matchDate)));
            if ((Date) dateSortedList.get(mid).get('EmissionsFactorUpdateYear__c') > matchDate) {
                // go left
                NZC_EmissionsMatchingLog.log('back in time farther');
                endIdx = mid - 1;
            } else {
                // go right
                NZC_EmissionsMatchingLog.log('new match');
                currentMatchingId = (String) dateSortedList.get(mid).get('Id');
                startIdx = mid + 1;
            }
        }

        return currentMatchingId;
    }
}