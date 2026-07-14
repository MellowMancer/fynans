# Fynans — Architecture Review & Remediation Roadmap

- **Date:** 2026-07-08
- **Branch:** `feature/testing-and-architecture-docs`
- **Scope:** Full read of `lib/` (~4,500 LOC) and `test/`, plus the composition root, data layer, state layer, models, SMS pipeline, UI, and widgets.
- **Overall grade:** **C- (half-migrated Clean Architecture).**

---

## Executive summary

The codebase is mid-refactor toward Clean Architecture and is stuck in the worst
possible middle state. The good patterns that were recently introduced — a
`TransactionRepository` port, an extracted `summariseTransactions` use case, and a
`TransactionFilter` value object — now sit **alongside** the old ones instead of
**replacing** them. The result is *two of everything*: two persistence layers, two
grouping implementations, two SMS ingestion strategies.

The abstractions were added but the payoff was never collected. The 96-line
`FakeTransactionRepository` is used by **zero tests**, and there are **no BLoC,
repository, or widget tests at all** — the exact capability those abstractions exist
to enable.

**The through-line of every finding below:** the refactors moved in the right
direction but were never *finished* — the old implementation was left in place beside
the new one every single time. The fix is rarely "more architecture." It is
**deleting the old half** so each concept has exactly one home.

---

## Part 1 — The six root-cause failures

Roughly fifty individual smells collapse into six structural failures.

### 1. The data layer is duplicated — two persistence classes over one Hive box  ·  Grade: D

`HiveService` (237 lines) and `HiveTransactionRepository` (146 lines) **both** open
`Hive.box<Transaction>('transactions')` and **both** implement `_getMonthBounds`,
`listenToTransactionsForMonth`, `fetchTransactionsForMonth`,
`getAll{Groups,Tags,Parties}`, and `getAnalyticsForMonth` — near-identical code, twice.

- The UI/BLoC **read** path goes through `TransactionRepository` (the new port).
- The SMS **write** path goes through `HiveService` (`transaction_sms_ingestor.dart:2,11`) — the old class.
- `HiveService.getAdvancedViews` + the entire `AdvancedViewSummary` model are **dead**
  (referenced only inside `HiveService` itself).
- ~200 of 237 lines of `HiveService` are dead-or-duplicated. The ingestor uses only
  `saveTransaction` and `hasMatchingTransaction`.

**Fix:** `HiveTransactionRepository` becomes the only data adapter. Add
`existsBySmsId`/`hasMatchingTransaction` to the `TransactionRepository` port, point the
SMS ingestor at the port, then **delete `HiveService`, `getAdvancedViews`, and
`AdvancedViewSummary` entirely.** One box → one adapter → one port.

### 2. The domain entity *is* a Hive object — framework coupling at the core  ·  Grade: D

`Transaction extends HiveObject` with `@HiveType`/`@HiveField` annotations
(`transaction.dart:1-6`) and is passed **unchanged** through every layer — repository,
use cases, BLoCs, and widgets all import the Hive-annotated model. Clean Architecture's
one inviolable rule is that Entities depend on nothing external.

Consequences: `late` mutable fields with no constructor, no validation, no invariants;
the sign convention (`isCredit` bool + always-positive `amount`) is implicit and
re-derived everywhere; entity construction happens via cascade setters in a **widget**
(`add_transaction_screen.dart:83-90`) and in the **ingestor**
(`transaction_sms_ingestor.dart:47-54`). There are also **three overlapping aggregate
models** — `MonthlySummary`, `MonthlyAnalytics`, and the dead `AdvancedViewSummary` —
that each re-fold the same transaction list.

**Fix:** a plain immutable `Transaction` domain entity (const constructor, validated,
framework-free) plus a separate `TransactionHiveDto` carrying the annotations, with
`toDomain()`/`fromDomain()` mappers in the data layer. Collapse the aggregates into one
analytics use-case output.

### 3. No dependency injection; the one abstraction is drilled, not provided  ·  Grade: D+

Every collaborator is `new`'d concretely:

- `TransactionSmsIngestor` hardcodes `SmsParserService()` + `HiveService()` as final fields.
- `SmsIntakeService` is **all-static** with a `static final` ingestor singleton — global
  mutable pipeline state that cannot be mocked or reset between tests.
- `ReadSmsService` instantiates `Telephony.instance` **and** `SharedPreferences` inside
  one class — two infrastructure concerns fused into one.
- The repository *is* an abstraction, but it is **manually threaded through widget
  constructors** (`AddTransactionScreen(repository:)` → `SummaryCard(repository:)` →
  `SimpleTransactionListView(repository:)`), coupling the whole widget tree to the data layer.

