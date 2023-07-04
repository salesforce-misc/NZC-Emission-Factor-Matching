/**
 * Created by mverigin on 6/27/23.
 */

public with sharing class NZC_EmissionsSetRecalcBatch implements Database.Batchable<SObject>, Database.Stateful {
    private final String objectName;

    public NZC_EmissionsSetRecalcBatch() {
        this.objectName = NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET;
    }

    public NZC_EmissionsSetRecalcBatch(String objectName) {
        this.objectName = objectName;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(this.objectName).getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + this.objectName + ' WHERE Recalculate_Emissions__c = TRUE';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){
        NZC_EmissionsSetRecalcEngine recalculateEngine = new NZC_EmissionsSetRecalcEngine(true);
        recalculateEngine.loadSetIds(scope);
        recalculateEngine.processRecords();
    }

    public void finish(Database.BatchableContext BC){
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_OTHER_EMISSION_SET) {
            // start Electricity next
            Database.executeBatch(new NZC_EmissionsSetRecalcBatch(NZC_EmissionsMatchingConstants.OBJECT_ELECTRICITY_SET));
        }
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_ELECTRICITY_SET) {
            // start waste next
            Database.executeBatch(new NZC_EmissionsSetRecalcBatch(NZC_EmissionsMatchingConstants.OBJECT_REFRIGERANT_SET));
        }
        if (objectName == NZC_EmissionsMatchingConstants.OBJECT_REFRIGERANT_SET) {
            // start waste next
            Database.executeBatch(new NZC_EmissionsSetRecalcBatch(NZC_EmissionsMatchingConstants.OBJECT_WASTE_SET));
        }
    }
}