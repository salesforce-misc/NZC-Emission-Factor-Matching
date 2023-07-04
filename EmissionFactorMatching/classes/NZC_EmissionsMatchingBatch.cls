/**
 * Created by mverigin on 6/22/23.
 */

public with sharing class NZC_EmissionsMatchingBatch implements Database.Batchable<SObject>, Database.Stateful {
    private final String objectName;

    public NZC_EmissionsMatchingBatch() {
        this(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE);
    }

    NZC_EmissionsMatchingBatch(String objectName) {
        this.objectName = objectName;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(this.objectName).getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + this.objectName + ' WHERE Recalculate_Emissions__c = TRUE';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){
        NZC_EmissionsMatchingUtil.triggerOnUpdateRun(scope, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
        update scope;
    }

    public void finish(Database.BatchableContext BC){
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE) {
            // start vehicle next
            Database.executeBatch(new NZC_EmissionsMatchingBatch(NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE));
        }
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE) {
            // start waste next
            Database.executeBatch(new NZC_EmissionsMatchingBatch(NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE));
        }
    }
}