The testability these abstractions were meant to buy is unrealized:
`FakeTransactionRepository` (96 lines) has **no test using it**.

**Fix:** define ports (`SmsSource`, `IngestCursorStore`, `TransactionRepository`), inject
implementations via constructors, and provide the repository **once** at the top via
`RepositoryProvider` so widgets read it from `context` — never carry it as a parameter.

### 4. Business logic scattered across every layer it shouldn't be in  ·  Grade: C-

`summariseTransactions` was correctly lifted to a use case — but the discipline stops
there. Domain logic still lives in:

- **The BLoC:** `_groupTransactions` (recursive hierarchy build + per-node summary +
  sort) is a real algorithm hosted in `advanced_view_bloc.dart:104-132`. And
  `HierarchyNode` — a domain type widgets render — is trapped as `part of` the BLoC file,
  forcing **widgets to import the BLoC** to draw a tree.
- **The enum:** `GroupingOption.getValues` embeds bucketing policy (empty → `'No Groups'`,
  month formatting) and imports `Transaction` + `intl`.
- **The persistence layer:** `getAnalyticsForMonth` computes inflow/outflow/daily/by-tag
  aggregation *inside the repository*.
- **Widgets:** `analytics_screen.dart:245-268` does "top-5 + Others" bucketing and
  percentage math; `add_transaction_screen.dart:74-120` parses amounts, splits the CSV
  group string, builds the entity, and calls `saveTransaction` directly; validation lives
  in `TextFormField.validator` closures.

**The grouping rule exists in three divergent places** — `GroupingOption.getValues`,
`_groupTransactions`, and `HiveService.getAdvancedViews` — with *different* empty-bucket
labels (`'No Groups'` vs `'Uncategorized'`) and *different* month formats (`'yyyy MMMM'`
vs `DateFormat.yMMMM()`). They have already drifted.

**Fix:** one `BuildTransactionHierarchy` use case owns all grouping/bucketing;
`GroupingOption` becomes a pure `(name, displayName)` enum; analytics aggregation moves
out of the repo into an `AnalyticsUseCase`; `HierarchyNode` moves to `lib/models/`; every
screen gets a cubit (`AddTransactionCubit`, `AnalyticsCubit`) so **no widget touches the
repository or holds business rules.**

### 5. The SMS pipeline: brittle, untestable, and quietly wrong  ·  Grade: D

This is where design failures become **correctness bugs** (see Part 2). Beyond the bugs:

- Bank whitelist, credit-card blocklist, and keyword lists are **compile-time `const`
  literals** (`sms_parser_service.dart:119-173`) — adding a bank or region needs an
  app-store release. This is configuration masquerading as code.
- `SmsParserService` is a ~500-line, 8-responsibility god class that even **title-cases
  merchant names** (a UI concern) after destructively lowercasing the whole body
  (`:216`), losing original casing irrecoverably.
- Ingestion is triggered as an **unawaited fire-and-forget** future in `main()`
  (`main.dart:17`) with no error handling — any failure becomes a silently swallowed async
  error, and one malformed SMS aborts the whole batch loop.
- The dedup key is derived from **parsed** fields, not raw-SMS identity, and runs an
  **O(n) scan per message** on a full-inbox sweep **every launch** — O(n·m).
- Documentation describes a "live listener" component that **does not exist**; the
  `getNewSms()` cursor path is **dead code** and buggy.

**Fix:** idempotency key = stable hash of raw `(sender, body, date)` or the platform row
id, stored on the record, looked up via an indexed/keyed box (O(1), correct). Split
`SmsParserService` into `SmsClassifier` + field extractors + a formatter; precompile all
regexes once. Move bank rules into an asset/remote-config `BankRuleSet`. Make ingestion an
**awaitable, error-reporting** job owned by a controller, with per-message failure
isolation and a dead-letter capture for unparsed bank SMS.

### 6. Dead code, rot, and a leaky cubit  ·  Grade: C

- **`login_screen.dart` — 470 lines, dead.** In an explicitly "no-authentication" app, a
  full sign-in/sign-up/confirm/forgot/reset UI survives with every method as
  `throw UnimplementedError('Auth removed')` and a 5-boolean state machine. Referenced
  nowhere. **Delete it.**
- **`TransactionCubit` leaks subscriptions (real bug).** Every `fetchTransactionsForMonth`
  call — init, each month-swipe, refresh button — opens a **new never-cancelled
  `.listen()`** on `box.watch()` into the same cubit (`transaction_cubit.dart:14`). The
  `try/catch` cannot catch async stream errors, and emits can fire after `close()`.
