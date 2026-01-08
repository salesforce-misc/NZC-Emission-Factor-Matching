/*
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
    public Boolean requiresSecondaryLookup;

    public Date dateToMatch;
    // primary lookup for object
    public String masterEmissionsSetId;
    // secondary lookup ( typically market based electricity lookup )
    public String secondaryEmissionsSetId;

    // factor we match with
    public String matchedId;
    // secondary factor we match with
    public String secondaryMatchedId;
    public String customMatchingValue;

    public NZC_EmissionsMatchingWrapper(String assetId, String energyUseRecordId, Date dateToMatch, String fuelType) {
        // used for all contexts outside of before record insert
        this(assetId, energyUseRecordId, dateToMatch, fuelType, getObjectTypeFromId(energyUseRecordId));
    }

    public NZC_EmissionsMatchingWrapper(String assetId, String energyUseRecordId, Date dateToMatch, String fuelType, String objectType) {
        // used for before insert because of lack of Record Id
        this.assetId = assetId;
        this.energyUseRecordId = energyUseRecordId;// this is a temp generated Id just for linking updates back to a record
        this.dateToMatch = dateToMatch;
        this.fuelType = fuelType;
        this.objectName = objectType;
        this.requiresSecondaryLookup = objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE
                && fuelType == NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY;
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
        SObject recordUpdate = Schema.getGlobalDescribe().get(objectName).newSObject();
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
        return defaultFieldName;
    }

    public String getSecondaryLookupName() {
        // primarily used to get market based lookup name, can be used for future functionality
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE && fuelType == NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY) {
            return NZC_EmissionsMatchingConstants.FIELD_STATIONARY_ASSET_MARKETBASED_ELECTRIC_EMISSIONS;
        }
        return null;
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

    public String getSecondaryEnergyUseLookupFieldName() {
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE && fuelType == NZC_EmissionsMatchingConstants.FUEL_TYPE_ELECTRICITY) {
            return NZC_EmissionsMatchingConstants.FIELD_EUR_MARKETBASED_ELECTRIC_EMISSIONS;
        }
        return null;
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