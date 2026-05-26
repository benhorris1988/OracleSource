import '../models/dq_rule.dart';
import '../models/oracle_source.dart';

/// Run every rule attached to [table] against its current rows, returning the
/// flat list of violations. Rules referencing missing columns are skipped
/// silently so renaming a column never crashes the validator.
List<DQViolation> validateTable({
  required OracleSource source,
  required OracleTable table,
  required List<DQRule> rules,
}) {
  final out = <DQViolation>[];
  for (final rule in rules) {
    if (rule.tableId != table.id) continue;
    if (table.columnByName(rule.columnName) == null) continue;
    for (int i = 0; i < table.rows.length; i++) {
      final row = table.rows[i];
      final value = row[rule.columnName];
      if (_violates(rule, value, row, source)) {
        out.add(DQViolation(
          rule: rule,
          rowIndex: i,
          columnName: rule.columnName,
          value: value,
        ));
      }
    }
  }
  return out;
}

bool _violates(DQRule rule, dynamic value, Map<String, dynamic> row, OracleSource source) {
  switch (rule.kind) {
    case DQKind.notNull:
      return value == null || value.toString().isEmpty;
    case DQKind.regex:
      if (value == null) return false;
      final pat = rule.pattern;
      if (pat == null || pat.isEmpty) return false;
      try {
        return !RegExp(pat).hasMatch(value.toString());
      } catch (_) {
        return false;
      }
    case DQKind.inSet:
      if (value == null) return false;
      return !rule.values.contains(value.toString());
    case DQKind.positive:
      final n = _asNum(value);
      if (n == null) return false;
      return n <= 0;
    case DQKind.range:
      final n = _asNum(value);
      if (n == null) return false;
      if (rule.min != null && n < rule.min!) return true;
      if (rule.max != null && n > rule.max!) return true;
      return false;
    case DQKind.datesOrdered:
      final second = rule.secondColumn;
      if (second == null) return false;
      final a = _asDate(value);
      final b = _asDate(row[second]);
      if (a == null || b == null) return false;
      return a.isAfter(b);
    case DQKind.foreignKey:
      if (value == null) return false;
      final refTableName = rule.refTableName;
      final refColumnName = rule.refColumnName;
      if (refTableName == null || refColumnName == null) return false;
      final ref = source.tables
          .where((t) => t.name.toUpperCase() == refTableName.toUpperCase())
          .firstOrNull;
      if (ref == null) return false;
      final target = value.toString();
      return !ref.rows.any((r) => r[refColumnName]?.toString() == target);
  }
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
