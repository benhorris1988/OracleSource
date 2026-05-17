import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_source/data/seed.dart';
import 'package:oracle_source/data/validate.dart';
import 'package:oracle_source/models/dq_rule.dart';
import 'package:oracle_source/models/oracle_source.dart';
import 'package:oracle_source/models/oracle_type.dart';

void main() {
  group('validator', () {
    test('notNull catches null + empty values', () {
      final t = OracleTable(
        name: 'T',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 20)
        ],
        rows: [
          {'NAME': 'Alice'},
          {'NAME': null},
          {'NAME': ''},
        ],
      );
      final rule = DQRule(
        code: 'X-001',
        tableId: t.id,
        kind: DQKind.notNull,
        columnName: 'NAME',
        message: 'name must be set',
      );
      final source = OracleSource(tables: [t], rules: [rule]);
      final v = validateTable(source: source, table: t, rules: [rule]);
      expect(v.length, 2);
      expect(v.map((x) => x.rowIndex).toSet(), {1, 2});
    });

    test('foreignKey is enforced across tables', () {
      final master = OracleTable(
        name: 'CUSTOMER',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'KUNNR', type: OracleType.varchar2, length: 10, primaryKey: true)
        ],
        rows: [
          {'KUNNR': 'C001'},
          {'KUNNR': 'C002'},
        ],
      );
      final order = OracleTable(
        name: 'SALES_ORDER',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'KUNNR', type: OracleType.varchar2, length: 10)
        ],
        rows: [
          {'KUNNR': 'C001'}, // ok
          {'KUNNR': 'C999'}, // dangling
        ],
      );
      final rule = DQRule(
        code: 'FK',
        tableId: order.id,
        kind: DQKind.foreignKey,
        columnName: 'KUNNR',
        refTableName: 'CUSTOMER',
        refColumnName: 'KUNNR',
        message: 'no such customer',
      );
      final source =
          OracleSource(tables: [master, order], rules: [rule]);
      final v = validateTable(source: source, table: order, rules: [rule]);
      expect(v.length, 1);
      expect(v.first.rowIndex, 1);
    });

    test('datesOrdered flags reversed date ranges', () {
      final t = OracleTable(
        name: 'PRICING_CONDITION',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'DATAB', type: OracleType.date),
          OracleColumn(name: 'DATBI', type: OracleType.date),
        ],
        rows: [
          {'DATAB': '2025-01-01', 'DATBI': '2025-12-31'}, // ok
          {'DATAB': '2025-12-31', 'DATBI': '2025-01-01'}, // bad
        ],
      );
      final rule = DQRule(
        code: 'X-DATES',
        tableId: t.id,
        kind: DQKind.datesOrdered,
        columnName: 'DATAB',
        secondColumn: 'DATBI',
        message: 'validity dates out of order',
      );
      final v = validateTable(
        source: OracleSource(tables: [t], rules: [rule]),
        table: t,
        rules: [rule],
      );
      expect(v.length, 1);
      expect(v.first.rowIndex, 1);
    });
  });

  group('default seed', () {
    test('SAP_MIRROR schema is present with rule bank', () {
      final s = buildDefaultSource();
      expect(s.schemas.map((x) => x.name), contains('SAP_MIRROR'));
      expect(s.rules, isNotEmpty);
      // The classic codes from the original RULE_BANK should be ported.
      final codes = s.rules.map((r) => r.code).toSet();
      expect(codes, containsAll(['V-CUST-001', 'V-PRICE-001', 'V-SO-001']));
    });
  });
}
