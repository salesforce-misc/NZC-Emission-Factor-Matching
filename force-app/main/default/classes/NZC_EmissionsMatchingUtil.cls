/**
 * Created by mverigin on 6/19/23.
 */

public with sharing class NZC_EmissionsMatchingUtil {
    private static final String STRIP_REGEX = '[^a-zA-Z0-9]';
    public static final String DEFAULT_HASH = '0';

    public static Map<String, SObjectType> globalDescribe{
        get {
            if (globalDescribe == null) {
                globalDescribe = Schema.getGlobalDescribe();
            }
            return globalDescribe;
        }
        set;
    }

    public static final Map<String, Boolean> isFormulaFieldCache = new Map<String, Boolean>();

    public static Boolean isFormulaField(String objectType, String fieldName) {
        System.debug('is formula ' + objectType + ' ' + fieldName);
        if (!isFormulaFieldCache.containsKey(objectType+fieldName)) {
            Boolean isFormula = globalDescribe.get(objectType).getDescribe().fields.getMap().get(fieldName).getDescribe().isCalculated();
            isFormulaFieldCache.put(objectType + fieldName, isFormula);
        }

        return isFormulaFieldCache.get(objectType + fieldName);
    }

    public static Integer createHashKey(String assetId, String fieldName) {
        return createHashKey(new List<String>{assetId, fieldName});
    }

    public static Integer createHashKey(List<String> keys) {
        return String.join(keys, '').hashCode();
    }

    public static String hashRecordFields(SObject record, List<String> fieldsToHash) {
        Integer hashedKeys = 0;

        for (String field : fieldsToHash) {
            if (String.isBlank(field)) continue;
            field = field.trim();
            String extractedValue = cleanString(record.get(field) + '');
            if (extractedValue != 'NULL') hashedKeys += extractedValue.hashCode();
        }

        return hashedKeys != 0? String.valueOf(hashedKeys) : DEFAULT_HASH;
    }

    public static void handleMatrixRecordHashing(List<NZC_EmissionsMatchingMatrix__c> matrixRecords) {
        NZC_EmissionsMatchingLog.log('Hashing Matrix records');
        for (NZC_EmissionsMatchingMatrix__c record : matrixRecords) {
            // the record hash values and is not hashed yet
            if (String.isNotBlank(record.PrimaryHashkeys__c) && String.isBlank(record.PrimaryHashStorage__c)) {
                record.PrimaryHashStorage__c = splitAndHashString(record.PrimaryHashkeys__c);
            }
            if (String.isNotBlank(record.AliasHashkeys__c) && String.isBlank(record.AliasHashStorage__c)) {
                record.AliasHashStorage__c = splitAndHashString(record.AliasHashkeys__c);
            }
        }
        NZC_EmissionsMatchingLog.log('Hashed');
    }

    public static String splitAndHashString(String fullString) {
        return hashListOfStrings(fullString.split(NZC_EmissionsMatchingAdvancedMatchWpr.DEFAULT_SEPARATOR));
    }

    public static String hashListOfStrings(List<String> valuesToHash) {
        Integer hashedKeys = 0;

        for (String stringValue : valuesToHash) {
            if (String.isBlank(stringValue) || stringValue == 'null') continue;
            String cleanString = cleanString(stringValue);
            hashedKeys += cleanString.hashCode();
        }

        return String.valueOf(hashedKeys);
    }

    public static String cleanString(Object inputString) {
        String replacedString = ('' + inputString).replaceAll(STRIP_REGEX,'');
        return replacedString.trim().toUpperCase();
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