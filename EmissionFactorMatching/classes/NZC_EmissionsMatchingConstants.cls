/**
 * Created by mverigin on 6/16/23.
 */

public with sharing class NZC_EmissionsMatchingConstants {

    public static final String FUEL_TYPE_ELECTRICITY = 'Electricity';
    public static final String FUEL_TYPE_REFRIGERANT = 'Refrigerant';

    public static final String OBJECT_STATIONARY_ENERGY_USE = 'StnryAssetEnrgyUse';
    public static final String OBJECT_VEHICLE_ENERGY_USE = 'VehicleAssetEnrgyUse';
    public static final String OBJECT_WASTE_USE = 'GeneratedWaste';
    public static final String OBJECT_HOTEL_USE = 'HotelStayEnrgyUse';
    public static final String OBJECT_WATER_USE = 'StnryAssetWaterActvty';

    public static final String OBJECT_OTHER_EMISSION_SET = 'OtherEmssnFctrSet';
    public static final String OBJECT_ELECTRICITY_SET = 'ElectricityEmssnFctrSet';
    public static final String OBJECT_REFRIGERANT_SET = 'RefrigerantEmssnFctr';
    public static final String OBJECT_WASTE_SET = 'WstDispoEmssnFctrSet';
    public static final String OBJECT_HOTEL_SET = 'HotelStayEmssnFctr';

    public static final String OBJECT_STATIONARY_ASSET = 'StnryAssetEnvrSrc';
    public static final String OBJECT_VEHICLE_ASSET = 'VehicleAssetEmssnSrc';
    public static final String OBJECT_SCOPE3_ASSET = 'Scope3EmssnSrc';

    public static final String FIELD_STATIONARY_ASSET_ELECTRIC_EMISSIONS = 'ElectricityEmssnFctrId';
    public static final String FIELD_STATIONARY_ASSET_REFRIGERANT_EMISSIONS = 'RefrigerantEmssnFctrId';
    public static final String FIELD_STATIONARY_ASSET_WASTE_EMISSIONS = 'WstDispoEmssnFctrSetId';
    public static final String FIELD_HOTEL_ASSET_EMISSIONS = 'HotelStayEmssnFctrId';
    public static final String FIELD_OTHER_ASSET_EMISSIONS = 'OtherEmssnFctrId';

    public static final String FIELD_EUR_ELECTRIC_EMISSIONS = 'ElectricityEmissionFactorsId';
    public static final String FIELD_EUR_REFRIGERANT_EMISSIONS = 'RefrigerantEmssnFctrId';
    public static final String FIELD_EUR_WASTE_EMISSIONS = 'WstDispoEmssnFctrId';
    public static final String FIELD_EUR_HOTEL_EMISSIONS = 'HotelStayEmssnFctrId';
    public static final String FIELD_EUR_OTHER_EMISSIONS = 'OtherEmssnFctrId';

    public static final String FIELD_EUR_STARTDATE = 'StartDate';
    public static final String FIELD_EUR_ENDDATE = 'EndDate';
    public static final String FIELD_EUR_MIDPOINT = 'Midpoint';
    public static final String EMISSIONS_MATCHING_SCREENING_FIELD = 'Recalculate_Emissions__c';

    // batch job related
    public static final Integer EMISSIONS_MATCH_BATCH_SIZE = 200;
    public static final Integer EMISSIONS_RECALC_BATCH_SIZE = 50;
    public static final String EMISSIONS_MATCH_BATCH_NAME = 'NZC_EmissionsMatchingBatch';
    public static final String EMISSIONS_RECALC_BATCH_NAME = 'NZC_EmissionsSetRecalcBatch';
    public static final String STATUS_BATCH_COMPLETED = 'Completed';
    public static final String STATUS_BATCH_ABORTED = 'Aborted';
    public static final String STATUS_BATCH_HOLDING = 'Holding';

    // asset field to get emissions Ids from for specific EUR type
    public static final Map<String, String> ASSET_OBJECT_SPECIFIC_FIELDS_MAP = new Map<String, String>{
            OBJECT_WASTE_USE => FIELD_STATIONARY_ASSET_WASTE_EMISSIONS,
            OBJECT_HOTEL_USE => FIELD_HOTEL_ASSET_EMISSIONS
    };

    // field to get emissions Ids from on stationary asset based on fuel type
    public static final Map<String, String> ASSET_FUEL_SPECIFIC_FIELDS_MAP = new Map<String, String>{
            FUEL_TYPE_ELECTRICITY => FIELD_STATIONARY_ASSET_ELECTRIC_EMISSIONS,
            FUEL_TYPE_REFRIGERANT => FIELD_STATIONARY_ASSET_REFRIGERANT_EMISSIONS
    };

    // where to put emissions for EUR object type
    public static final Map<String, String> EUR_OBJECT_SPECIFIC_FIELDS_MAP = new Map<String, String>{
            OBJECT_WASTE_USE => FIELD_EUR_WASTE_EMISSIONS,
            OBJECT_HOTEL_USE => FIELD_EUR_HOTEL_EMISSIONS
    };

    // where to put emissions Ids on stationary EUR
    public static final Map<String, String> EUR_FUEL_SPECIFIC_FIELDS_MAP = new Map<String, String>{
            FUEL_TYPE_ELECTRICITY => FIELD_EUR_ELECTRIC_EMISSIONS,
            FUEL_TYPE_REFRIGERANT => FIELD_EUR_REFRIGERANT_EMISSIONS
    };

    // used to know what object to query for eur type
    public static final Map<String, String> EUR_ASSET_OBJ_LOOKUP = new Map<String, String>{
            OBJECT_STATIONARY_ENERGY_USE => OBJECT_STATIONARY_ASSET,
            OBJECT_VEHICLE_ENERGY_USE => OBJECT_VEHICLE_ASSET,
            OBJECT_WASTE_USE => OBJECT_STATIONARY_ASSET,
            OBJECT_HOTEL_USE => OBJECT_SCOPE3_ASSET
    };

    // used to jump from emissions set record to lookup field name for dynamic query
    public static final Map<String, String> EMISSIONS_SET_EMISSIONS_LOOKUP_FIELDNAME_MAP = new Map<String, String>{
            OBJECT_ELECTRICITY_SET => FIELD_EUR_ELECTRIC_EMISSIONS,
            OBJECT_REFRIGERANT_SET => FIELD_EUR_REFRIGERANT_EMISSIONS,
            OBJECT_OTHER_EMISSION_SET => FIELD_EUR_OTHER_EMISSIONS
    };

    // used to know what emissions object we are looking for from energy use fuel type
    public static final Map<String, String> ENERGY_USE_EMISSIONS_SET_NAME_MAP = new Map<String, String>{
            FUEL_TYPE_ELECTRICITY => OBJECT_ELECTRICITY_SET,
            FUEL_TYPE_REFRIGERANT => OBJECT_REFRIGERANT_SET
    };

    // used to know what emissions object we are looking for from energy use type
    public static final Map<String, String> EUR_OBJECT_EMISSIONS_SET_NAME_MAP = new Map<String, String>{
            OBJECT_WASTE_USE => OBJECT_WASTE_SET,
            OBJECT_HOTEL_USE => OBJECT_HOTEL_SET
    };
}