# Emissions Matching User Guide

## Overview

The Emissions Matching solution provides a simple way to update emissions factors and recalculate any records connected to specific emissions factors. It also provides the ability to match emissions factors based on date boundaries as well as custom tags (example: countries).

Additionally, emissions factors can be automatically paired up into hierarchy structure if a flow has been provisioned to call matching Apex. This allows reference data loads to link up records into hierarchy structure minimizing having to involve any manual processes.

## Permission Set

**Required Permission Set**: `EmissionsMatching`

Assign this permission set to users who need access to the emissions matching functionality.

## Custom Fields

### Recalculate Emissions Fields

The following objects have a **Recalculate Emissions** checkbox field that flags records to be targeted by batch jobs or Apex triggers:

- **Stationary Energy Use** (`StnryAssetEnrgyUse`)
- **Vehicle Energy Use** (`VehicleAssetEnrgyUse`)
- **Hotel Energy Use** (`HotelStayEnrgyUse`)
- **Generated Waste** (`GeneratedWaste`)
- **Other Emissions Set** (`OtherEmssnFctrSet`)
- **Electricity Emissions Set** (`ElectricityEmssnFctrSet`)
- **Refrigerant Emissions Set** (`RefrigerantEmssnFctr`)
- **Hotel Emissions Set** (`HotelStayEmssnFctr`)
- **Waste Emissions Set** (`WstDispoEmssnFctrSet`)

### Master Emissions Set Fields

The following emissions set objects have a **Master Emissions Set** lookup field that tags an emissions set to a master set and enables the hierarchy structure:

- **Other Emissions Set** (`OtherEmssnFctrSet`)
- **Electricity Emissions Set** (`ElectricityEmssnFctrSet`)
- **Refrigerant Emissions Set** (`RefrigerantEmssnFctr`)
- **Hotel Emissions Set** (`HotelStayEmssnFctr`)
- **Waste Emissions Set** (`WstDispoEmssnFctrSet`)

### Emissions Factor Update Year Fields

The following emissions set objects have an **Emissions Factor Update Year** field that attaches a date to emissions sets for when they become active:

- **Other Emissions Set** (`OtherEmssnFctrSet`)
- **Electricity Emissions Set** (`ElectricityEmssnFctrSet`)
- **Refrigerant Emissions Set** (`RefrigerantEmssnFctr`)
- **Hotel Emissions Set** (`HotelStayEmssnFctr`)
- **Waste Emissions Set** (`WstDispoEmssnFctrSet`)

## Custom Setting: NZC Emissions Matching Configuration

The Custom Setting controls key features of how emissions are matched. Navigate to **Setup** → **Custom Settings** → **NZC Emissions Matching Configuration** → **Manage** → **New** to create a configuration record.

### Configuration Fields

#### Date Matching Field
- **Purpose**: Denotes what field should be used to match energy use records to emissions factors
- **Options**: `StartDate`, `EndDate`, or `Midpoint`
- **Default**: `StartDate`

#### Do Log
- **Purpose**: Used to enable Apex to log messages related to matching emissions, useful for debugging errors
- **Recommendation**: Keep off for better performance in production

#### Do Match Emissions on Insert
- **Purpose**: Enables Generated Waste, Stationary Energy Use, and Vehicle Energy Use to try to match emissions factors on record insert
- **Default**: `false`

#### Do Match Emissions on Update
- **Purpose**: Enables Generated Waste, Stationary Energy Use, and Vehicle Energy Use to try to match emissions factors on record update
- **Default**: `false`

#### Emissions Matching Batch Size
- **Purpose**: When the bulk process is fired from the custom component, this controls how many energy consumption records are rematched in a single batch
- **Default**: `200`
- **Recommendation**: 200 is a good default value

#### Emissions Recalc Batch Size
- **Purpose**: When the bulk emissions set process is fired, this controls how many records are processed at once. Each emissions set can have many records it forces to recalculate on
- **Default**: `50`
- **Recommendation**: 50 is a safe amount to start with for performance reasons

#### Allow Custom Tag Matching
- **Purpose**: Used to enable records to be matched by a Tag (example: country) instead of looking at the asset record for master emissions set
- **Default**: `false`

#### Allow Advanced Matching
- **Purpose**: Enables advanced hash-based matching capabilities
- **Default**: `false`

#### Allow Transmission Distribution
- **Purpose**: Enables Transmission & Distribution (T&D) loss processing for electricity emissions sets
- **Default**: `false`

## Custom Metadata Types Configuration

This section provides comprehensive documentation for all custom metadata types used in the Emissions Matching solution. Custom metadata types allow you to configure advanced matching behaviors without code changes.

### Prerequisites

Before configuring custom metadata types, ensure the following:
- **Custom Setting**: A `NZC_EmissionsMatchingConfig__c` record must exist
- **Permission Set**: Users must have the `EmissionsMatching` permission set assigned
- **Feature Flags**: Enable the appropriate feature flags in the custom setting:
  - `Allow Custom Tag Matching` for `NZC_EmissionsMatchingCustomMatch__mdt`
  - `Allow Advanced Matching` for `NZC_EmissionsMatchingAdvanceMatch__mdt`
  - `Allow Transmission Distribution` for `NZC_EmissionsMatchingTDCloning__mdt`

---

## Custom Metadata: NZC_EmissionsMatchingCustomMatch

The custom metadata is used to notify the emissions matching how to match for specific objects if custom tag matching is desired. This allows matching based on custom fields (e.g., country, ZIP code) instead of looking at the asset record for master emissions set.

**Use Case Example**: Matching Hotel energy use to Hotel emissions factors by country and bypassing the asset emissions factor set.

### Prerequisites

- **Custom Setting**: `Allow Custom Tag Matching` must be set to `true` in `NZC_EmissionsMatchingConfig__c`
- **Common Field**: Both the energy use record and emissions set record must have a common field with matching values (recommendation: use a global picklist field)

### Configuration Fields

