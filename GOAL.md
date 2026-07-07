# Goal: Finish the half-done Clean Architecture migration in Fynans — delete every duplicated "old half", fix the 11 correctness bugs test-first, and land the BLoC/repo/widget tests the seams were built for.

This ledger turns `docs/ARCHITECTURE_REVIEW.md` (Parts 1, 2, 4, 5, 6) into a dependency-ordered
DAG. The through-line of the review is that each refactor added a new implementation *beside* the
old one instead of replacing it — so most features here are **deletions and consolidations**, not
new architecture. Every feature is a vertical slice: independently buildable, `flutter analyze`
clean, and verifiable with `flutter test` (SDK `flutter_test` + `mocktail`; **`bloc_test` is
unavailable** — assert cubits via `cubit.stream` + `emitsInOrder`, per
`test/blocs/transaction_cubit_test.dart`). No `git push` / remote / CI work is in scope.

## Scope decisions (resolved 2026-07-08 — supersede the Open questions below)

- **Scope: Phases 0–2 (F0–F14) PLUS F21 folder restructure.** Phase 3 (F15 de-Hive),
  Phase 4 (F16–F18 SMS rework), and Phase 5 (F19–F20) are **DEFERRED to a follow-up run**.
- **F21 (folder restructure to review Part 4 layout) IS in scope**, run LAST after F1–F14
  so all feature work uses the current stable paths and there is exactly one physical move.
- **AdvancedViewBloc → reactive (stream-based)** to match `TransactionCubit`; folded into F12.
- **Canonical grouping labels:** empty bucket = `"Uncategorized"`; month = `DateFormat.yMMMM()`
  ("July 2026"). Applied in F12.
- **On-device data:** pre-release, a wipe is acceptable (only relevant to the deferred F15).
- **No co-author trailers on any commit; no push / no remote.**

