# Instructions for Creating a Repository Summary File

## Purpose

Create a comprehensive `REPOSITORY_SUMMARY.md` file that serves as an LLM-optimized reference document for understanding the entire codebase structure, architecture, and components. This file should be the first resource consulted when working with the codebase.

## Target Audience

This document is designed for:
- AI assistants and LLMs working with the codebase
- New developers onboarding to the project
- Team members needing quick architectural reference
- Documentation systems and search tools

## File Location

Create the file at the project root: `REPOSITORY_SUMMARY.md`

## Document Structure

### 1. Header & Introduction (Required)

**Format:**
```markdown
# [Project Name] Repository

**[Project Name]** ([Full Name/Acronym]) is a [technology stack]-based application for [primary purpose]. Brief description of what the project does and key technologies used.
```

**What to include:**
- Project name and full name/acronym explanation
- One-sentence project description
- Primary purpose and domain
- Key technology stack mentioned upfront

### 2. Overview Section (Required)

**What to include:**
- Bullet list of main capabilities/features
- High-level user-facing functionality
- Core business objectives the system addresses
- 5-8 key points maximum

**Example:**
```markdown
## Overview

This [platform] project provides:
- [Main capability 1]
- [Main capability 2]
- [Main capability 3]
```

### 3. Technology Stack (Required)

**What to include:**
- Platform/framework with version numbers
- Frontend technologies
- Backend technologies
- Database/storage systems
- Third-party integrations
- Testing frameworks
- Development tools

**Format as bullet list with categories:**
```markdown
## Technology Stack

- **Platform**: [Name] (Version X.X)
- **Frontend**: [Technologies]
- **Backend**: [Technologies]
- **Integration**: [External services]
- **Testing**: [Test frameworks]
- **Development Tools**: [Tools used]
```

### 4. Architecture Section (Required)

This is the **most important section** for LLMs. Provide exhaustive detail.

#### 4.1 Core Components Subsection

List ALL components by type with descriptions:

**For Web Applications:**
- UI Components (React/Vue/LWC/etc.)
- Controllers/Services (backend logic)
- API endpoints
- Database models
- Background jobs/workers
- Integration adapters

**Format:**
```markdown
### Core Components

#### [Component Type 1] (e.g., React Components, LWC, Vue Components)
- **`componentName`**: Detailed description of purpose, key features, and interactions
- **`anotherComponent`**: Description...

#### [Component Type 2] (e.g., Backend Classes, Controllers, Services)
- **`ClassName`**: What it does, key methods, responsibilities
```

**Guidelines:**
- Use actual component/class/file names in code formatting
- Describe PURPOSE not just existence
- Mention key features or unique aspects
- Note important interactions or dependencies
- Include ALL major components, not just recent ones

#### 4.2 Platform-Specific Components

If using a platform (Salesforce, Django, Rails, etc.), document platform-specific elements:

- Flows/Workflows
- Triggers/Hooks
- Custom objects/models
- Templates/Views
- Middleware
- Plugins/Extensions

### 5. Key Features Section (Required)

Group functionality into major feature areas with detailed subsections:

```markdown
## Key Features

### 1. [Feature Name]

- What it does
- Key components involved
- User-facing capabilities
- Technical implementation notes
- Any architectural decisions

### 2. [Next Feature]
...
```

**Guidelines:**
- Number features for easy reference
- Explain WHY features were implemented certain ways
- Note any complex architectural decisions
- Mention patterns used (async, event-driven, etc.)

### 6. Data Model (Required)

**Critical for LLMs to understand data relationships.**

#### 6.1 List All Custom Entities

```markdown
### Custom Objects/Models/Tables

- **EntityName**: Purpose, key fields, record types if applicable
- **AnotherEntity**: Description...
```

#### 6.2 Extended Standard Entities

If extending platform objects:
```markdown
### Extended Standard Objects

- **StandardObject**: Extended with custom fields including:
  - Category: `field_name__c`, `another_field__c`
  - Another category: `field_name__c`
```

#### 6.3 Record Types/Polymorphism

Document any type variations:
```markdown
### Record Types / Entity Types

- **Entity.TypeName**: Purpose of this type
```

#### 6.4 Relationships

**Essential for LLMs:**
```markdown
### Relationships

- Entity A → Entity B → Entity C (describe relationship)
- Parent → Children (one-to-many)
- Entity ↔ Related Entity (many-to-many)
```

