# EmissionsMatching Repository

**EmissionsMatching** (NZC Emissions Factor Matching) is a Salesforce DX-based application for automatically matching emissions factors to energy use records based on active date ranges. The system provides intelligent date-based matching, custom field matching, advanced matching capabilities, and batch processing for large-scale emissions factor assignment across multiple energy use object types (Stationary, Vehicle, Waste, Hotel).

## Overview

This Salesforce managed package provides:

- **Automated Emissions Factor Matching**: Automatically matches emissions factors to energy use records based on date ranges (StartDate, EndDate, or Midpoint)
- **Multi-Object Support**: Handles Stationary Energy Use, Vehicle Energy Use, Waste, and Hotel Stay energy use records
- **Flexible Matching Strategies**: Supports standard date matching, custom field matching, and advanced matching via metadata configuration
- **Batch Processing**: Processes large volumes of records efficiently through configurable batch jobs
- **Transmission & Distribution Support**: Handles T&D losses and cloning for electricity emissions sets
- **Configurable Triggers**: Optional insert and update triggers for real-time matching
- **Master Emissions Set Management**: Supports hierarchical emissions sets with parent-child relationships
- **Recalculation Engine**: Batch process to recalculate emissions when emissions sets are updated

## Technology Stack

- **Platform**: Salesforce Platform (API Version 60.0)
- **Development Framework**: Salesforce DX (SFDX)
- **Backend**: Apex (with sharing model for security)
- **Frontend**: Lightning Web Components (LWC)
- **Metadata Types**: Custom Metadata Types for configuration
- **Batch Processing**: Apex Batchable interface
- **Testing**: Apex Test Classes with comprehensive coverage
- **Development Tools**: Salesforce CLI, VS Code/Cursor with Salesforce extensions
- **Version Control**: Git with GitHub

## Architecture

### Core Components

#### Apex Classes

##### Engine Classes (Core Logic)
- **`NZC_EmissionsMatchingEngine`**: Main matching engine that orchestrates the emissions factor matching process. Handles date-based matching, master emissions set lookups, custom matching keys, and populates matched emissions factors on energy use records. Manages complex queries across multiple emissions set objects and asset relationships.

- **`NZC_EmissionsMatchingInsertEngine`**: Specialized engine for handling emissions matching during record insert operations when record IDs are not yet available. Uses temporary generated IDs for linking updates back to records.

- **`NZC_EmissionsSetRecalcEngine`**: Engine for recalculating emissions when emissions sets are updated. Processes emissions sets marked for recalculation and updates all related energy use records.

##### Wrapper Classes (Data Transfer Objects)
- **`NZC_EmissionsMatchingWrapper`**: Base wrapper class that encapsulates energy use record information for matching. Contains asset ID, energy use record ID, object name, fuel type, date to match, and matched emissions factor ID. Provides methods to determine lookup field names dynamically based on object and fuel type.

- **`NZC_EmissionsMatchingHotelWrapper`**: Specialized wrapper for hotel stay energy use records with hotel-specific matching logic.

- **`NZC_EmissionsMatchingStationaryWrapper`**: Specialized wrapper for stationary energy use records with stationary-specific matching logic.

- **`NZC_EmissionsMatchingVehicleWrapper`**: Specialized wrapper for vehicle energy use records with vehicle-specific matching logic.

- **`NZC_EmissionsMatchingWasteWrapper`**: Specialized wrapper for waste energy use records with waste-specific matching logic.

- **`NZC_EmissionMatchingInsertWrapper`**: Wrapper specifically designed for insert operations with temporary ID handling.

##### Advanced Matching Classes
- **`NZC_EmissionsMatchingAdvancedMatch`**: Handles advanced matching scenarios using custom metadata configuration. Supports hash-based matching, secondary match fields, and lookup population based on metadata rules.

- **`NZC_EmissionsMatchingAdvancedMatchWpr`**: Wrapper class for advanced matching operations that encapsulates advanced matching logic and data structures.

##### Batch Processing Classes
- **`NZC_EmissionsMatchingBatch`**: Batchable class that processes energy use records marked for recalculation (`Recalculate_Emissions__c = true`). Sequentially processes Stationary, Vehicle, Waste, and Hotel energy use records. Configurable batch size via custom settings.

