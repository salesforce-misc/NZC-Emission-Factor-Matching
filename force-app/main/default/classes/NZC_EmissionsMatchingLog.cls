/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


public with sharing class NZC_EmissionsMatchingLog {

    public static void log(String msg) {
        if (NZC_EmissionsMatchingMTD.doLog) {
            System.debug(msg);
        }
    }

    public static void log(String msg, Object data) {
        if (NZC_EmissionsMatchingMTD.doLog) {
            System.debug(msg + ' ' + JSON.serializePretty(data));
        }
    }

    public static void log(Object data) {
        if (NZC_EmissionsMatchingMTD.doLog) {
            System.debug(JSON.serializePretty(data));
        }
    }
}