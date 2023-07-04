/**
 * Created by mverigin on 6/16/23.
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

    public NZC_EmissionsMatchingEngine() {
        masterSetAssetObjectTypeAndFieldsMap = new Map<String, Set<String>>();
        matchTargets = new List<NZC_EmissionsMatchingWrapper>();
        assetIdsSet = new Set<String>();
        emissionsSetObjectNames = new Set<String>();
        masterEmissionsSetIdsByAssetHash = new Map<Integer, String>();
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
        loadAssetDataExtractMasterSetIds();

        attachMasterEmissionsSetToWrapper();

        getDateSortedEmissionFactorSets();

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
    }

    private void loadAssetDataExtractMasterSetIds() {
        NZC_EmissionsMatchingLog.log('query assets with ', masterSetAssetObjectTypeAndFieldsMap);
        for (String objectName : masterSetAssetObjectTypeAndFieldsMap.keySet()) {
            // for each asset type ( 2 possibilities )
            String query = 'SELECT Id, ' + String.join(new List<String>(masterSetAssetObjectTypeAndFieldsMap.get(objectName)), ',')
                    + ' FROM ' + objectName+ ' WHERE Id IN:assetIdsSet';
            for (SObject returnedAsset : Database.query(query)) {
                NZC_EmissionsMatchingLog.log(returnedAsset);
                for (String fieldName : masterSetAssetObjectTypeAndFieldsMap.get(objectName)) {
                    // extract each emissions field ( 3 possibilities )
                    if (returnedAsset.get(fieldName) != null) {
                        Integer hashKey = (returnedAsset.Id + fieldName).hashCode();
                        masterEmissionsSetIdsByAssetHash.put(hashKey, (String) returnedAsset.get(fieldName));
                        emissionsSetObjectNames.add(((Id) returnedAsset.get(fieldName)).getSobjectType() + '');
                    }
                }
            }
        }
        NZC_EmissionsMatchingLog.log('emissions set by hash', masterEmissionsSetIdsByAssetHash);
    }

    private void attachMasterEmissionsSetToWrapper() {
        for (NZC_EmissionsMatchingWrapper wrapper : matchTargets) {
            Integer hashKey = (wrapper.assetId + wrapper.getObjectAssetLookupFieldName()).hashCode();
            wrapper.masterEmissionsSetId = masterEmissionsSetIdsByAssetHash.get(hashKey);
        }
    }

    private void getDateSortedEmissionFactorSets() {
        dateSortedEmissionsSetsMap = new Map<String, List<SObject>>();
        NZC_EmissionsMatchingLog.log('get date sorted sets', emissionsSetObjectNames);
        Set<String> masterEmissionsSetIds = new Set<String>(masterEmissionsSetIdsByAssetHash.values());
        for (String objectName : emissionsSetObjectNames) {
            String currentQuery = 'SELECT Id, EmissionsFactorUpdateYear__c, MasterEmissionsSet__c FROM ' + objectName
                    +' WHERE EmissionsFactorUpdateYear__c != NULL' +
                    ' AND MasterEmissionsSet__c IN: masterEmissionsSetIds' +
                    ' ORDER BY EmissionsFactorUpdateYear__c ASC';

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