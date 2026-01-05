/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

public with sharing virtual class NZC_EmissionsMatchingWrapper {

    public String assetId;
    public String energyUseRecordId;
    public String objectName;
    public String fuelType;

    public Date dateToMatch;
    public String masterEmissionsSetId;

    public String matchedId;
    public String customMatchingValue;

    public NZC_EmissionsMatchingWrapper(String assetId, String energyUseRecordId, Date dateToMatch, String fuelType) {
        // used for all contexts outside of before record insert
        this.assetId = assetId;
        this.energyUseRecordId = energyUseRecordId;
        this.dateToMatch = dateToMatch;
        this.fuelType = fuelType;
        this.objectName = getObjectTypeFromId(energyUseRecordId);
    }

    public NZC_EmissionsMatchingWrapper(String assetId, String generatedId, Date dateToMatch, String fuelType, String objectType) {
        // used for record insert because of lack of Record Id
        this.assetId = assetId;
        this.energyUseRecordId = generatedId;// this is a temp generated Id just for linking updates back to a record
        this.dateToMatch = dateToMatch;
        this.fuelType = fuelType;
        this.objectName = objectType;
    }

    public Boolean doesUseCustomEmissionsMatching() {
        return NZC_EmissionsMatchingMTD.customMatchingRules.containsKey(NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectName, fuelType}));
    }

    public void attachCustomMatchingField(SObject energyRecord) {
        if (NZC_EmissionsMatchingMTD.allowCustomTagMatching && doesUseCustomEmissionsMatching()) {
            String matchField = NZC_EmissionsMatchingMTD.customMatchingRules.get(NZC_EmissionsMatchingUtil.createHashKey(new List<String>{objectName, fuelType})).EnergyUseFieldToMatch__c;
            customMatchingValue = (String) energyRecord.get(matchField);
        }
    }

    public void attachMasterEmissionSetId(String masterEmissionSetId) {
        this.masterEmissionsSetId = masterEmissionSetId;
    }

    public SObject createRecordUpdate() {
        SObject recordUpdate = NZC_EmissionsMatchingUtil.globalDescribe.get(objectName).newSObject();
        recordUpdate.put('Id', energyUseRecordId);

        recordUpdate.put(getEnergyUseLookupFieldName(), matchedId);

        return recordUpdate;
    }

    public String getParentAssetObjName() {
        return NZC_EmissionsMatchingConstants.EUR_ASSET_OBJ_LOOKUP.get(objectName);
    }

    public String getObjectAssetLookupFieldName() {
        String defaultFieldName = NZC_EmissionsMatchingConstants.FIELD_OTHER_ASSET_EMISSIONS;

        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE && NZC_EmissionsMatchingConstants.ASSET_FUEL_SPECIFIC_FIELDS_MAP.get(fuelType) != null) {
            defaultFieldName = NZC_EmissionsMatchingConstants.ASSET_FUEL_SPECIFIC_FIELDS_MAP.get(fuelType);
        }

        if (NZC_EmissionsMatchingConstants.ASSET_OBJECT_SPECIFIC_FIELDS_MAP.containsKey(objectName)) {
            defaultFieldName = NZC_EmissionsMatchingConstants.ASSET_OBJECT_SPECIFIC_FIELDS_MAP.get(objectName);
        }

        if (NZC_EmissionsMatchingMTD.customLookupRules.containsKey(NZC_EmissionsMatchingUtil.createHashKey(objectName, fuelType))) {
            // using custom lookup
            System.debug('looking for custom lookup');
            defaultFieldName = NZC_EmissionsMatchingMTD.customLookupRules.get(NZC_EmissionsMatchingUtil.createHashKey(objectName, fuelType));
        }

        return defaultFieldName;
    }

    public String getEnergyUseLookupFieldName() {
        String defaultFieldName = NZC_EmissionsMatchingConstants.FIELD_EUR_OTHER_EMISSIONS;

        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE && NZC_EmissionsMatchingConstants.EUR_FUEL_SPECIFIC_FIELDS_MAP.get(fuelType) != null) {
            defaultFieldName = NZC_EmissionsMatchingConstants.EUR_FUEL_SPECIFIC_FIELDS_MAP.get(fuelType);
        }

        if (NZC_EmissionsMatchingConstants.EUR_OBJECT_SPECIFIC_FIELDS_MAP.containsKey(objectName)) {
            defaultFieldName = NZC_EmissionsMatchingConstants.EUR_OBJECT_SPECIFIC_FIELDS_MAP.get(objectName);
        }

        return defaultFieldName;
    }

    public String getEmissionsFactorObjectName() {
        String defaultFieldName = NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET;

        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE && NZC_EmissionsMatchingConstants.ENERGY_USE_EMISSIONS_SET_NAME_MAP.get(fuelType) != null) {
            defaultFieldName = NZC_EmissionsMatchingConstants.ENERGY_USE_EMISSIONS_SET_NAME_MAP.get(fuelType);
        }

        if (NZC_EmissionsMatchingConstants.EUR_OBJECT_EMISSIONS_SET_NAME_MAP.containsKey(objectName)) {
            defaultFieldName = NZC_EmissionsMatchingConstants.EUR_OBJECT_EMISSIONS_SET_NAME_MAP.get(objectName);
        }

        return defaultFieldName;
    }

    private static String getObjectTypeFromId(String recordId) {
        if (String.isNotBlank(recordId)) {
            return ((Id)recordId).getSobjectType() + '';
        }
        return null;
    }
}