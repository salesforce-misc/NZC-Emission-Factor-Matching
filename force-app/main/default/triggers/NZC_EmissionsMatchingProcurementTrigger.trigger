/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

trigger NZC_EmissionsMatchingProcurementTrigger on Scope3PcmtItem (before insert, before update) {
    if (Trigger.isInsert && NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert) {
        NZC_EmissionsMatchingProcurementEngine.matchItems((List<SObject>) Trigger.new);
    }

    if (Trigger.isUpdate && NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate) {
        NZC_EmissionsMatchingProcurementEngine.matchItems((List<SObject>) Trigger.new);
    }
}
