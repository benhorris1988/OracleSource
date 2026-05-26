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
        name: 'CUSTOMERS',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'CUSTOMER_ID', type: OracleType.integer, primaryKey: true)
        ],
        rows: [
          {'CUSTOMER_ID': 1},
          {'CUSTOMER_ID': 2},
        ],
      );
      final order = OracleTable(
        name: 'ORDERS',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'CUSTOMER_ID', type: OracleType.integer)
        ],
        rows: [
          {'CUSTOMER_ID': 1},   // ok
          {'CUSTOMER_ID': 999}, // dangling
        ],
      );
      final rule = DQRule(
        code: 'FK',
        tableId: order.id,
        kind: DQKind.foreignKey,
        columnName: 'CUSTOMER_ID',
        refTableName: 'CUSTOMERS',
        refColumnName: 'CUSTOMER_ID',
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
        name: 'CONTRACTS',
        schemaId: 'x',
        columns: [
          OracleColumn(name: 'VALID_FROM', type: OracleType.date),
          OracleColumn(name: 'VALID_TO', type: OracleType.date),
        ],
        rows: [
          {'VALID_FROM': '2025-01-01', 'VALID_TO': '2025-12-31'}, // ok
          {'VALID_FROM': '2025-12-31', 'VALID_TO': '2025-01-01'}, // bad
        ],
      );
      final rule = DQRule(
        code: 'X-DATES',
        tableId: t.id,
        kind: DQKind.datesOrdered,
        columnName: 'VALID_FROM',
        secondColumn: 'VALID_TO',
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
    test('seeds IFS-flavoured rules against IFSAPP tables', () {
      final s = buildDefaultSource();
      expect(s.schemas.map((x) => x.name), contains('IFSAPP'));
      expect(s.rules, isNotEmpty);
      final codes = s.rules.map((r) => r.code).toSet();
      expect(
        codes,
        containsAll([
          'R-SIT-002', // SITE.COMPANY FK → COMPANY_TAB
          'R-PRT-001', // INVENTORY_PART_TAB.CONTRACT FK → SITE_TAB
          'R-COH-001', // CUSTOMER_ORDER_TAB.CUSTOMER_NO FK → CUSTOMER_INFO_TAB
          'R-POH-001', // PURCHASE_ORDER_TAB.SUPPLIER_NO FK → SUPPLIER_INFO_TAB
        ]),
      );
    });
  });
}