- **`NZC_EmissionsSetRecalcBatch`**: Batchable class for recalculating emissions when emissions sets are updated. Processes emissions sets and triggers recalculation on related energy use records.

- **`NZC_EmissionsMatchingBatchController`**: Controller class for LWC components to start batch jobs and poll for batch status. Provides client-side methods for batch management.

##### Utility and Support Classes
- **`NZC_EmissionsMatchingUtil`**: Utility class providing shared functionality including trigger execution, matrix record hashing, hash key creation, and global describe caching. Central hub for common operations across the matching system.

- **`NZC_EmissionsMatchingConstants`**: Constants class defining all object names, field names, fuel types, and mapping relationships used throughout the system. Contains maps for object-to-field relationships, fuel type mappings, and emissions set object mappings.

- **`NZC_EmissionsMatchingLog`**: Logging utility that conditionally logs debug messages based on custom settings configuration. Supports configurable logging to reduce debug statement overhead.

- **`NZC_EmissionsMatchingMTD`**: Metadata Type Data class that loads and caches custom metadata type records for matching rules, custom lookups, custom matches, and T&D cloning rules. Provides static access to configuration data.

- **`NZC_EmissionsMatchingTDLosses`**: Handles Transmission & Distribution (T&D) losses for electricity emissions sets. Creates T&D loss records and manages relationships between parent and child emissions sets.

- **`NZC_EmissionsMatchingDatafactory`**: Test data factory class for creating test records across all object types used in the matching system. Simplifies test class setup.

##### Test Classes
- **`NZC_EmissionsMatchingEngineTest`**: Comprehensive test coverage for the main matching engine
- **`NZC_EmissionsMatchingInsertEngineTest`**: Tests for insert engine functionality
- **`NZC_EmissionsMatchingWrapperTest`**: Tests for base wrapper class
- **`NZC_EmissionsMatchingHotelWrapperTest`**: Tests for hotel wrapper
- **`NZC_EmissionsMatchingStationaryWpprTest`**: Tests for stationary wrapper
- **`NZC_EmissionsMatchingVehicleTggrTest`**: Tests for vehicle wrapper
- **`NZC_EmissionsMatchingWasteTggrTest`**: Tests for waste wrapper
- **`NZC_EmissionsMatchingAdvancedMatchTest`**: Tests for advanced matching
- **`NZC_EmissionsMatchingAdvcMatchWprTest`**: Tests for advanced matching wrapper
- **`NZC_EmissionsMatchingBatchTest`**: Tests for batch processing
- **`NZC_EmissionsMatchingBatchControllerTest`**: Tests for batch controller
- **`NZC_EmissionsMatchingLogTest`**: Tests for logging utility
- **`NZC_EmissionsMatchingMTDTest`**: Tests for metadata loading
- **`NZC_EmissionsMatchingTDLossesTest`**: Tests for T&D losses
- **`NZC_EmissionsMatchingUtilTest`**: Tests for utility class
- **`NZC_EmissionsSetRecalcBatchTest`**: Tests for recalculation batch
- **`NZC_EmissionsSetRecalcEngineTest`**: Tests for recalculation engine
- **`NZC_EmissionsMatchingHotelTriggerTest`**: Tests for hotel trigger
- **`NZC_EmissionsMatchingStationaryTggrTest`**: Tests for stationary trigger

#### Apex Triggers

- **`NZC_EmissionsMatchingHotelTrigger`**: Trigger on `HotelStayEnrgyUse` object. Executes matching logic on insert/update based on custom settings configuration. Calls wrapper and engine classes to perform matching.

- **`NZC_EmissionsMatchingMatrixTrigger`**: Trigger on `NZC_EmissionsMatchingMatrix__c` object. Handles matrix record hashing on before insert/update to support advanced matching capabilities.

- **`NZC_EmissionsMatchingStationaryTrigger`**: Trigger on `StnryAssetEnrgyUse` object. Executes matching logic for stationary energy use records.

- **`NZC_EmissionsMatchingVehicleTrigger`**: Trigger on `VehicleAssetEnrgyUse` object. Executes matching logic for vehicle energy use records.

- **`NZC_EmissionsMatchingWasteTrigger`**: Trigger on `GeneratedWaste` object. Executes matching logic for waste records.