#### Object Applies To (`ObjectAppliesTo__c`)
- **Type**: Text (Required)
- **Purpose**: What Net Zero Cloud object does this rule apply to?
- **Valid Objects**: Object must be one that emissions matching runs on:
  - Stationary Energy Use (`StnryAssetEnrgyUse`)
  - Vehicle Energy Use (`VehicleAssetEnrgyUse`)
  - Hotel Energy Use (`HotelStayEnrgyUse`)
  - Generated Waste (`GeneratedWaste`)
- **Example**: `StnryAssetEnrgyUse`

#### Fuel Type (`FuelType__c`)
- **Type**: Text (Optional)
- **Purpose**: For Stationary and Vehicle objects, specify what fuel this matching rule applies to. Some objects do not have a fuel type (Hotel Energy Use).
- **Examples**: 
  - `Electricity`
  - `Refrigerant`
  - `NaturalGas`
- **Note**: Leave blank for objects without fuel types (e.g., `HotelStayEnrgyUse`, `GeneratedWaste`)

#### Energy Use Field To Match (`EnergyUseFieldToMatch__c`)
- **Type**: Text (Required, max 75 characters)
- **Purpose**: API field name of the field on the energy use record that we want to look at when trying to match to an emissions set
- **Examples**: 
  - `Name` (for matching by record name)
  - `Country__c` (for matching by country)
  - `ZIP_Code__c` (for matching by ZIP code)
  - `PostalCode` (for matching by postal code)
- **Important**: This field must exist on the energy use object and contain values that match values in the emissions set field

#### Emissions Set Field To Match (`EmissionsSetFieldToMatch__c`)
- **Type**: Text (Required, max 75 characters)
- **Purpose**: API field name of the emissions set field that we want to look at when trying to match to an energy use record
- **Examples**: 
  - `Name` (for matching by record name)
  - `Country__c` (for matching by country)
  - `ZIP_Code__c` (for matching by ZIP code)
  - `PostalCodeSet` (for matching by postal code)
- **Important**: This field must exist on the emissions set object and contain values that match values in the energy use field

### Configuration Examples

#### Example 1: Stationary Energy Use - Electricity Matching by Name

This example matches Stationary Energy Use records with Electricity fuel type to Electricity Emissions Sets based on the `Name` field.

**Configuration:**
- **Object Applies To**: `StnryAssetEnrgyUse`
- **Fuel Type**: `Electricity`
- **Energy Use Field To Match**: `Name`
- **Emissions Set Field To Match**: `Name`

**How it works:**
1. When a Stationary Energy Use record with `FuelType = 'Electricity'` is created or updated
2. The system reads the `Name` field value from the energy use record
3. It searches for an Electricity Emissions Set with a matching `Name` value
4. If found, the energy use record is linked to that emissions set

**Test Class Reference**: `NZC_EmissionsMatchingEngineTest.testCustomKeyMatching()`

#### Example 2: Stationary Energy Use - Refrigerant Matching by Name

This example matches Stationary Energy Use records with Refrigerant fuel type to Refrigerant Emissions Sets based on the `Name` field.

**Configuration:**
- **Object Applies To**: `StnryAssetEnrgyUse`
- **Fuel Type**: `Refrigerant`
- **Energy Use Field To Match**: `Name`
- **Emissions Set Field To Match**: `Name`

**Test Class Reference**: `NZC_EmissionsMatchingEngineTest.testCustomKeyMatching()`

#### Example 3: Hotel Energy Use Matching by Country

This example matches Hotel Energy Use records to Hotel Emissions Sets based on country, bypassing the asset lookup.

**Configuration:**
- **Object Applies To**: `HotelStayEnrgyUse`
- **Fuel Type**: *(leave blank)*
- **Energy Use Field To Match**: `Country__c`
- **Emissions Set Field To Match**: `Country__c`

**How it works:**
1. When a Hotel Energy Use record is created or updated
2. The system reads the `Country__c` field value from the energy use record
3. It searches for a Hotel Emissions Set with a matching `Country__c` value
4. If found, the energy use record is linked to that emissions set

### Setup Instructions

1. Navigate to **Setup** → **Custom Metadata Types** → **NZC Emissions Matching Custom Match** → **Manage Records**
2. Click **New** to create a new custom metadata record
3. Fill in the required fields:
   - **Label**: Enter a descriptive label (e.g., "Stationary Electricity Name Match")
   - **Object Applies To**: Enter the API name of the object
   - **Fuel Type**: Enter the fuel type (if applicable) or leave blank
   - **Energy Use Field To Match**: Enter the API field name on the energy use record
   - **Emissions Set Field To Match**: Enter the API field name on the emissions set record
4. Click **Save**
5. Ensure `Allow Custom Tag Matching` is enabled in the custom setting
6. Test the configuration by creating or updating an energy use record with matching field values

### Important Notes

#### Case-Insensitive Matching

**Field value matching is case-insensitive** - the system automatically normalizes both energy use field values and emissions set field values to uppercase when performing custom matching. This means:
- An energy use record with `External_ID__c = "zone 1"` will match an emissions set with `Name = "ZONE 1"`
- An energy use record with `Country__c = "united states"` will match an emissions set with `Country__c = "United States"`
- Case differences between field values will not prevent matching

This ensures robust matching even when data entry conventions differ between energy use records and emissions sets.

---

## Custom Metadata: NZC_EmissionsMatchingCustomLookups

This custom metadata type allows you to override default lookup field mappings. By default, the system uses standard lookup fields on assets to find emissions factor sets. This metadata type enables you to specify a different lookup field to search when a specific fuel type needs to look at a non-standard lookup field on the asset.

**Use Case Example**: T&D (Transmission & Distribution) losses require looking at a specific lookup field on the asset that differs from the standard electricity emissions factor lookup.

### Prerequisites

- No specific feature flag required (works with standard matching)
- The specified lookup field must exist on the asset object
- The lookup field must reference an emissions set object

### Configuration Fields

#### Object Applies For (`ObjectAppliesFor__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: What object does this custom fuel mapping lookup apply to?
- **Valid Objects**:
  - Stationary Energy Use (`StnryAssetEnrgyUse`)
  - Vehicle Energy Use (`VehicleAssetEnrgyUse`)
  - Hotel Energy Use (`HotelStayEnrgyUse`)
  - Generated Waste (`GeneratedWaste`)
