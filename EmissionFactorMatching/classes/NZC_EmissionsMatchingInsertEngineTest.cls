/**
 * Created by mverigin on 4/18/24.
 */

@IsTest
private class NZC_EmissionsMatchingInsertEngineTest {

    private static final String SET_NAME = 'Other Factor Set';

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingInsertEngine.bypassTrigger = true;
        List<OtherEmssnFctrSet> emissionSets = NZC_EmissionsMatchingDatafactory.createOtherSetMatrix(5, SET_NAME);
    }

    @IsTest
    static void testBehavior() {
        List<NZC_EmissionMatchingInsertWrapper> wrappers = new List<NZC_EmissionMatchingInsertWrapper>();

        NZC_EmissionMatchingInsertWrapper w = new NZC_EmissionMatchingInsertWrapper();
        w.recordInserting = new OtherEmssnFctrSet(
                Name = SET_NAME,
                EmissionsFactorUpdateYear__c = Date.today().addMonths(-13)
        );
        w.dateFieldName = 'EmissionsFactorUpdateYear__c';
        w.lookupName = 'MasterEmissionsSet__c';
        wrappers.add(w);

        Integer emissionsSetCount = [SELECT COUNT() FROM OtherEmssnFctrSet];
        Integer hieracyLinkedEmissions = 0;
        Id masterSetId;
        for (OtherEmssnFctrSet emSet : [SELECT Id, MasterEmissionsSet__c FROM OtherEmssnFctrSet]) {
            if (emSet.MasterEmissionsSet__c != null) {
                hieracyLinkedEmissions += 1;
            } else {
                masterSetId = emSet.Id;
            }
        }
        Assert.areEqual(emissionsSetCount-1, hieracyLinkedEmissions, 'Expected all but 1 record to be hierachy linked');
        Assert.isNotNull(masterSetId);

        Test.startTest();
        NZC_EmissionsMatchingInsertEngine.linkEmissionSets(wrappers);
        Test.stopTest();

        Integer emissionsSetCountAfter = [SELECT COUNT() FROM OtherEmssnFctrSet];
        Integer hieracyLinkedEmissionsAfter = 0;
        Id masterSetIdAfter;
        for (OtherEmssnFctrSet emSet : [SELECT Id, MasterEmissionsSet__c FROM OtherEmssnFctrSet]) {
            if (emSet.MasterEmissionsSet__c != null) {
                hieracyLinkedEmissionsAfter += 1;
            } else {
                masterSetIdAfter = emSet.Id;
            }
        }
        Assert.areEqual(emissionsSetCountAfter-1, hieracyLinkedEmissionsAfter, 'Expected all but 1 record to be hierachy linked');
        Assert.isNotNull(masterSetIdAfter, 'still expect a master record');
        Assert.areEqual(masterSetId, masterSetIdAfter, 'expect master to remain the same with new emissions set added');
        Assert.areEqual(emissionsSetCount, emissionsSetCountAfter-1, 'expected a new emissions set after running engine');
    }
}