#### Lightning Web Components (LWC)

- **`nzc_EmissionsMatchingBatchStart`**: LWC component for starting emissions matching batch jobs. Provides UI for batch initiation, real-time status polling, progress bar display, and batch completion tracking. Uses `@salesforce/apex` to call `NZC_EmissionsMatchingBatchController` methods.

- **`nzc_EmissionsRecalcBatchStart`**: LWC component for starting emissions recalculation batch jobs. Similar functionality to matching batch start component but for recalculation operations.

#### Flows

- **`Link_Electricity_Sets`**: Flow for linking electricity emissions sets. Handles relationships between electricity emissions factor sets and related records.

#### Custom Metadata Types

- **`NZC_EmissionsMatchingAdvanceMatch__mdt`**: Metadata type for configuring advanced matching rules. Fields include:
  - `ObjectAppliesTo__c`: Object type this rule applies to
  - `ScreeningField__c`: Field used for screening/initial filtering
  - `HashFields__c`: Fields used to create hash keys for matching
  - `Hash_Destination__c`: Destination field for hash storage
  - `LookupDestination__c`: Lookup field to populate
  - `LookupToPopulate__c`: Target lookup field
  - `SecondaryMatchSourceField__c`: Secondary matching source field
  - `SecondaryMatchFieldTarget__c`: Secondary matching target field

- **`NZC_EmissionsMatchingCustomLookups__mdt`**: Metadata type for configuring custom lookup field mappings. Fields include:
  - `ObjectAppliesFor__c`: Object this lookup applies to
  - `FuelAppliesFor__c`: Fuel type this lookup applies to
  - `LookupToSearch__c`: Lookup field name to search

- **`NZC_EmissionsMatchingCustomMatch__mdt`**: Metadata type for configuring custom field-based matching. Fields include:
  - `ObjectAppliesTo__c`: Object type
  - `FuelType__c`: Fuel type
  - `EmissionsSetFieldToMatch__c`: Field on emissions set to match against
  - `EnergyUseFieldToMatch__c`: Field on energy use record to match against

- **`NZC_EmissionsMatchingTDCloning__mdt`**: Metadata type for configuring Transmission & Distribution cloning rules. Fields include:
  - `ObjectName__c`: Object name
  - `FuelType__c`: Fuel type
  - `FieldsToClone__c`: Comma-separated list of fields to clone

## Key Features

### 1. Date-Based Emissions Factor Matching

The core feature matches emissions factors to energy use records based on date ranges. The system supports three date matching strategies:
- **StartDate**: Matches based on the start date of the energy use period
- **EndDate**: Matches based on the end date of the energy use period  
- **Midpoint**: Matches based on the midpoint date between start and end dates

The matching field is configurable via `NZC_EmissionsMatchingConfig__c.DateMatchingField__c` custom setting.

**Key Components:**
- `NZC_EmissionsMatchingEngine`: Performs date range queries and matching logic
- `NZC_EmissionsMatchingWrapper`: Encapsulates date matching requirements
- Triggers: Execute matching on insert/update based on configuration

**Technical Implementation:**
- Queries emissions sets ordered by date ranges
- Matches energy use record dates to active emissions factor date ranges
- Supports master emissions sets with child emissions sets
- Handles overlapping date ranges by selecting appropriate active set

### 2. Custom Field Matching

Allows matching based on custom field values (e.g., country code, ZIP code) rather than just date ranges. This feature enables location-specific or context-specific emissions factor matching.

**Key Components:**
- `NZC_EmissionsMatchingCustomMatch__mdt`: Metadata configuration for custom matching rules
- `NZC_EmissionsMatchingEngine`: Implements custom matching logic
- `NZC_EmissionsMatchingWrapper`: Stores custom matching values

**Technical Implementation:**
- Uses hash keys to efficiently match custom field values
- Supports multiple custom matching fields per object/fuel type combination
- Overrides standard asset-based matching when custom matching is enabled

### 3. Advanced Matching

Provides sophisticated matching capabilities using hash-based lookups and secondary matching fields. Supports complex matching scenarios where multiple fields must match.

**Key Components:**
- `NZC_EmissionsMatchingAdvancedMatch`: Advanced matching engine
- `NZC_EmissionsMatchingAdvancedMatchWpr`: Wrapper for advanced matching data
- `NZC_EmissionsMatchingMatrix__c`: Stores hash keys for efficient matching
- `NZC_EmissionsMatchingAdvanceMatch__mdt`: Metadata configuration

