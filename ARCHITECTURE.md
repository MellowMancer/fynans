# ARCHITECTURE.md — Fynans remediation contract (F0)

This is the contract every Developer reads before touching a feature in this run.
It fixes the cross-cutting decisions so that F1–F14 add up to **one** coherent
Clean-Architecture app instead of fourteen inconsistent slices.

**Scope of this contract: Phases 0–2 (F0–F14).** Phases 3–5 (F15–F20) are
DEFERRED; they are described only under "Future direction (deferred)" so the
in-scope work does not paint them into a corner. Do **not** build them here.

Ground rules inherited from `GOAL.md` (do not relitigate):
- Test tooling is `flutter_test` (SDK) + `mocktail`. **`bloc_test` is unavailable.**
  Assert cubits/blocs via `cubit.stream` + `emitsInOrder` (see the reuse registry).
- `AdvancedViewBloc` becomes **reactive/stream-based** in F12.
- Canonical grouping labels: empty bucket = `"Uncategorized"`; month =
  `DateFormat.yMMMM()` (e.g. "July 2026"). Applied in F12.
- No `git push` / remote / CI / co-author trailers.
- Every feature is a vertical slice: `flutter analyze` clean and `flutter test`
  green at the end of the feature.

---

## 1. Layering (Clean Architecture)

Dependencies point **inward only**. Outer may import inner; inner must never
import outer. The one inviolable rule: **a use case never imports Flutter, Hive,
`another_telephony`, or `SharedPreferences`.**

| Layer | Contains | May depend on |
|-------|----------|---------------|
| **Entities** | Core domain objects + value objects: `Transaction`, `TransactionFilter`, `MonthlySummary`, `MonthlyAnalytics`, `GroupingOption`, `HierarchyNode` | Nothing external (pure Dart + `intl` for formatting only) |
| **Use Cases** | Application logic + the **ports** (abstract interfaces) they call: `summariseTransactions`, `BuildTransactionHierarchy`, `GetMonthlyAnalytics`, `SaveTransaction`, and the `TransactionRepository` port | Entities only |
| **Interface Adapters** | Cubits/BLoCs, the repository **implementation**, DTOs | Use Cases + Entities + ports |
| **Frameworks & Drivers** | Screens, widgets, `main.dart` composition root, Hive/telephony/prefs SDKs | All inner layers |

### This repo's folders → layers

We **keep the existing folder taxonomy** (matching the repo, per the simplicity
rule) and assign each folder a layer meaning. We do **not** do the aspirational
`entities/ ports/ adapters/ ui/` rename from review Part 4 — no F1–F14 criterion
requires it, and it would be pure churn. The layer boundary is enforced by
**import discipline**, documented per folder below.

| Folder | Layer | Import rule |
|--------|-------|-------------|
| `lib/models/` | Entities | No `package:flutter/*`, no Hive-flutter, no bloc. (`intl` OK.) See the Hive exception below. |
| `lib/use_cases/` | Use Cases | Imports `lib/models/` + `lib/repositories/` only. **Never** Flutter/Hive/plugins. |
| `lib/repositories/` | Use-case-layer **ports** (interfaces) | `transaction_repository.dart` imports `lib/models/` only. It is the abstract seam; no concrete Hive here. |
| `lib/blocs/` | Interface Adapters | Cubits/BLoCs. Depend on ports + use cases + entities. May import `flutter_bloc`/`bloc`. **No** direct Hive box access; go through the port. No business rules — delegate to use cases. |
| `lib/services/` | Interface Adapters (impls) + Frameworks | `hive_transaction_repository.dart` (the port impl) + SMS pipeline classes. This is where Hive/telephony/prefs are allowed. |
| `lib/screens/`, `lib/widgets/` | Frameworks & Drivers | UI only. **No business logic** (no amount parsing, CSV splits, grouping, percentage math). Dispatch intents to cubits; render state. Read the repository from `context`, never as a constructor param. |
| `lib/utils/` | Shared helpers (cross-layer, pure) | `capitalize`, currency formatting, `TagHelper`. Pure Dart / Flutter-asset helpers only. |
| `lib/main.dart` | Composition root | Builds the one repository, provides it via `RepositoryProvider`, wires cubits. |

**Documented Hive exception (in-scope):** `lib/models/transaction.dart` still
carries `@HiveType`/`@HiveField` and `extends HiveObject` during F0–F14. De-Hiving
it (pure `Transaction` + `TransactionHiveDto`) is **F15 — DEFERRED**. Until then,
`Transaction` is treated as the entity and the cubits/use cases mediate access to
it so F15 can slot a DTO underneath without touching them. Do not add new Hive
annotations to any *other* model.

---

## 2. Target folder shape after F14

