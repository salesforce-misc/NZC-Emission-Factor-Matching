# Wiki log

Append-only. Newest entries at the bottom. Heading format:
`## [YYYY-MM-DD] ingest|query|lint|decision | title`

## [2026-10-28] decision | Adopt LLM Wiki pattern

Bootstrapped from the workspace template while adding Scope 3 procurement backfill and the rule wizard.

## [2026-10-30] ingest | AF1 cleanup, deploy and Apex test run
- AF1: removed old Advanced Match/TD Losses/Matrix classes; kept InsertEngine (+Test, Wrapper) because flow Link_Electricity_Sets references it.
- Deployed Scope 3 procurement + wizard code; 17 Apex tests pass (procurement engine 95%, rule controller 87%).
- Test gotchas: `allowCustomTagMatching` getter re-reads `matchingConfig`, so tests must use `NZC_EmissionsMatchingDatafactory.createEmissionsSettings()`; one `executeBatch` per test, scope ≤200; `enqueueDeployment` is skipped under `Test.isRunningTest()`.
