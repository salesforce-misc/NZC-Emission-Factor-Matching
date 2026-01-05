/**
 * Created by mverigin on 11/18/24.
 */

@IsTest
private class NZC_EmissionsMatchingAdvcMatchWprTest {

    @TestSetup
    static void setup() {
        NZC_EmissionsMatchingDatafactory.setupStationary('Enginestationary');
    }

    @IsTest
    static void testScreenAndQuickSearch() {
        NZC_EmissionsMatchingAdvancedMatchTest.createAdvanceMatchRules();
        StnryAssetEnvrSrc asset = NZC_EmissionsMatchingDatafactory.createStationaryAsset(
                'Test stationary Asset', null, null, null, null);
        asset.Country = 'CA';
        asset.City = 'Castlegar';
        asset.StationaryAssetIdentifier = '1dfvadg';

        String expectedPostalCode = 'expectedValue';
        asset.PostalCode = expectedPostalCode;

        NZC_EmissionsMatchingAdvancedMatchWpr wrapper = new NZC_EmissionsMatchingAdvancedMatchWpr(asset);
        wrapper.screenRecordCreateQuickSearchHash();

        // 3 match rules setup, expect each to have a value hashed
        Assert.isTrue(wrapper.canMatchQuickSearch(0), 'first hash did not create');
        Assert.isTrue(wrapper.canMatchQuickSearch(1), 'second hash did not create');
        Assert.isTrue(wrapper.canMatchQuickSearch(2), 'third hash did not create');

        String newName = 'myNewName';
        Assert.areNotEqual(newName, asset.Name, 'Asset name was changed already');
        wrapper.updateOriginalRecord('Name', newName);
        Assert.areEqual(newName, asset.Name, 'Asset name not changed');

        // check to see if matching rules pull values
        String electricityId = [
                SELECT Id
                FROM ElectricityEmssnFctrSet
                LIMIT 1
        ].Id;
        NZC_EmissionsMatchingAdvanceMatch__mdt elecRule = NZC_EmissionsMatchingMTD.advancedMatchingRules.get('StnryAssetEnvrSrc').get(0);

        Assert.isTrue(wrapper.factorMatched.size() < 1, 'wrapper already has a matched factor');
        wrapper.addFactorMatchedValue(elecRule, electricityId);
        Assert.isTrue(wrapper.factorMatched.size() > 0, 'did not attach factor');

        Assert.areEqual(expectedPostalCode, wrapper.getSecondaryMatchValue(elecRule), 'electricity rule did not request expected secondary field');
    }
}