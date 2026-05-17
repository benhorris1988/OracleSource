import 'package:uuid/uuid.dart';

import 'oracle_type.dart';

const _uuid = Uuid();

class OracleColumn {
  OracleColumn({
    String? id,
    required this.name,
    required this.type,
    this.length,
    this.precision,
    this.scale,
    this.nullable = true,
    this.primaryKey = false,
    this.unique = false,
    this.defaultValue,
    this.synthHint,
  }) : id = id ?? _uuid.v4();

  final String id;
  String name;
  OracleType type;
  int? length;
  int? precision;
  int? scale;
  bool nullable;
  bool primaryKey;
  bool unique;
  String? defaultValue;

  /// Hint used by the data synthesizer, e.g. `first_name`, `email`, `salary`,
  /// `currency`, `country`. Null means "use type defaults".
  String? synthHint;

  String renderType() {
    if (type.takesLength && length != null) {
      return '${type.sqlName}($length)';
    }
    if (type.takesPrecisionScale && precision != null) {
      return scale != null && scale! > 0
          ? '${type.sqlName}($precision,$scale)'
          : '${type.sqlName}($precision)';
    }
    return type.sqlName;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'length': length,
        'precision': precision,
        'scale': scale,
        'nullable': nullable,
        'primaryKey': primaryKey,
        'unique': unique,
        'defaultValue': defaultValue,
        'synthHint': synthHint,
      };

  factory OracleColumn.fromJson(Map<String, dynamic> j) => OracleColumn(
        id: j['id'] as String?,
        name: j['name'] as String,
        type: oracleTypeFromString(j['type'] as String),
        length: j['length'] as int?,
        precision: j['precision'] as int?,
        scale: j['scale'] as int?,
        nullable: j['nullable'] as bool? ?? true,
        primaryKey: j['primaryKey'] as bool? ?? false,
        unique: j['unique'] as bool? ?? false,
        defaultValue: j['defaultValue'] as String?,
        synthHint: j['synthHint'] as String?,
      );
}

class OracleTable {
  OracleTable({
    String? id,
    required this.name,
    required this.schemaId,
    List<OracleColumn>? columns,
    List<Map<String, dynamic>>? rows,
    this.rowCountTarget = 50,
    this.synthSeed,
  })  : id = id ?? _uuid.v4(),
        columns = columns ?? [],
        rows = rows ?? [];

  final String id;
  String name;
  String schemaId;
  List<OracleColumn> columns;
  List<Map<String, dynamic>> rows;
  int rowCountTarget;
  int? synthSeed;

  OracleColumn? columnByName(String n) =>
      columns.where((c) => c.name.toUpperCase() == n.toUpperCase()).firstOrNull;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'schemaId': schemaId,
        'rowCountTarget': rowCountTarget,
        'synthSeed': synthSeed,
        'columns': columns.map((c) => c.toJson()).toList(),
        'rows': rows,
      };

  factory OracleTable.fromJson(Map<String, dynamic> j) => OracleTable(
        id: j['id'] as String?,
        name: j['name'] as String,
        schemaId: j['schemaId'] as String,
        rowCountTarget: j['rowCountTarget'] as int? ?? 50,
        synthSeed: j['synthSeed'] as int?,
        columns: (j['columns'] as List<dynamic>? ?? [])
            .map((c) => OracleColumn.fromJson(c as Map<String, dynamic>))
            .toList(),
        rows: (j['rows'] as List<dynamic>? ?? [])
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(),
      );
}

class OracleSchema {
  OracleSchema({
    String? id,
    required this.name,
    this.description = '',
  }) : id = id ?? _uuid.v4();

  final String id;
  String name;
  String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory OracleSchema.fromJson(Map<String, dynamic> j) => OracleSchema(
        id: j['id'] as String?,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
      );
}

class OracleSource {
  OracleSource({
    this.name = 'ORACLE_DEV',
    this.host = 'localhost',
    this.port = 1521,
    this.serviceName = 'ORCLPDB1',
    List<OracleSchema>? schemas,
    List<OracleTable>? tables,
  })  : schemas = schemas ?? [],
        tables = tables ?? [];

  String name;
  String host;
  int port;
  String serviceName;
  List<OracleSchema> schemas;
  List<OracleTable> tables;

  List<OracleTable> tablesIn(String schemaId) =>
      tables.where((t) => t.schemaId == schemaId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  OracleSchema? schemaById(String id) =>
      schemas.where((s) => s.id == id).firstOrNull;

  Map<String, dynamic> toJson() => {
        'name': name,
        'host': host,
        'port': port,
        'serviceName': serviceName,
        'schemas': schemas.map((s) => s.toJson()).toList(),
        'tables': tables.map((t) => t.toJson()).toList(),
      };

  factory OracleSource.fromJson(Map<String, dynamic> j) => OracleSource(
        name: j['name'] as String? ?? 'ORACLE_DEV',
        host: j['host'] as String? ?? 'localhost',
        port: j['port'] as int? ?? 1521,
        serviceName: j['serviceName'] as String? ?? 'ORCLPDB1',
        schemas: (j['schemas'] as List<dynamic>? ?? [])
            .map((s) => OracleSchema.fromJson(s as Map<String, dynamic>))
            .toList(),
        tables: (j['tables'] as List<dynamic>? ?? [])
            .map((t) => OracleTable.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

