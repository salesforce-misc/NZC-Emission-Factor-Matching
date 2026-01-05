/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingLogTest {

    @IsTest
    static void testLogging() {
        NZC_EmissionsMatchingLog.log('test');
        NZC_EmissionsMatchingLog.log('test', new Account(Name = 'testLog'));
        NZC_EmissionsMatchingLog.log(new Account(Name = 'testLog'));
    }

    @IsTest
    static void testLogging_loggingDisabled() {
        NZC_EmissionsMatchingMTD.doLog = false;

        NZC_EmissionsMatchingLog.log('no log test');
        NZC_EmissionsMatchingLog.log('no log test', new Account(Name = 'no log test'));
        NZC_EmissionsMatchingLog.log(new Account(Name = 'no log test'));
    }
}