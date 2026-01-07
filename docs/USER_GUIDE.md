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

## Custom Metadata: NZC_EmissionsMatchingCustomMatch

The custom metadata is used to notify the emissions matching how to match for specific objects if custom tag matching is desired. Example: Matching Hotel energy use to Hotel emissions factors by country and bypassing the asset emissions factor set.

### Custom Match Fields

#### Object Applies To
- **Purpose**: What Net Zero Cloud object does this rule apply to?
- **Valid Objects**: Object must be one that emissions matching runs on:
  - Stationary Energy Use (`StnryAssetEnrgyUse`)
  - Vehicle Energy Use (`VehicleAssetEnrgyUse`)
  - Hotel Energy Use (`HotelStayEnrgyUse`)
  - Generated Waste (`GeneratedWaste`)

#### Fuel Type
- **Purpose**: Optional field, some objects do not have a fuel type (Hotel Energy Use). For Stationary and Vehicle, specify what fuel this matching rule applies to
- **Examples**: `Electricity`, `Refrigerant`

#### Energy Use Field To Match
- **Purpose**: API field name of the field on the energy use record that we want to look at when trying to match to an emissions set
- **Example**: `Country__c`, `ZIP_Code__c`

#### Emissions Set Field To Match
- **Purpose**: API field name of the emissions set field that we want to look at when trying to match to an energy use record
- **Example**: `Country__c`, `ZIP_Code__c`

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

## Additional Resources

- See [README.md](../README.md) for installation instructions
- See [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md) for technical architecture details
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines



