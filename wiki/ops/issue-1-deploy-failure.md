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
- Not reproduced: no org or Workbench run, and the live release asset was not downloaded.

## Fix applied (uncommitted, 2026-10-30)
- `scripts/build-deploy-zip.py` builds the release zip: `package.xml` generated from the folders (API 65.0), root-level, no `jsconfig.json`/`.gitkeep`/tests. Same function regenerated `force-app/main/default/package.xml`, which was stale (no RuleWizard bundle).
- Still to do: build and attach the new zip to the release, copy to `deploy-mdapi`, test in an org.

## Next steps
- Ask the reporter how they built the zip; have them use the release asset unchanged.
- Drop `jsconfig.json` and `.gitkeep` from the release zip; check the deploy tool's root-selection rules.