Use arrows to show relationship direction and cardinality.

### 7. Security & Access Control (If Applicable)

Document:
- User roles/profiles
- Permission systems
- Authentication methods
- Authorization patterns
- Security considerations in code (e.g., `with sharing` in Salesforce)

### 8. Recent Development (Recommended)

**Purpose:** Give immediate context on current work.

```markdown
## Recent Development

### Current Branch: `branch-name`

Brief description of current feature work.

**Features:**
1. What was added
2. What was changed
3. Purpose

**Status**: Current state (In Progress, Testing, Complete)

### Previous Work

Brief notes on recently completed major features.
```

**Guidelines:**
- Update this section regularly
- Reference specific branches
- Note breaking changes
- Document architectural decisions made

### 9. Project Structure (Required)

**Critical visual aid for LLMs.**

Create an ASCII tree structure showing:
- All major directories
- Key subdirectories
- Important files
- Brief inline comments

```markdown
## Project Structure

\`\`\`
ProjectName/
├── src/                        # Source code
│   ├── components/             # UI components
│   │   ├── ComponentA/
│   │   └── ComponentB/
│   ├── services/               # Business logic
│   ├── models/                 # Data models
│   └── utils/                  # Utilities
├── tests/                      # Test files
├── config/                     # Configuration
├── docs/                       # Documentation
├── package.json               # Dependencies
└── README.md                  # Main readme
\`\`\`
```

**Guidelines:**
- Show 3-4 levels deep maximum
- Include file counts for large directories
- Add inline comments explaining purpose
- Highlight important configuration files

### 10. Development Workflow (Required)

```markdown
## Development Workflow

### Prerequisites
- List required tools/software with versions
- System requirements

### Available Scripts
\`\`\`bash
command-name              # Description
another-command           # Description
\`\`\`

### Common Tasks
\`\`\`bash
# Deploy
command here

# Run tests
command here

# Build
command here
\`\`\`
```

### 11. Testing (Required)

Document:
- Testing frameworks used
- Test file locations/naming conventions
- Coverage requirements
- How to run tests
- Testing patterns specific to the project

### 12. Integration Points (If Applicable)

For each external integration:
- What service/API
- Purpose of integration
- Key files/components involved
- Authentication method
- Important notes

### 13. Important Notes for LLMs/AI Assistants (Critical)

**This section is specifically for other AI assistants.**

```markdown
## Important Notes for LLMs/AI Assistants

When working with this codebase:

1. **[Specific Pattern/Rule]**: Explanation of why and how
2. **[Framework Specifics]**: Important framework behaviors
3. **[Data Model]**: Key relationships to remember
4. **[Security]**: Security patterns used
5. **[Testing]**: Testing requirements
...
```

**Include:**
- Platform-specific gotchas
- Naming conventions
- Architectural patterns to follow
- Common pitfalls to avoid
- Where to find additional rules (e.g., .cursor/rules/)
- Code standards and practices
- Dependencies between components
- Performance considerations

**Guidelines:**
- Number each point
- Be specific, not generic
- Reference actual files/classes/patterns
- Explain WHY, not just WHAT
- Think about what would confuse an AI without context

### 14. Documentation Files (Required)

List all documentation with brief descriptions:

```markdown
## Documentation Files

- **REPOSITORY_SUMMARY.md**: This file - purpose
- **README.md**: Purpose
- **docs/specific-guide.md**: Purpose
- **CONTRIBUTING.md**: Purpose (if exists)
```

**Include subsections for:**
- Coding rules/guidelines (if in separate files)
- Architecture Decision Records
- API documentation
- Deployment guides

### 15. Metadata Footer (Required)

```markdown
---

**Last Updated**: [Date] - Based on branch `[current-branch]`
**Repository**: [Repo Name] - [Organization]
**Platform**: [Platform Name] (Version X.X)
**Active Environments**: [List environments]
```

## Writing Guidelines for LLMs

### Language and Style

1. **Be Explicit**: Don't assume knowledge. State things clearly.
2. **Use Code Formatting**: Always use backticks for:
   - File names: `fileName.js`
   - Class names: `ClassName`
   - Method names: `methodName()`
   - Field names: `field_name__c`
   - Commands: `npm run test`

