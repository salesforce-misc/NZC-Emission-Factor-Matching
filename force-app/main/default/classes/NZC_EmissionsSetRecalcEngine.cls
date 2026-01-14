/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
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
        if (recordsToUpdate.isEmpty()) {
            return;
        }
        
        // Check CRUD permissions before DML - check first record's object type
        String objectName = String.valueOf(recordsToUpdate[0].getSObjectType());
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        if (sObjectType == null) {
            NZC_EmissionsMatchingLog.log('Object type not found: ' + objectName);
            return;
        }
        // Cache describe result to avoid eager loading of all child relationships
        Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
        // Explicit CRUD permission check before DML operation
        if (!objectDescribe.isUpdateable()) {
            NZC_EmissionsMatchingLog.log('User does not have update permission for: ' + objectName);
            return;
        }
        
        for (SObject record : recordsToUpdate) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, true);
        }

        NZC_EmissionsMatchingLog.log('DML start');
        // CRUD permission validated above, safe to perform DML
        Database.update(recordsToUpdate, false);
        NZC_EmissionsMatchingLog.log('DML complete');
    }

    private void updateEmissionsRecordsWithFlag() {
        NZC_EmissionsMatchingLog.log('Updating emissions flags', recordsToUpdate.size());
        for (SObject record : emissionsSetsPassedIn) {
            record.put(NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD, false);
        }

        if (doUpdateEmissionsSets && !emissionsSetsPassedIn.isEmpty()) {
            // Check CRUD permissions before DML - check first record's object type
            String objectName = String.valueOf(emissionsSetsPassedIn[0].getSObjectType());
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            if (sObjectType == null) {
                NZC_EmissionsMatchingLog.log('Object type not found: ' + objectName);
                return;
            }
            // Cache describe result to avoid eager loading of all child relationships
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            // Explicit CRUD permission check before DML operation
            if (!objectDescribe.isUpdateable()) {
                NZC_EmissionsMatchingLog.log('User does not have update permission for: ' + objectName);
                return;
            }
            
            NZC_EmissionsMatchingLog.log('DML start');
            // CRUD permission validated above, safe to perform DML
            Database.update(emissionsSetsPassedIn, false);
            NZC_EmissionsMatchingLog.log('DML complete');
        }
    }

    private void getWasteRecords() {
        NZC_EmissionsMatchingLog.log('getting waste');
        // Check CRUD permissions before query
        if (!Schema.sObjectType.GeneratedWaste.isAccessible()) {
            NZC_EmissionsMatchingLog.log('User does not have access to GeneratedWaste');
            return;
        }
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_WASTE_SET);

        // Note: WITH USER_MODE is not supported in static SOQL, CRUD check above ensures permissions
        recordsToUpdate.addAll([
                SELECT Id
                FROM GeneratedWaste
                WHERE WstDispoEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getStationaryRecords(String objectName) {
        NZC_EmissionsMatchingLog.log('getting Station ' + objectName);
        // Check CRUD permissions before query
        if (!Schema.sObjectType.StnryAssetEnrgyUse.isAccessible()) {
            NZC_EmissionsMatchingLog.log('User does not have access to StnryAssetEnrgyUse');
            return;
        }
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(objectName);
        String lookupFieldName = NZC_EmissionsMatchingConstants.EMISSIONS_SET_EMISSIONS_LOOKUP_FIELDNAME_MAP.get(objectName);

        // Validate field name to prevent SOQL injection
        if (String.isBlank(lookupFieldName) || !validateFieldName('StnryAssetEnrgyUse', lookupFieldName)) {
            NZC_EmissionsMatchingLog.log('Invalid field name: ' + lookupFieldName);
            return;
        }

        // Field name validated via validateFieldName(), object name is hardcoded constant 'StnryAssetEnrgyUse'
        // Bind variable :emissionsMatchingSet prevents injection
        // WITH USER_MODE enforces user permissions, CRUD check above ensures accessibility
        String query = 'SELECT Id FROM StnryAssetEnrgyUse WHERE ' + lookupFieldName + ' IN :emissionsMatchingSet WITH USER_MODE';

        recordsToUpdate.addAll(Database.query(query));
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getVehicleRecords() {
        NZC_EmissionsMatchingLog.log('getting Vehicle');
        // Check CRUD permissions before query
        if (!Schema.sObjectType.VehicleAssetEnrgyUse.isAccessible()) {
            NZC_EmissionsMatchingLog.log('User does not have access to VehicleAssetEnrgyUse');
            return;
        }
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET);

        // Note: WITH USER_MODE is not supported in static SOQL, CRUD check above ensures permissions
        recordsToUpdate.addAll([
                SELECT Id
                FROM VehicleAssetEnrgyUse
                WHERE OtherEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    private void getHotelRecords() {
        NZC_EmissionsMatchingLog.log('getting hotel');
        // Check CRUD permissions before query
        if (!Schema.sObjectType.HotelStayEnrgyUse.isAccessible()) {
            NZC_EmissionsMatchingLog.log('User does not have access to HotelStayEnrgyUse');
            return;
        }
        Set<Id> emissionsMatchingSet = objectNameToSetIdMap.get(NZC_EmissionsMatchingConstants.OBJECT_HOTEL_SET);

        // Note: WITH USER_MODE is not supported in static SOQL, CRUD check above ensures permissions
        recordsToUpdate.addAll([
                SELECT Id
                FROM HotelStayEnrgyUse
                WHERE HotelStayEmssnFctrId IN : emissionsMatchingSet
        ]);
        NZC_EmissionsMatchingLog.log('retrieved');
    }

    /**
     * Validates that a field name exists on an SObject to prevent SOQL injection
     * @param objectName The object name to check
     * @param fieldName The field name to validate
     * @return true if the field name is valid, false otherwise
     */
    private Boolean validateFieldName(String objectName, String fieldName) {
        if (String.isBlank(objectName) || String.isBlank(fieldName)) {
            return false;
        }
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            if (sObjectType == null) {
                return false;
            }
            // Cache describe result to avoid eager loading of all child relationships
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Schema.SObjectField field = objectDescribe.fields.getMap().get(fieldName);
            return field != null;
        } catch (Exception e) {
            NZC_EmissionsMatchingLog.log('Error validating field name: ' + fieldName + ' on object: ' + objectName, e.getMessage());
            return false;
        }
    }
}