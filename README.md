# EmissionsMatching

## Project Title & Purpose

**EmissionsMatching** is a Salesforce accelerator that automatically matches emissions factors to energy use records based on active date ranges. This solution solves the business problem of manually maintaining and matching emissions factors across multiple energy use object types (Stationary, Vehicle, Waste, Hotel) by providing intelligent, date-based automated matching with support for custom field matching and advanced matching strategies.

## Features

- **Automated Date-Based Matching**: Automatically matches emissions factors to energy use records based on configurable date fields (StartDate, EndDate, or Midpoint)
- **Multi-Object Support**: Handles Stationary Energy Use, Vehicle Energy Use, Waste, and Hotel Stay energy use records
- **Flexible Matching Strategies**: Supports standard date matching, custom field matching (e.g., country code, ZIP code), and advanced hash-based matching via metadata configuration
- **Batch Processing**: Processes large volumes of records efficiently through configurable batch jobs with sequential processing across object types
- **Transmission & Distribution Support**: Handles T&D losses and cloning for electricity emissions sets
- **Configurable Triggers**: Optional insert and update triggers for real-time matching, controlled via custom settings
- **Master Emissions Set Management**: Supports hierarchical emissions sets with parent-child relationships for efficient factor management
- **Recalculation Engine**: Batch process to recalculate emissions when emissions sets are updated

## Technical Architecture

This accelerator contains:
- **2 Lightning Web Components** (LWC): Batch start components for matching and recalculation
- **41 Apex Classes**: Including matching engines, wrappers, batch processors, utilities, and comprehensive test coverage
- **5 Apex Triggers**: Trigger handlers for Hotel, Stationary, Vehicle, Waste energy use records, and Matrix object
- **1 Flow**: Link Electricity Sets flow for managing electricity emissions set relationships
- **Custom Objects**: Configuration object, Matrix object, and extended standard objects with custom fields
- **Custom Metadata Types**: 4 metadata types for advanced matching, custom lookups, custom matching, and T&D cloning configuration
- **Permission Sets**: EmissionsMatching permission set for access control
- **Page Layouts**: 5 custom page layouts for metadata and custom objects

## Installation Instructions

### Path 1: One-Click Deploy (Admin-Friendly)

[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://github.com/afawcett/githubsfdeploy?owner=jvillalpando_sfemu&repo=NZC---Emission-Factor-Matching)

Click the button above to deploy this accelerator directly to your Salesforce org. You'll be prompted to authenticate and select your target org.

### Path 2: Metadata .zip File (Admin-Friendly)

1. Navigate to the [Releases](https://github.com/jvillalpando_sfemu/NZC---Emission-Factor-Matching/releases) tab on GitHub
2. Download the latest release `.zip` file
3. Extract the contents
4. Deploy using one of these methods:
   - **Workbench**: Use the "Deploy" feature to upload the metadata
   - **Salesforce Inspector**: Use the deployment tools to import the metadata
   - **Ant Migration Tool**: Use the `sf:deploy` Ant task to deploy the metadata

### Path 3: Pro-Code / CI/CD (Developer-Friendly)

For developers using Salesforce CLI or CI/CD pipelines:

```bash
# Clone the repository
git clone https://github.com/jvillalpando_sfemu/NZC---Emission-Factor-Matching.git
cd NZC---Emission-Factor-Matching

# Authenticate with your org
sf org login web --alias MyOrg

# Deploy to your org
sf project deploy start --target-org MyOrg
```

**Alternative using legacy SFDX commands:**
```bash
sfdx force:source:deploy --sourcepath force-app --targetusername MyOrg
```

This accelerator is compatible with CI/CD tools including:
- Gearset
- Copado
- Salesforce DevOps Center
- GitHub Actions
- GitLab CI/CD

## Post-Installation Steps

After successful installation, complete these essential configuration steps:

1. **Create Custom Setting Record**: Navigate to **Setup** → **Custom Settings** → **NZC Emissions Matching Configuration** → **Manage** → **New** and configure the matching settings (see [User Guide](docs/USER_GUIDE.md) for detailed configuration options)

2. **Assign Permission Set**: Assign the **EmissionsMatching** permission set to users who need access to the matching functionality

3. **Configure Page Layouts**: Add the **Recalculate emission** checkbox field to energy use page layouts and emissions set fields to emissions set page layouts

4. **Configure Custom Metadata** (Optional): If using advanced matching or custom field matching, create custom metadata records for matching rules

5. **Verify Installation**: Create a test energy use record, set the **Recalculate emission** checkbox, and verify matching works correctly

> 📖 **For detailed configuration instructions, troubleshooting, and advanced features, see the [User Guide](docs/USER_GUIDE.md)**

## How to Report Bugs

Found a bug or have a feature request? Please report it on the [GitHub Issues](https://github.com/jvillalpando_sfemu/NZC---Emission-Factor-Matching/issues) tab.

When reporting bugs, please include:
- Steps to reproduce the issue
- Expected vs. actual behavior
- Salesforce org edition and API version
- Any relevant error messages or logs
- Screenshots if applicable

## Disclaimer

**This accelerator is open-source, not an official Salesforce product, and is community-supported.**

This solution is provided as-is without warranty or support from Salesforce. The community maintains this accelerator, and contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## Documentation

- **[User Guide](docs/USER_GUIDE.md)**: Comprehensive user documentation covering configuration, matching strategies, batch processing, troubleshooting, and advanced features
- **[Repository Summary](REPOSITORY_SUMMARY.md)**: Technical architecture and codebase reference for developers
- **[Contributing Guide](CONTRIBUTING.md)**: Guidelines for contributing to this project

## Additional Resources

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Net Zero Cloud Documentation](https://help.salesforce.com/s/articleView?id=sf.netzero_cloud.htm)

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