```
lib/
  models/                         # Entities
    transaction.dart              # (Hive-annotated until deferred F15)
    transaction.g.dart            # generated adapter — regenerate via build_runner
    transaction_filter.dart       # value object (reuse — do not clone)
    monthly_summary.dart
    monthly_analytics.dart
    grouping_option.dart          # F12: reduced to a pure (name, displayName) enum
    hierarchy_node.dart           # F11: MOVED here from advanced_view_bloc.dart
  use_cases/                      # Use Cases (no Flutter/Hive imports)
    summarise_transactions.dart   # EXISTS — the model to follow
    build_transaction_hierarchy.dart   # F12: owns ALL grouping/bucketing rules
    get_monthly_analytics.dart         # F13: inflow/outflow/daily/by-tag + top-5+Others
    save_transaction.dart              # F14: entity construction + validation
  repositories/                   # Use-case-layer ports
    transaction_repository.dart   # the single port (F3 adds dedup + save methods)
  blocs/                          # Interface Adapters (cubits/blocs)
    transaction/                  # TransactionCubit (F7: hold+cancel subscription)
    advanced_view/                # AdvancedViewBloc (F12: reactive + delegates to use case)
    analytics/                    # F13: AnalyticsCubit  (+ analytics_state.dart)
    add_transaction/              # F14: AddTransactionCubit (+ add_transaction_state.dart)
  services/                       # Interface Adapters (impls) + Frameworks
    hive_transaction_repository.dart   # the ONLY data adapter (F3 folds HiveService in)
    sms_parser_service.dart            # (bug fixes F5/F6/F9; full split is deferred F18)
    transaction_sms_ingestor.dart      # F3: point at the port, not HiveService
    read_sms_service.dart / sms_intake_service.dart / parsed_transaction.dart / inbox_sms.dart
  screens/ , widgets/             # Frameworks & Drivers — UI only
  utils/                          # shared pure helpers (tag_helper.dart; F19 adds string/currency)
  main.dart                       # composition root: build repo + RepositoryProvider
```

### Key structural moves this run makes

- **F11 — `HierarchyNode` → `lib/models/hierarchy_node.dart`.** It is a domain
  type widgets render. Remove it from `advanced_view_state.dart` (`part of`
  `advanced_view_bloc.dart`). After F11, no widget imports `advanced_view_bloc.dart`
  just to name the type.
- **F12 — one `BuildTransactionHierarchy` use case.** Move `_groupTransactions`
  (`advanced_view_bloc.dart:104-132`) and the bucketing policy out of
  `GroupingOption.getValues` into this use case. `GroupingOption` becomes a pure
  `(name, displayName)` enum (drops its `Transaction` + `intl` imports). Grouping
  logic must then exist in **exactly one place** (`rg` shows no second grouping
  switch). Apply canonical labels here.
- **F12 — `AdvancedViewBloc` reactive.** Subscribe to
  `listenToTransactionsForMonth` (stream) instead of one-shot
  `fetchTransactionsForMonth`; **hold the subscription as a field and cancel it in
  `close()`** (mirror F7). Also drop the `DateTime.now()` in the constructor
  initializer (non-deterministic).
- **F13 — `GetMonthlyAnalytics` + `AnalyticsCubit`.** Aggregation math leaves the
  repository (`hive_transaction_repository.dart:87-134`) and the widget
  (`analytics_screen.dart:245-268`) and lands in the use case. `AnalyticsScreen`
  ends up holding **no** aggregation math.
- **F14 — `AddTransactionCubit` + `SaveTransaction`.** Amount parsing, CSV group
  split, entity construction, and validation leave
  `add_transaction_screen.dart:74-120`. The widget contains no `double.parse`, no
  CSV split, no direct `saveTransaction`.
- **F10 — provide the repository once.** Build the single `HiveTransactionRepository`
  in the composition root and expose it via `RepositoryProvider<TransactionRepository>`.
  Widgets read `context.read<TransactionRepository>()`. After F10,
  `rg "repository:" lib/` shows no widget constructor still taking a repository
  parameter (removes the `AddTransactionScreen → SummaryCard → SimpleTransactionListView`
  and `AnalyticsScreen` drilling).

---

## 3. Data models (entities) — defined once

Defined once in `lib/models/`. Do not re-define near-copies beside a feature.

- **`Transaction`** (`@HiveType(typeId: 0)`) — core record: `amount` (always
  positive), `date`, `tags: List<String>`, `group: List<String>`, `party`,
  `isCredit`, `note`. Sign convention: `isCredit` bool + positive `amount`.
  **Do not change `typeId`** without a migration. Regenerate `transaction.g.dart`
  with `dart run build_runner build --delete-conflicting-outputs` after any
  `@HiveField` change.