- **Example**: `StnryAssetEnrgyUse`

#### Fuel Applies For (`FuelAppliesFor__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: What fuel type does this custom lookup mapping apply for?
- **Examples**: 
  - `Electricity`
  - `Refrigerant`
  - `T&D Losses` (for Transmission & Distribution losses)
- **Note**: This must match the fuel type value used in the energy use records

#### Lookup To Search (`LookupToSearch__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: What API lookup field name should this fuel type look into on the asset?
- **Examples**: 
  - `T_D_Emissions_Factor_Set__c` (for T&D losses lookup)
  - `CustomElectricityEmssnFctrId__c` (for custom electricity lookup)
- **Important**: 
  - This must be the API name of a lookup field on the asset object
  - The field must reference an emissions set object
  - Use the full API name including `__c` suffix for custom fields

### Configuration Examples

#### Example 1: T&D Losses Custom Lookup

This example configures Stationary Energy Use records with T&D fuel type to look at a specific lookup field on the asset for finding the emissions factor set.

**Configuration:**
- **Object Applies For**: `StnryAssetEnrgyUse`
- **Fuel Applies For**: `T&D Losses`
- **Lookup To Search**: `T_D_Emissions_Factor_Set__c`

**How it works:**
1. When a Stationary Energy Use record with `FuelType = 'T&D Losses'` is processed
2. Instead of using the default lookup field (e.g., `ElectricityEmssnFctrId`), the system looks at `T_D_Emissions_Factor_Set__c` on the asset
3. The system retrieves the emissions factor set ID from this custom lookup field
4. The energy use record is matched to that emissions set

**Test Class Reference**: `NZC_EmissionsMatchingTDLossesTest.testCreateStationaryTDRecords()`

### Default Lookup Field Behavior

If no custom lookup rule is configured, the system uses default lookup fields based on object and fuel type:

- **Stationary Energy Use**:
  - `Electricity` → `ElectricityEmssnFctrId` on `StnryAssetEnvrSrc`
  - `Refrigerant` → `RefrigerantEmssnFctrId` on `StnryAssetEnvrSrc`
  - `Other` → `WstDispoEmssnFctrSetId` on `StnryAssetEnvrSrc`
- **Vehicle Energy Use**: `OtherEmssnFctrId` on `VehicleAssetEmssnSrc`
- **Hotel Energy Use**: `HotelStayEmssnFctrId` on the hotel asset
- **Generated Waste**: `WstDispoEmssnFctrSetId` on `StnryAssetEnvrSrc`

### Setup Instructions

1. Navigate to **Setup** → **Custom Metadata Types** → **NZC Emissions Matching Custom Lookups** → **Manage Records**
2. Click **New** to create a new custom metadata record
3. Fill in the required fields:
   - **Label**: Enter a descriptive label (e.g., "T&D Losses Custom Lookup")
   - **Object Applies For**: Enter the API name of the object
   - **Fuel Applies For**: Enter the fuel type value
   - **Lookup To Search**: Enter the API name of the lookup field on the asset
4. Click **Save**
5. Test the configuration by creating or updating an energy use record with the specified fuel type

---

## Custom Metadata: NZC_EmissionsMatchingAdvanceMatch

This custom metadata type enables hash-based advanced matching for complex matching scenarios. It allows matching based on multiple fields, secondary matching criteria, and quick search capabilities using hash values.

**Use Case Examples**: 
- Matching emissions sets to assets based on country with secondary postal code validation
- Generating hash codes on emissions sets for quick lookup
- Complex multi-field matching scenarios

### Prerequisites

- **Custom Setting**: `Allow Advanced Matching` must be set to `true` in `NZC_EmissionsMatchingConfig__c`
- **Hash Fields**: Fields specified in `HashFields__c` must exist on the source object
- **Target Fields**: Fields specified in `LookupDestination__c` and `SecondaryMatchFieldTarget__c` must exist on the target object

### Configuration Fields

#### Object Applies To (`ObjectAppliesTo__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: The object API name this matching rule applies to
- **Valid Objects**: Can be applied to:
  - Emissions set objects: `ElectricityEmssnFctrSet`, `OtherEmssnFctrSet`, `RefrigerantEmssnFctr`
  - Asset objects: `StnryAssetEnvrSrc`, `VehicleAssetEmssnSrc`
- **Example**: `StnryAssetEnvrSrc`

#### Hash Fields (`HashFields__c`)
- **Type**: Text (Optional, max 255 characters)
- **Purpose**: Comma-separated list of API field names used for searching or to be matched against
- **Format**: Comma-separated list (e.g., `Country,City` or `Name`)
- **Examples**: 
  - `Name` (single field)
  - `Country,City` (multiple fields)
  - `StationaryAssetIdentifier` (identifier field)
- **How it works**: 
  - For emissions sets: Values from these fields are concatenated and hashed, stored in `Hash_Destination__c`
  - For assets: Values from these fields are used to generate a hash for matching against emissions sets

#### Hash Destination (`Hash_Destination__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: The destination field on record to store the quick search value (hash)
- **When to use**: Typically used on emissions set objects to store generated hash codes
- **Examples**: 
  - `ExternalIdentifier` (commonly used field for storing hash)
  - `QuickSearchCode__c` (custom field)
- **Note**: This field should be a text field that can store the hash value

#### Lookup Destination (`LookupDestination__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: The quick search API field name on the target object to match against
- **When to use**: Used when matching assets to emissions sets - this is the field on the emissions set that contains the hash
- **Examples**: 
  - `ExternalIdentifier` (matches the hash stored in emissions sets)
- **Note**: This should match the `Hash_Destination__c` field on the target emissions set object

