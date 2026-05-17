import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_source/data/synth.dart';
import 'package:oracle_source/data/seed.dart';
import 'package:oracle_source/models/oracle_source.dart';
import 'package:oracle_source/models/oracle_type.dart';

void main() {
  group('SeededRandom', () {
    test('is deterministic for a given seed', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      for (int i = 0; i < 100; i++) {
        expect(a.nextDouble(), b.nextDouble());
      }
    });

    test('differs across seeds', () {
      final a = SeededRandom(1);
      final b = SeededRandom(2);
      final aVals = List.generate(5, (_) => a.nextDouble());
      final bVals = List.generate(5, (_) => b.nextDouble());
      expect(aVals, isNot(equals(bVals)));
    });
  });

  group('synthesizeRows', () {
    test('produces the requested row count with all columns populated', () {
      final t = OracleTable(
        name: 'EMP',
        schemaId: 'x',
        rowCountTarget: 25,
        synthSeed: 7,
        columns: [
          OracleColumn(
            name: 'EMP_ID',
            type: OracleType.integer,
            primaryKey: true,
            nullable: false,
          ),
          OracleColumn(name: 'FIRST_NAME', type: OracleType.varchar2, length: 20),
          OracleColumn(name: 'EMAIL', type: OracleType.varchar2, length: 50),
        ],
      );
      synthesizeRows(t);
      expect(t.rows.length, 25);
      // PK column always present and unique.
      final ids = t.rows.map((r) => r['EMP_ID']).toSet();
      expect(ids.length, 25);
      // Each row has every column key.
      for (final r in t.rows) {
        expect(r.keys.toSet(), {'EMP_ID', 'FIRST_NAME', 'EMAIL'});
      }
    });

    test('is reproducible: same seed → same rows', () {
      OracleTable mk() => OracleTable(
            name: 'T',
            schemaId: 'x',
            rowCountTarget: 10,
            synthSeed: 99,
            columns: [
              OracleColumn(name: 'ID', type: OracleType.integer, primaryKey: true),
              OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 20),
            ],
          );
      final a = mk();
      final b = mk();
      synthesizeRows(a);
      synthesizeRows(b);
      expect(a.rows, b.rows);
    });
  });

  group('buildDefaultSource', () {
    test('returns a populated HR + SALES seed', () {
      final s = buildDefaultSource();
      expect(s.schemas.map((s) => s.name), containsAll(['HR', 'SALES']));
      expect(s.tables.length, greaterThanOrEqualTo(5));
      for (final t in s.tables) {
        expect(t.columns, isNotEmpty);
        expect(t.rows, isNotEmpty);
      }
    });
  });
}
