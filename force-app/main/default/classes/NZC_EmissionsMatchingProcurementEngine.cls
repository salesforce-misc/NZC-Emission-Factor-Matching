/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * Backfills the emissions factor (PcmtEmssnFctrSetItemId) on Scope 3 procurement items that were
 * loaded without one. Unlike the other energy use types, procurement factors live on emissions set
 * ITEMS, so matching is driven by a multi-field rule in NZC_EmissionsMatchingCustomMatch__mdt:
 * EnergyUseFieldToMatch__c lists item fields and EmissionsSetFieldToMatch__c lists the paired
 * emissions set item fields (comma separated, same order). When several set items share a key,
 * the one whose set update year is the latest on or before the item's spend/report year wins.
 */
public with sharing class NZC_EmissionsMatchingProcurementEngine {

    /**
     * Fills the emissions set item lookup on items that do not have one.
     * @param items Scope3PcmtItem records (before-trigger context or batch scope). Not DML'd here.
     */
    public static void matchItems(List<SObject> items) {
        if (items == null || items.isEmpty() || !NZC_EmissionsMatchingMTD.allowCustomTagMatching) {
            return;
        }

        NZC_EmissionsMatchingCustomMatch__mdt rule = NZC_EmissionsMatchingMTD.customMatchingRules.get(
                NZC_EmissionsMatchingUtil.createHashKey(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, null));
        if (rule == null) {
            NZC_EmissionsMatchingLog.log('no procurement matching rule configured');
            return;
        }

        List<String> itemFields = splitFields(rule.EnergyUseFieldToMatch__c);
        List<String> setItemFields = splitFields(rule.EmissionsSetFieldToMatch__c);
        if (itemFields.isEmpty() || itemFields.size() != setItemFields.size()
                || !fieldsAreReadable(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_ITEM, itemFields)
                || !fieldsAreReadable(NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_SET_ITEM, setItemFields)) {
            NZC_EmissionsMatchingLog.log('invalid procurement matching rule', rule);
            return;
        }

        Map<Integer, String> indexToKey = new Map<Integer, String>();
        Set<String> firstFieldValues = new Set<String>();
        for (Integer i = 0; i < items.size(); i++) {
            SObject item = items[i];
            if (item.get(NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_ITEM_LOOKUP) != null) {
                continue;
            }
            String key = buildKey(item, itemFields);
            if (key != null) {
                indexToKey.put(i, key);
                firstFieldValues.add(String.valueOf(item.get(itemFields[0])));
            }
        }
        if (indexToKey.isEmpty()) {
            return;
        }

        Map<String, List<SObject>> keyToSetItems = loadSetItems(setItemFields, firstFieldValues);
        for (Integer i : indexToKey.keySet()) {
            SObject best = pickClosest(keyToSetItems.get(indexToKey.get(i)), getItemYear(items[i]));
            if (best != null) {
                items[i].put(NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_ITEM_LOOKUP, best.Id);
            }
        }
    }

    /**
     * Builds the composite match key. Null when any part is blank, so partially filled items never match.
     */
    @TestVisible
    private static String buildKey(SObject record, List<String> fields) {
        List<String> parts = new List<String>();
        for (String field : fields) {
            Object value = record.get(field);
            if (value == null || String.isBlank(String.valueOf(value))) {
                return null;
            }
            parts.add(String.valueOf(value).trim().toUpperCase());
        }
        return String.join(parts, NZC_EmissionsMatchingConstants.MATCH_KEY_DELIMITER);
    }

    public static List<String> splitFields(String csv) {
        List<String> fields = new List<String>();
        if (String.isBlank(csv)) {
            return fields;
        }
        for (String field : csv.split(NZC_EmissionsMatchingConstants.MATCH_FIELD_DELIMITER)) {
            if (String.isNotBlank(field)) {
                fields.add(field.trim());
            }
        }
        return fields;
    }

    /**
     * Picks the set item with the latest update year that is not after the item year.
     * With no item year the latest set item is used. Set items with no year only win as a last resort.
     */
    @TestVisible
    private static SObject pickClosest(List<SObject> candidates, Integer itemYear) {
        if (candidates == null) {
            return null;
        }
        SObject best;
        Integer bestYear;
        SObject undated;
        for (SObject candidate : candidates) {
            Integer year = getSetYear(candidate);
            if (year == null) {
                undated = undated == null ? candidate : undated;
            } else if ((itemYear == null || year <= itemYear) && (bestYear == null || year > bestYear)) {
                best = candidate;
                bestYear = year;
            }
        }
        return best != null ? best : undated;
    }

    private static Map<String, List<SObject>> loadSetItems(List<String> setItemFields, Set<String> firstFieldValues) {
        Set<String> selected = new Set<String>{
                'Id', NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SET_YEAR
        };
        selected.addAll(setItemFields);
        String query = 'SELECT ' + String.join(new List<String>(selected), ', ')
                + ' FROM ' + NZC_EmissionsMatchingConstants.OBJECT_PROCUREMENT_SET_ITEM
                + ' WHERE ' + setItemFields[0] + ' IN :firstFieldValues';

        Map<String, List<SObject>> keyToSetItems = new Map<String, List<SObject>>();
        for (SObject setItem : Database.query(query)) {
            String key = buildKey(setItem, setItemFields);
            if (key != null) {
                if (!keyToSetItems.containsKey(key)) {
                    keyToSetItems.put(key, new List<SObject>());
                }
                keyToSetItems.get(key).add(setItem);
            }
        }
        return keyToSetItems;
    }

    private static Integer getItemYear(SObject item) {
        Object spent = item.get(NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_SPENT_DATE);
        Object reported = item.get(NZC_EmissionsMatchingConstants.FIELD_PROCUREMENT_REPORT_DATE);
        Date matchDate = (Date) (spent != null ? spent : reported);
        return matchDate == null ? null : matchDate.year();
    }

    private static Integer getSetYear(SObject setItem) {
        SObject parent = setItem.getSObject('PcmtEmssnFctrSet');
        String year = parent == null ? null : (String) parent.get('EmissionFactorUpdateYear');
        return (year != null && year.isNumeric()) ? Integer.valueOf(year) : null;
    }

    private static Boolean fieldsAreReadable(String objectName, List<String> fields) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return false;
        }
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        for (String field : fields) {
            if (!fieldMap.containsKey(field) || !fieldMap.get(field).getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }
}