- **Reactivity is inconsistent on the same screen:** `TransactionCubit` is stream-based
  (live) but `AdvancedViewBloc` uses one-shot `fetchTransactionsForMonth`, so the simple
  view auto-refreshes on box changes and the advanced view does not. Both also
  independently recompute the same month summary.
- **`DateTime.now()` in `AdvancedViewBloc`'s constructor initializer** (evaluated twice) —
  non-deterministic and untestable.
- **Pervasive micro-duplication:** `capitalize` reimplemented **6×** (and crashes on
  `''`), `₹` + `toStringAsFixed` money formatting **5×+**, `_getMonthBounds` 2×, date↔index
  math 3×. `TagHelper` is a hardcoded UI-asset taxonomy whose valid-tag list is *derived
  from an icon map*, and a `'pokemon': Icons.catching_pokemon` joke entry still ships.

---

## Part 2 — Correctness bugs (not just design)

| # | Bug | Where | Impact |
|---|-----|-------|--------|
| 1 | Dedup keyed on **parsed** fields; two real transactions in the same minute with equal amount/party **collapse into one** | `hive_service.dart:31-42` | **Data loss** |
| 2 | O(n·m) dedup — full box scan per message, every launch | `hive_service.dart:37` | Quadratic, unbounded |
| 3 | Declined SMS recorded as a real debit (debit keywords checked before "declined") | `sms_parser_service.dart:251-260` | Wrong outflow |
| 4 | Amount extractor can capture the **available balance** instead of the transaction amount | `sms_parser_service.dart:307-323` | Wrong amount |
| 5 | Over-escaped end-anchor `\\$` matches a literal `$`; end-of-string merchant terminator never fires | `sms_parser_service.dart:470` | Merchant over-capture |
| 6 | `SmsIntakeService.catchUp()` unawaited in `main()`; one bad SMS aborts the batch; failures swallowed | `main.dart:17`, `sms_intake_service.dart:20-27` | Silent partial import |
| 7 | `maxMessages = 1000` silently truncates history while docs promise "the ENTIRE inbox" | `read_sms_service.dart:17` | Missing transactions |
| 8 | `getNewSms()` cursor advances to `now()`, not the max processed timestamp | `read_sms_service.dart:76-77` | Lost-update (dead path) |
| 9 | `TransactionCubit` never cancels its stream subscriptions | `transaction_cubit.dart:14` | Leak + emit-after-close |
| 10 | `double.parse` on raw form input; validator only checks non-empty | `add_transaction_screen.dart:84` | UI crash on bad input |
| 11 | `capitalize` (`s[0]...`) throws on empty string | 6 call sites | UI crash |

---

## Part 3 — Grades by layer

| Layer | Grade | One-line reason |
|-------|-------|-----------------|
| Composition root / DI | D+ | No DI; static singletons; repository drilled through widgets |
| Domain entity & models | D | Entity is a Hive object; three overlapping aggregates |
| Data layer | D | Two duplicate persistence classes; ~200 dead lines |
| State management (BLoC) | C | Leaky cubit, business logic in bloc, `HierarchyNode` misplaced, inconsistent reactivity |
| Use cases | B- | `summariseTransactions` / `TransactionFilter` are genuinely good — the model to follow |
| SMS pipeline | D | Correctness bugs, hardcoded rules, god-parser, no error handling |
| UI / widgets | C- | Half use BLoCs, half hit the repo directly; god-file; dead auth screen |
| Tests | D | 4 files; 0 for BLoC/repo/widgets; fake used by nothing |

---

## Part 4 — The direction: target architecture

Strict Clean Architecture. Dependencies point inward only.

```
Frameworks & Drivers   Flutter widgets · Hive · another_telephony · SharedPreferences
        │  (implement ports, map DTOs)
Interface Adapters     BLoCs/Cubits · HiveTransactionRepository · SmsSource impl · DTOs
        │  (call use cases, depend on ports)
Use Cases              SummariseTransactions · BuildTransactionHierarchy · IngestSms ·
        │              GetMonthlyAnalytics · SaveTransaction   (depend on entities + ports)
Entities               Transaction (pure) · TransactionFilter · MonthlySummary · HierarchyNode
```

**Rules to hold the line:**
- A use case never imports Flutter, Hive, or a plugin.
- The domain `Transaction` has no `@HiveType`; a `TransactionHiveDto` in the data layer does.
- External systems are reached only through interfaces defined in the use-case layer.
- Widgets contain no business logic; they dispatch intents to cubits and render state.
- Each concept has exactly one implementation.

**Target folder shape:**