#### Lookup To Populate (`LookupToPopulate__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: The lookup field on source object to populate if a match is found
- **When to use**: Used on asset objects to specify which emissions factor lookup field should be populated
- **Examples**: 
  - `ElectricityEmssnFctrId` (on `StnryAssetEnvrSrc`)
  - `OtherEmssnFctrId` (on `StnryAssetEnvrSrc` or `VehicleAssetEmssnSrc`)
  - `RefrigerantEmssnFctrId` (on `StnryAssetEnvrSrc`)

#### Screening Field (`ScreeningField__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: API field name on trigger object used to screen out records from processing (Boolean field)
- **When to use**: If a record has this boolean field set to `true`, it will be excluded from advanced matching
- **Examples**: 
  - `SkipAdvancedMatching__c`
  - `ExcludeFromMatching__c`
- **Note**: Leave blank if no screening is needed

#### Secondary Match Source Field (`SecondaryMatchSourceField__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: Secondary field to compare after initial match is found. Field name should exist on triggering record. Use API name.
- **When to use**: When you need a two-level matching process - first match on hash, then validate with secondary field
- **Examples**: 
  - `PostalCode` (on `StnryAssetEnvrSrc`)
  - `State` (on asset objects)
- **Note**: This field is compared with `SecondaryMatchFieldTarget__c` after the initial hash match

#### Secondary Match Target Field (`SecondaryMatchFieldTarget__c`)
- **Type**: Text (Optional, max 150 characters)
- **Purpose**: Secondary match field to compare after initial match. Field should exist on target object. Use API name.
- **When to use**: Used in conjunction with `SecondaryMatchSourceField__c` for two-level matching
- **Examples**: 
  - `PostalCodeSet` (on `ElectricityEmssnFctrSet`)
  - `StateCode` (on emissions set objects)
- **Note**: This field is compared with `SecondaryMatchSourceField__c` after the initial hash match

### Configuration Examples

#### Example 1: Emissions Set Hash Generation

This example generates hash codes on emissions sets for quick lookup. When an emissions set is created or updated, its `Name` field is hashed and stored in `ExternalIdentifier`.

**Configuration:**
- **Object Applies To**: `ElectricityEmssnFctrSet`
- **Hash Fields**: `Name`
- **Hash Destination**: `ExternalIdentifier`
- **Lookup Destination**: *(leave blank - not used for hash generation)*
- **Lookup To Populate**: *(leave blank - not used for hash generation)*
- **Screening Field**: *(leave blank)*
- **Secondary Match Source Field**: *(leave blank)*
- **Secondary Match Target Field**: *(leave blank)*

**How it works:**
1. When an `ElectricityEmssnFctrSet` record is created or updated
2. The system reads the `Name` field value
3. It generates a hash from this value
4. The hash is stored in the `ExternalIdentifier` field
5. This hash can then be used for quick matching against assets

**Test Class Reference**: `NZC_EmissionsMatchingAdvancedMatchTest.testCreateMatchingCode()`

#### Example 2: Asset Matching by Country with Secondary Postal Code Match

This example matches stationary assets to electricity emissions sets based on country, with a secondary validation on postal code for more precise matching.

**Configuration:**
- **Object Applies To**: `StnryAssetEnvrSrc`
- **Hash Fields**: `Country`
- **Hash Destination**: *(leave blank - hash not stored on asset)*
- **Lookup Destination**: `ExternalIdentifier`
- **Lookup To Populate**: `ElectricityEmssnFctrId`
- **Screening Field**: *(leave blank)*
- **Secondary Match Source Field**: `PostalCode`
- **Secondary Match Target Field**: `PostalCodeSet`

**How it works:**
1. When a `StnryAssetEnvrSrc` record is processed
2. The system generates a hash from the `Country` field value
3. It searches for `ElectricityEmssnFctrSet` records where `ExternalIdentifier` matches this hash
4. If multiple matches are found, it compares `PostalCode` on the asset with `PostalCodeSet` on the emissions set
5. The best match (matching both country and postal code) is selected
6. The `ElectricityEmssnFctrId` field on the asset is populated with the matched emissions set ID

**Test Class Reference**: `NZC_EmissionsMatchingAdvancedMatchTest.testSecondLevelSearch()`

#### Example 3: Asset Matching by City (Simple Match)

This example matches stationary assets to other emissions sets based on city name.

**Configuration:**
- **Object Applies To**: `StnryAssetEnvrSrc`
- **Hash Fields**: `City`
- **Hash Destination**: *(leave blank)*
- **Lookup Destination**: `ExternalIdentifier`
- **Lookup To Populate**: `OtherEmssnFctrId`
- **Screening Field**: *(leave blank)*
- **Secondary Match Source Field**: *(leave blank)*
- **Secondary Match Target Field**: *(leave blank)*

**Test Class Reference**: `NZC_EmissionsMatchingAdvancedMatchTest.testAdvanceAssetMatch()`

#### Example 4: Vehicle Asset Matching by City

This example matches vehicle assets to other emissions sets based on city.

**Configuration:**
- **Object Applies To**: `VehicleAssetEmssnSrc`
- **Hash Fields**: `City`
- **Hash Destination**: *(leave blank)*
- **Lookup Destination**: `ExternalIdentifier`
- **Lookup To Populate**: `OtherEmssnFctrId`
- **Screening Field**: *(leave blank)*
- **Secondary Match Source Field**: *(leave blank)*
- **Secondary Match Target Field**: *(leave blank)*

**Test Class Reference**: `NZC_EmissionsMatchingAdvancedMatchTest.testAdvanceAssetMatch()`

### Advanced Matching Flow

1. **Hash Generation** (for emissions sets):
   - System reads values from `HashFields__c`
   - Concatenates and hashes the values
   - Stores hash in `Hash_Destination__c` field

2. **Asset Matching** (for assets):
   - System reads values from `HashFields__c` on the asset
   - Generates hash from these values
   - Searches emissions sets where `LookupDestination__c` matches the hash
   - If `SecondaryMatchSourceField__c` is specified:
     - Compares secondary field on asset with `SecondaryMatchFieldTarget__c` on emissions set
     - Selects best match based on both criteria
   - Populates `LookupToPopulate__c` field on asset with matched emissions set ID

### Setup Instructions

