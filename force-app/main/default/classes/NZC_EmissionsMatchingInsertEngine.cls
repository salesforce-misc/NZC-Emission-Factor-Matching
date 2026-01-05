/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


public with sharing class NZC_EmissionsMatchingInsertEngine {

    @TestVisible
    private static Boolean bypassTrigger = false;

    @InvocableMethod
    public static void linkEmissionSets(List<NZC_EmissionMatchingInsertWrapper> wrappers) {
        if (bypassTrigger) return;
        Map<String, NZC_EmissionMatchingInsertWrapper> emissionsNamesMap = new Map<String, NZC_EmissionMatchingInsertWrapper>();
        Set<String> emissionsNames = new Set<String>();
        String dateField = wrappers.get(0).dateFieldName;
        String lookupName = wrappers.get(0).lookupName;
        String objectType = wrappers.get(0).recordInserting.getSObjectType() + '';

        for (NZC_EmissionMatchingInsertWrapper wrapper : wrappers) {
            wrapper.preProcessRecords();
            emissionsNames.add('\'%' + wrapper.name + '%\'');

            if (!emissionsNamesMap.containsKey(wrapper.name)) {
                emissionsNamesMap.put(wrapper.name, wrapper);
            } else {
                // if name already in map add to relevant factor set to link up later on
                emissionsNamesMap.get(wrapper.name).relevantEmissionsSets.add(wrapper);
            }
        }
        System.debug(emissionsNames);
        String query = 'SELECT Name, CreatedDate, ' + dateField + ' FROM ' + objectType+ ' WHERE Name LIKE ' + String.join(emissionsNames, ' OR Name LIKE ');
        for (SObject s : Database.query(query)) {
            // create wrapper for them
            NZC_EmissionMatchingInsertWrapper wrapper = new NZC_EmissionMatchingInsertWrapper();
            wrapper.lookupName = lookupName;
            wrapper.dateFieldName = dateField;
            wrapper.recordInserting = s;
            wrapper.preProcessRecords();
            // find a more efficient algo for this its clunky and slow
            for (String name : emissionsNamesMap.keySet()) {
                if (wrapper.name.contains(name)) {
                    // this wrapper belongs in this bucket
                    emissionsNamesMap.get(name).relevantEmissionsSets.add(wrapper);
                    break;
                }
            }
        }

        Map<Id, SObject> recordUpdates = new Map<Id, SObject>();
        // determine oldest record and make it 'master'
        for (String name : emissionsNamesMap.keySet()) {
//            TODO REMOVE Date oldestDate = emissionsNamesMap.get(name).startDate;
            Date oldestDate = Date.today();
            String oldestId = emissionsNamesMap.get(name).recordInserting.Id;
            for (NZC_EmissionMatchingInsertWrapper wrapper : emissionsNamesMap.get(name).relevantEmissionsSets) {
                if (wrapper.startDate == null) {
                    // this is a default emission set make it master
                    oldestId = wrapper.recordInserting.Id;
                    break;
                }
                if (wrapper.startDate != null && oldestDate > wrapper.startDate) {
                    oldestDate = wrapper.startDate;
                    oldestId = wrapper.recordInserting.Id;
                }
            }

            // base wrapper update, then dive into nested wrapper
            NZC_EmissionMatchingInsertWrapper currentRef = emissionsNamesMap.get(name);
            if (currentRef.recordInserting.Id == oldestId) {
                // skip this record
                currentRef.recordInserting.put(currentRef.dateFieldName, currentRef.startDate);
                currentRef.recordInserting.put(currentRef.lookupName, null);
            } else {
                currentRef.recordInserting.put(currentRef.dateFieldName, currentRef.startDate);
                currentRef.recordInserting.put(currentRef.lookupName, oldestId);
            }
            // flag these emissions for recalc because EUR could have changed
            currentRef.recordInserting.put('Recalculate_Emissions__c', true);
            recordUpdates.put(currentRef.recordInserting.Id, currentRef.recordInserting);

            System.debug(JSON.serializePretty(emissionsNamesMap.get(name).relevantEmissionsSets));
            for (NZC_EmissionMatchingInsertWrapper wrapper : emissionsNamesMap.get(name).relevantEmissionsSets) {
                if (wrapper.recordInserting.Id == oldestId) {
                    // skip this record
                    wrapper.recordInserting.put(wrapper.dateFieldName, wrapper.startDate);
                    wrapper.recordInserting.put(wrapper.lookupName, null);
                } else {
                    wrapper.recordInserting.put(wrapper.dateFieldName, wrapper.startDate);
                    wrapper.recordInserting.put(wrapper.lookupName, oldestId);
                }
                // flag these emissions for recalc because EUR could have changed
                wrapper.recordInserting.put('Recalculate_Emissions__c', true);
                recordUpdates.put(wrapper.recordInserting.Id, wrapper.recordInserting);
            }
        }
        if (recordUpdates.size() > 0) {
            System.debug('dml');
            System.debug(recordUpdates.size());
            bypassTrigger = true;
            upsert recordUpdates.values();
        }
    }
}