- **`TransactionFilter`** — value object; `matches(Transaction)`, `isEmpty`,
  `copyWith`. Reuse for all filtering; do not write ad-hoc `where` predicates that
  duplicate it.
- **`MonthlySummary`** — output of `summariseTransactions` (income/expenses/total +
  top tags/groups). Has `MonthlySummary.empty`.
- **`MonthlyAnalytics`** — inflow/outflow/daily/by-tag aggregate (F13 consolidates
  the analytics output; do not add a third aggregate model).
- **`GroupingOption`** — enum; after F12 a pure `(name, displayName)` with **no**
  `Transaction`/`intl` imports and no embedded policy.
- **`HierarchyNode`** — recursive grouping node (name, summary, count, children,
  leaf transactions). Lives in `lib/models/` after F11.

Relationships: a `Transaction` list is folded by `summariseTransactions` →
`MonthlySummary`, by `GetMonthlyAnalytics` → `MonthlyAnalytics`, and by
`BuildTransactionHierarchy` (using `GroupingOption` + `TransactionFilter`) →
`List<HierarchyNode>`.

---

## 4. Reuse registry (anti-duplication contract)

Developers **MUST reuse/extend** these. A new feature extends the registry; it does
not clone a near-copy beside it.

### Already exists — reuse as-is

| Component | Path | Use it for |
|-----------|------|-----------|
| `TransactionRepository` (port) | `lib/repositories/transaction_repository.dart` | The **only** persistence seam. F3 extends it (adds `saveTransaction`/dedup lookup); all reads/writes go through it. Never `new HiveService()`. |
| `HiveTransactionRepository` (impl) | `lib/services/hive_transaction_repository.dart` | The **only** data adapter. F3 folds `HiveService` into it and deletes `HiveService`. |
| `TransactionFilter` | `lib/models/transaction_filter.dart` | All month/group/tag/party filtering. |
| `summariseTransactions` | `lib/use_cases/summarise_transactions.dart` | Income/expenses/top-N folding. The **template** for new use cases (pure function, entities-only imports). Reused inside `BuildTransactionHierarchy`. |
| `MonthlySummary` / `MonthlyAnalytics` | `lib/models/` | Aggregate outputs. Do not add a 3rd. |
| `GroupingOption` | `lib/models/grouping_option.dart` | Grouping dimension enum. |
| `TagHelper` | `lib/utils/tag_helper.dart` | Predefined tag → icon/color map. Add new tags **here**, nowhere else. (F19 removes the `pokemon` joke entry — leave it until then.) |
| `ParsedTransactionDetails` / `TransactionType` | `lib/services/parsed_transaction.dart` | SMS parse output + declined/debit/credit/unknown enum. |

### Test infrastructure — reuse as-is

| Component | Path | Use it for |
|-----------|------|-----------|
| `FakeTransactionRepository` | `test/fakes/fake_transaction_repository.dart` | In-memory `TransactionRepository` for **all** BLoC/use-case tests. Do not mock the port ad-hoc when this exists; extend it if a new port method (F3) needs faking. |
| **cubit.stream + emitsInOrder pattern** | `test/blocs/transaction_cubit_test.dart` | The canonical way to assert cubit/bloc emissions (since `bloc_test` is unavailable). Copy this shape for `AnalyticsCubit`, `AddTransactionCubit`, and the reactive `AdvancedViewBloc`. Includes the `_txn(...)` builder helper worth mirroring. |

### Canonical helpers to be created (single home: `lib/utils/`)

To stop the known duplication (review Finding #6 / Bug #11), there is **one** home
and **one** definition for each. In-scope features (F1–F14) that need one of these
MUST create/extend the single canonical helper — never add a 7th private copy.
Their formal centralization + back-fill of existing call sites is **F19 (DEFERRED)**.

- `capitalize(String)` → `lib/utils/` — must be **safe on `''`** (return `''`, no
  throw). `rg "String capitalize"` must eventually show exactly one definition.
- money/currency formatter (the `₹` + `toStringAsFixed` pattern, duplicated 5×+) →
  `lib/utils/` — one helper used by all widgets.

---

## 5. Test strategy (decided once)

- **Framework:** `flutter_test` (SDK) + `mocktail` (`^1.0.5`). **`bloc_test` is not
  available** (blocked by the pinned `hive_generator`/`analyzer <7` stack). Assert
  cubits/blocs by subscribing to `cubit.stream` and matching with `emitsInOrder`,
  per `test/blocs/transaction_cubit_test.dart`.
- **Layout:** `test/` **mirrors** `lib/`. Existing dirs: `test/blocs/`,
  `test/use_cases/`, `test/models/`, `test/services/`, plus `test/fakes/`. A new
  use case gets `test/use_cases/<name>_test.dart`; a new cubit gets
  `test/blocs/<feature>/<name>_test.dart`.
- **Naming:** `<subject>_test.dart` mirroring the `lib/` file under test.
- **Whole-suite command (the Tester runs this):** `flutter test`.
  Single file: `flutter test test/path/to_test.dart`.
  Coverage: `flutter test --coverage` (emits `coverage/lcov.info`).
  Static analysis: `flutter analyze`.
- **Fakes over real Hive:** use `FakeTransactionRepository` for all BLoC/use-case
  tests — **no** real Hive box in those. A real in-memory Hive box is reserved for
  `HiveTransactionRepository`'s own contract test (that harvest is **F20 —
  DEFERRED**; do not open Hive boxes in BLoC/use-case tests here).