1. Navigate to **Setup** → **Custom Metadata Types** → **NZC Emissions Matching Advance Match** → **Manage Records**
2. Click **New** to create a new custom metadata record
3. Fill in the fields based on your use case:
   - **Label**: Enter a descriptive label
   - **Object Applies To**: Enter the API name of the object
   - **Hash Fields**: Enter comma-separated field names (if generating or matching on hash)
   - **Hash Destination**: Enter field to store hash (for emissions sets)
   - **Lookup Destination**: Enter hash field to match against (for assets)
   - **Lookup To Populate**: Enter lookup field to populate (for assets)
   - **Screening Field**: Enter boolean field name (optional)
   - **Secondary Match Source Field**: Enter secondary match field on source (optional)
   - **Secondary Match Target Field**: Enter secondary match field on target (optional)
4. Click **Save**
5. Ensure `Allow Advanced Matching` is enabled in the custom setting
6. Test the configuration by creating or updating records

---

## Custom Metadata: NZC_EmissionsMatchingTDCloning

This custom metadata type configures Transmission & Distribution (T&D) loss record cloning for specific objects and fuel types. When an energy use record is created with a specified fuel type, the system automatically creates a corresponding T&D loss record by cloning specified fields.

**Use Case**: Automatically creating T&D loss records when electricity energy use records are created, with specific fields cloned from the original record.

### Prerequisites

- **Custom Setting**: `Allow Transmission Distribution` must be set to `true` in `NZC_EmissionsMatchingConfig__c`
- **T&D Fuel Type**: A fuel type must be configured for T&D losses (typically `T&D Losses` or similar)
- **Scope Allocations**: T&D scope allocations must be created (handled automatically by `NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel()`)

### Configuration Fields

#### Object Name (`ObjectName__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: The Object API name this rule applies to
- **Valid Objects**:
  - Stationary Energy Use (`StnryAssetEnrgyUse`)
  - Vehicle Energy Use (`VehicleAssetEnrgyUse`)
- **Example**: `StnryAssetEnrgyUse`

#### Fuel Type (`FuelType__c`)
- **Type**: Text (Required, max 150 characters)
- **Purpose**: Fuel type that should be converted for T&D losses
- **Examples**: 
  - `Electricity` (most common - electricity consumption creates T&D loss records)
- **Note**: When an energy use record with this fuel type is created, a T&D loss record will be automatically created

#### Fields To Clone (`FieldsToClone__c`)
- **Type**: Text (Optional, max 255 characters)
- **Purpose**: Comma-separated list of API field names to clone when creating the T&D record
- **Format**: Comma-separated list (e.g., `StartDate,EndDate,FuelConsumption` or `SuplScope1Emissions`)
- **Examples**: 
  - `StartDate,EndDate,FuelConsumption,FuelConsumptionUnit` (basic fields)
  - `SuplScope1Emissions` (scope 1 emissions field)
  - `StartDate,EndDate,FuelConsumption,FuelConsumptionUnit,StnryAssetEnvrSrcId,SuplScope1Emissions` (comprehensive)
- **Default Behavior**: If not specified, standard fields are cloned (StartDate, EndDate, FuelConsumption, FuelConsumptionUnit, Asset lookup)
- **Important**: 
  - Field names must be valid API names on the source object
  - Fields will be copied as-is to the T&D loss record
  - The T&D loss record will have `FuelType` set to the T&D fuel type (e.g., `T&D Losses`)

### Configuration Examples

#### Example 1: Electricity T&D Loss Cloning with Scope 1 Emissions

This example configures Stationary Energy Use records with Electricity fuel type to automatically create T&D loss records, cloning the scope 1 emissions field in addition to standard fields.

**Configuration:**
- **Object Name**: `StnryAssetEnrgyUse`
- **Fuel Type**: `Electricity`
- **Fields To Clone**: `SuplScope1Emissions`

**How it works:**
1. When a Stationary Energy Use record with `FuelType = 'Electricity'` is created
2. The system automatically creates a new Stationary Energy Use record for T&D losses
3. The T&D record has:
   - `FuelType = 'T&D Losses'` (or configured T&D fuel type)
   - `TDLossParent__c` = ID of the original electricity record
   - Standard fields cloned: `StartDate`, `EndDate`, `FuelConsumption`, `FuelConsumptionUnit`, `StnryAssetEnvrSrcId`
   - Additional field cloned: `SuplScope1Emissions` (as specified in the rule)
4. The T&D record is linked to the appropriate emissions factor set via custom lookup rules

**Test Class Reference**: `NZC_EmissionsMatchingTDLossesTest.testCreateStationaryTDRecords()`

### T&D Loss Record Structure

When a T&D loss record is created, it has the following characteristics:

- **Parent Relationship**: `TDLossParent__c` field links back to the original energy use record
- **Fuel Type**: Set to the configured T&D fuel type (e.g., `T&D Losses`)
- **Cloned Fields**: Fields specified in `FieldsToClone__c` are copied from the original record
- **Asset Link**: The asset relationship is maintained (e.g., `StnryAssetEnvrSrcId`)
- **Emissions Factor**: Linked via custom lookup rules to the appropriate T&D emissions factor set

### Integration with Custom Lookups

T&D loss records use custom lookup rules to find their emissions factor sets. You must configure a `NZC_EmissionsMatchingCustomLookups__mdt` record:

- **Object Applies For**: `StnryAssetEnrgyUse`
- **Fuel Applies For**: `T&D Losses` (or your configured T&D fuel type)
- **Lookup To Search**: The lookup field on the asset that points to the T&D emissions factor set

### Setup Instructions

1. **Enable T&D Feature**:
   - Navigate to **Setup** → **Custom Settings** → **NZC Emissions Matching Configuration**
   - Set `Allow Transmission Distribution` to `true`

2. **Create T&D Scope Allocations** (if not already created):
   - Run the method `NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel()` via Anonymous Apex or ensure it's called during setup

3. **Configure Custom Lookup Rule**:
   - Create a `NZC_EmissionsMatchingCustomLookups__mdt` record for T&D fuel type
   - See "Custom Metadata: NZC_EmissionsMatchingCustomLookups" section above

