---
title: Procurement backfill
type: feature
sources:
  - force-app/main/default/classes/NZC_EmissionsMatchingProcurementEngine.cls
  - force-app/main/default/classes/NZC_EmissionsMatchingProcurementBatch.cls
  - force-app/main/default/triggers/NZC_EmissionsMatchingProcurementTrigger.trigger
updated: 2026-10-28
---

# Procurement backfill

Fills `Scope3PcmtItem.PcmtEmssnFctrSetItemId` for items uploaded without an EF.

- Matches directly to `PcmtEmssnFctrSetItem` (no master set, no Recalculate field). Default key: item `SupplierId` = set item `Supplier__c` (both lookups to the standard Supplier object, compared by Id) + `Scope3GhgCategory`.
- Rule: one custom-match record with `ObjectAppliesTo__c = Scope3PcmtItem`; `EnergyUseFieldToMatch__c` / `EmissionsSetFieldToMatch__c` hold ordered comma-separated field lists (255 chars) of equal length. Key is uppercased, `|`-joined, null if any part is blank.
- Tie-break: latest parent `EmissionFactorUpdateYear` that is <= the item's SpentDate (else ReportDate) year.
- Runs in a before insert/update trigger (gated by the insert/update toggles and `AllowCustomTagMatching__c`) and in `NZC_EmissionsMatchingProcurementBatch`, chained last from `NZC_EmissionsMatchingBatch`.
- `PcmtEmssnFctrSetItem.Supplier__c` is a custom lookup to Supplier (verified in AF1 2026-10-29); the wizard lets admins pick any pair.
- Status: Apex compiles (check-only deploy ok) but tests had not been executed at time of writing.
