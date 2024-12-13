/**
 * Created by mverigin on 6/26/23.
 */

public with sharing class NZC_EmissionsSetRecalcEngine {

    private final Map<String, Set<Id>> objectNameToSetIdMap;
    private final List<SObject> recordsToUpdate;
    private final List<SObject> emissionsSetsPassedIn;
    private final Boolean doUpdateEmissionsSets;

    public NZC_EmissionsSetRecalcEngine() {
        this(false);
    }

    public NZC_EmissionsSetRecalcEngine(Boolean incomingDoUpdateEmissionsSets) {
        objectNameToSetIdMap = new Map<String, Set<Id>>();
        recordsToUpdate = new List<SObject>();
        emissionsSetsPassedIn = new List<SObject>();
        this.doUpdateEmissionsSets = incomingDoUpdateEmissionsSets;
    }

    public void loadSetIds(List<SObject> emissionSets) {
        NZC_EmissionsMatchingLog.log('Loading Sets');
        emissionsSetsPassedIn.addAll(emissionSets);
        for (SObject emissionSet : emissionSets) {
            if (!((Boolean) emissionSet.get(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD))) {
                continue;
            }

            String objectName = String.valueOf(emissionSet.getSObjectType());
            if (!objectNameToSetIdMap.containsKey(objectName)) {
                objectNameToSetIdMap.put(objectName, new Set<Id>());
            }
            objectNameToSetIdMap.get(objectName).add(emissionSet.Id);
        }
        NZC_EmissionsMatchingLog.log('Amount of sets', objectNameToSetIdMap.size());
        NZC_EmissionsMatchingLog.log('Name of sets', objectNameToSetIdMap.keySet());
    }

    public void processRecords() {
        NZC_EmissionsMatchingLog.log('Starting processing');
        queryRelatedRecords();
        updateEnergyRecordsWithFlag();
        updateEmissionsRecordsWithFlag();
        NZC_EmissionsMatchingLog.log('Process completed');
    }

    private void queryRelatedRecords() {
        for (String objectName : objectNameToSetIdMap.keySet()) {
            // 4 potential options
            Boolean defaultMatch = true;
            if (objectName == NZC_EmissionsMatchingConstants.OBJECT_ELECTRICITY_SET || objectName == NZC_EmissionsMatchingConstants.OBJECT_REFRIGERANT_SET) {
                defaultMatch = false;
                getStationaryRecords(objectName);
            }

            if (objectName == NZC_EmissionsMatchingConstants.OBJECT_WASTE_SET) {
                defaultMatch = false;
                getWasteRecords();
            }

            if (objectName == NZC_EmissionsMatchingConstants.OBJECT_HOTEL_SET) {
                defaultMatch = false;
                getHotelRecords();
            }

            if (defaultMatch) {
                getVehicleRecords();
                getStationaryRecords(objectName);
            }
        }
    }

    private void updateEnergyRecordsWithFlag() {
        //TODO verify DML limits before starting
        NZC_EmissionsMatchingLog.log('Updating energy flags', recordsToUpdate.size());
        for (SObject record : recordsToUpdate) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, true);
        }

        NZC_EmissionsMatchingLog.log('DML start');
        update recordsToUpdate;
        NZC_EmissionsMatchingLog.log('DML complete');
    }

    private void updateEmissionsRecordsWithFlag() {
        NZC_EmissionsMatchingLog.log('Updating emissions flags', recordsToUpdate.size());
        for (SObject record : emissionsSetsPassedIn) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, false);
        }

        if (doUpdateEmissionsSets) {
            NZC_EmissionsMatchingLog.log('DML start');
            update emissionsSetsPassedIn;
            NZC_EmissionsMatchingLog.log('DML complete');
        }
    }

    private void getWasteRecords() {
        NZC_EmissionsMatchingLog.log('getting waste');
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_WASTE_SET);

        recordsToUpdate.addAll([
                SELECT Id
                FROM GeneratedWaste
                WHERE WstDispoEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getStationaryRecords(String objectName) {
        NZC_EmissionsMatchingLog.log('getting Station ' + objectName);
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(objectName);
        String lookupFieldName = NZC_EmissionsMatchingConstants.EMISSIONS_SET_EMISSIONS_LOOKUP_FIELDNAME_MAP.get(objectName);

        String query = 'SELECT Id FROM StnryAssetEnrgyUse WHERE ' + lookupFieldName + ' IN :emissionsMatchingSet';

        recordsToUpdate.addAll(Database.query(query));
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getVehicleRecords() {
        NZC_EmissionsMatchingLog.log('getting Vehicle');
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET);

        recordsToUpdate.addAll([
                SELECT Id
                FROM VehicleAssetEnrgyUse
                WHERE OtherEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getHotelRecords() {
        NZC_EmissionsMatchingLog.log('getting hotel');
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_SET);

        recordsToUpdate.addAll([
                SELECT Id
                FROM HotelStayEnrgyUse
                WHERE HotelStayEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }
}