```
lib/
  entities/            transaction.dart · transaction_filter.dart · monthly_summary.dart · hierarchy_node.dart
  use_cases/           summarise_transactions.dart · build_transaction_hierarchy.dart ·
                       get_monthly_analytics.dart · ingest_sms.dart · save_transaction.dart
  ports/               transaction_repository.dart · sms_source.dart · ingest_cursor_store.dart · bank_rule_set.dart
  adapters/
    blocs/             transaction_cubit.dart · advanced_view_bloc.dart · analytics_cubit.dart · add_transaction_cubit.dart
    data/              hive_transaction_repository.dart · transaction_hive_dto.dart
    sms/               telephony_sms_source.dart · sms_parser_service.dart (split) · prefs_cursor_store.dart
  ui/
    screens/ · widgets/ · theme/ · l10n/
  main.dart            (composition root: build ports, provide via RepositoryProvider)
```

---

## Part 5 — Remediation roadmap (phased, dependency-ordered)

**Phase 0 — Delete dead weight (zero-risk, high signal).**
Remove `login_screen.dart`, `getAdvancedViews`, `AdvancedViewSummary`, and the `getNewSms`
cursor path. Then collapse `HiveService` into `HiveTransactionRepository` and delete it.

**Phase 1 — Fix the correctness bugs (Part 2).**
SMS dedup key (data loss), declined-misclassification, amount-vs-balance, the
`TransactionCubit` subscription leak, and the `double.parse` crash. Write a regression test
for each *before* fixing.

**Phase 2 — Finish the Clean Architecture migration.**
Provide the repository via `RepositoryProvider` (stop drilling). Add `AddTransactionCubit`
and `AnalyticsCubit`. Move `_groupTransactions` and all grouping rules into one
`BuildTransactionHierarchy` use case. Move `HierarchyNode` to the entities layer.

**Phase 3 — De-Hive the entity.**
Introduce a pure domain `Transaction` + `TransactionHiveDto` + mappers.

**Phase 4 — Rework SMS ingestion.**
Ports + DI, an awaitable error-reporting ingestion job, indexed/keyed idempotency, a split
parser, and externalized bank rules.

**Phase 5 — Harvest the tests.**
Now that the seams exist, write the BLoC / repository / widget tests the
`FakeTransactionRepository` was built for, and centralize currency/strings/`capitalize`.

---

## Part 6 — Testing strategy & environment

### What is set up now (this branch)
- `flutter_test` (SDK) — unit and widget tests.
- `mocktail: ^1.0.5` — mocking/faking (already a dev dependency).
- `FakeTransactionRepository` — a complete in-memory `TransactionRepository`, now
  exercised by `test/blocs/transaction_cubit_test.dart` (previously used by nothing).
- Coverage: `flutter test --coverage` emits `coverage/lcov.info` (now git-ignored).

### Commands
```bash
flutter test                       # run the whole suite
flutter test test/path/to_test.dart# run one file
flutter test --coverage            # emit coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html   # optional HTML report (needs lcov)
flutter analyze                    # static analysis
```

### Recommended structure
```
test/
  entities/   use_cases/   blocs/   data/   widgets/
  fakes/      helpers/
```
Mirror `lib/`. Use `FakeTransactionRepository` for BLoC/use-case tests; reserve a real
in-memory Hive box only for `HiveTransactionRepository`'s own contract test.

### Known blocker: `bloc_test` cannot be added yet
`bloc_test` (the standard BLoC-testing sugar) **fails dependency resolution** because
`hive_generator 2.0.1` (the latest in its line) hard-caps `analyzer <7.0.0`, which
conflicts with `bloc_test`'s modern `test` requirement. BLoCs/cubits are still fully
testable **today** with `flutter_test` + `mocktail` by subscribing to `cubit.stream` and
asserting with `emitsInOrder` (see the example test). Unblocking `bloc_test` requires
migrating off the abandoned `hive` / `hive_generator` stack (e.g. to `hive_ce` or `isar`)
— a Phase 3 dependency-modernization item, tracked here so it is a deliberate decision
rather than a surprise.

### What to test next (priority order)
1. Regression tests for every Part 2 bug (red before green).
2. `TransactionCubit` / `AdvancedViewBloc` behavior via the fake.
3. `HiveTransactionRepository` contract test against an in-memory box.
4. The `SmsParserService` bug cases (declined, amount-vs-balance, merchant casing).
5. Widget tests for the money/`capitalize` formatting once centralized.

---

## Appendix — dependency staleness

`flutter pub get` reports **42 packages have newer versions incompatible with current
constraints.** The `hive` / `hive_generator` pin is the load-bearing one: it is
effectively abandoned, blocks modern test tooling (above), and is the reason the domain
entity is welded to a persistence framework (Failure #2). Modernizing the persistence
stack is therefore not cosmetic — it unlocks Phase 3 and Phase 5 simultaneously.
