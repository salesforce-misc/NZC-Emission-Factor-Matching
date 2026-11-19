---
title: Matching rule wizard
type: feature
sources:
  - force-app/main/default/lwc/nzc_EmissionsMatchingRuleWizard/nzc_EmissionsMatchingRuleWizard.js
  - force-app/main/default/classes/NZC_EmissionsMatchingRuleController.cls
updated: 2026-10-28
---

# Matching rule wizard

LWC `nzc_EmissionsMatchingRuleWizard` (AppPage/HomePage/Tab) creates custom-match rules without hand-editing metadata.

- Steps: record type (+ fuel type for stationary/vehicle) -> field pairs (several only for procurement) -> review (validation, warnings, unmatched count) -> save.
- `NZC_EmissionsMatchingRuleController.saveRule` deploys via `Metadata.DeployContainer`; developer name `Match_<Object>[_Fuel]`, an existing rule for the same object+fuel is overwritten. Apex has no deploy-status API, so the wizard polls `isRuleDeployed` (reads the rule back, 2s x 30).
- Jest tests: `lwc/nzc_EmissionsMatchingRuleWizard/__tests__` (11 passing, 100% statements); run `npm install && npm test` (the script creates and removes a temporary `sfdx-project.json`, which the repo omits on purpose).
