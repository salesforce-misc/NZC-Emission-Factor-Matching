# Setup Automation Guide

This guide explains how to use the automated setup scripts to configure the Emissions Matching accelerator after deployment.

## Overview

The automation scripts handle the following post-deployment configuration steps:

1. **Custom Setting Creation** - Creates the default `NZC_EmissionsMatchingConfig__c` record with recommended values
2. **Permission Set Assignment** - Assigns the `EmissionsMatching` permission set to specified users
3. **Page Layout Configuration** - Provides guidance for adding required fields to page layouts
4. **Setup Validation** - Validates that the setup is complete and reports status

**Important:** The setup classes are **NOT deployed** to your org. They are included inline in the Anonymous Apex script, so you can run setup without deploying any additional code. The class files are stored in `scripts/apex/` for reference only.

## Prerequisites

Before running the automation scripts, ensure you have:

- ✅ **Salesforce CLI** installed (sf CLI v2 or sfdx CLI)
  - Download: https://developer.salesforce.com/tools/sfdxcli
  - Verify installation: `sf --version` or `sfdx --version`
- ✅ **Authenticated to target org**
  - Authenticate: `sf org login web --alias MyOrg` or `sfdx auth:web:login -a MyOrg`
  - Verify: `sf org list` or `sfdx force:org:list`
- ✅ **Appropriate permissions**
  - System Administrator or equivalent permissions
  - Ability to execute Anonymous Apex
  - Ability to create Custom Setting records
  - Ability to assign Permission Sets

**Note:** No Apex classes need to be deployed. The setup class code is included inline in the Anonymous Apex script.

## Quick Start

### Option 1: Complete Automated Setup (Recommended)

Run the complete setup orchestrator script:

**macOS/Linux:**
```bash
./scripts/complete-setup.sh [org-alias]
```

**Windows (PowerShell):**
```powershell
.\scripts\complete-setup.ps1 [org-alias]
```

This script will:
1. Execute the Anonymous Apex setup script (includes class code inline)
2. Create the Custom Setting
3. Assign Permission Set to users (configured in script)
4. Provide page layout guidance
5. Validate the setup

### Option 2: Step-by-Step Setup

Run individual scripts in sequence:

1. **Setup Script** - Creates Custom Setting and assigns Permission Set
   ```bash
   ./scripts/setup.sh [org-alias]
   ```

2. **Page Layout Guidance** - Shows instructions for configuring layouts
   ```bash
   ./scripts/configure-page-layouts.sh [org-alias]
   ```

### Option 3: Anonymous Apex (Manual)

If you prefer to run setup manually or don't have CLI access:

1. Open `scripts/setup-anon-apex.txt`
2. Modify the `USERNAMES_OR_IDS` list with actual usernames or user IDs
3. Copy the entire script (it includes the setup class code inline)
4. Paste into Developer Console (Debug > Open Execute Anonymous Window)
5. Execute the script

**Note:** The script includes the setup class code inline, so no deployment is required. The class code is automatically included in the script.

## Detailed Usage

### Setup Script (`setup.sh` / `setup.ps1`)

The setup script performs the core configuration:

**Features:**
- Executes Anonymous Apex script (includes setup class inline - no deployment needed)
- Creates default Custom Setting record
- Assigns Permission Set to users (configured in script)
- Validates setup and reports status

**Usage:**
```bash
# Using default org
./scripts/setup.sh

# Using specific org alias
./scripts/setup.sh MyOrg
```

**What it does:**
1. Checks for Salesforce CLI (sf or sfdx)
2. Prompts you to update the Anonymous Apex script with user IDs/usernames
3. Executes the Anonymous Apex script which includes the setup class code inline
4. The script creates Custom Setting with defaults:
   - `DateMatchingField__c = 'StartDate'`
   - `Emissions_Matching_Batch_Size__c = 200`
   - `Emissions_Recalc_Batch_Size__c = 50`
   - `doLog__c = true` (for initial setup)
   - All other flags = false (defaults)
