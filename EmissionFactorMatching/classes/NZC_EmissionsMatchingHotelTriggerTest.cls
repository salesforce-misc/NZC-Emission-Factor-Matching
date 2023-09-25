/**
 * Created by mverigin on 9/19/23.
 */

@IsTest
private class NZC_EmissionsMatchingHotelTriggerTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupHotel('myVehicle');
    }

    @IsTest
    static void testInsert() {
        Scope3EmssnSrc asset = [
                SELECT Id
                FROM Scope3EmssnSrc
                LIMIT 1
        ];

        HotelStayEnrgyUse useWithoutTrigger = NZC_EmissionsMatchingDatafactory.createHotelEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());
        insert useWithoutTrigger;

        HotelStayEnrgyUse useWithTrigger = NZC_EmissionsMatchingDatafactory.createHotelEnergyUse( 'testInsert', asset.Id, Date.today(), Date.today());

        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        Test.startTest();
        insert useWithTrigger;
        Test.stopTest();

        HotelStayEnrgyUse useWithoutTriggerAfter = [
                SELECT HotelStayEmssnFctrId, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
                WHERE Id =: useWithoutTrigger.Id
        ];

        HotelStayEnrgyUse useWithriggerAfter = [
                SELECT HotelStayEmssnFctrId, Recalculate_Emissions__c
                FROM HotelStayEnrgyUse
                WHERE Id =: useWithTrigger.Id
        ];

        Assert.areNotEqual(useWithoutTriggerAfter.HotelStayEmssnFctrId, useWithriggerAfter.HotelStayEmssnFctrId, 'Factors should be different for emission matched record');
        Assert.areNotEqual(useWithoutTriggerAfter.Recalculate_Emissions__c, useWithriggerAfter.Recalculate_Emissions__c);
        Assert.isFalse(useWithriggerAfter.Recalculate_Emissions__c);
    }

    //test update
}