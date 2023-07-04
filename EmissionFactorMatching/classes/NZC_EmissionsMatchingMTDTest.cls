/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingMTDTest {
    @IsTest
    static void testSettingsFetch() {
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert, 'Expecting insert to be true');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate, 'Expecting update to be true');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,NZC_EmissionsMatchingMTD.dateMatchingField, 'Expecting date field populated');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doLog, 'Expecting logging enabled');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsMatchBatchSize > NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE, 'Expecting a match batch size set');
        Assert.isTrue(NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize > NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE, 'Expecting a recalc batch size set');
        Assert.isNotNull(NZC_EmissionsMatchingMTD.matchingConfig, 'no setting created');

    }

    @IsTest
    static void testSettingsDefaults() {
        Assert.isFalse(NZC_EmissionsMatchingMTD.doEmissionsMatchOnInsert, 'Expecting default false');
        Assert.isFalse(NZC_EmissionsMatchingMTD.doEmissionsMatchOnUpdate, 'Expecting default false');
        Assert.areEqual(NZC_EmissionsMatchingConstants.FIELD_EUR_STARTDATE,NZC_EmissionsMatchingMTD.dateMatchingField, 'Expecting date field populated to default');
        Assert.isTrue(NZC_EmissionsMatchingMTD.doLog, 'Expecting logging enabled by default');
        Assert.areEqual(NZC_EmissionsMatchingConstants.EMISSIONS_MATCH_BATCH_SIZE, NZC_EmissionsMatchingMTD.emissionsMatchBatchSize, 'Default not set correctly');
        Assert.areEqual(NZC_EmissionsMatchingConstants.EMISSIONS_RECALC_BATCH_SIZE, NZC_EmissionsMatchingMTD.emissionsRecalcBatchSize, 'Default not set correctly');
    }
}