4. Prompts for usernames/user IDs to assign Permission Set
5. Validates setup and displays status report

**Custom Setting Defaults:**
- **Date Matching Field**: `StartDate` (can be changed to `EndDate` or `Midpoint`)
- **Matching Batch Size**: `200` (recommended per USER_GUIDE.md)
- **Recalc Batch Size**: `50` (recommended per USER_GUIDE.md)
- **Logging**: `true` (enabled for initial setup/debugging)
- **Insert Matching**: `false` (disabled by default)
- **Update Matching**: `false` (disabled by default)
- **Custom Tag Matching**: `false` (disabled by default)
- **Advanced Matching**: `false` (disabled by default)
- **T&D Losses**: `false` (disabled by default)

### Page Layout Configuration (`configure-page-layouts.sh` / `configure-page-layouts.ps1`)

**Note:** Page layout modification is complex and org-specific. This script provides guidance for manual configuration.

**Usage:**
```bash
./scripts/configure-page-layouts.sh [org-alias]
```

**What it does:**
- Provides guidance for configuring page layouts
- Lists required fields per object
- Explains manual configuration steps

**Required Fields by Object:**

**Energy Use Objects:**
- `StnryAssetEnrgyUse` (Stationary Energy Use): `Recalculate_Emissions__c`
- `VehicleAssetEnrgyUse` (Vehicle Energy Use): `Recalculate_Emissions__c`
- `GeneratedWaste` (Waste): `Recalculate_Emissions__c`
- `HotelStayEnrgyUse` (Hotel Energy Use): `Recalculate_Emissions__c`

**Emissions Set Objects:**
- `ElectricityEmssnFctrSet`: `Recalculate_Emissions__c`, `MasterEmissionsSet__c`, `EmissionsFactorUpdateYear__c`
- `RefrigerantEmssnFctr`: `Recalculate_Emissions__c`, `MasterEmissionsSet__c`, `EmissionsFactorUpdateYear__c`
- `OtherEmssnFctrSet`: `Recalculate_Emissions__c`, `MasterEmissionsSet__c`, `EmissionsFactorUpdateYear__c`
- `WstDispoEmssnFctrSet`: `Recalculate_Emissions__c`, `MasterEmissionsSet__c`, `EmissionsFactorUpdateYear__c`
- `HotelStayEmssnFctr`: `Recalculate_Emissions__c`, `MasterEmissionsSet__c`, `EmissionsFactorUpdateYear__c`

**Manual Configuration Steps:**

1. Navigate to **Setup > Object Manager**
2. Select the object (e.g., `Stationary Asset Energy Use`)
3. Go to **Page Layouts**
4. Click **Edit** on the layout you want to modify
5. Drag the required fields onto the layout
6. **Save** the layout

### Complete Setup Orchestrator (`complete-setup.sh` / `complete-setup.ps1`)

The orchestrator script runs all setup steps in sequence:

**Usage:**
```bash
./scripts/complete-setup.sh [org-alias]
```

**What it does:**
1. Runs the setup script (Custom Setting + Permission Set)
2. Optionally shows page layout guidance
3. Provides final summary and next steps

## Apex Setup Class

The `NZC_EmissionsMatchingSetup` class provides programmatic setup methods. **Note:** This class is NOT deployed to your org. It is included inline in the Anonymous Apex script (`scripts/setup-anon-apex.txt`) so it can run without deployment. The class file is stored in `scripts/apex/` for reference only.

### Using the Setup Class

The setup class is automatically included in the Anonymous Apex script, so you don't need to deploy it. However, if you want to use it programmatically, you can:

1. **Use the Anonymous Apex script** (recommended) - The class code is included inline
2. **Reference the class file** - Located at `scripts/apex/NZC_EmissionsMatchingSetup.cls` for reference

### Methods

