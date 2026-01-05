# EmissionsMatching

This Salesforce DX project is used to match emissions factors based on active date range. The repository follows the LLM-Based Salesforce Project template structure, optimized for AI-assisted development with Cursor and other LLM-powered tools.

## 🚨 IMPORTANT: First Step When Using This Template

**Before you start development, you MUST create a `REPOSITORY_SUMMARY.md` file at the root of your project.**

This file is critical for:
- AI assistants (like Cursor) to understand your codebase
- New developers onboarding to your project
- Maintaining architectural documentation
- Ensuring consistent development patterns

### How to Create Your Repository Summary

Follow the comprehensive instructions in [`docs/how-to-create-repository-summary.md`](docs/how-to-create-repository-summary.md).

**This is not optional** - the REPOSITORY_SUMMARY.md file serves as the primary reference for understanding your project's:
- Architecture and component structure
- Data models and relationships
- Technology stack and dependencies
- Development workflow and patterns
- Integration points
- LLM-specific guidance for AI-assisted development

### Quick Start for Repository Summary

1. Read the instructions: [`docs/how-to-create-repository-summary.md`](docs/how-to-create-repository-summary.md)
2. Create `REPOSITORY_SUMMARY.md` at your project root
3. Follow all sections outlined in the guide
4. Update it regularly as your project evolves

**Time Investment**: 1-2 hours initially, saves countless hours later.

---

## Project Overview

Used to match emissions factors based on active date range.

### Post-Installation Setup

After package installation:

1. **Create custom setting record** for emissions matching
2. **Configure triggers**: Set update and insert triggers as desired
3. **Configure logging and batch size** if required
4. **Set matching field** to desired date (StartDate should be default)

### Page Layout Configuration

**Energy Use Page Layouts:**
- Add "Recalculate emission" checkbox to:
  - Vehicle energy use pages
  - Stationary energy use pages
  - Waste energy use pages

**Emissions Set Page Layouts:**
Add the following fields to Refrigerant, Electricity, Waste and Other emissions sets page layouts:
- Recalculate emissions
- Master emissions set
- Date active fields

### Verification

Verify matching is working correctly with a test record & running Apex classes.

---

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) installed
- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) with Salesforce extensions
- Node.js and npm installed

## Project Structure

```
.
├── .cursor/                     # Cursor AI configuration
│   └── rules/                   # AI coding rules and guidelines
│       ├── apex-best-practices.mdc
│       ├── lwc-best-practices.mdc
│       ├── lwc-jest-tests.mdc
│       ├── lookup-field-creation.mdc
│       ├── static-enum-creation-rule.mdc
│       ├── text-field-creation-rule.mdc
│       └── repo-shape.mdc
├── config/                      # Configuration files
│   └── project-scratch-def.json # Scratch org definition
├── docs/                        # Project documentation
│   └── how-to-create-repository-summary.md
├── force-app/                   # Main Salesforce source directory
│   └── main/
│       └── default/             # Default package directory
│           ├── classes/         # Apex classes
│           ├── triggers/        # Apex triggers
│           ├── lwc/             # Lightning Web Components
│           ├── aura/            # Aura components
│           ├── objects/         # Custom objects
│           ├── flows/           # Flow definitions
│           ├── layouts/         # Page layouts
│           ├── permissionsets/  # Permission sets
│           ├── tabs/            # Custom tabs
│           └── ...              # Other metadata types
├── .forceignore                 # Files to ignore in Salesforce operations
├── .gitignore                   # Files to ignore in Git
├── README.md                    # This file
├── REPOSITORY_SUMMARY.md        # **YOU MUST CREATE THIS - See docs/**
└── sfdx-project.json            # SFDX project configuration
```

## Getting Started

### 1. Clone this repository

```bash
git clone <repository-url>
cd EmissionsMatching
```

### 2. Authenticate with your Dev Hub

```bash
sf org login web --set-default-dev-hub --alias DevHub
```

### 3. Create a scratch org

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias MyScratchOrg --set-default --duration-days 30
```

### 4. Push source to scratch org

```bash
sf project deploy start
```

### 5. Open the scratch org

```bash
sf org open
```

## Development Workflow

1. Make changes to your source code in the `force-app` directory
2. Push changes to your scratch org: `sf project deploy start`
3. Pull changes from your scratch org: `sf project retrieve start`
4. Test your changes in the scratch org
5. Commit your changes to version control

## Useful Commands

- Create scratch org: `sf org create scratch -f config/project-scratch-def.json -a <alias>`
- Push source: `sf project deploy start`
- Pull source: `sf project retrieve start`
- Open org: `sf org open`
- Run Apex tests: `sf apex run test --test-level RunLocalTests`
- Delete scratch org: `sf org delete scratch --target-org <alias>`

## Included Cursor Rules

This project includes pre-configured Cursor AI rules in the `.cursor/rules/` directory:

- **`apex-best-practices.mdc`**: Expert guidelines for Salesforce backend development using Apex
- **`lwc-best-practices.mdc`**: LWC coding standards and best practices
- **`lwc-jest-tests.mdc`**: LWC rules for writing Jest unit tests
- **`lwc-jest-tests-sfdc.mdc`**: Salesforce core-specific instructions for LWC Jest tests
- **`lookup-field-creation.mdc`**: Rule for creating new foreign lookup fields on Base Platform Objects
- **`static-enum-creation-rule.mdc`**: Rule for creating new static enum fields
- **`text-field-creation-rule.mdc`**: Rule for creating new text fields
- **`repo-shape.mdc`**: Project structure reference and documentation guidance

These rules will automatically guide AI assistants when working with your code.

## Documentation

### Essential Documentation Files

- **`REPOSITORY_SUMMARY.md`** (YOU MUST CREATE THIS): Comprehensive codebase reference
- **`docs/how-to-create-repository-summary.md`**: Instructions for creating your repository summary
- **`README.md`** (this file): Getting started guide

### Creating Your Documentation

When you start your project from this template:

1. **First**: Create `REPOSITORY_SUMMARY.md` following the guide in `docs/`
2. **Then**: Update this README with project-specific information
3. **Maintain**: Keep both files updated as your project evolves

## Additional Resources

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