**Technical Implementation:**
- Creates hash keys from multiple fields for fast matching
- Stores hash values in matrix object for lookup performance
- Supports secondary matching fields for additional filtering
- Populates lookup fields based on matching results

### 4. Batch Processing

Processes large volumes of energy use records efficiently through configurable batch jobs. Supports sequential processing across multiple object types.

**Key Components:**
- `NZC_EmissionsMatchingBatch`: Main batch class for matching
- `NZC_EmissionsSetRecalcBatch`: Batch class for recalculation
- `NZC_EmissionsMatchingBatchController`: Controller for LWC batch management
- LWC components: UI for batch initiation and monitoring

**Technical Implementation:**
- Configurable batch sizes via custom settings
- Sequential batch chaining (Stationary → Vehicle → Waste → Hotel)
- Stateful batch processing for status tracking
- Real-time status polling from LWC components

### 5. Transmission & Distribution (T&D) Losses

Handles electricity transmission and distribution losses by creating T&D loss records and managing parent-child relationships between emissions sets.

**Key Components:**
- `NZC_EmissionsMatchingTDLosses`: T&D loss processing logic
- `NZC_EmissionsMatchingTDCloning__mdt`: Metadata for field cloning rules
- `StnryAssetEnrgyUse.TDLossParent__c`: Field linking to T&D parent record

**Technical Implementation:**
- Creates child T&D loss records from parent emissions sets
- Clones specified fields based on metadata configuration
- Maintains parent-child relationships for loss calculations

### 6. Master Emissions Set Management

Supports hierarchical emissions sets where master sets contain child emissions sets with different date ranges. Enables efficient management of emissions factors that change over time.

**Key Components:**
- `NZC_EmissionsMatchingEngine`: Queries master sets and child sets
- `MasterEmissionsSet__c` fields on emissions set objects
- Date sorting logic for child set selection

**Technical Implementation:**
- Queries master emissions set from asset records
- Retrieves child emissions sets ordered by date
- Matches energy use dates to appropriate child set date range

### 7. Configurable Trigger Execution

Allows administrators to control when matching occurs (on insert, update, or both) via custom settings. Provides flexibility for different deployment scenarios.

**Key Components:**
- `NZC_EmissionsMatchingConfig__c`: Custom settings with trigger flags
- All trigger classes: Check configuration before executing
- `NZC_EmissionsMatchingUtil`: Central trigger execution method

**Technical Implementation:**
- `DoMatchEmissionsOnInsert__c`: Controls insert trigger execution
- `DoMatchEmissionsOnUpdate__c`: Controls update trigger execution
- Triggers check settings before processing records

## Data Model

### Custom Objects

#### Configuration Objects
- **`NZC_EmissionsMatchingConfig__c`** (Custom Settings - List): Configuration object for system-wide settings. Key fields:
  - `AllowAdvancedMatching__c`: Enable/disable advanced matching
  - `AllowCustomTagMatching__c`: Enable/disable custom field matching
  - `AllowTransmissionDistribution__c`: Enable/disable T&D loss processing
  - `DateMatchingField__c`: Field name for date matching (StartDate, EndDate, Midpoint)
  - `DoMatchEmissionsOnInsert__c`: Execute matching on insert
  - `DoMatchEmissionsOnUpdate__c`: Execute matching on update
  - `Emissions_Matching_Batch_Size__c`: Batch size for matching jobs
  - `Emissions_Recalc_Batch_Size__c`: Batch size for recalculation jobs
  - `doLog__c`: Enable/disable debug logging

- **`NZC_EmissionsMatchingMatrix__c`**: Matrix object for storing hash keys used in advanced matching. Key fields:
  - `ApplicableObject__c`: Object type this matrix applies to
  - `PrimaryHashkeys__c`: Primary hash key values
  - `PrimaryHashStorage__c`: Storage for primary hash
  - `AliasHashkeys__c`: Alias hash key values
  - `AliasHashStorage__c`: Storage for alias hash
  - `LookupOverride__c`: Override lookup field

