---
title: Issue 1 - One-Click and Workbench deploy failures
type: ops
sources:
  - README.md
  - scripts/build-deploy-zip.py
  - user (2026-10-30)
  - https://github.com/salesforce-misc/NZC-Emission-Factor-Matching/issues/1
updated: 2026-10-30
---

# Issue 1 - deploy failures (open, triage only)

Reporter: One-Click Deploy says classes etc. "named in package.xml, but not found in zipped directory". Workbench (API 68.0) accepts a 146-file zip but reports 0 components and fails on `aura|classes|layouts|lwc|objects|permissionsets|triggers/package.xml`.

## Findings (nothing fixed yet)
- `main` has no `sfdx-project.json`; the README button targets branch `deploy-mdapi`, which does. Its `force-app/main/default/package.xml` is mdapi-format (version 55.0, 105 members) beside source-folder content.
- `deploy-mdapi` flipped `sfdx-project.json` path between `force-app` and `force-app/main/default` (commits 552eadc, 0455838), a sign the deploy tool was guessing which root to zip. The error is consistent with it zipping a root that lacks the package.xml's folders.
- The release zip (`NZC-Emission-Factor-Matching-Deploy.zip`, v1.0.0, 147 entries) has a root `package.xml`, but also stray non-metadata `lwc/jsconfig.json` and `aura/.gitkeep`. The reporter's zip had 146 files and per-folder `package.xml` failures, so it was not this asset as committed: likely a re-zip from the wrong level.
- Workbench failure reproduced with the sf CLI; see root cause below.

## Root cause and fix (2026-11-04)
- **Workbench:** the **Single Package** box must be ticked. Unticked, the Metadata API treats each top-level folder as a package and wants `<folder>/package.xml`, which is exactly the reported `aura|classes|...|triggers/package.xml` failures. Reproduced with `sf project deploy start --metadata-dir <zip>` (fails) vs `--single-package` (check-only passes 125/125 on a Net Zero Cloud org). README Option 2 now says so.
- **Real content bug found:** the Config layout referenced `AllowAdvancedMatching__c` and `AllowTransmissionDistribution__c`, which no longer exist on the object, so a fresh org rejects the layout. Items removed.
- **Generated package.xml:** `scripts/build-deploy-zip.py` builds it from the folders (API 65.0) incl. `CustomField`/`ListView` children read from each `.object`. Zip has no `jsconfig.json`/`.gitkeep`/tests.
- **One-Click:** root-selection theory still unproven; not testable without the Heroku tool.

## Scratch-org deploy test (2026-11-12)
- Org: `sf org create scratch` with `../NZC-Assist/config/project-scratch-def.json` (SustainabilityApp) on DevHub `nzc-gus`, alias `nzc-efm-test`; then PSLs `NetZeroCloudUserPsl`/`DataProcessingEnginePsl` + permsets `NetZeroAdmin`/`NetZeroManager`/`DataProcessingEngineUser`. This repo's own `config/project-scratch-def.json` has no NZC licensing, so don't use it.
- `build-deploy-zip.py` was missing `tabs`, so `EmissionsMatching` failed on the `NZC_EmissionsMatchingRuleWizard` tab; fixed (CustomTab).
- Waste failure cause: the scratch org had `enableSCWasteManagement` false (`GeneratedWaste` not createable, no `WstDispoEmssnFctrSetId`). `config/project-scratch-def.json` now matches NZC-Assist's plus `enableSCWasteManagement` and `enableSCScope3HubEnabled`.
- After creating the org: assign PSLs/permsets, then deploy NZC-Assist `metadata/record-types` and `metadata/nzc-configs` (zip them, `--single-package`) and assign `NZC_RecordType_Access`. Without the record types every test fails with "Configure the record types using the setup entities".
- Result on a fresh org (`nzc-efm-test2`): zip deploys 132/132, `RunLocalTests` 88 passed, 0 failed.
