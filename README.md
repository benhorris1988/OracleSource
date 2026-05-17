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

## SAP mirror schema

The default seed also includes a `SAP_MIRROR` schema that ports the canonical SAP entities from the `ConnectorExpenses` reference as Oracle tables — with native SAP column names so the synthetic source feels right at home next to a real one:

| Oracle table | SAP fields |
|--------------|------------|
| `CUSTOMER` | `KUNNR`, `NAME1`, `LAND1`, `KTOKD`, `STCEG`, `ERDAT` |
| `MATERIAL` | `MATNR`, `MAKTX`, `MATKL`, `MEINS`, `MTART` |
| `VENDOR` | `LIFNR`, `NAME1`, `LAND1`, `STCEG` |
| `SALES_ORG` | `VKORG`, `NAME`, `WAERS` |
| `SALES_ORDER` | `VBELN`, `KUNNR`, `AUDAT`, `NETWR`, `WAERK`, `VKORG` |
| `SALES_ORDER_ITEM` | `VBELN`, `POSNR`, `MATNR`, `KWMENG`, `NETWR`, `WAERK` |
| `PURCHASE_ORDER` | `EBELN`, `LIFNR`, `BEDAT`, `WAERS` |
| `DELIVERY` | `VBELN`, `LFART`, `LFDAT`, `KUNNR` |
| `PRICING_CONDITION` | `KNUMH`, `KSCHL`, `DATAB`, `DATBI`, `KBETR` |
| `INVENTORY_STOCK` | `MATNR`, `WERKS`, `LABST`, `MEINS` |
| `GL_ACCOUNT` | `SAKNR`, `TXT50`, `BUKRS` |
| `COST_CENTER` | `KOSTL`, `KTEXT`, `BUKRS` |

## Data-quality rules

Each table has a **Rules** tab. Rules are declarative and run by the bundled validator (`lib/data/validate.dart`):

| Kind | What it checks |
|------|----------------|
| `notNull` | value is non-null and non-empty |
| `regex` | value matches a regular expression |
| `inSet` | value is one of an allowed list (e.g. ISO codes, SAP UoMs) |
| `positive` | numeric value is strictly > 0 |
| `range` | numeric value lies within `[min, max]` |
| `datesOrdered` | date in `column` ≤ date in `secondColumn` |
| `foreignKey` | value exists in another table's column |

The default seed ports the original `RULE_BANK` codes (`V-CUST-001`, `V-MAT-002`, `V-SO-001`, `V-SO-002`, `V-PRICE-001`, `V-STOCK-001`, `V-VENDOR-001`, …) and pins each one to its target SAP table. Tap the **Validate** icon on a table to surface row-level violations.
