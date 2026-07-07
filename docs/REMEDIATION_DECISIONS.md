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