#### `createDefaultConfig()`
Creates the default Custom Setting record with recommended values.

```apex
NZC_EmissionsMatchingConfig__c config = NZC_EmissionsMatchingSetup.createDefaultConfig();
```

**Returns:** `NZC_EmissionsMatchingConfig__c` - The created or existing configuration record

**Behavior:**
- Checks if a default record already exists (idempotent)
- Creates new record if none exists
- Returns existing record if already present

#### `assignPermissionSetToUsers(List<String> usernamesOrIds)`
Assigns the EmissionsMatching permission set to specified users.

```apex
List<String> users = new List<String>{'user@example.com', '005000000000001AAA'};
List<PermissionSetAssignment> assignments = NZC_EmissionsMatchingSetup.assignPermissionSetToUsers(users);
```

**Parameters:**
- `usernamesOrIds` - List of usernames (strings) or user IDs (strings)

**Returns:** `List<PermissionSetAssignment>` - List of created assignments

**Behavior:**
- Supports both username and user ID input
- Validates users exist before assignment
- Skips users who already have the permission set (no duplicates)
- Throws exception if no users found or permission set missing

#### `validateSetup()`
Validates that the setup is complete.

```apex
NZC_EmissionsMatchingSetup.SetupValidationResult result = NZC_EmissionsMatchingSetup.validateSetup();
if (result.isValid()) {
    System.debug('Setup is valid');
} else {
    for (String error : result.errors) {
        System.debug('Error: ' + error);
    }
}
```

**Returns:** `SetupValidationResult` - Validation result object

**Checks:**
- Custom Setting record exists
- Required fields are populated
- Permission Set exists (warning if missing)

#### `getSetupStatus()`
Gets a human-readable setup status report.

```apex
String status = NZC_EmissionsMatchingSetup.getSetupStatus();
System.debug(status);
```

**Returns:** `String` - Formatted status report

## Troubleshooting

### Common Issues

#### 1. CLI Not Found
**Error:** `Salesforce CLI (sf or sfdx) not found`

**Solution:**
- Install Salesforce CLI from https://developer.salesforce.com/tools/sfdxcli
- Verify installation: `sf --version` or `sfdx --version`
- Ensure CLI is in your PATH

#### 2. Not Authenticated
**Error:** `No default org found` or authentication errors

**Solution:**
- Authenticate to your org: `sf org login web --alias MyOrg`
- Verify authentication: `sf org list`
- Use `--target-org` flag with org alias if not using default

#### 3. Permission Denied
**Error:** `Insufficient access rights` or `Permission denied`

**Solution:**
- Ensure you're logged in as System Administrator
- Verify you have permissions to:
  - Deploy Apex classes
  - Create Custom Setting records
  - Assign Permission Sets
- Check object and field-level security settings

#### 4. Custom Setting Already Exists
**Behavior:** Script reports "Default configuration already exists"

**Solution:**
- This is expected behavior (idempotent operation)
- The script will use the existing record
- To recreate, manually delete the existing record first

#### 5. Permission Set Not Found
**Error:** `Permission Set "EmissionsMatching" not found`

**Solution:**
- Ensure the Permission Set metadata is deployed
- Check that `EmissionsMatching.permissionset` exists in your org
- Redeploy the permission set if needed

#### 6. Users Not Found
**Error:** `No users found matching the provided identifiers`

**Solution:**
- Verify usernames are correct (case-sensitive)
- Verify user IDs are valid (18-character Salesforce IDs)
- Check that users exist and are active
- Use Developer Console to query users: `SELECT Id, Username FROM User WHERE Username = 'user@example.com'`

#### 7. Page Layout Script Shows Guidance Only
**Behavior:** Script doesn't automatically modify layouts

**Explanation:**
- Page layouts are org-specific and complex to modify programmatically
- The script provides guidance for manual configuration
- Use Setup UI or Metadata API tools for automated layout modification

### Debugging