#### Energy Use Objects (Extended Standard Objects)
- **`StnryAssetEnrgyUse`**: Stationary Asset Energy Use records. Extended with:
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation
  - `TDLossParent__c`: Lookup to T&D loss parent record
  - `ElectricityEmissionFactorsId`: Lookup to electricity emissions set
  - `RefrigerantEmssnFctrId`: Lookup to refrigerant emissions set
  - `OtherEmssnFctrId`: Lookup to other emissions set

- **`VehicleAssetEnrgyUse`**: Vehicle Asset Energy Use records. Extended with:
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

- **`GeneratedWaste`**: Generated Waste records. Extended with:
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation
  - `WstDispoEmssnFctrId`: Lookup to waste disposal emissions set

- **`HotelStayEnrgyUse`**: Hotel Stay Energy Use records. Extended with:
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation
  - `HotelStayEmssnFctrId`: Lookup to hotel stay emissions set

#### Emissions Set Objects (Extended Standard Objects)
- **`ElectricityEmssnFctrSet`**: Electricity Emissions Factor Set. Extended with:
  - `MasterEmissionsSet__c`: Lookup to master emissions set
  - `EmissionsFactorUpdateYear__c`: Year field for updates
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

- **`RefrigerantEmssnFctr`**: Refrigerant Emissions Factor. Extended with:
  - `MasterEmissionsSet__c`: Lookup to master emissions set
  - `EmissionsFactorUpdateYear__c`: Year field for updates
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

- **`OtherEmssnFctrSet`**: Other Emissions Factor Set. Extended with:
  - `MasterEmissionsSet__c`: Lookup to master emissions set
  - `EmissionsFactorUpdateYear__c`: Year field for updates
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

- **`WstDispoEmssnFctrSet`**: Waste Disposal Emissions Factor Set. Extended with:
  - `MasterEmissionsSet__c`: Lookup to master emissions set
  - `EmissionsFactorUpdateYear__c`: Year field for updates
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

- **`HotelStayEmssnFctr`**: Hotel Stay Emissions Factor. Extended with:
  - `MasterEmissionsSet__c`: Lookup to master emissions set
  - `EmissionsFactorUpdateYear__c`: Year field for updates
  - `Recalculate_Emissions__c`: Checkbox to trigger recalculation

#### Asset Objects (Standard Objects - Referenced)
- **`StnryAssetEnvrSrc`**: Stationary Asset Environment Source. Referenced for:
  - `ElectricityEmssnFctrId`: Lookup to electricity emissions set
  - `RefrigerantEmssnFctrId`: Lookup to refrigerant emissions set
  - `WstDispoEmssnFctrSetId`: Lookup to waste emissions set
  - `T_D_losses_emissions_set__c`: Lookup to T&D losses emissions set

- **`VehicleAssetEmssnSrc`**: Vehicle Asset Emissions Source (referenced in constants)

- **`Scope3EmssnSrc`**: Scope 3 Emissions Source (referenced for hotel stays)

### Custom Metadata Types

- **`NZC_EmissionsMatchingAdvanceMatch__mdt`**: Advanced matching configuration
- **`NZC_EmissionsMatchingCustomLookups__mdt`**: Custom lookup field configuration
- **`NZC_EmissionsMatchingCustomMatch__mdt`**: Custom field matching configuration
- **`NZC_EmissionsMatchingTDCloning__mdt`**: T&D cloning field configuration

### Relationships

- **Energy Use Records → Emissions Sets**: One-to-many relationship via lookup fields (e.g., `ElectricityEmissionFactorsId`, `RefrigerantEmssnFctrId`)
- **Asset Objects → Emissions Sets**: One-to-many relationship via lookup fields on asset records
- **Master Emissions Sets → Child Emissions Sets**: One-to-many via `MasterEmissionsSet__c` lookup field
- **Stationary Energy Use → T&D Loss Parent**: One-to-one via `TDLossParent__c` lookup field
- **Emissions Sets → Energy Use Records**: Many-to-one (multiple energy use records can reference same emissions set)

### Data Flow