3. **Use Hierarchy**: Proper markdown heading levels (##, ###, ####)

4. **Be Comprehensive**: Include ALL components, not just important ones

5. **Update Regularly**: Keep this file current with codebase changes

6. **Optimize for Search**: Use consistent terminology, include synonyms

### What Makes This LLM-Optimized?

1. **Front-loaded Information**: Most important info first
2. **Consistent Structure**: Same sections, same order
3. **Explicit Relationships**: Show connections with arrows/diagrams
4. **Complete Component Lists**: Every file/class mentioned
5. **Context for Decisions**: Explain WHY things are built certain ways
6. **Cross-references**: Link related sections
7. **Actual Code Names**: Use real identifiers, not placeholders
8. **Version Information**: Include versions for all dependencies
9. **Environment Information**: Note different deployment targets

### Information Gathering Process

To create this document:

1. **Scan the entire repository structure**
   - Use `list_dir` recursively
   - Note file counts in each directory
   - Identify all major file types

2. **Read package/dependency files**
   - package.json, requirements.txt, pom.xml, etc.
   - Note versions

3. **Identify all components**
   - List every file in component directories
   - Read key files to understand purpose

4. **Map data models**
   - Find all database models/schemas
   - Document custom fields on standard objects
   - Map relationships

5. **Trace relationships**
   - How components call each other
   - Data flow between layers
   - Integration points

6. **Check recent commits/branches**
   - Understand current work
   - Note recent architectural changes

7. **Read existing documentation**
   - README files
   - Inline code comments
   - Architecture docs
   - Coding standards/rules

8. **Verify accuracy**
   - Count files (don't estimate)
   - Use exact class/component names
   - Verify version numbers

## Template Checklist

Before considering the REPOSITORY_SUMMARY.md complete, verify:

- [ ] All major directories documented in structure tree
- [ ] Every component/class/module listed with description
- [ ] All custom data models/objects documented
- [ ] Data relationships clearly mapped
- [ ] Integration points identified
- [ ] Current branch/recent work documented
- [ ] Technology stack with versions listed
- [ ] Testing approach documented
- [ ] LLM-specific guidance included
- [ ] File uses consistent formatting (code blocks, bullets)
- [ ] Metadata footer includes date and version info
- [ ] Cross-references between sections are accurate
- [ ] No placeholders or TBD sections remain
- [ ] File is at project root as REPOSITORY_SUMMARY.md

## Maintenance

**Update this file when:**
- New components/features are added
- Architecture changes
- Dependencies are updated
- Current branch changes
- Data model changes
- New integrations added
- Documentation files are added/changed

**Frequency:** 
- After major feature completion
- Monthly minimum for active projects
- Before branch merges

## Example Sections

### Good Example - Component Documentation

```markdown
#### Lightning Web Components (LWC)

- **`interestFormsList`**: Displays Interest Forms grouped by Record Type and Contact with filtering capabilities, real-time refresh, and Lightning Message Service integration for inter-component communication. Includes year and record type filters, shows guardian information, and provides direct links to contact records.
- **`programParticipants`**: Displays program participants and guardians in a data table with medical information (allergies, conditions), generates PDF reports of participant lists, tracks cohort capacity and available spots, includes visual differentiation between participants and guardians.
```

**Why this is good:**
- Actual component names in code format
- Detailed feature descriptions
- Multiple aspects covered per component
- Technical details included

### Bad Example - Component Documentation

```markdown
#### Components

- interestFormsList - shows forms
- programParticipants - shows participants
```

**Why this is bad:**
- Not using code formatting
- Too brief, no useful details
- Doesn't explain features or purpose
- Missing technical context

### Good Example - Data Relationships

```markdown
### Relationships

- Interest Forms → Contacts (applicant and guardian relationships)
- Program Cohorts → Program Engagements → Contacts (tracks participant enrollment)
- Contacts → Related Contacts (guardian/participant parent-child relationships)
- Waivers → Contacts (one-to-many, participant agreements)
- Payments/Purchases → Contacts (financial tracking with lookup fields)
```

**Why this is good:**
- Uses arrows to show direction
- Explains relationship type
- Provides context in parentheses
- Shows chained relationships

## Final Notes

This REPOSITORY_SUMMARY.md file is a **living document** that should grow with your codebase. The time invested in creating and maintaining it will save countless hours for developers, AI assistants, and new team members trying to understand the project.

Think of it as the "map and guidebook" for your codebase - make it comprehensive, accurate, and easy to navigate.

