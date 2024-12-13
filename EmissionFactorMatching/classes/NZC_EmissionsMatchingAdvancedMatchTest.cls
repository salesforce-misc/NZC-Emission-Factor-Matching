/**
 * Created by mverigin on 11/14/24.
 */

@IsTest
public class NZC_EmissionsMatchingAdvancedMatchTest {

    @TestSetup
    static void setup() {
        System.debug('setup start');
        NZC_EmissionsMatchingDatafactory.setupStationary('AdvanceEngineStationary');
        System.debug('setup finish');
    }

    @IsTest
    static void testCreateMatchingCode() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        ElectricityEmssnFctrSet testFactor = new ElectricityEmssnFctrSet(
                Name = 'ThisFieldShouldGetHashed',
                ExternalIdentifier = null
        );

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                testFactor
        }, false);
        Test.stopTest();

        Assert.isNotNull(testFactor.Name, 'name was removed');
        Assert.isNotNull(testFactor.ExternalIdentifier, 'Hash was not generated');
    }

    @IsTest
    static void testMatchAssetUsingMatrixDefault() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();
        createMatrixDefaults();

        StnryAssetEnvrSrc asset = new StnryAssetEnvrSrc(
                Name = 'Stationary Asset without Emissions Factors'
        );

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                asset
        }, false);
        Test.stopTest();

        Assert.isNotNull(asset.ElectricityEmssnFctrId, 'Electricty factor was not added by matrix records');
        Assert.isNotNull(asset.RefrigerantEmssnFctrId, 'Refrigerant factor was not added by matrix records');
        Assert.isNotNull(asset.OtherEmssnFctrId, 'Other factor was not added by matrix records');
    }

    @IsTest
    static void testAdvanceAssetMatch() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.setupVehicle('AdvanceMatchVehicle');
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id, OtherEmssnFctrId
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'no factor on base asset');
        String oldFactorId = vehicleAsset.OtherEmssnFctrId;

        String hashStringForMatching = 'ThisStringExistsOnBothObjectsSoTheyMatch';

        OtherEmssnFctrSet newTestFactor = new OtherEmssnFctrSet(
                Name = hashStringForMatching
        );
        insert newTestFactor;

        // generate matching code on new factor
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                newTestFactor
        }, true);

        vehicleAsset.City = hashStringForMatching;

        // process vehicle asset to match with our new factor

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                vehicleAsset
        }, true);
        Test.stopTest();

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'other emissions factor was removed');
        Assert.areNotEqual(oldFactorId, vehicleAsset.OtherEmssnFctrId, 'Did not match the new factor as expected');
        Assert.areEqual(newTestFactor.Id, vehicleAsset.OtherEmssnFctrId, 'did not pick factor expected');
    }

    @IsTest
    static void testSecondLevelSearch() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        StnryAssetEnvrSrc stationaryAsset = [
                SELECT Id, ElectricityEmssnFctrId, Country, City, StationaryAssetIdentifier
                FROM StnryAssetEnvrSrc
                LIMIT 1
        ];

        Assert.isNotNull(stationaryAsset.ElectricityEmssnFctrId, 'no factor on base asset');
        String oldFactorId = stationaryAsset.ElectricityEmssnFctrId;

        String hashStringForMatching = 'US';
        String expectedPostalCode = '123456';

        ElectricityEmssnFctrSet newTestFactor = NZC_EmissionsMatchingDatafactory.createElectricityEmissionSet(hashStringForMatching, null,null);
        System.debug('inserting first factor');
        insert newTestFactor;
        System.debug('finish first factor');
        ElectricityEmssnFctrSet secondFactorWithSecondaryFields = newTestFactor.clone(false);
        secondFactorWithSecondaryFields.PostalCodeSet = expectedPostalCode;
        System.debug('inserting second factor');
        insert secondFactorWithSecondaryFields;
        System.debug('finish second factor');

        // generate matching code on new factor
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                newTestFactor, secondFactorWithSecondaryFields
        }, true);

        // add values to asset to match against
        stationaryAsset.Country = hashStringForMatching;
        stationaryAsset.PostalCode = expectedPostalCode;

        // process vehicle asset to match with our new factor

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                stationaryAsset
        }, true);
        Test.stopTest();

        Assert.isNotNull(stationaryAsset.ElectricityEmssnFctrId, 'Electricity emissions factor was removed');
        Assert.areNotEqual(oldFactorId, stationaryAsset.ElectricityEmssnFctrId, 'Did not match the new factor as expected');
        Assert.areNotEqual(newTestFactor.Id, stationaryAsset.ElectricityEmssnFctrId, 'Did not match the new factor as expected');
        Assert.areEqual(secondFactorWithSecondaryFields.Id, stationaryAsset.ElectricityEmssnFctrId, 'Should pick this factor');
    }

    @IsTest
    public static void testOverRideMatch() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.setupVehicle('AdvanceMatchVehicle');
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id, OtherEmssnFctrId
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'no factor on base asset');
        String oldFactorId = vehicleAsset.OtherEmssnFctrId;

        String hashStringForMatching = 'thisValueFindsAMatrixRecord';
        vehicleAsset.City = hashStringForMatching;

        OtherEmssnFctrSet newTestFactor = new OtherEmssnFctrSet(
                Name = 'My TestFactor'
        );
        insert newTestFactor;

        // create override Matrix record
        NZC_EmissionsMatchingMatrix__c matrixOverRide = new NZC_EmissionsMatchingMatrix__c(
                ApplicableObject__c = OtherEmssnFctrSet.SObjectType + '',
                LookupOverride__c = newTestFactor.Id + '',
                PrimaryHashkeys__c = hashStringForMatching,
                AliasHashkeys__c = 'ThisIsTheAliasToFindFactorWith'
        );
        insert matrixOverRide;

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                vehicleAsset
        }, false);
        Test.stopTest();

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'other emissions factor was removed');
        Assert.areNotEqual(oldFactorId, vehicleAsset.OtherEmssnFctrId, 'Did not match the new factor as expected');
        Assert.areEqual(newTestFactor.Id, vehicleAsset.OtherEmssnFctrId, 'did not pick factor expected');
    }

    @IsTest
    public static void testAliasMatch() {
        createAdvanceMatchRules();
        NZC_EmissionsMatchingDatafactory.setupVehicle('AdvanceMatchVehicle');
        NZC_EmissionsMatchingDatafactory.createEmissionsSettings();

        VehicleAssetEmssnSrc vehicleAsset = [
                SELECT Id, OtherEmssnFctrId
                FROM VehicleAssetEmssnSrc
                LIMIT 1
        ];

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'no factor on base asset');
        String oldFactorId = vehicleAsset.OtherEmssnFctrId;

        String hashStringForMatching = 'thisValueFindsAMatrixRecord';
        String aliasString = 'thisIsTheAliasforMatrixRecord';
        vehicleAsset.City = hashStringForMatching;

        OtherEmssnFctrSet newTestFactor = new OtherEmssnFctrSet(
                Name = aliasString
        );
        insert newTestFactor;
        // generate a matching code for factor with Alias key
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                newTestFactor
        }, true);

        // create Matrix alias record to point our assets value to alias factor value
        NZC_EmissionsMatchingMatrix__c matrixOverRide = new NZC_EmissionsMatchingMatrix__c(
                ApplicableObject__c = OtherEmssnFctrSet.SObjectType + '',
                PrimaryHashkeys__c = hashStringForMatching,
                AliasHashkeys__c = aliasString
        );
        insert matrixOverRide;

        Test.startTest();
        NZC_EmissionsMatchingAdvancedMatch.fireAdvancedMatching(new List<SObject>{
                vehicleAsset
        }, false);
        Test.stopTest();

        Assert.isNotNull(vehicleAsset.OtherEmssnFctrId, 'other emissions factor was removed');
        Assert.areNotEqual(oldFactorId, vehicleAsset.OtherEmssnFctrId, 'Did not match the new factor as expected');
        Assert.areEqual(newTestFactor.Id, vehicleAsset.OtherEmssnFctrId, 'did not pick factor expected');
    }

    public static void createAdvanceMatchRules() {
        Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>> advancedMatchingRules = new Map<String, List<NZC_EmissionsMatchingAdvanceMatch__mdt>>{
                'ElectricityEmssnFctrSet' => new List<NZC_EmissionsMatchingAdvanceMatch__mdt>{
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'Name',
                                LookupToPopulate__c = null,
                                ObjectAppliesTo__c = 'ElectricityEmssnFctrSet',
                                Hash_Destination__c = 'ExternalIdentifier',
                                LookupDestination__c = null,
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        )
                },
                'OtherEmssnFctrSet' => new List<NZC_EmissionsMatchingAdvanceMatch__mdt>{
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'Name',
                                LookupToPopulate__c = null,
                                ObjectAppliesTo__c = 'OtherEmssnFctrSet',
                                Hash_Destination__c = 'ExternalIdentifier',
                                LookupDestination__c = null,
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        )
                },
                'RefrigerantEmssnFctr' => new List<NZC_EmissionsMatchingAdvanceMatch__mdt>{
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'Name',
                                LookupToPopulate__c = null,
                                ObjectAppliesTo__c = 'RefrigerantEmssnFctr',
                                Hash_Destination__c = 'ExternalIdentifier',
                                LookupDestination__c = null,
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        )
                },
                'StnryAssetEnvrSrc' => new List<NZC_EmissionsMatchingAdvanceMatch__mdt>{
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'Country',
                                LookupToPopulate__c = 'ElectricityEmssnFctrId',
                                ObjectAppliesTo__c = 'StnryAssetEnvrSrc',
                                Hash_Destination__c = null,
                                LookupDestination__c = 'ExternalIdentifier',
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = 'PostalCode',
                                SecondaryMatchFieldTarget__c = 'PostalCodeSet'
                        ),
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'City',
                                LookupToPopulate__c = 'OtherEmssnFctrId',
                                ObjectAppliesTo__c = 'StnryAssetEnvrSrc',
                                Hash_Destination__c = null,
                                LookupDestination__c = 'ExternalIdentifier',
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        ),
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'StationaryAssetIdentifier',
                                LookupToPopulate__c = 'RefrigerantEmssnFctrId',
                                ObjectAppliesTo__c = 'StnryAssetEnvrSrc',
                                Hash_Destination__c = null,
                                LookupDestination__c = 'ExternalIdentifier',
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        )
                },
                'VehicleAssetEmssnSrc' => new List<NZC_EmissionsMatchingAdvanceMatch__mdt>{
                        new NZC_EmissionsMatchingAdvanceMatch__mdt(
                                HashFields__c = 'City',
                                LookupToPopulate__c = 'OtherEmssnFctrId',
                                ObjectAppliesTo__c = 'VehicleAssetEmssnSrc',
                                Hash_Destination__c = null,
                                LookupDestination__c = 'ExternalIdentifier',
                                ScreeningField__c = null,
                                SecondaryMatchSourceField__c = null,
                                SecondaryMatchFieldTarget__c = null
                        )
                }
        };
        NZC_EmissionsMatchingMTD.advancedMatchingRules = advancedMatchingRules;
    }

    public static void createMatrixDefaults() {
        List<NZC_EmissionsMatchingMatrix__c> matrixRecords = new List<NZC_EmissionsMatchingMatrix__c>();

        // electricity
        ElectricityEmssnFctrSet testElecFactor = NZC_EmissionsMatchingDatafactory.createElectricityEmissionSet('Matrix default', null, null);
        insert testElecFactor;

        matrixRecords.add(new NZC_EmissionsMatchingMatrix__c(
                ApplicableObject__c = ElectricityEmssnFctrSet.SObjectType + '',
                LookupOverride__c = testElecFactor.Id + ''
        ));

        // other
        OtherEmssnFctrSet testOtherFactor = NZC_EmissionsMatchingDatafactory.createOtherEmissionSet('matrix other default', null, null);
        insert testOtherFactor;

        OtherEmssnFctrSetItem testOtherItem1 = NZC_EmissionsMatchingDatafactory.createOtherEmissionsItem(testOtherFactor.Id);
        OtherEmssnFctrSetItem testOtherItem2 = NZC_EmissionsMatchingDatafactory.createOtherEmissionsItem(testOtherFactor.Id);
        testOtherItem2.FuelType = 'Gasoline';
        OtherEmssnFctrSetItem testOtherItem3 = NZC_EmissionsMatchingDatafactory.createOtherEmissionsItem(testOtherFactor.Id);
        testOtherItem3.FuelType = 'NaturalGas';
        insert new List<OtherEmssnFctrSetItem>{testOtherItem1, testOtherItem2, testOtherItem3};

        matrixRecords.add(new NZC_EmissionsMatchingMatrix__c(
                ApplicableObject__c = OtherEmssnFctrSet.SObjectType + '',
                LookupOverride__c = testOtherFactor.Id + ''
        ));

        // refri
        RefrigerantEmssnFctr testRefFactor = NZC_EmissionsMatchingDatafactory.createRefrigerantEmissionSet('matrix refri default', null, null);
        insert testRefFactor;

        matrixRecords.add(new NZC_EmissionsMatchingMatrix__c(
                ApplicableObject__c = RefrigerantEmssnFctr.SObjectType + '',
                LookupOverride__c = testRefFactor.Id + ''
        ));

        insert matrixRecords;
    }
}