4. **Configure T&D Cloning Rule**:
   - Navigate to **Setup** → **Custom Metadata Types** → **NZC Emissions Matching TD Cloning** → **Manage Records**
   - Click **New** to create a new custom metadata record
   - Fill in the fields:
     - **Label**: Enter a descriptive label (e.g., "Electricity T&D Cloning")
     - **Object Name**: Enter `StnryAssetEnrgyUse`
     - **Fuel Type**: Enter `Electricity`
     - **Fields To Clone**: Enter comma-separated list of additional fields to clone (optional)
   - Click **Save**

5. **Test the Configuration**:
   - Create a Stationary Energy Use record with `FuelType = 'Electricity'`
   - Verify that a T&D loss record is automatically created
   - Verify that the specified fields are cloned correctly

### Common Fields to Clone

- `SuplScope1Emissions` - Scope 1 supplementary emissions
- `Scope1Emissions` - Scope 1 emissions
- `Scope2Emissions` - Scope 2 emissions
- `Scope3Emissions` - Scope 3 emissions
- Custom fields specific to your organization's requirements

---

## Data Structure Overview

### Emissions Sets Structure

Emissions sets need to be set up in a hierarchy structure to take advantage of emissions matching code. This structure is fairly simple to set up.

#### Setting Up Master and Child Emissions Sets

1. **Create or pull up an emissions set record** that is going to be the master Set
2. **Check off the 'Recalculate emissions' checkbox**
3. **Clone this record**, while cloning:
   - Set the `EmissionsFactorUpdateYear__c` to today's date (or any date you want it to pick up records from)
   - Set `MasterEmissionsSet__c` to be the Master set we cloned this record from
   - Change the name to prevent confusion
4. **Run the Emissions Set recalculate batch**

This will force all records attached to the current master set to rematch and any applicable records will be moved to the new set.

5. **Going forward**, any energy use records will now start to match the cloned emissions set if the dates are after the 'Emissions factor update year date'

#### Example Hierarchy Structure

```
Master Emissions Set (EEIO Default)
├── Child Emissions Set (EEIO 2023) - EmissionsFactorUpdateYear__c = 2023-01-01
├── Child Emissions Set (EEIO 2024) - EmissionsFactorUpdateYear__c = 2024-01-01
└── Child Emissions Set (EEIO 2025) - EmissionsFactorUpdateYear__c = 2025-01-01
```

### Emissions Sets Custom Matching Structure

For custom matching, Energy Use and Emissions Sets need a common field with common values. **Recommendation is a global picklist field**. This field is used in concert with the custom tag matching MTD to pair energy use to emissions sets based on a value instead of looking to the asset.

## How Matching Works

### Standard Matching Process

1. **Master Emissions Sets** are identified and serve as the default match if no better match is found
2. **All child emission sets** are queried that have the master set records as their parent
3. **Child records are date ordered** for efficiency
4. **The triggering record** has its date to compare field selected based on the custom setting Date Matching field
5. **This is used to find the closest date** with a value less than the date to compare to on the record
6. **If no better match is found**, then the master set is used
7. **Records then proceed to update** with the matched emissions set

### Custom Tag Matching Process

1. **Custom Metadata Rule** is configured for the object and fuel type
2. **Energy Use record** is evaluated for the field specified in `EnergyUseFieldToMatch__c`
3. **Emissions Sets** are queried matching the value in `EmissionsSetFieldToMatch__c`
4. **Matching occurs** based on the custom field value instead of asset lookup
5. **Record is updated** with the matched emissions set

## Running Matching Batch

The Apex batch processes flagged energy use records and rematches emissions. Order of processed records is:
1. Stationary Energy Use
2. Vehicle Energy Use
3. Generated Waste
4. Hotel Energy Use

### Using the Lightning Web Component

1. On a record page for an energy use record, add the component named **NzcEmissionsMatchingBatchStart** to the page layout
2. The emissions matching custom setting holds a value for how many records to process per batch - verify this value is populated
3. Hit the **'Start batch'** button
4. Monitor progress through the component's progress bar

### Using Anonymous Apex

Alternatively, you can run the batch using Anonymous Apex:

```apex
Database.executeBatch(new NZC_EmissionsMatchingBatch());
```

## Running Emissions Set Recalculation Batch

The recalculation batch processes emissions sets flagged for recalculation and updates related energy use records.

### Using the Lightning Web Component

1. On a record page for an energy use record, add the component named **NzcEmissionsRecalcBatchStart** to the page layout
2. The emissions matching custom setting holds a value for how many emissions set records to process per batch - verify this value is populated
3. Hit the **'Start batch'** button
4. Monitor progress through the component's progress bar

### Using Anonymous Apex

Alternatively, you can run the batch using Anonymous Apex:

```apex
Database.executeBatch(new NZC_EmissionsSetRecalcBatch());
```

### Recalculation Process

1. **Emissions set records** with the 'Recalculate emissions' checkbox checked are selected
2. **Records are loaded** and IDs extracted
3. **Energy use records** are queried that are attached to the flagged emissions set
4. **These selected energy use records** have the 'Recalculate emissions' checkbox checked
5. **These energy use records** are then updated, triggering a rematch or emissions recalc based on the custom setting for 'Match emissions on update'

## Reference Data Load Matching

Reference data loads can automatically create hierarchy structures for emissions sets using a flow and Apex action.

### Prerequisites

1. A custom flow is set up to run on emissions factor set that fires matching Apex code
2. The **NZC_EmissionsMatchingInsertEngine** custom Apex action is called from the flow

### Required Parameters

1. **Field Name**: The name of the field used to keep track of when an emissions factor begins being used. If unsure, use `EmissionsFactorUpdateYear__c` (the custom field this solution provides)
2. **Lookup Field Name**: The lookup field name used to link emissions sets into hierarchy. By default with this solution, we use `MasterEmissionsSet__c`
3. **Record**: The record being processed needs to be passed in as well

### How Reference Data Load Matching Works

