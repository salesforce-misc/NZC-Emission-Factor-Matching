/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


public with sharing class NZC_EmissionsMatchingBatch implements Database.Batchable<SObject>, Database.Stateful {
    // objects are processed sequentially in this order
    @TestVisible
    private static final List<String> BATCH_ORDER = new List<String>{
            NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE,
            NZC_EmissionsMatchingConstants.OBJECT_VEHICLE_ENERGY_USE,
            NZC_EmissionsMatchingConstants.OBJECT_WASTE_USE,
            NZC_EmissionsMatchingConstants.OBJECT_HOTEL_USE,
            NZC_EmissionsMatchingConstants.OBJECT_FREIGHT_USE,
            NZC_EmissionsMatchingConstants.OBJECT_AIR_TRAVEL_USE,
            NZC_EmissionsMatchingConstants.OBJECT_GROUND_TRAVEL_USE,
            NZC_EmissionsMatchingConstants.OBJECT_RENTAL_CAR_USE
    };

    private final String objectName;

    public NZC_EmissionsMatchingBatch() {
        this(NZC_EmissionsMatchingConstants.OBJECT_STATIONARY_ENERGY_USE);
    }

    NZC_EmissionsMatchingBatch(String objectName) {
        this.objectName = objectName;
    }

    public Database.QueryLocator start(Database.BatchableContext batchContext){
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(this.objectName).getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + this.objectName + ' WHERE Recalculate_Emissions__c = TRUE';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchContext, List<SObject> scope){
        NZC_EmissionsMatchingUtil.triggerOnUpdateRun(scope, NZC_EmissionsMatchingConstants.EMISSIONS_MATCHING_SCREENING_FIELD);
        update scope;
    }

    public void finish(Database.BatchableContext batchContext){
        Integer currentIndex = BATCH_ORDER.indexOf(objectName);
        if (currentIndex >= 0 && currentIndex < BATCH_ORDER.size() - 1) {
            Database.executeBatch(new NZC_EmissionsMatchingBatch(BATCH_ORDER[currentIndex + 1]));
        } else if (currentIndex == BATCH_ORDER.size() - 1 && !Test.isRunningTest()) {
            // procurement items are matched last
            Database.executeBatch(new NZC_EmissionsMatchingProcurementBatch(), NZC_EmissionsMatchingMTD.emissionsMatchBatchSize);
        }
    }
}
