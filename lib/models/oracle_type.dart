enum OracleType {
  number,
  integer,
  varchar2,
  char,
  clob,
  date,
  timestamp,
  raw,
  blob,
  boolean,
}

extension OracleTypeX on OracleType {
  String get sqlName {
    switch (this) {
      case OracleType.number:
        return 'NUMBER';
      case OracleType.integer:
        return 'NUMBER(38,0)';
      case OracleType.varchar2:
        return 'VARCHAR2';
      case OracleType.char:
        return 'CHAR';
      case OracleType.clob:
        return 'CLOB';
      case OracleType.date:
        return 'DATE';
      case OracleType.timestamp:
        return 'TIMESTAMP';
      case OracleType.raw:
        return 'RAW';
      case OracleType.blob:
        return 'BLOB';
      case OracleType.boolean:
        return 'NUMBER(1,0)';
    }
  }

  bool get takesLength {
    switch (this) {
      case OracleType.varchar2:
      case OracleType.char:
      case OracleType.raw:
        return true;
      default:
        return false;
    }
  }

  bool get takesPrecisionScale => this == OracleType.number;

  String get label => name.toUpperCase();
}

OracleType oracleTypeFromString(String s) {
  return OracleType.values.firstWhere(
    (t) => t.name == s,
    orElse: () => OracleType.varchar2,
  );
}
