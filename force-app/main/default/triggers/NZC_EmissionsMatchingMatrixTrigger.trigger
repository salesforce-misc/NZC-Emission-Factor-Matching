/**
 * Created by mverigin on 10/29/24.
 */

trigger NZC_EmissionsMatchingMatrixTrigger on NZC_EmissionsMatchingMatrix__c (before insert, before update) {
    if (Trigger.isBefore) {
        NZC_EmissionsMatchingUtil.handleMatrixRecordHashing(Trigger.new);
    }
}