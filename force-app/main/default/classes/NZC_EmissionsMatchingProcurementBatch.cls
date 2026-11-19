/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * Backfills emissions set item lookups on Scope 3 procurement items that have none.
 */
public with sharing class NZC_EmissionsMatchingProcurementBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        Set<String> fields = new Set<String>{'Id', NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_ITEM_LOOKUP,
                NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SPENT_DATE, NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_REPORT_DATE};
        NZC_EmissionsMatchingCustomMatch__mdt rule = NZC_EmissionsMatchingMTD.customMatchingRules.get(
                NZC_EmissionsMatchingUtil.createHashKey(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, null));
        if (rule != null) {
            fields.addAll(NZC_EmissionsMatchingProcurementEngine.splitFields(rule.EnergyUseFieldToMatch__c));
        }
        return Database.getQueryLocator('SELECT ' + String.join(new List<String>(fields), ', ')
                + ' FROM ' + NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM
                + ' WHERE ' + NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_ITEM_LOOKUP + ' = NULL');
    }

    public void execute(Database.BatchableContext batchContext, List<SObject> scope) {
        NZC_EmissionsMatchingProcurementEngine.matchItems(scope);
        List<SObject> matched = new List<SObject>();
        for (SObject item : scope) {
            if (item.get(NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_ITEM_LOOKUP) != null) {
                matched.add(item);
            }
        }
        update matched;
    }

    public void finish(Database.BatchableContext batchContext) {
    }
}
