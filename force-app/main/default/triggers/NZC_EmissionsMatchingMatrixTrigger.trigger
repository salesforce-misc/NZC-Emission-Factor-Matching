/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


trigger NZC_EmissionsMatchingMatrixTrigger on NZC_EmissionsMatchingMatrix__c (before insert, before update) {
    if (Trigger.isBefore) {
        NZC_EmissionsMatchingUtil.handleMatrixRecordHashing(Trigger.new);
    }
}