1. **Flow fires** and triggers Apex code
2. **Apex code takes the name** of the record passed in and cleans it:
   - Strips out any brackets or symbols from name
   - Attempts to find a date from the name (example: if name is "EEIO 2023", it pulls out "2023")
   - Numbers and any extra whitespace are stripped out from name
3. **System is queried** to try to find emissions sets with the same name format to link into hierarchy
4. **Emissions returned are checked by dates** to find the oldest record to make it the 'Master' or default emissions set in the hierarchy
5. **Other emissions factors** are then linked underneath in hierarchy structure

### Expected Matching Behavior

1. **If an emissions set comes in without relevance dates**, dates are attempted to be pulled from the name of the record (example: name "EEIO 2023" would pull "2023" and set it as relevance date)
2. **If an emissions set comes in with no relevance dates at all and none are pulled from name**, it's expected to be the default set and used as master
3. **If an emissions set is inserted with a date older than the current master set**, it will replace the current master set. This does not update the assets with the new master set however (example: EEIO 2023 exists in system linked to assets, EEIO 2022 is inserted, EEIO 2022 becomes master set in hierarchy and EEIO 2023 is linked as child record, but the asset still has EEIO 2023 linked to it)

## Naming Convention for Emissions Sets

Naming convention is important because that's how emissions sets match. Below is a recommended approach:

### Standard Reference Data Load Format

The recommended naming format follows this pattern:

**`<Source> - <Type> - <Year>`**

**Examples:**
- `EEIO - Default` (Master set)
- `EEIO - 2023` (Child set for 2023)
- `EEIO - 2024` (Child set for 2024)
- `EPA - Electricity - 2023`
- `GHG Protocol - Stationary - 2024`

### Naming Best Practices

1. **Master Sets**: Use a simple name without year (e.g., "EEIO - Default")
2. **Child Sets**: Include the year or date in the name (e.g., "EEIO - 2023")
3. **Consistency**: Use the same source prefix for related sets
4. **Avoid Special Characters**: Keep names simple and avoid brackets, special symbols
5. **Date Extraction**: The system can extract dates from names, so including the year helps with automatic date assignment

## Page Layout Configuration

### Energy Use Page Layouts

Add the **Recalculate emission** checkbox field to:
- Vehicle energy use page layouts
- Stationary energy use page layouts
- Waste energy use page layouts
- Hotel energy use page layouts

### Emissions Set Page Layouts

Add the following fields to Refrigerant, Electricity, Waste, and Other emissions sets page layouts:
- **Recalculate emissions** checkbox
- **Master emissions set** lookup field
- **Emissions Factor Update Year** field
- **Date active** fields (StartDate, EndDate, Midpoint)

## Lightning Web Components

### NzcEmissionsMatchingBatchStart

Component for starting the emissions matching batch job. Provides:
- Start batch button
- Progress bar showing batch completion status
- Real-time status updates
- Error message display

**Usage**: Add to energy use record page layouts where users need to trigger matching.

### NzcEmissionsRecalcBatchStart

Component for starting the emissions set recalculation batch job. Provides:
- Start batch button
- Progress bar showing batch completion status
- Real-time status updates
- Error message display

**Usage**: Add to energy use record page layouts where users need to trigger recalculation.

## Flows

### Link Electricity Sets

Flow for linking electricity emissions sets. Handles relationships between electricity emissions factor sets and related records.

## Apex Classes Reference

### Core Engine Classes
- **NZC_EmissionsMatchingEngine**: Main matching engine
- **NZC_EmissionsMatchingInsertEngine**: Engine for insert operations
- **NZC_EmissionsSetRecalcEngine**: Recalculation engine

### Batch Classes
- **NZC_EmissionsMatchingBatch**: Batch processor for matching
- **NZC_EmissionsSetRecalcBatch**: Batch processor for recalculation
- **NZC_EmissionsMatchingBatchController**: Controller for LWC components

### Wrapper Classes
- **NZC_EmissionsMatchingWrapper**: Base wrapper class
- **NZC_EmissionsMatchingHotelWrapper**: Hotel-specific wrapper
- **NZC_EmissionsMatchingStationaryWrapper**: Stationary-specific wrapper
- **NZC_EmissionsMatchingVehicleWrapper**: Vehicle-specific wrapper
- **NZC_EmissionsMatchingWasteWrapper**: Waste-specific wrapper
- **NZC_EmissionMatchingInsertWrapper**: Insert operation wrapper

### Utility Classes
- **NZC_EmissionsMatchingConstants**: Constants and mappings
- **NZC_EmissionsMatchingUtil**: Utility methods
- **NZC_EmissionsMatchingLog**: Logging utility
- **NZC_EmissionsMatchingMTD**: Metadata type data loader
- **NZC_EmissionsMatchingDatafactory**: Test data factory

### Advanced Matching Classes
- **NZC_EmissionsMatchingAdvancedMatch**: Advanced matching engine
- **NZC_EmissionsMatchingAdvancedMatchWpr**: Advanced matching wrapper

### T&D Losses Classes
- **NZC_EmissionsMatchingTDLosses**: Transmission & Distribution losses handler

All classes have corresponding test classes for code coverage.

## Troubleshooting

### Matching Not Working

1. **Check Custom Setting**: Verify that `NZC_EmissionsMatchingConfig__c` has a record created
2. **Check Permission Set**: Ensure users have the `EmissionsMatching` permission set assigned
3. **Check Triggers**: Verify that "Do match emissions on insert/update" is enabled if using triggers
4. **Check Date Matching Field**: Verify the Date Matching Field is set correctly in custom settings
5. **Check Master Emissions Set**: Ensure emissions sets have proper master set relationships
6. **Enable Logging**: Set "do Log" to `true` in custom settings to see debug messages

### Batch Jobs Not Running

1. **Check Batch Size**: Verify batch size values are set in custom settings
2. **Check Component**: Ensure LWC components are added to page layouts
3. **Check Permissions**: Verify user has permission to run batch jobs
4. **Check Limits**: Monitor Apex governor limits if processing large volumes

