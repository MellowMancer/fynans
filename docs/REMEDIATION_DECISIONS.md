# Remediation build — decisions & open doubts log

Running log for the `/goal` build on `refactor/architecture-remediation`. Per the user's
directive, the build does not pause between phases: doubts are recorded here with the default
taken, and work continues as long as `flutter analyze` is clean and `flutter test` is green.

## Locked decisions (Phase 0 checkpoint)
- Scope: F1–F14 (review Phases 0–2) **plus F21** (physical folder restructure to review Part 4),
  run last. Phases 3–5 (de-Hive entity, SMS rework, test harvest) DEFERRED to a follow-up.
- `AdvancedViewBloc` → reactive/stream-based (F12).
- Canonical grouping labels: empty = `"Uncategorized"`; month = `DateFormat.yMMMM()` ("July 2026").
- Pre-release data: a wipe is acceptable (only relevant to deferred F15).
- No co-author trailers on commits; no push / no remote. Work stays local in the worktree.

## Doubts encountered during the build
(Appended as they arise: feature id · the doubt · the default taken · why.)

| Feature | Doubt | Default taken | Rationale |
|---------|-------|---------------|-----------|
| F2 | `shared_preferences` became an unused dependency once `getNewSms` (its only user) was deleted. | Left it declared in `pubspec.yaml`; did NOT remove. | Removing a pubspec dep is outside F2's scope and analyze/test don't flag it. Flag for a later dependency-cleanup pass. |
| F3 | Full constructor DI for the SMS ingestor is the DEFERRED F16. | Ingestor default-constructs `HiveTransactionRepository()` for now. | Keeps `SmsIntakeService` (static, no-arg) working; behavior identical; proper DI comes in the deferred SMS rework. |
| F4 | The interim dedup fix needs per-SMS identity to both allow distinct same-key txns AND stay idempotent on re-scan. | Added `@HiveField(7) String? smsId` to `Transaction` (regen adapter, typeId 0 kept); dedup on a deterministic `Object.hash(sender, body, date)`; **linear scan** (O(1) indexing is deferred F17). | Only correct interim fix; additive schema change is backward-compatible and pre-release wipe is acceptable. Replaced `hasMatchingTransaction` with `existsWithSmsId` on the port. |
| F4 | Injecting the fake repo into the ingestor needed a seam. | Gave `TransactionSmsIngestor` an optional `{TransactionRepository? repository}` ctor defaulting to `HiveTransactionRepository()`. | Minimal testability seam; `SmsIntakeService` no-arg construction unchanged; full DI still deferred to F16. |
| F12 | `AdvancedViewBloc` used non-deterministic `DateTime.now()` in its constructor. | Added optional `initialMonth` + injectable `buildHierarchy` to the ctor. | Makes the bloc deterministically testable; production still defaults to the current month. |
| F13 | "One analytics output" vs keeping the raw `spendingByTag` map. | Replaced `MonthlyAnalytics.spendingByTag` with chart-ready `List<TagSlice>` (label/amount/percentage), top-5 + "Others", divide-by-zero guarded. | Nothing consumed the raw map; honors the single-output directive; percentage/bucketing now lives in the use case, not the widget. |
| F14 | The credit→party default (`'Me'`) was a UI rule; group CSV separator. | Encoded `isCredit && party.isEmpty → 'Me'` and the `,` group split in the `SaveTransaction` use case. | Moves business rules out of the widget; matches prior behavior exactly. |