1. **Energy Use Record Created/Updated** → Trigger fires (if enabled)
2. **Wrapper Created** → Encapsulates energy use record data
3. **Asset Lookup** → Retrieves master emissions set from asset
4. **Emissions Set Query** → Queries child emissions sets ordered by date
5. **Date Matching** → Matches energy use date to active emissions set date range
6. **Custom Matching** → Applies custom field matching if configured
7. **Advanced Matching** → Applies hash-based matching if configured
8. **Update Energy Use** → Populates emissions set lookup field on energy use record

## Security & Access Control

- **Sharing Model**: All Apex classes use `with sharing` keyword to enforce object-level and field-level security
- **Permission Set**: `EmissionsMatching` permission set provides access to custom objects and fields
- **Custom Settings**: `NZC_EmissionsMatchingConfig__c` is a List custom setting, allowing multiple configuration records
- **Field-Level Security**: All custom fields respect Salesforce field-level security settings
- **Object Permissions**: Standard Salesforce object permissions apply to extended standard objects

## Recent Development

### Current Branch: `master`

**Status**: Initial SFDX conversion and repository restructuring complete

**Recent Changes:**
1. **SFDX Conversion**: Converted from MDAPI format to SFDX format
   - Moved metadata from `EmissionFactorMatching/` to `force-app/main/default/`
   - Created `sfdx-project.json` with API version 60.0
   - Updated project structure to match LLM-Based Salesforce Project template

2. **Repository Restructuring**: Aligned with template structure
   - Added `.cursor/rules/` directory with AI coding guidelines
   - Added `config/` directory with scratch org definition
   - Added `docs/` directory with documentation guides
   - Updated `.gitignore` and added `.forceignore`
   - Updated `README.md` with comprehensive project information

3. **Documentation**: Created initial repository summary (this file)

## Project Structure

```
EmissionsMatching/
├── .cursor/                              # Cursor AI configuration
│   └── rules/                            # AI coding rules and guidelines
│       ├── Accelerator README.mdc
│       ├── apex-best-practices.mdc
│       ├── lwc-best-practices.mdc
│       ├── lwc-jest-tests.mdc
│       ├── lwc-jest-tests-sfdc.mdc
│       ├── lookup-field-creation.mdc
│       ├── OSPO-Comppliance.mdc
│       ├── repo-shape.mdc
│       ├── Salesforce Quality.mdc
│       ├── static-enum-creation-rule.mdc
│       └── text-field-creation-rule.mdc
├── config/                               # Configuration files
│   └── project-scratch-def.json         # Scratch org definition
├── docs/                                 # Project documentation
│   └── how-to-create-repository-summary.md
├── force-app/                            # Main Salesforce source directory
│   └── main/
│       └── default/                      # Default package directory
│           ├── classes/                  # Apex classes (41 classes)
│           │   ├── NZC_EmissionsMatchingEngine.cls
│           │   ├── NZC_EmissionsMatchingBatch.cls
│           │   ├── NZC_EmissionsMatchingWrapper.cls
│           │   └── [38 more classes...]
│           ├── triggers/                 # Apex triggers (6 triggers)
│           │   ├── NZC_EmissionsMatchingHotelTrigger.trigger
│           │   ├── NZC_EmissionsMatchingMatrixTrigger.trigger
│           │   ├── NZC_EmissionsMatchingStationaryTrigger.trigger
│           │   ├── NZC_EmissionsMatchingVehicleTrigger.trigger
│           │   └── NZC_EmissionsMatchingWasteTrigger.trigger
│           ├── lwc/                     # Lightning Web Components (2 components)
│           │   ├── jsconfig.json
│           │   ├── nzc_EmissionsMatchingBatchStart/
│           │   └── nzc_EmissionsRecalcBatchStart/
│           ├── aura/                    # Aura components (empty, .gitkeep)
│           ├── objects/                 # Custom objects (16 objects)
│           │   ├── NZC_EmissionsMatchingConfig__c.object
│           │   ├── NZC_EmissionsMatchingMatrix__c.object
│           │   └── [14 extended standard objects...]
│           ├── flows/                   # Flow definitions (1 flow)
│           │   └── Link_Electricity_Sets.flow
│           ├── layouts/                  # Page layouts (5 layouts)
│           ├── permissionsets/          # Permission sets (1 permission set)
│           │   └── EmissionsMatching.permissionset
│           ├── tabs/                    # Custom tabs (1 tab)
│           │   └── NZC_EmissionsMatchingMatrix__c.tab
│           └── package.xml             # Metadata package manifest
├── .forceignore                         # Files to ignore in Salesforce operations
├── .gitignore                           # Files to ignore in Git
├── README.md                            # Main project readme
├── REPOSITORY_SUMMARY.md                # This file - comprehensive codebase reference
├── build.properties                     # Ant build properties (legacy)
├── build.xml                            # Ant build file (legacy)
└── sfdx-project.json                   # SFDX project configuration
```