### Custom Matching Not Working

1. **Check Custom Metadata**: Verify `NZC_EmissionsMatchingCustomMatch__mdt` records are created
2. **Check Allow Custom Tag Matching**: Ensure this is enabled in custom settings
3. **Check Field Names**: Verify API field names in custom metadata match actual field names
4. **Check Field Values**: Ensure energy use and emissions set records have matching values in the specified fields

### Custom Metadata Configuration Issues

#### Custom Match Metadata Not Working

1. **Verify Feature Flag**: Ensure `Allow Custom Tag Matching` is set to `true` in `NZC_EmissionsMatchingConfig__c`
2. **Check Object Name**: Verify `ObjectAppliesTo__c` uses the exact API name (e.g., `StnryAssetEnrgyUse`, not "Stationary Energy Use")
3. **Check Fuel Type**: 
   - For Stationary/Vehicle objects, ensure `FuelType__c` matches the exact fuel type value used in records
   - For objects without fuel types (Hotel, Waste), leave `FuelType__c` blank
4. **Verify Field Existence**: 
   - Ensure `EnergyUseFieldToMatch__c` field exists on the energy use object
   - Ensure `EmissionsSetFieldToMatch__c` field exists on the emissions set object
5. **Check Field Values**: Verify that energy use records and emissions set records have matching values in the specified fields (case-insensitive matching is supported)
6. **Case Sensitivity**: Field value matching is **case-insensitive** - the system automatically normalizes values to uppercase, so "zone 1" will match "ZONE 1"
7. **Enable Logging**: Set `doLog__c` to `true` in custom settings to see detailed matching logs

#### Custom Lookup Metadata Not Working

1. **Verify Object Name**: Ensure `ObjectAppliesFor__c` uses the exact API name
2. **Check Fuel Type**: Verify `FuelAppliesFor__c` matches the exact fuel type value used in energy use records
3. **Verify Lookup Field**: 
   - Ensure `LookupToSearch__c` field exists on the asset object
   - Verify the field is a lookup field (not a text field)
   - Check that the lookup field references the correct emissions set object type
4. **Check Field Permissions**: Ensure the user has read access to the lookup field on the asset
5. **Verify Data**: Ensure the asset record has a value populated in the specified lookup field

#### Advanced Matching Metadata Not Working

1. **Verify Feature Flag**: Ensure `Allow Advanced Matching` is set to `true` in `NZC_EmissionsMatchingConfig__c`
2. **Check Object Name**: Verify `ObjectAppliesTo__c` uses the exact API name
3. **Verify Hash Fields**: 
   - Ensure all fields in `HashFields__c` exist on the source object
   - Check that fields are comma-separated (no spaces after commas)
   - Verify field API names are correct (including `__c` suffix for custom fields)
4. **Check Hash Destination**: 
   - For emissions sets: Ensure `Hash_Destination__c` field exists and is a text field
   - Verify the field can store the generated hash value
5. **Verify Lookup Destination**: 
   - Ensure `LookupDestination__c` field exists on the target emissions set object
   - This should typically match `Hash_Destination__c` on emissions sets
6. **Check Lookup To Populate**: 
   - Ensure `LookupToPopulate__c` field exists on the source asset object
   - Verify it's a lookup field to the correct emissions set object type
7. **Secondary Match Fields**: 
   - If using secondary matching, ensure both `SecondaryMatchSourceField__c` and `SecondaryMatchFieldTarget__c` exist
   - Verify field types are compatible (e.g., both text, both number)
8. **Hash Generation**: 
   - For emissions sets, verify that hash is being generated (check `Hash_Destination__c` field after record save)
   - If hash is not generated, check that `HashFields__c` contains valid field names

#### T&D Cloning Metadata Not Working

1. **Verify Feature Flag**: Ensure `Allow Transmission Distribution` is set to `true` in `NZC_EmissionsMatchingConfig__c`
2. **Check Object Name**: Verify `ObjectName__c` uses the exact API name (`StnryAssetEnrgyUse`)
3. **Check Fuel Type**: Verify `FuelType__c` matches the exact fuel type value used in energy use records (typically `Electricity`)
4. **Verify Fields To Clone**: 
   - Ensure all fields in `FieldsToClone__c` exist on the source object
   - Check that fields are comma-separated (no spaces after commas)
   - Verify field API names are correct
5. **Check T&D Fuel Type**: 
   - Verify that the T&D fuel type is configured (typically `T&D Losses`)
   - Ensure this fuel type matches what's used in `NZC_EmissionsMatchingCustomLookups__mdt`
6. **Verify Custom Lookup Rule**: 
   - Ensure a `NZC_EmissionsMatchingCustomLookups__mdt` record exists for the T&D fuel type
   - Verify the lookup field on the asset is populated with a T&D emissions factor set
7. **Check Scope Allocations**: 
   - Verify that T&D scope allocations have been created
   - Run `NZC_EmissionsMatchingTDLosses.createAllocationsForT_DFuel()` if needed
8. **Check T&D Record Creation**: 
   - After creating an energy use record, verify a T&D record is created
   - Check that `TDLossParent__c` on the T&D record points to the original record
   - Verify that specified fields are cloned correctly

### Common Configuration Mistakes

1. **Incorrect API Names**: Using display names instead of API names (e.g., "Stationary Energy Use" instead of `StnryAssetEnrgyUse`)
2. **Missing Feature Flags**: Forgetting to enable the required feature flag in custom settings
3. **Field Name Typos**: Misspelling field API names or forgetting `__c` suffix for custom fields
4. **Fuel Type Mismatch**: Using different fuel type values in metadata vs. actual records
5. **Comma Spaces**: Adding spaces after commas in comma-separated lists (should be `Field1,Field2` not `Field1, Field2`)
6. **Missing Secondary Fields**: Configuring secondary match source but forgetting to configure target (or vice versa)
7. **Wrong Object Types**: Using the wrong object API name (e.g., using asset object name when energy use object is needed)

## Additional Resources

- See [README.md](../README.md) for installation instructions
- See [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md) for technical architecture details
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines



