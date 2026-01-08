/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

public with sharing class NZC_EmissionsMatchingUtil {

    public static String createHashKey(String assetId, String fieldName) {
        return createHashKey(new List<String>{assetId, fieldName});
    }

    public static String createHashKey(List<String> keys) {
        return String.join(keys, '');
    }

    public static Date getDateForWrapper(SObject energyuseRecord) {
        if (NZC_EmissionsMatchingMTD.dateMatchingField == NZC_EmissionsMatchingConstants.FIELD_EUR_MIDPOINT) {
            Date startDate = (Date) energyuseRecord.get(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE);
            Integer daysBetween = startDate.daysBetween((Date) energyuseRecord.get(NZC_EmissionsMatchingConstants.FIELD_EUR_ENDDATE))/2;
            return startDate.addDays(daysBetween);
        }
        return (Date) energyuseRecord.get(NZC_EmissionsMatchingMTD.dateMatchingField);
    }

    public static List<NZC_EmissionsMatchingWrapper> createMatchingWrapper(List<SObject> incomingEnergyList) {
        List<NZC_EmissionsMatchingWrapper> completedWrapper = new List<NZC_EmissionsMatchingWrapper>();

        for (SObject energyUse : incomingEnergyList) {
            // get wrapper type to create
            String objectType = String.valueOf(energyUse.getSObjectType());
            System.debug('object type ' + objectType);
            // can't use switch case with variables
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingStationaryWrapper((StnryAssetEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingVehicleWrapper((VehicleAssetEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingWasteWrapper((GeneratedWaste) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingHotelWrapper((HotelStayEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingFreightWrapper((FrgtHaulingEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_AIR_TRAVEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingAirTravelWrapper((AirTravelEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_GROUND_TRAVEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingGroundTravelWrapper((GroundTravelEnrgyUse) energyUse));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_RENTAL_CAR_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingRentalCarWrapper((RentalCarEnrgyUse) energyUse));
            }
        }
        NZC_EmissionsMatchingLog.log('generated wrappers', completedWrapper.size());

        return completedWrapper;
    }

    public static List<NZC_EmissionsMatchingWrapper> createWrapperWithGeneratedIds(Map<String, SObject> generatedIdMap) {
        List<NZC_EmissionsMatchingWrapper> completedWrapper = new List<NZC_EmissionsMatchingWrapper>();

        for (String generatedRecordId : generatedIdMap.keySet()) {
            // get wrapper type to create
            String objectType = String.valueOf(generatedIdMap.get(generatedRecordId).getSObjectType());

            // can't use switch case with variables
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingStationaryWrapper((StnryAssetEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingVehicleWrapper((VehicleAssetEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingWasteWrapper((GeneratedWaste) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingHotelWrapper((HotelStayEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingFreightWrapper((FrgtHaulingEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_AIR_TRAVEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingAirTravelWrapper((AirTravelEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_GROUND_TRAVEL_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingGroundTravelWrapper((GroundTravelEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
            if (objectType == NZC_EmissionsMatchingConstants.OBJECT_RENTAL_CAR_USE) {
                completedWrapper.add(new NZC_EmissionsMatchingRentalCarWrapper((RentalCarEnrgyUse) generatedIdMap.get(generatedRecordId), generatedRecordId));
            }
        }
        NZC_EmissionsMatchingLog.log('generated wrappers with temp id', completedWrapper.size());

        return completedWrapper;
    }

    public static Map<String, SObject> createInsertMatchingIdsMap(List<SObject> incomingRecords) {
        Map<String, SObject> generatedIdMap = new Map<String, SObject>();

        for (SObject recordUse : incomingRecords) {
            String tempId = createTemporaryRecordId();
            generatedIdMap.put(tempId, recordUse);
        }
        NZC_EmissionsMatchingLog.log('creating temp ids', generatedIdMap.size());

        return generatedIdMap;
    }

    public static List<SObject> screenRecordsBasedOnFlag(List<SObject> records, String fieldName) {
        List<SObject> returnResults = new List<SObject>();

        for (SObject record : records) {
            if (record.get(fieldName) != null && Boolean.valueOf(record.get(fieldName))) {
                returnResults.add(record);
                // remove flag
                record.put(fieldName, false);
            }
        }
        NZC_EmissionsMatchingLog.log('records passing screening', returnResults.size());

        return returnResults;
    }

    public static void triggerOnInsertRun(List<SObject> incomingRecords, String screeningField) {
        NZC_EmissionsMatchingLog.log('running insert engine',incomingRecords.size());
        NZC_EmissionsMatchingEngine matchingEngine = new NZC_EmissionsMatchingEngine();
        // only process records with a recalculate flag
        Map<String, SObject> generatedIdsMap = NZC_EmissionsMatchingUtil.createInsertMatchingIdsMap(
                screenRecordsBasedOnFlag(incomingRecords, screeningField)
        );
        matchingEngine.loadMatchTargets(NZC_EmissionsMatchingUtil.createWrapperWithGeneratedIds(generatedIdsMap));
        matchingEngine.process();
        // attach updates to existing records
        matchingEngine.attachUpdatesToExistingRecord(generatedIdsMap);
    }

    public static void triggerOnUpdateRun(List<SObject> incomingRecords, String screeningField) {
        NZC_EmissionsMatchingLog.log('running update engine',incomingRecords.size());
        NZC_EmissionsMatchingEngine matchingEngine = new NZC_EmissionsMatchingEngine();
        // screen records without recalculate flag
        matchingEngine.loadMatchTargets(NZC_EmissionsMatchingUtil.createMatchingWrapper(
                screenRecordsBasedOnFlag(incomingRecords, screeningField)
        ));
        matchingEngine.process();
        // attach updates to existing records
        matchingEngine.attachUpdatesToExistingRecord(new Map<String, SObject>(incomingRecords));
    }

    private static String createTemporaryRecordId() {
        return String.valueOf(Math.abs(Crypto.getRandomInteger()));
    }
}