## Development Workflow

### Prerequisites

- Salesforce CLI (sf CLI) version 2.114.5 or later
- VS Code or Cursor with Salesforce extensions
- Node.js and npm (for LWC development)
- Git for version control
- Access to Salesforce org with appropriate permissions

### Available Scripts

```bash
# Authenticate with Dev Hub
sf org login web --set-default-dev-hub --alias DevHub

# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias MyScratchOrg --set-default --duration-days 30

# Deploy source to org
sf project deploy start

# Deploy specific source directory
sf project deploy start --source-dir force-app/main/default/classes

# Retrieve source from org
sf project retrieve start

# Open org in browser
sf org open

# Run Apex tests
sf apex run test --test-level RunLocalTests

# Run specific test class
sf apex run test --class-names NZC_EmissionsMatchingEngineTest

# Delete scratch org
sf org delete scratch --target-org MyScratchOrg
```

### Common Tasks

```bash
# Full deployment workflow
sf org create scratch -f config/project-scratch-def.json -a EmissionsMatching -d 30
sf project deploy start
sf org open

# Run all tests
sf apex run test --test-level RunLocalTests --result-format human --code-coverage

# Pull latest changes from org
sf project retrieve start --source-dir force-app/main/default
```

## Testing

### Testing Framework

- **Framework**: Apex Test Classes
- **Coverage Requirement**: All classes have corresponding test classes
- **Test Naming Convention**: `[ClassName]Test.cls`

### Test File Locations

All test classes are located in `force-app/main/default/classes/` with naming pattern `*Test.cls`.

### Running Tests

```bash
# Run all tests
sf apex run test --test-level RunLocalTests

# Run specific test class
sf apex run test --class-names NZC_EmissionsMatchingEngineTest

# Run with code coverage
sf apex run test --test-level RunLocalTests --code-coverage --result-format human
```

### Test Patterns

- **Test Data Factory**: `NZC_EmissionsMatchingDatafactory` provides methods for creating test records
- **Test Isolation**: Each test class creates its own test data
- **Assertions**: Comprehensive assertions validate matching logic and data updates
- **Bulk Testing**: Tests include bulk operation scenarios (200+ records)

### Test Coverage

The project includes test classes for:
- All engine classes
- All wrapper classes
- All batch classes
- All utility classes
- All trigger handlers
- Controller classes

## Integration Points

### External Dependencies

- **Salesforce Platform**: Core platform functionality
- **Net Zero Cloud (NZC)**: Extends Net Zero Cloud standard objects and fields
- **Standard Objects**: Extends standard Net Zero Cloud objects:
  - Stationary Asset Energy Use
  - Vehicle Asset Energy Use
  - Generated Waste
  - Hotel Stay Energy Use
  - Various Emissions Factor Set objects

### Integration Patterns

- **Trigger-Based**: Integrates with Salesforce trigger framework
- **Batch Processing**: Uses Salesforce batchable framework
- **Metadata-Driven**: Uses Custom Metadata Types for configuration
- **LWC Integration**: LWC components call Apex methods via `@salesforce/apex`

## Important Notes for LLMs/AI Assistants

When working with this codebase:

1. **Object Naming Convention**: All custom objects and classes use `NZC_` prefix (Net Zero Cloud). Custom fields use `__c` suffix, metadata types use `__mdt` suffix.

2. **Constants Class Usage**: Always reference `NZC_EmissionsMatchingConstants` for object names, field names, and mappings. Do not hardcode object or field names.

3. **Wrapper Pattern**: The system uses wrapper classes (`NZC_EmissionsMatchingWrapper` and subclasses) to encapsulate matching data. Wrappers determine lookup field names dynamically based on object type and fuel type.

4. **Metadata-Driven Configuration**: Matching behavior is controlled by Custom Metadata Types. Check `NZC_EmissionsMatchingMTD` class for loaded metadata before implementing matching logic.

