# Fynans

> A privacy-first personal finance tracker for Android that turns your bank SMS messages into organized, searchable spending data — entirely on-device.

Fynans reads the transaction alerts your bank already sends over SMS, parses out the amount, party, and account details automatically, and lets you categorize everything with tags and groups. Nothing leaves your phone: there is no account, no sign-in, and no server. All data lives in a local [Hive](https://docs.hivedb.dev/) database.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [How It Works](#how-it-works)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
  - [Layered Overview](#layered-overview)
  - [Application Shell](#application-shell)
  - [State Management](#state-management)
  - [Data Layer](#data-layer)
  - [SMS Pipeline](#sms-pipeline)
  - [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Common Commands](#common-commands)
- [Testing](#testing)
- [Permissions & Privacy](#permissions--privacy)
- [Docker Dev Environment](#docker-dev-environment)
- [Roadmap & Known Gaps](#roadmap--known-gaps)
- [Contributing](#contributing)

---

## Features

- **Automatic SMS parsing** — Recognizes transaction alerts from major Indian banks (ICICI, HDFC, SBI, Kotak, Bank of Baroda, Central Bank, Airtel Payments Bank, and more) and extracts amount, transaction type (debit/credit/declined), party/merchant, account number, and available balance.
- **Manual entry & editing** — Add or adjust transactions by hand, with autocomplete for party and group fields sourced from your existing data.
- **Tags & groups** — Categorize each transaction with multiple tags and groups. A curated [`TagHelper`](lib/utils/tag_helper.dart) maps common categories (food, transport, bills, groceries…) to icons and colors.
- **Monthly navigation** — Swipe horizontally through months across a five-year window.
- **Simple and Advanced views** — Toggle between a flat chronological list and a hierarchical tree that groups transactions by group → tag → party → month in any order you choose.
- **Filtering** — Narrow the view by group, tag, or party.
- **Analytics** — Per-month bar chart of daily spending plus a pie chart of spending by tag, powered by [`fl_chart`](https://pub.dev/packages/fl_chart).
- **Reactive UI** — The transaction list updates automatically whenever the underlying Hive box changes, via Dart streams.
- **Fully offline & local** — No authentication, no network calls for your data, no cloud sync.

## Screenshots

> _Add screenshots or screen recordings here (e.g. `docs/screenshots/`)._

| Expenses | Advanced View | Analytics |
| --- | --- | --- |
| _coming soon_ | _coming soon_ | _coming soon_ |

---

## How It Works

1. Your bank sends a transaction alert SMS (e.g. _"Rs. 450.00 debited from a/c XX1234 to SWIGGY…"_).
2. Fynans reads recent inbox messages (with your permission), filters them by a whitelist of known bank sender IDs, and rejects non-transactional noise (OTPs, offers, promos).
3. A stateless regex-based parser extracts the structured details into a `ParsedTransactionDetails` object.
4. Transactions are stored locally in Hive, where you can tag, group, and analyze them.

> **Note:** The end-to-end auto-import path (parse → persist directly into the Expenses list) is currently staged through the **Test SMS** screen, which demonstrates live parsing of inbox messages. The automatic save-to-database step is stubbed in [`main_screen.dart`](lib/main_screen.dart) (see [Roadmap & Known Gaps](#roadmap--known-gaps)).

---

## Tech Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK `>=3.4.0 <4.0.0`) |
| State management | [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) (Cubit + Bloc) |
| Local persistence | [`hive`](https://pub.dev/packages/hive) / `hive_flutter` |
| SMS access | [`flutter_sms_inbox`](https://pub.dev/packages/flutter_sms_inbox) |
| Permissions | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| Lightweight prefs | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| Charts | [`fl_chart`](https://pub.dev/packages/fl_chart) |
| Date formatting | [`intl`](https://pub.dev/packages/intl) |
| Value equality | [`equatable`](https://pub.dev/packages/equatable) |

**Target platform:** Android (the SMS-reading feature is Android-only). The repository also contains scaffolding for iOS, web, macOS, Linux, and Windows, but those targets cannot read SMS and are not supported.

---

## Architecture

### Layered Overview

```
┌───────────────────────────────────────────────────────────┐
│  UI (screens/ + widgets/)                                  │
│  TransactionsListScreen · AnalyticsScreen · TestSmsScreen  │
└───────────────┬───────────────────────────────────────────┘
                │ reads state / dispatches events
┌───────────────▼───────────────────────────────────────────┐
│  State (blocs/)                                            │
│  TransactionCubit (stream)   AdvancedViewBloc (grouping)   │
└───────────────┬───────────────────────────────────────────┘
                │ calls
┌───────────────▼───────────────────────────────────────────┐
│  Data (services/hive_service.dart)                        │
│  Single access layer over the Hive 'transactions' box      │
└───────────────┬───────────────────────────────────────────┘
                │ persists
┌───────────────▼───────────────────────────────────────────┐
│  Hive box  'transactions'  (Transaction, typeId: 0)       │
└───────────────────────────────────────────────────────────┘

   SMS ingestion (parallel path):
   ReadSmsService ──▶ SmsParserService ──▶ ParsedTransactionDetails
```

### Application Shell

- **[`lib/main.dart`](lib/main.dart)** — Initializes Hive, registers `TransactionAdapter`, opens the `'transactions'` box, and launches straight into `MainScreen`. Configures a dark Material 3 theme seeded from blue-grey. No auth gate.
- **[`lib/main_screen.dart`](lib/main_screen.dart)** — A `BottomNavigationBar` over an `IndexedStack` (state is preserved across tab switches) with three tabs:
  1. **Expenses** — `TransactionsListScreen`, wrapped in a `MultiBlocProvider` supplying `TransactionCubit` and `AdvancedViewBloc`.
  2. **Analytics** — `AnalyticsScreen`.
  3. **Test SMS** — `TestSmsScreen`, a developer/debug surface for inspecting SMS parsing.

### State Management

Built on `flutter_bloc`:

- **[`TransactionCubit`](lib/blocs/transaction/transaction_cubit.dart)** — Subscribes to `HiveService.listenToTransactionsForMonth()` for the selected month. Because it listens to a stream backed by `box.watch()`, the UI stays in sync with any database change. Emits a `MonthlySummary` plus the transaction list via `TransactionLoadSuccess`.
- **[`AdvancedViewBloc`](lib/blocs/advanced_view/advanced_view_bloc.dart)** — Owns filtering and hierarchical grouping. It fetches a flat list for the month, then recursively groups it into a tree of `HierarchyNode`s according to a configurable `List<GroupingOption>` hierarchy. Each node carries its own `MonthlySummary`, and siblings are sorted by total amount. Events:
  - `AdvancedViewDataFetched` — (re)compute the tree.
  - `AdvancedViewMonthChanged` — change the active month.
  - `AdvancedViewHierarchyChanged` — change the group-by ordering.
  - `AdvancedViewGroupFilterChanged` / `AdvancedViewTagFilterChanged` / `AdvancedViewPartyFilterChanged` — apply or clear filters.

### Data Layer

**[`HiveService`](lib/services/hive_service.dart)** is the single source of truth for transaction access. Hive has no query engine, so **all filtering, sorting, and aggregation happens in Dart** over `box.values`. Key methods:

| Method | Purpose |
| --- | --- |
| `saveTransaction` / `deleteTransaction` | Create / remove records |
| `listenToTransactionsForMonth` | Reactive stream of a month's transactions (filterable) |
| `fetchTransactionsForMonth` | One-shot `Future` variant of the above |
| `getAdvancedViews` | Grouped summaries for a `GroupingOption` |
| `getAnalyticsForMonth` | Inflow/outflow totals, daily spending, spending by tag |
| `getAllGroups` / `getAllUniqueTags` / `getAllParties` | Distinct values for autocomplete |
| `getLatestTransaction` | Most recent record |
| `clearDatabase` | Wipe the box |

Month boundaries are computed by a private `_getMonthBounds` helper that returns the first and last microsecond of the month.

### SMS Pipeline

Three collaborating pieces under [`lib/services/`](lib/services/):

- **[`ReadSmsService`](lib/services/read_sms_service.dart)** — Requests the `READ_SMS` permission, queries the last 200 inbox messages (the package returns them newest-first), and filters to messages newer than a `last_read_timestamp` persisted in `SharedPreferences` (falling back to the last 7 days on first run).
- **[`SmsParserService`](lib/services/sms_parser_service.dart)** — A stateless parser that:
  1. **Filters** — rejects messages containing exclusion keywords (`otp`, `offer`, `cashback`…), requires the sender to match a whitelist of bank IDs, and requires at least one transactional keyword.
  2. **Classifies** — maps the body to a `TransactionType` (`debit`, `credit`, `declined`, `unknown`) via keyword lists.
  3. **Extracts** — pulls `amount` (with `lakh`/`crore` unit scaling), `balance`, `accountNumber`, and `merchant` using a layered set of regular expressions. Merchant extraction prioritizes UPI IDs, then keyword-anchored capture with terminators, with validation to avoid mistaking amounts or dates for a party name.
- **[`ParsedTransactionDetails`](lib/services/parsed_transaction.dart)** — Immutable, `Equatable` value object holding the structured parse result.

> Extending bank coverage usually means adding a sender ID to `_whiteListedSenders` and, if needed, new keywords/patterns in `SmsParserService`.

### Data Model

Defined in [`lib/models/`](lib/models/):

- **[`Transaction`](lib/models/transaction.dart)** — `@HiveType(typeId: 0)`. Fields: `amount` (double), `date` (DateTime), `tags` (List), `group` (List), `party` (String), `isCredit` (bool), `note` (String?). The generated adapter lives in `transaction.g.dart`.
  > ⚠️ **Do not change `typeId` or renumber `@HiveField`s without writing a migration** — existing on-device data is keyed by these.
- **[`GroupingOption`](lib/models/grouping_option.dart)** — Enum (`group`, `tag`, `party`, `month`) where each value implements `getValues(Transaction)` to drive hierarchical grouping.
- **`MonthlySummary`** — Aggregate of income, spend, top tags, and top groups for a set of transactions.
- **`MonthlyAnalytics`** — Total inflow/outflow, daily spending map, and spending-by-tag map for the analytics screen.
- **`AdvancedViewSummary`** / **`HierarchyNode`** — Grouped/tree summaries for the advanced view.

---

## Project Structure

```
lib/
├── main.dart                       # Entry point: Hive init + MaterialApp
├── main_screen.dart                # Bottom-nav shell (IndexedStack)
├── blocs/
│   ├── transaction/                # TransactionCubit + states (monthly stream)
│   └── advanced_view/              # AdvancedViewBloc + events/states (grouping)
├── models/
│   ├── transaction.dart            # Hive model (typeId 0)
│   ├── transaction.g.dart          # Generated Hive adapter
│   ├── grouping_option.dart        # Group-by enum
│   ├── monthly_summary.dart        # Aggregate
│   ├── monthly_analytics.dart      # Analytics aggregate
│   └── advanced_view_summary.dart  # Grouped summary
├── screens/
│   ├── transactions_list_screen.dart  # Expenses tab (Simple/Advanced)
│   ├── add_transaction_screen.dart    # Manual add/edit form
│   ├── analytics_screen.dart          # Charts
│   └── test_sms_screen.dart           # Dev: live SMS parse inspector
├── services/
│   ├── hive_service.dart           # Data access layer
│   ├── read_sms_service.dart       # Inbox reader + permission
│   ├── sms_parser_service.dart     # Whitelist + regex parser
│   └── parsed_transaction.dart     # Parse result value object
├── utils/
│   └── tag_helper.dart             # Tag → icon/color registry
└── widgets/                        # Reusable UI (list items, month picker, etc.)
```

---

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.4.0`). The project is verified against Flutter 3.32.x; newer stable releases also work.
- An Android device or emulator (a physical device with real bank SMS gives the best results, since emulators have no SMS history).

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. (If you edited any @HiveType model) regenerate adapters
dart run build_runner build --delete-conflicting-outputs

# 3. Run on a connected Android device
flutter run -d android
```

On first launch the app will request the **SMS read** permission. Grant it to enable parsing; deny it and you can still use Fynans for fully manual tracking.

---

## Common Commands

```bash
flutter pub get                                              # Install dependencies
flutter run -d android                                       # Run on Android
flutter run                                                  # Run on default device
flutter analyze                                              # Lint / static analysis
flutter test                                                 # Run all tests
flutter test test/widget_test.dart                           # Run a single test file
dart run build_runner build --delete-conflicting-outputs     # Regenerate Hive adapters
```

> After editing any `@HiveType` / `@HiveField` annotation, you **must** rerun `build_runner` to regenerate `transaction.g.dart`.

---

## Testing

Tests live in [`test/`](test/) and run with `flutter test`. The current `widget_test.dart` is the default Flutter scaffold and is a good first target to replace with meaningful coverage — high-value candidates include `SmsParserService` (pure, deterministic, easy to unit test) and `HiveService` aggregation logic.

---

## Permissions & Privacy

Fynans is designed to be **local-first and private**:

- The only sensitive permission requested is `READ_SMS` (declared in `android/app/src/main/AndroidManifest.xml`), used solely to read bank transaction alerts.
- Message contents are parsed on-device and never transmitted anywhere.
- There is no authentication, account system, analytics SDK, or backend for your financial data — it is stored exclusively in the on-device Hive box.

> Because Fynans reads SMS, distribution via the Google Play Store requires complying with Google's [SMS/Call Log permissions policy](https://support.google.com/googleplay/android-developer/answer/10208820). Sideloading or self-distribution avoids that review.

---

## Docker Dev Environment

The repository ships a [`Dockerfile`](Dockerfile) that provisions a complete headless Flutter + Android toolchain (Ubuntu Focal, Flutter 3.32.7 stable, Android SDK platform 34, build-tools 33.0.0, OpenJDK 17). It is suited for CI builds and reproducible environments:

```bash
docker build -t fynans-dev .
docker run --rm -it -v "$PWD":/app -w /app fynans-dev bash
# inside the container:
flutter pub get && flutter analyze
```

Building a signed APK still requires the usual Android signing setup.

---

## Roadmap & Known Gaps

These are intentionally surfaced so contributors know where the rough edges are:

- **Auto-import is stubbed.** The wiring that would automatically parse new SMS and persist them into the Expenses list is commented out in [`main_screen.dart`](lib/main_screen.dart); the **Test SMS** tab currently serves as the live parsing demonstration. Connecting `ReadSmsService` → `SmsParserService` → `HiveService.saveTransaction` is the most impactful next step.
- **`ReadSmsService` calls `prefs.clear()`** before reading the last-read timestamp, which resets the incremental-read bookmark on every run. This should be removed so only genuinely new messages are processed.
- **Settings & About screens** are placeholders in the app drawer (`TODO`).
- **Vestigial `login_screen.dart`.** Authentication was removed; the file remains but is not part of the active navigation flow and can be deleted.
- **Bank coverage is India-centric** and whitelist-driven. Broadening it means extending `SmsParserService`'s sender list and patterns.
- **Test coverage is minimal** — the default scaffold test should be replaced with real unit tests.

---

## Contributing

1. Create a feature branch.
2. Run `flutter analyze` and `flutter test` before opening a PR.
3. If you touch a Hive model, regenerate adapters and never change an existing `typeId` without a migration.
4. Keep new bank-specific parsing rules in `SmsParserService` and new tag definitions in `TagHelper`.

---

_Fynans — your money, on your device, parsed for you._
