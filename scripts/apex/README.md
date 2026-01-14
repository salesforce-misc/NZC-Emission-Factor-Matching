# Setup Apex Classes

This directory contains setup utility classes that are **NOT deployed** to your Salesforce org.

## Purpose

These classes are provided for reference only. The actual setup is performed using Anonymous Apex, which includes the class code inline.

## Files

- `NZC_EmissionsMatchingSetup.cls` - Setup utility class with methods for:
  - Creating default Custom Setting records
  - Assigning Permission Sets to users
  - Validating setup configuration
  - Generating setup status reports

## Usage

**Do NOT deploy these classes to your org.**

Instead, use the Anonymous Apex script located at:
- `scripts/setup-anon-apex.txt`

This script includes the class code inline and can be executed directly without any deployment.

## Why Not Deploy?

1. **Setup-only code** - These classes are only needed for initial configuration
2. **No production dependency** - The main application doesn't depend on these classes
3. **Flexibility** - Users can run setup without deploying additional code
4. **Clean org** - Keeps your org free of temporary setup utilities

## Alternative: Manual Setup

If you prefer to deploy the class for reuse, you can:
1. Copy the class to `force-app/main/default/classes/`
2. Deploy it to your org
3. Use the class methods directly in your own scripts

However, the recommended approach is to use the Anonymous Apex script with inline class code.