## Foundation
- [ ] F0 Architecture & shared skeleton  (owner: designer)
      criteria: `ARCHITECTURE.md` exists describing the target layer/folder shape from review
      Part 4 (entities / use_cases / ports / adapters / ui), the DTO strategy for de-Hiving
      the entity, and the port list (`TransactionRepository`, `SmsSource`, `IngestCursorStore`,
      `BankRuleSet`). Designer confirms whether stack migration (hive_ce/isar) is in or out
      (see Open questions #1). `flutter analyze` and `flutter test` still green (no code change).

## Features (dependency order)

### Phase 0 — Delete dead weight (review Part 5 Phase 0 / Part 6 Finding)

- [x] F1 Delete dead auth screen — depends on: F0
      Remove `lib/screens/login_screen.dart` (470 lines, every method `throw
      UnimplementedError('Auth removed')`, referenced nowhere) in a no-auth app.
      criteria: `rg "login_screen|LoginScreen"` over `lib/` returns nothing; `flutter analyze`
      clean; `flutter test` green.  (addresses Finding #6)  risk: low
      parallel-with: F2

- [x] F2 Delete dead read paths — depends on: F0
      Remove `HiveService.getAdvancedViews`, `lib/models/advanced_view_summary.dart`
      (`AdvancedViewSummary`), and the `ReadSmsService.getNewSms()` cursor path
      (`read_sms_service.dart:46-79`) — all dead / referenced only internally.
      criteria: `rg "AdvancedViewSummary|getAdvancedViews|getNewSms"` returns nothing;
      `flutter analyze` clean; `flutter test` green.  (addresses Finding #1, Finding #5,
      Bug #8)  risk: low
      parallel-with: F1

- [x] F3 One box, one adapter — collapse `HiveService` into `HiveTransactionRepository` and
      delete it — depends on: F2
      Add a dedup lookup (`hasMatchingTransaction`/`existsBySmsId`) and `saveTransaction` to
      the `TransactionRepository` port, point `TransactionSmsIngestor` and `SmsIntakeService`
      at the port instead of `new HiveService()`, then delete `lib/services/hive_service.dart`.
      criteria: `rg "HiveService"` returns nothing; SMS ingest writes through
      `TransactionRepository`; `flutter analyze` clean; `flutter test` green.
      (addresses Finding #1, Finding #3)  risk: med
      parallel-with: none

### Phase 1 — Fix correctness bugs (review Part 2 / Part 5 Phase 1) — RED before GREEN

Each feature writes a failing regression test first, then makes it pass.

- [ ] F4 Fix dedup data-loss — depends on: F3
      Bug #1: dedup keys on parsed `(date, amount, isCredit, party)`, so two genuine
      transactions in the same minute with equal amount/party collapse into one.
      criteria: a repository/ingestor test seeds two distinct bank SMS that share
      minute+amount+party and asserts **two** transactions persist (red before the key fix,
      green after). Interim fix only — the O(1) indexed raw-SMS key is F17.  (Bug #1)  risk: med
      parallel-with: F5, F6, F7, F8, F9

- [ ] F5 Fix declined-as-debit — depends on: F0
      Bug #3: debit keywords are matched before the "declined" check, so a declined SMS is
      recorded as real outflow (`sms_parser_service.dart:251-260`).
      criteria: `test/services/sms_parser_test.dart` gains a case: a declined-transaction SMS
      body parses to `TransactionType.declined` (not `debit`) and produces no saved
      transaction. Red before, green after.  (Bug #3)  risk: low
      parallel-with: F4, F6, F7, F8, F9

- [ ] F6 Fix amount-vs-balance capture — depends on: F0
      Bug #4: the amount extractor can capture the available-balance figure instead of the
      transaction amount (`sms_parser_service.dart:307-323`).
      criteria: parser test with a real-shaped SMS containing both "debited ₹X" and "Avl Bal
      ₹Y" asserts the parsed `amount == X`. Red before, green after.  (Bug #4)  risk: med
      parallel-with: F4, F5, F7, F8, F9

- [ ] F7 Fix cubit subscription leak — depends on: F0
      Bug #9: `TransactionCubit.fetchTransactionsForMonth` opens a new never-cancelled
      `.listen()` on every call (init, month-swipe, refresh), the sync `try/catch` cannot
      catch async stream errors, and emits can fire after `close()`
      (`transaction_cubit.dart:14`).
      criteria: a test proves (a) a second `fetch...` cancels the prior subscription, and
      (b) no state is emitted after `close()`. Hold the subscription as a field and cancel it
      in `close()`. Red before, green after.  (Bug #9)  risk: med
      parallel-with: F4, F5, F6, F8, F9

- [ ] F8 Fix amount-parse crash — depends on: F0
      Bug #10: `double.parse(_amountController.text)` with a validator that only checks
      non-empty crashes on non-numeric input (`add_transaction_screen.dart:84`).
      criteria: an extracted, pure amount validator/parser rejects non-numeric / negative /
      empty input and is covered by a unit test; the save path no longer calls bare
      `double.parse`. (Superseded structurally by F14 `AddTransactionCubit`; this is the
      minimal safe fix.)  (Bug #10)  risk: low
      parallel-with: F4, F5, F6, F7, F9

- [ ] F9 Fix merchant over-capture regex — depends on: F0
      Bug #5: an over-escaped end-anchor (`\\$` matching a literal `$`) means the
      end-of-string merchant terminator never fires (`sms_parser_service.dart:470`).
      criteria: parser test with a merchant name at end-of-body asserts the merchant is not
      over-captured. Red before, green after. (Full parser split is F18.)  (Bug #5)  risk: med
      parallel-with: F4, F5, F6, F7, F8

### Phase 2 — Finish the Clean Architecture migration (review Part 5 Phase 2 / Finding #4)

- [ ] F10 Provide the repository once via `RepositoryProvider` — depends on: F3
      Stop drilling `repository:` through `AddTransactionScreen` → `SummaryCard` →
      `SimpleTransactionListView` → `AnalyticsScreen`. Build the one repository in the
      composition root and expose it via `RepositoryProvider`; widgets read `context.read`.
      criteria: `rg "repository:" lib/` shows no widget constructor still taking a repository
      parameter; app builds; `flutter analyze` clean; `flutter test` green.
      (Finding #3)  risk: med
      parallel-with: F11

- [ ] F11 Move `HierarchyNode` to the model/entity layer — depends on: F0
      `HierarchyNode` is trapped as `part of advanced_view_bloc.dart`, forcing widgets to
      import the BLoC to render a tree.
      criteria: `HierarchyNode` lives in `lib/models/` (or `lib/entities/`); no widget imports
      `advanced_view_bloc.dart` for the type; `flutter analyze` clean; `flutter test` green.
      (Finding #4)  risk: low
      parallel-with: F10

- [ ] F12 Single `BuildTransactionHierarchy` use case — depends on: F2, F11
      Move `_groupTransactions` (`advanced_view_bloc.dart:104-132`) and all bucketing rules
      into one use case; reduce `GroupingOption` to a pure `(name, displayName)` enum (drop
      its `Transaction`/`intl` imports and embedded policy). Canonical labels (resolved):
      empty bucket = `"Uncategorized"`, month = `DateFormat.yMMMM()` ("July 2026").
      **Also make `AdvancedViewBloc` reactive** (resolved): subscribe to
      `listenToTransactionsForMonth` (stream) instead of one-shot `fetchTransactionsForMonth`
      in `_onDataFetched`, so the advanced view live-updates like `TransactionCubit`; hold and
      cancel the subscription (mirror F7).
      criteria: a use-case unit test covers nested grouping, the `"Uncategorized"` empty label,
      and the `yMMMM` month format; the BLoC delegates to the use case and re-emits on box
      changes (a test proves a second box write re-emits grouped state); grouping logic exists
      in exactly one place (`rg` shows no second grouping switch); `flutter analyze` clean.
      (Finding #4, Finding #6)  risk: med
      parallel-with: F13

- [ ] F13 `GetMonthlyAnalytics` use case + `AnalyticsCubit` — depends on: F10
      Move inflow/outflow/daily/by-tag aggregation out of the repository
      (`hive_transaction_repository.dart:87-134`) into a use case, and the "top-5 + Others"
      bucketing + percentage math out of `analytics_screen.dart:245-268` into the use
      case/cubit. Collapse the overlapping aggregate models toward one analytics output.
      criteria: use-case unit test (via `FakeTransactionRepository`) covers top-5+Others and
      percentages; `AnalyticsScreen` holds no aggregation math; `flutter analyze` clean.
      (Finding #2, Finding #4)  risk: med
      parallel-with: F12

- [ ] F14 `AddTransactionCubit` — depends on: F8, F10
      Move entity construction, amount parsing, CSV group split, and validation out of
      `add_transaction_screen.dart:74-120` into a cubit that calls a `SaveTransaction` use
      case; the widget only dispatches intents and renders state.
      criteria: cubit unit test (via `FakeTransactionRepository`) covers save + suggestion
      loading + invalid-amount rejection; the widget contains no `double.parse`, no CSV split,
      no direct `saveTransaction`; `flutter analyze` clean.  (Finding #4)  risk: med
      parallel-with: none
      RESOLVED: `AdvancedViewBloc` reactivity is handled in F12, not here.

---
## DEFERRED — Phases 3–5 (NOT built in this run; kept for the follow-up epic)
---

### Phase 3 — De-Hive the entity (review Part 5 Phase 3 / Finding #2) — HIGH RISK — DEFERRED

- [ ] F15 Pure domain `Transaction` + `TransactionHiveDto` + mappers — depends on: F12, F13, F14
      Introduce a framework-free immutable `Transaction` (const constructor, validated, no
      `@HiveType`), keep the annotations on a new `TransactionHiveDto` in the data layer, and
      add `toDomain()`/`fromDomain()` mappers. This ripples through repository, use cases,
      BLoCs, and widgets — it is only safe once the cubits (F14/F13) and the single grouping
      use case (F12) mediate access to the entity.
      criteria: `rg "@HiveType|@HiveField|extends HiveObject" lib/models` shows the annotations
      only on the DTO, never on domain `Transaction`; a mapper round-trip test passes; the
      Hive `typeId: 0` is preserved on the DTO (no data-format break); full suite + analyze
      green.  (Finding #2)  risk: high
      parallel-with: none
      NEEDS-CLARIFICATION: on-device data preservation vs acceptable wipe (Open questions #6);
      this is a **DTO-only** de-Hive that keeps the pinned hive/hive_generator stack — a
      hive_ce/isar migration is explicitly NOT bundled here (Open questions #1).

### Phase 4 — Rework SMS ingestion (review Part 5 Phase 4 / Finding #5) — HIGH RISK — DEFERRED

- [ ] F16 SMS ports + dependency injection — depends on: F3, F15
      Define `SmsSource`, `IngestCursorStore`, and `BankRuleSet` ports in the use-case layer.
      Split `ReadSmsService` (it fuses `Telephony.instance` + `SharedPreferences`); inject
      collaborators into `TransactionSmsIngestor` (currently hardcodes `SmsParserService()` +
      `HiveService()`); remove the all-static `SmsIntakeService` singleton.
      criteria: ports defined with no Flutter/plugin imports; ingestor + intake take
      dependencies via constructor; an `IngestSms` unit test runs against a fake `SmsSource`
      (no device); `rg "static final .*Ingestor"` returns nothing; `flutter analyze` clean.
      (Finding #3, Finding #5)  risk: high
      parallel-with: none

- [ ] F17 Awaitable, isolated, O(1)-idempotent ingest job — depends on: F16
      Make ingestion an awaitable, error-reporting job with per-message failure isolation
      (Bug #6: `main.dart:17` fire-and-forget + one bad SMS aborts the batch). Replace the
      O(n·m) parsed-field dedup (Bug #2) with a stable raw-SMS idempotency key
      (`hash(sender, body, date)` or platform row id) stored on the record and looked up via
      a keyed box. Remove the `maxMessages` history truncation (Bug #7:
      `read_sms_service.dart:17`).
      criteria: a test proves one malformed SMS does not abort the batch and its error is
      reported (not swallowed); a test proves re-running the same inbox imports each SMS once
      via the stored key with no full-box scan; `main()` awaits/handles the job; `flutter
      analyze` clean.  (Bug #2, Bug #6, Bug #7)  risk: high
      parallel-with: none

- [ ] F18 Split the parser + externalize bank rules — depends on: F16
      Break the ~500-line 8-responsibility `SmsParserService` into `SmsClassifier` + field
      extractors + a formatter; precompile all regexes once; stop destructively lowercasing
      the whole body then re-title-casing merchant names (`:216`). Move the bank whitelist /
      card blocklist / keyword lists out of `const` literals (`:119-173`) into an
      asset-loaded `BankRuleSet`.
      criteria: unit tests per split component (classify / extract / format) pass, including
      the Phase-1 bug cases; bank rules load from a bundled asset, not compile-time `const`;
      `flutter analyze` clean.  (Finding #5)  risk: high
      parallel-with: F17
      NEEDS-CLARIFICATION: asset-bundled rules only vs remote-config; dead-letter UI scope
      (Open questions #4 and #5).

### Phase 5 — Harvest the tests & centralize duplication (review Part 5 Phase 5 / Part 6) — DEFERRED

- [ ] F19 Centralize `capitalize`, currency, and strings — depends on: F0
      Bug #11: `capitalize` (`s[0]...`) is reimplemented 6× and crashes on `''`; `₹` +
      `toStringAsFixed` money formatting is duplicated 5×+; `_getMonthBounds` 2×.
      criteria: a single `capitalize` util with an empty-string test (returns `''`, no throw);
      `rg "String capitalize"` shows exactly one definition; one money-format helper used by
      the widgets. Also remove the `'pokemon': Icons.catching_pokemon` joke entry from
      `TagHelper`.  (Bug #11, Finding #6)  risk: low
      parallel-with: F20

- [ ] F20 Harvest BLoC / repository / widget tests — depends on: F13, F14, F15
      Now that the seams exist, write the tests the `FakeTransactionRepository` was built for:
      `AdvancedViewBloc` behavior via the fake, a `HiveTransactionRepository` contract test
      against a real in-memory Hive box, and widget tests for the centralized money/capitalize
      formatting.
      criteria: new test files under `test/blocs/`, `test/data/`, `test/widgets/` exist and
      pass; `flutter test --coverage` emits `coverage/lcov.info`; every prior bug regression
      test still green.  (Part 6)  risk: low
      parallel-with: F19

## Open questions — RESOLVED / DEFERRED (2026-07-08)

Resolutions (see "Scope decisions" at top): **#2** → AdvancedViewBloc becomes reactive (F12).
**#3** → `"Uncategorized"` + `DateFormat.yMMMM()` (F12). **#6** → wipe acceptable.
**#1, #4, #5, #7** pertain only to the **deferred** Phases 3–4 and will be settled in the
follow-up run (this plan's assumptions — defer stack migration, asset-only rules, no
dead-letter, decide TestSmsScreen later — stand until then). Original text kept below.

1. **Stack migration (hive → hive_ce / isar).** The pinned `hive_generator 2.0.1`
   (`analyzer <7`) blocks `bloc_test` and is the reason the entity is welded to Hive
   (Appendix / Part 6). F15 de-Hives the entity with a **DTO-only** approach that keeps the
   pinned stack. Do we attempt the full hive_ce/isar migration now (unblocking `bloc_test` and
   modern tooling in one move, HIGH RISK, touches persistence + adapters + on-device data), or
   defer it to a separate epic after this remediation? This plan assumes **defer**.

2. **`AdvancedViewBloc` reactivity.** `TransactionCubit` is stream-based (live) while
   `AdvancedViewBloc` uses one-shot `fetchTransactionsForMonth`, so the simple view
   auto-refreshes on box changes and the advanced view does not, and both independently
   recompute the same month summary (Finding #6). Should F12/F14 make `AdvancedViewBloc`
   reactive to match (bigger change, consistent UX), or keep it future-based (smaller change)?
   Guessing wrong reshapes the state layer.

3. **Canonical grouping labels.** The three grouping implementations disagree: empty-bucket
   label is `'No Groups'` vs `'Uncategorized'`, and month format is `'yyyy MMMM'` vs
   `DateFormat.yMMMM()` (Finding #4). F12 must pick one of each as the user-visible canonical
   value — which? Wrong choice silently changes what users see.

4. **`BankRuleSet` source.** F18 externalizes bank rules. The app is explicitly device-local /
   no-cloud, so remote-config implies a new network dependency that contradicts that stance.
   Confirm **asset-bundled JSON only** (this plan assumes yes), or is a remote/updatable
   ruleset actually wanted?

5. **Dead-letter capture scope.** Review Finding #5 mentions "a dead-letter capture for
   unparsed bank SMS". Is that in scope for F17/F18 (adds storage + likely diagnostic UI), or
   out of scope for this remediation? This plan does not add a dead-letter feature; confirm.

6. **On-device data preservation.** F15 changes the entity shape (though it keeps `typeId: 0`
   on the DTO). Is there real user data on devices that must survive, requiring a verified
   migration path, or is a one-time wipe acceptable in this pre-release state? Determines
   whether F15 needs an explicit migration + migration test.

7. **`TestSmsScreen` fate.** The third nav tab (`TestSmsScreen`) is a dev/diagnostic screen
   depending on `ReadSmsService.getAllSms`. F16 restructures SMS reading — should the diagnostic
   screen be kept and rewired onto the new `SmsSource` port, or removed? Not currently a feature.
