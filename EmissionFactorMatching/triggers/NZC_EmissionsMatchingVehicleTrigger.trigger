/**
 * Created by mverigin on 6/20/23.
 */

trigger NZC_EmissionsMatchingVehicleTrigger on VehicleAssetEnrgyUse (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert && NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert) {
        NZC_EmissionsMatchingUtil.triggerOnInsertRun((List<SObject>) Trigger.new, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
    }

    if (Trigger.isBefore && Trigger.isUpdate && NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate) {
        NZC_EmissionsMatchingUtil.triggerOnUpdateRun((List<SObject>) Trigger.new, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
    }
}