5. **Date Matching Field**: The date field used for matching is configurable via `NZC_EmissionsMatchingConfig__c.DateMatchingField__c`. Valid values are: `StartDate`, `EndDate`, or `Midpoint`.

6. **Batch Sequential Processing**: `NZC_EmissionsMatchingBatch` processes objects sequentially: Stationary → Vehicle → Waste → Hotel. Each batch completion triggers the next batch in the `finish()` method.

7. **Hash Key Creation**: The system uses hash keys for efficient matching. `NZC_EmissionsMatchingUtil.createHashKey()` creates hash keys from field values. Matrix object stores hash keys for advanced matching.

8. **Custom Settings**: `NZC_EmissionsMatchingConfig__c` is a List custom setting, meaning multiple configuration records can exist. The system should handle multiple records appropriately.

9. **Trigger Execution Control**: Triggers check `DoMatchEmissionsOnInsert__c` and `DoMatchEmissionsOnUpdate__c` before executing. Always use `NZC_EmissionsMatchingUtil.triggerOnUpdateRun()` for trigger execution.

10. **Master Emissions Sets**: When matching, the system first looks up the master emissions set from the asset record, then queries child emissions sets ordered by date. The matching date determines which child set to use.

11. **Custom Matching Override**: Custom field matching (via `NZC_EmissionsMatchingCustomMatch__mdt`) can override standard asset-based matching. Check `doesUseCustomEmissionsMatching()` on wrapper before applying standard matching.

12. **T&D Losses**: Transmission & Distribution losses are handled separately via `NZC_EmissionsMatchingTDLosses`. T&D records are created as children of electricity emissions sets and linked via `TDLossParent__c` field.

13. **Recalculation Flag**: Energy use records use `Recalculate_Emissions__c` checkbox to flag records for batch processing. Emissions sets use the same field to trigger recalculation of related energy use records.

14. **Sharing Model**: All classes use `with sharing` to enforce security. Be aware of sharing implications when querying records.

15. **Logging**: Use `NZC_EmissionsMatchingLog.log()` for debug statements. Logging is controlled by `doLog__c` custom setting to reduce overhead in production.

16. **Test Data Factory**: Use `NZC_EmissionsMatchingDatafactory` methods when creating test data. The factory handles relationships and required fields automatically.

17. **Field Name Mapping**: The system uses multiple maps in `NZC_EmissionsMatchingConstants` to determine field names based on object type and fuel type. Always use these maps rather than hardcoding field names.

18. **LWC Apex Methods**: LWC components use `@salesforce/apex` to call controller methods. Methods must be `@AuraEnabled` and use `cacheable=false` for batch status polling.

19. **Metadata Type Loading**: Custom Metadata Types are loaded once in `NZC_EmissionsMatchingMTD` and cached statically. Changes to metadata require code deployment or metadata refresh.

20. **Package.xml**: The `package.xml` file in `force-app/main/default/` is for reference only. SFDX projects don't require it for deployment, but it documents all metadata types in the project.

## Documentation Files

- **`REPOSITORY_SUMMARY.md`**: This file - comprehensive LLM-optimized codebase reference
- **`README.md`**: Main project readme with getting started guide, prerequisites, and development workflow
- **`docs/how-to-create-repository-summary.md`**: Detailed instructions for creating and maintaining repository summary files
- **`.cursor/rules/`**: AI coding rules and best practices for:
  - Apex development (`apex-best-practices.mdc`)
  - LWC development (`lwc-best-practices.mdc`)
  - LWC Jest testing (`lwc-jest-tests.mdc`, `lwc-jest-tests-sfdc.mdc`)
  - Field creation rules (`lookup-field-creation.mdc`, `text-field-creation-rule.mdc`, `static-enum-creation-rule.mdc`)
  - Repository structure (`repo-shape.mdc`)
  - OSPO compliance (`OSPO-Comppliance.mdc`)
  - Salesforce quality standards (`Salesforce Quality.mdc`)

---

**Last Updated**: January 5, 2025 - Based on branch `master`  
**Repository**: NZC---Emission-Factor-Matching - jvillalpando_sfemu  
**Platform**: Salesforce Platform (API Version 60.0)  
**Active Environments**: Development, Scratch Orgs

