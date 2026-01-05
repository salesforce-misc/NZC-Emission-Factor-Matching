/**
 * Created by mverigin on 6/21/23.
 */

public with sharing class NZC_EmissionsMatchingLog {

    public static void log(String msg) {
        if (NZC_EmissionsMatchingMTD.doLog) System.debug(msg);
    }

    public static void log(String msg, Object data) {
        if (NZC_EmissionsMatchingMTD.doLog) System.debug(msg + ' ' + JSON.serializePretty(data));
    }

    public static void log(Object data) {
        if (NZC_EmissionsMatchingMTD.doLog) System.debug(JSON.serializePretty(data));
    }
}