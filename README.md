# Oracle Source

A cross-platform Flutter app (web, Android, iOS) for designing and synthesizing a **fake Oracle database**. Add schemas, tables and columns; tweak Oracle types and constraints; generate deterministic synthetic rows; and export DDL + `INSERT` statements ready to run against a real Oracle instance.

The data-synthesis approach (deterministic seeded random, entity + column + row generation) is borrowed from the [`ConnectorExpenses`](https://github.com/benhorris1988/ConnectorExpenses) operator console and re-implemented in Dart for portable, offline-first use.

## What you can do

- Configure source metadata (host, port, service name).
- Add / rename / delete schemas (`HR`, `SALES`, etc.).
- Add tables with Oracle types: `NUMBER`, `VARCHAR2`, `CHAR`, `CLOB`, `DATE`, `TIMESTAMP`, `RAW`, `BLOB`, plus a `BOOLEAN` shortcut for `NUMBER(1,0)`.
- Edit columns: length / precision / scale, nullable, primary key, unique, default, and a **synth hint** that steers fake-data generation (`first_name`, `email`, `country`, `salary`, …).
- Regenerate rows deterministically (same seed → same data).
- Edit individual cells, add or delete rows manually.
- Copy generated SQL to clipboard (per table or whole source).
- State persists locally via `shared_preferences` on every platform.

The first launch is seeded with classic Oracle-style content: `HR.EMPLOYEES`, `HR.DEPARTMENTS`, `HR.JOBS`, `SALES.CUSTOMERS`, `SALES.ORDERS`.

## Bootstrapping (one-time)

This repo intentionally ships only the Dart sources + `web/`. Native platform folders (`android/`, `ios/`, …) are excluded from version control so they always match your local Flutter SDK. Generate them once:

```bash
# from the project root, with Flutter 3.22+ installed
flutter create . --org com.oraclesource --platforms=web,android,ios
flutter pub get
```

That will fill in `android/`, `ios/`, and refresh `web/` without overwriting the custom `index.html` / `manifest.json` in this repo.

## Running

```bash
# web
flutter run -d chrome

# Android (device or emulator attached)
flutter run -d android

# iOS (Mac with Xcode + simulator/device)
flutter run -d ios

# release builds
flutter build web
flutter build apk --release
flutter build ios --release
```

## Project layout

```
lib/
  main.dart                       app entry, loads the store
  app.dart                        MaterialApp + a lightweight InheritedWidget store scope
  models/
    oracle_source.dart            OracleSource / Schema / Table / Column data classes + JSON
    oracle_type.dart              Oracle type enum + SQL rendering
  data/
    synth.dart                    Mulberry32-seeded fake-data generator
    seed.dart                     Default HR + SALES schema
    persistence.dart              shared_preferences JSON store
    export.dart                   DDL + INSERT generator
  state/
    source_store.dart             ChangeNotifier-backed mutable store
  pages/
    home_page.dart                schemas list
    schema_page.dart              tables in a schema
    table_page.dart               Columns + Data tabs
    column_editor.dart            add / edit a column
    add_schema_dialog.dart
    add_table_dialog.dart
    source_settings_page.dart     connection metadata, export, reset
web/
  index.html, manifest.json       PWA shell (preserved across `flutter create`)
```

## Synth hints

When a column is generated, the synthesizer picks values based on the **synth hint** (or infers one from the column name). Available hints:

| Hint | Sample values |
|------|---------------|
| `first_name` / `last_name` / `full_name` | `Mary`, `Patel`, `Mary Patel` |
| `email` | `mary.patel@example.com` |
| `phone` | `+44-555-1234` |
| `city` / `country` | `London`, `GB` |
| `department` / `job_title` | `Engineering`, `Senior Engineer` |
| `currency` / `status` | `USD`, `ACTIVE` |
| `salary` / `amount` | rounded numerics |
| `sequence` | 1, 2, 3, … (row index) |
| `boolean` / `flag` | 0 / 1 |
| _(auto)_ | inferred from column name + Oracle type |

Names like `FIRST_NAME`, `EMAIL`, `COUNTRY`, `SALARY`, `*_ID` are auto-detected.

## Data-quality rules

Each table has a **Rules** tab. Rules are declarative and run by the bundled validator (`lib/data/validate.dart`):

| Kind | What it checks |
|------|----------------|
| `notNull` | value is non-null and non-empty |
| `regex` | value matches a regular expression |
| `inSet` | value is one of an allowed list (ISO codes, statuses, …) |
| `positive` | numeric value is strictly > 0 |
| `range` | numeric value lies within `[min, max]` |
| `datesOrdered` | date in `column` ≤ date in `secondColumn` |
| `foreignKey` | value exists in another table's column |

The default seed includes Oracle-native rules against HR + SALES:

| Code | Table | Check |
|------|-------|-------|
| `R-DEP-001` | `HR.DEPARTMENTS` | `DEPARTMENT_NAME` not null |
| `R-DEP-002` | `HR.DEPARTMENTS` | `COUNTRY_CODE` is a known ISO code |
| `R-JOB-002` | `HR.JOBS` | `MIN_SALARY` is positive |
| `R-EMP-003` | `HR.EMPLOYEES` | `EMAIL` matches `name@host.tld` |
| `R-EMP-004` | `HR.EMPLOYEES` | `SALARY` is positive |
| `R-EMP-005` | `HR.EMPLOYEES` | `DEPARTMENT_ID` foreign-key into `DEPARTMENTS` |
| `R-CUS-002` | `SALES.CUSTOMERS` | `COUNTRY_CODE` is a known ISO code |
| `R-ORD-001` | `SALES.ORDERS` | `CUSTOMER_ID` foreign-key into `CUSTOMERS` |
| `R-ORD-002` | `SALES.ORDERS` | `AMOUNT` is positive |
| `R-ORD-003` | `SALES.ORDERS` | `CURRENCY` is a known ISO 4217 code |

Tap the **Validate** icon on a table to surface row-level violations.
