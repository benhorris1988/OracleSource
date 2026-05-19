import '../models/oracle_source.dart';
import '../models/oracle_type.dart';

/// Render an Oracle DDL + INSERT script for a single table.
String exportTableSql(OracleSource source, OracleTable table) {
  final schema = source.schemaById(table.schemaId);
  final schemaName = schema?.name ?? 'APP';
  final buf = StringBuffer()
    ..writeln('-- Schema: $schemaName')
    ..writeln('-- Table:  ${table.name}')
    ..writeln()
    ..writeln('CREATE TABLE $schemaName.${table.name} (');

  final colLines = <String>[];
  for (final c in table.columns) {
    final parts = <String>[
      '  ${c.name}',
      c.renderType(),
      if (!c.nullable) 'NOT NULL',
      if (c.unique && !c.primaryKey) 'UNIQUE',
      if (c.defaultValue != null && c.defaultValue!.isNotEmpty)
        'DEFAULT ${c.defaultValue}',
    ];
    colLines.add(parts.join(' '));
  }
  final pks = table.columns.where((c) => c.primaryKey).toList();
  if (pks.isNotEmpty) {
    colLines.add(
      '  CONSTRAINT PK_${table.name} PRIMARY KEY (${pks.map((c) => c.name).join(', ')})',
    );
  }
  buf
    ..writeln(colLines.join(',\n'))
    ..writeln(');')
    ..writeln();

  for (final row in table.rows) {
    final cols = table.columns.map((c) => c.name).join(', ');
    final vals = table.columns.map((c) => _sqlLiteral(row[c.name], c)).join(', ');
    buf.writeln('INSERT INTO $schemaName.${table.name} ($cols) VALUES ($vals);');
  }
  buf.writeln('COMMIT;');
  return buf.toString();
}

String exportSourceSql(OracleSource source) {
  final buf = StringBuffer()
    ..writeln('-- Source: ${source.name}')
    ..writeln('-- ${source.host}:${source.port}/${source.serviceName}')
    ..writeln('-- Login: ${source.username}')
    ..writeln();

  // Create one Oracle user per schema. In an IFS-style single-owner deploy
  // there's typically only one schema (IFSAPP) and `source.password` is its
  // login password; any additional schemas get the same password for dev
  // convenience.
  for (final schema in source.schemas) {
    final pwd = _quoteIdentPassword(source.password);
    buf.writeln('CREATE USER ${schema.name} IDENTIFIED BY $pwd;');
    buf.writeln('GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO ${schema.name};');
    buf.writeln();
  }
  for (final table in source.tables) {
    buf.writeln(exportTableSql(source, table));
    buf.writeln();
  }
  return buf.toString();
}

/// Oracle accepts unquoted passwords for simple alphanumerics, otherwise
/// they need double-quotes. We always quote for safety and escape embedded
/// quotes by doubling.
String _quoteIdentPassword(String pwd) {
  final escaped = pwd.replaceAll('"', '""');
  return '"$escaped"';
}

String _sqlLiteral(dynamic v, OracleColumn col) {
  if (v == null) return 'NULL';
  switch (col.type) {
    case OracleType.integer:
    case OracleType.number:
    case OracleType.boolean:
      return v.toString();
    case OracleType.date:
      return "TO_DATE('${_asIsoDate(v)}', 'YYYY-MM-DD')";
    case OracleType.timestamp:
      return "TO_TIMESTAMP('${_asIsoTs(v)}', 'YYYY-MM-DD\"T\"HH24:MI:SS')";
    default:
      final s = v.toString().replaceAll("'", "''");
      return "'$s'";
  }
}

String _asIsoDate(dynamic v) {
  final s = v.toString();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

String _asIsoTs(dynamic v) {
  final s = v.toString();
  return s.length >= 19 ? s.substring(0, 19) : s;
}
