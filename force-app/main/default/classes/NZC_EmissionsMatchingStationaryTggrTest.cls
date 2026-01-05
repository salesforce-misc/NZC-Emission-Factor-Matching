/**
 * Created by mverigin on 6/23/23.
 */

@IsTest
private class NZC_EmissionsMatchingStationaryTggrTest {
    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('myStationary');
    }

    @IsTest
    static void testInsert() {
        StnryAssetEnvrSrc asset = [
                SELECT Id
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];

        StnryAssetEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'testInsert', asset.Id, 'Electricity', 'kWH', Date.today(), Date.today());
        insert useWithoutTrigger;

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        StnryAssetEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createStationaryEnergyUse( 'testInsert', asset.Id, 'Electricity', 'kWH', Date.today(), Date.today());

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        StnryAssetEnrgyUse useWithoutTriggerAfter = [
                SELECT ElectricityEmissionFactorsId, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        StnryAssetEnrgyUse useWithriggerAfter = [
                SELECT ElectricityEmissionFactorsId, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.ElectricityEmissionFactorsId, useWithriggerAfter.ElectricityEmissionFactorsId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    @IsTest
    static void testUpdate() {
        StnryAssetEnrgyUse usePreUpdate = [
                SELECT Id, OtherEmssnFctrId, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE FuelType = 'Diesel'
                LIMIT 1
        ];

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        update usePreUpdate;
        Test.stopTest();

        StnryAssetEnrgyUse usePostUpdate = [
                SELECT Id, OtherEmssnFctrId, Recalculate_Emissions__c
                FROM StnryAssetEnrgyUse
                WHERE Id =: usePreUpdate.Id
                LIMIT 1
        ];

        Assert.areNotEqual(usePreUpdate.OtherEmssnFctrId, usePostUpdate.OtherEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(usePreUpdate.Recalculate_Emissions__c, usePostUpdate.Recalculate_Emissions__c);
        Assert.isFalse(usePostUpdate.Recalculate_Emissions__c);
    }
}