/**
 * Created by mverigin on 6/19/23.
 */

trigger NZC_EmissionsMatchingStationaryTrigger on StnryAssetEnrgyUse (before insert, before update, after insert) {
    if (Trigger.isBefore && Trigger.isInsert && NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert) {
        NZC_EmissionsMatchingUtil.triggerOnInsertRun((List<SObject>) Trigger.new, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
    }

    if (Trigger.isInsert && Trigger.isAfter && NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert) {
        NZC_EmissionsMatchingTDLosses.handleT_DLossRecords((List<SObject>) Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate && NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate) {
        NZC_EmissionsMatchingUtil.triggerOnUpdateRun((List<SObject>) Trigger.new, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
        NZC_EmissionsMatchingTDLosses.handleT_DLossRecords((List<SObject>) Trigger.new);
    }
}