- **"unit" vs "integration" for this app:** *unit* = a single use case, cubit,
  entity, or the parser, driven by a fake — no Flutter binding, no plugins, no Hive.
  *integration* = the repository impl against a real in-memory Hive box, or a widget
  pumped with `testWidgets` reading from `RepositoryProvider`. Only unit-level tests
  are in scope for F1–F14 (widget/contract harvest is deferred F20).
- **RED-before-GREEN (mandatory for Phase 1 bug features F4–F9):** write the failing
  regression test **first**, watch it fail for the documented reason, then make the
  minimal fix that turns it green. Each Phase-1 criterion names the exact assertion.

---

## 6. Feature isolation rules

- **Vertical slices, no sibling coupling.** A feature depends only on shared **inner**
  layers (entities, use cases, ports) and the shared registry above — never on
  another feature's cubit/screen/private helpers. Features compose through the shared
  layers (the port, the use cases, `RepositoryProvider`), not by reaching sideways.
- **Green gate per feature.** Every feature ends with `flutter analyze` clean and
  `flutter test` green. A slice that leaves either red is not done.
- **One home per concept.** If you need behavior that already exists in the registry,
  extend it there. Grouping logic, aggregation math, amount parsing, `capitalize`,
  and money formatting each have exactly one home (see §2, §4).
- **Shared reactive-subscription pattern (F7 and F12).** Both `TransactionCubit`
  (F7) and `AdvancedViewBloc` (F12) subscribe to a repository stream. The shared
  contract: **hold the `StreamSubscription` as a field, cancel any prior subscription
  before opening a new one (on re-fetch/month-swipe), and cancel it in `close()`.**
  Never call `emit` after `close()`. Use `emit.onEach`/guarded emits so async stream
  errors surface as a failure state instead of an uncaught async error.
- **Composition root is the only place that `new`s infrastructure.** `main.dart`
  builds `HiveTransactionRepository` and provides it via `RepositoryProvider`. No
  widget or cubit constructs a repository or opens a Hive box directly.

---

## 7. Future direction (DEFERRED — documented, NOT built here)

These are described so F1–F14 leave room for them. Do not skeleton them as build
targets in this run.

- **De-Hive the entity (F15).** Introduce a framework-free immutable `Transaction`
  (const constructor, validated, no `@HiveType`) as the entity in `lib/models/`, and
  move the annotations onto a new **`TransactionHiveDto`** in the data layer
  (`lib/services/`) that preserves `typeId: 0`, with `toDomain()`/`fromDomain()`
  mappers. Because F12/F13/F14 route all entity access through use cases and cubits,
  F15 can slot the DTO underneath the port without touching the presentation layer.
  Keep entity construction out of widgets/ingestor (already achieved by F14/F3) so
  the mapper is the single construction seam.
- **SMS ports + rework (F16–F18).** Define `SmsSource`, `IngestCursorStore`, and
  `BankRuleSet` ports in the use-case layer (reserve `lib/ports/`), split
  `ReadSmsService` (it fuses `Telephony.instance` + `SharedPreferences`), inject
  collaborators into `TransactionSmsIngestor` via constructor (F3 already points it
  at the `TransactionRepository` port, so the persistence half is ready), remove the
  all-static `SmsIntakeService` singleton, make ingest an awaitable error-reporting
  job with an O(1) raw-SMS idempotency key, and split the ~500-line parser with
  asset-loaded bank rules. F1–F14 must not entrench the static singleton or the
  parsed-field dedup as public API.

---

## 8. Skeleton created in F0

- `ARCHITECTURE.md` (this file).
- Reserved directories for the two new cubits F13/F14 introduce, each anchored with
  a `.gitkeep` (non-code, keeps analyze/test green — F0 makes no code change):
  - `lib/blocs/analytics/`
  - `lib/blocs/add_transaction/`

All other target locations already exist. No `.dart` stubs are created: F0 is a
no-code-change gate, and empty stubs would be speculative. Developers create their
layer files at the paths in §2.