#### Enable Logging
The Custom Setting has `doLog__c = true` by default for initial setup. This enables debug logging in Apex.

To view logs:
1. Go to **Setup > Debug Logs**
2. Create a trace flag for your user
3. Run the setup again
4. View logs in Developer Console

#### Check Setup Status
Run validation to see current setup status:

```apex
String status = NZC_EmissionsMatchingSetup.getSetupStatus();
System.debug(status);
```

Or use Anonymous Apex:
```apex
System.debug(NZC_EmissionsMatchingSetup.getSetupStatus());
```

## Manual Fallback Steps

If automation scripts fail, you can perform setup manually:

### 1. Create Custom Setting

1. Navigate to **Setup > Custom Settings**
2. Click **NZC Emissions Matching Configuration**
3. Click **Manage** > **New**
4. Configure fields:
   - **Name**: `Default`
   - **Date Matching Field**: `StartDate`
   - **Emissions Matching Batch Size**: `200`
   - **Emissions Recalc Batch Size**: `50`
   - **do Log**: `true` (for initial setup)
   - Other fields: `false` (defaults)
5. Click **Save**

### 2. Assign Permission Set

1. Navigate to **Setup > Users > Permission Sets**
2. Find **EmissionsMatching** permission set
3. Click **Manage Assignments**
4. Click **Add Assignments**
5. Select users
6. Click **Assign**

### 3. Configure Page Layouts

See [USER_GUIDE.md](USER_GUIDE.md) for detailed page layout configuration instructions.

## Next Steps After Setup

After running the automation scripts:

1. **Verify Custom Setting**
   - Go to **Setup > Custom Settings > NZC Emissions Matching Configuration**
   - Verify the record exists and is configured correctly
   - Adjust settings as needed for your org

2. **Verify Permission Set**
   - Go to **Setup > Users > Permission Set Assignments**
   - Verify users have the EmissionsMatching permission set
   - Test by logging in as an assigned user

3. **Configure Page Layouts**
   - Follow guidance from `configure-page-layouts.sh` output
   - Or see [USER_GUIDE.md](USER_GUIDE.md) for detailed instructions
   - Add required fields to energy use and emissions set layouts

4. **Test the Setup**
   - Create a test energy use record
   - Set `Recalculate_Emissions__c = true`
   - Save the record (if triggers enabled) or run batch job
   - Verify emissions factor lookup is populated

5. **Optional: Configure Advanced Features**
   - Custom Metadata for custom matching (see USER_GUIDE.md)
   - Advanced matching configuration
   - T&D losses configuration

6. **Set Up Emissions Set Hierarchy**
   - Create master emissions sets
   - Create child emissions sets with dates
   - Link child sets to master sets
   - See USER_GUIDE.md for detailed instructions

## Additional Resources

- **User Guide**: [docs/USER_GUIDE.md](USER_GUIDE.md) - Comprehensive usage instructions
- **README**: [README.md](../README.md) - Project overview and installation
- **Repository Summary**: [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md) - Technical architecture

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review error messages in script output
3. Check Salesforce debug logs
4. Verify prerequisites are met
5. Try manual fallback steps
6. Report issues via GitHub Issues

## Script Files Reference

| File | Purpose | Platform |
|------|---------|----------|
| `setup.sh` / `setup.ps1` | Core setup (Custom Setting + Permission Set) | macOS/Linux / Windows |
| `configure-page-layouts.sh` / `configure-page-layouts.ps1` | Page layout guidance | macOS/Linux / Windows |
| `complete-setup.sh` / `complete-setup.ps1` | Complete setup orchestrator | macOS/Linux / Windows |
| `setup-anon-apex.txt` | Anonymous Apex script with inline class code | All platforms |
| `scripts/apex/NZC_EmissionsMatchingSetup.cls` | Setup class (reference only, not deployed) | All platforms |

## Version History

- **v1.0** (2025-01-05): Initial automation scripts and documentation

