import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Kinds of declarative data-quality checks the validator knows how to run.
enum DQKind {
  notNull,       // column has a non-null, non-empty value
  regex,         // value matches a regular expression
  inSet,         // value is one of a fixed list (codes, lookups)
  positive,      // numeric value is strictly > 0
  range,         // numeric value is within [min, max]
  datesOrdered,  // date in `column` <= date in `secondColumn`
  foreignKey,    // value exists in another table's column
}

enum DQSeverity { info, warning, error, critical }

extension DQKindX on DQKind {
  String get label {
    switch (this) {
      case DQKind.notNull: return 'NOT NULL';
      case DQKind.regex: return 'REGEX';
      case DQKind.inSet: return 'IN SET';
      case DQKind.positive: return 'POSITIVE';
      case DQKind.range: return 'RANGE';
      case DQKind.datesOrdered: return 'DATES ORDERED';
      case DQKind.foreignKey: return 'FOREIGN KEY';
    }
  }
}

extension DQSeverityX on DQSeverity {
  String get label {
    switch (this) {
      case DQSeverity.info: return 'INFO';
      case DQSeverity.warning: return 'WARNING';
      case DQSeverity.error: return 'ERROR';
      case DQSeverity.critical: return 'CRITICAL';
    }
  }
}

DQKind dqKindFromString(String s) =>
    DQKind.values.firstWhere((k) => k.name == s, orElse: () => DQKind.notNull);

DQSeverity dqSeverityFromString(String s) => DQSeverity.values
    .firstWhere((k) => k.name == s, orElse: () => DQSeverity.error);

class DQRule {
  DQRule({
    String? id,
    required this.code,
    required this.tableId,
    required this.kind,
    required this.columnName,
    this.severity = DQSeverity.error,
    this.message = '',
    this.secondColumn,
    this.refTableName,
    this.refColumnName,
    List<String>? values,
    this.pattern,
    this.min,
    this.max,
  })  : id = id ?? _uuid.v4(),
        values = values ?? [];

  final String id;
  String code;        // e.g. V-CUST-001
  String tableId;
  DQKind kind;
  String columnName;
  DQSeverity severity;
  String message;

  String? secondColumn;
  String? refTableName;
  String? refColumnName;
  List<String> values;
  String? pattern;
  double? min;
  double? max;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'tableId': tableId,
        'kind': kind.name,
        'columnName': columnName,
        'severity': severity.name,
        'message': message,
        'secondColumn': secondColumn,
        'refTableName': refTableName,
        'refColumnName': refColumnName,
        'values': values,
        'pattern': pattern,
        'min': min,
        'max': max,
      };

  factory DQRule.fromJson(Map<String, dynamic> j) => DQRule(
        id: j['id'] as String?,
        code: j['code'] as String,
        tableId: j['tableId'] as String,
        kind: dqKindFromString(j['kind'] as String),
        columnName: j['columnName'] as String,
        severity: dqSeverityFromString(j['severity'] as String? ?? 'error'),
        message: j['message'] as String? ?? '',
        secondColumn: j['secondColumn'] as String?,
        refTableName: j['refTableName'] as String?,
        refColumnName: j['refColumnName'] as String?,
        values: (j['values'] as List<dynamic>? ?? [])
            .map((v) => v.toString())
            .toList(),
        pattern: j['pattern'] as String?,
        min: (j['min'] as num?)?.toDouble(),
        max: (j['max'] as num?)?.toDouble(),
      );
}

class DQViolation {
  DQViolation({
    required this.rule,
    required this.rowIndex,
    required this.columnName,
    required this.value,
  });

  final DQRule rule;
  final int rowIndex;
  final String columnName;
  final dynamic value;
}
