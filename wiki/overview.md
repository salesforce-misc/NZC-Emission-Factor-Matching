---
title: Project overview
type: overview
sources:
  - README.md
  - force-app/main/default/classes/NZC_EmissionsMatchingEngine.cls
  - force-app/main/default/classes/NZC_EmissionsMatchingProcurementEngine.cls
updated: 2026-10-28
---

# Project overview

Net Zero Cloud add-on that links energy-use / Scope 3 records to emission factor (EF) sets.
Source format lives in `force-app/main/default`; `sfdx-project.json` is intentionally absent (githubsfdeploy button, branch `deploy-mdapi`).

- Matching engine (`NZC_EmissionsMatchingEngine`): custom-tag matching plus date-effective matching for stationary, vehicle, waste, hotel, freight, air, ground and rental car. Advanced/matrix matching was removed earlier.
- Scope 3 procurement is a separate path: see [Procurement backfill](features/procurement-backfill.md).
- Rules are `NZC_EmissionsMatchingCustomMatch__mdt` records, created by hand or with the [rule wizard](features/rule-wizard.md).
- Repo rules: Apache-2.0 header on every file, `with sharing`, Apex coverage >75%, Jest >85%. System.Comparator needs API 61+, new classes use 65.0.
