import '../models/dq_rule.dart';
import '../models/oracle_source.dart';
import '../models/oracle_type.dart';
import 'lookups.dart';
import 'synth.dart';

/// A default Oracle-style source seeded with the classic HR + SALES sample
/// schemas, populated with deterministic synthetic rows and a small bank of
/// data-quality rules so the validator has something to chew on immediately.
OracleSource buildDefaultSource() {
  final source = OracleSource(
    name: 'ORACLE_DEV',
    host: 'localhost',
    port: 1521,
    serviceName: 'ORCLPDB1',
  );

  _seedHr(source);
  _seedSales(source);
  _seedRules(source);

  for (final t in source.tables) {
    synthesizeRows(t);
  }
  return source;
}

// ---------------------------------------------------------------------------
// HR (employees, departments, jobs)
// ---------------------------------------------------------------------------

void _seedHr(OracleSource source) {
  final hr = OracleSchema(
    name: 'HR',
    description: 'Human Resources — employees, departments, jobs.',
  );
  source.schemas.add(hr);

  source.tables.add(OracleTable(
    name: 'DEPARTMENTS',
    schemaId: hr.id,
    rowCountTarget: 12,
    synthSeed: 1001,
    columns: [
      OracleColumn(name: 'DEPARTMENT_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'DEPARTMENT_NAME', type: OracleType.varchar2, length: 30, nullable: false, synthHint: 'department'),
      OracleColumn(name: 'LOCATION', type: OracleType.varchar2, length: 30, synthHint: 'city'),
      OracleColumn(name: 'COUNTRY_CODE', type: OracleType.char, length: 2, synthHint: 'country'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'JOBS',
    schemaId: hr.id,
    rowCountTarget: 12,
    synthSeed: 1002,
    columns: [
      OracleColumn(name: 'JOB_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'JOB_TITLE', type: OracleType.varchar2, length: 40, nullable: false, synthHint: 'job_title'),
      OracleColumn(name: 'MIN_SALARY', type: OracleType.number, precision: 8, scale: 2, synthHint: 'salary'),
      OracleColumn(name: 'MAX_SALARY', type: OracleType.number, precision: 8, scale: 2, synthHint: 'salary'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'EMPLOYEES',
    schemaId: hr.id,
    rowCountTarget: 80,
    synthSeed: 1003,
    columns: [
      OracleColumn(name: 'EMPLOYEE_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'FIRST_NAME', type: OracleType.varchar2, length: 20, nullable: false),
      OracleColumn(name: 'LAST_NAME', type: OracleType.varchar2, length: 25, nullable: false),
      OracleColumn(name: 'EMAIL', type: OracleType.varchar2, length: 50, unique: true),
      OracleColumn(name: 'PHONE_NUMBER', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'HIRE_DATE', type: OracleType.date, nullable: false),
      OracleColumn(name: 'JOB_TITLE', type: OracleType.varchar2, length: 40, synthHint: 'job_title'),
      OracleColumn(name: 'SALARY', type: OracleType.number, precision: 8, scale: 2, synthHint: 'salary'),
      OracleColumn(name: 'DEPARTMENT_ID', type: OracleType.integer),
    ],
  ));
}

// ---------------------------------------------------------------------------
// SALES (customers, orders)
// ---------------------------------------------------------------------------

void _seedSales(OracleSource source) {
  final sales = OracleSchema(
    name: 'SALES',
    description: 'Customer and order data.',
  );
  source.schemas.add(sales);

  source.tables.add(OracleTable(
    name: 'CUSTOMERS',
    schemaId: sales.id,
    rowCountTarget: 60,
    synthSeed: 2001,
    columns: [
      OracleColumn(name: 'CUSTOMER_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 60, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'EMAIL', type: OracleType.varchar2, length: 60),
      OracleColumn(name: 'COUNTRY_CODE', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'STATUS', type: OracleType.varchar2, length: 10, synthHint: 'status'),
      OracleColumn(name: 'CREATED_AT', type: OracleType.timestamp),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'ORDERS',
    schemaId: sales.id,
    rowCountTarget: 120,
    synthSeed: 2002,
    columns: [
      OracleColumn(name: 'ORDER_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'CUSTOMER_ID', type: OracleType.integer, nullable: false),
      OracleColumn(name: 'ORDER_DATE', type: OracleType.date, nullable: false),
      OracleColumn(name: 'AMOUNT', type: OracleType.number, precision: 10, scale: 2, synthHint: 'amount'),
      OracleColumn(name: 'CURRENCY', type: OracleType.char, length: 3, synthHint: 'currency'),
      OracleColumn(name: 'STATUS', type: OracleType.varchar2, length: 10, synthHint: 'status'),
    ],
  ));
}

// ---------------------------------------------------------------------------
// Oracle-native data-quality rules
// ---------------------------------------------------------------------------

void _seedRules(OracleSource source) {
  final departments = source.tables.firstWhere((t) => t.name == 'DEPARTMENTS');
  final jobs = source.tables.firstWhere((t) => t.name == 'JOBS');
  final employees = source.tables.firstWhere((t) => t.name == 'EMPLOYEES');
  final customers = source.tables.firstWhere((t) => t.name == 'CUSTOMERS');
  final orders = source.tables.firstWhere((t) => t.name == 'ORDERS');

  source.rules.addAll([
    // HR.DEPARTMENTS
    DQRule(
      code: 'R-DEP-001',
      tableId: departments.id,
      kind: DQKind.notNull,
      columnName: 'DEPARTMENT_NAME',
      severity: DQSeverity.error,
      message: 'Department name must be set.',
    ),
    DQRule(
      code: 'R-DEP-002',
      tableId: departments.id,
      kind: DQKind.inSet,
      columnName: 'COUNTRY_CODE',
      values: List<String>.from(isoCountryCodes),
      severity: DQSeverity.warning,
      message: 'Country code must be a known ISO code.',
    ),

    // HR.JOBS
    DQRule(
      code: 'R-JOB-001',
      tableId: jobs.id,
      kind: DQKind.notNull,
      columnName: 'JOB_TITLE',
      severity: DQSeverity.error,
      message: 'Job title must be set.',
    ),
    DQRule(
      code: 'R-JOB-002',
      tableId: jobs.id,
      kind: DQKind.positive,
      columnName: 'MIN_SALARY',
      severity: DQSeverity.error,
      message: 'Minimum salary must be > 0.',
    ),

    // HR.EMPLOYEES
    DQRule(
      code: 'R-EMP-001',
      tableId: employees.id,
      kind: DQKind.notNull,
      columnName: 'FIRST_NAME',
      severity: DQSeverity.error,
      message: 'First name must be set.',
    ),
    DQRule(
      code: 'R-EMP-002',
      tableId: employees.id,
      kind: DQKind.notNull,
      columnName: 'LAST_NAME',
      severity: DQSeverity.error,
      message: 'Last name must be set.',
    ),
    DQRule(
      code: 'R-EMP-003',
      tableId: employees.id,
      kind: DQKind.regex,
      columnName: 'EMAIL',
      pattern: emailPattern,
      severity: DQSeverity.warning,
      message: 'Email must look like name@host.tld.',
    ),
    DQRule(
      code: 'R-EMP-004',
      tableId: employees.id,
      kind: DQKind.positive,
      columnName: 'SALARY',
      severity: DQSeverity.error,
      message: 'Salary must be strictly positive.',
    ),
    DQRule(
      code: 'R-EMP-005',
      tableId: employees.id,
      kind: DQKind.foreignKey,
      columnName: 'DEPARTMENT_ID',
      refTableName: 'DEPARTMENTS',
      refColumnName: 'DEPARTMENT_ID',
      severity: DQSeverity.error,
      message: 'Department must exist in HR.DEPARTMENTS.',
    ),

    // SALES.CUSTOMERS
    DQRule(
      code: 'R-CUS-001',
      tableId: customers.id,
      kind: DQKind.notNull,
      columnName: 'NAME',
      severity: DQSeverity.error,
      message: 'Customer name must be set.',
    ),
    DQRule(
      code: 'R-CUS-002',
      tableId: customers.id,
      kind: DQKind.inSet,
      columnName: 'COUNTRY_CODE',
      values: List<String>.from(isoCountryCodes),
      severity: DQSeverity.warning,
      message: 'Country code must be a known ISO code.',
    ),
    DQRule(
      code: 'R-CUS-003',
      tableId: customers.id,
      kind: DQKind.inSet,
      columnName: 'STATUS',
      values: List<String>.from(statusCodes),
      severity: DQSeverity.warning,
      message: 'Status must be one of ACTIVE/INACTIVE/PENDING/CLOSED.',
    ),

    // SALES.ORDERS
    DQRule(
      code: 'R-ORD-001',
      tableId: orders.id,
      kind: DQKind.foreignKey,
      columnName: 'CUSTOMER_ID',
      refTableName: 'CUSTOMERS',
      refColumnName: 'CUSTOMER_ID',
      severity: DQSeverity.error,
      message: 'Customer must exist in SALES.CUSTOMERS.',
    ),
    DQRule(
      code: 'R-ORD-002',
      tableId: orders.id,
      kind: DQKind.positive,
      columnName: 'AMOUNT',
      severity: DQSeverity.error,
      message: 'Order amount must be strictly positive.',
    ),
    DQRule(
      code: 'R-ORD-003',
      tableId: orders.id,
      kind: DQKind.inSet,
      columnName: 'CURRENCY',
      values: List<String>.from(currencyCodes),
      severity: DQSeverity.warning,
      message: 'Currency must be a known ISO 4217 code.',
    ),
    DQRule(
      code: 'R-ORD-004',
      tableId: orders.id,
      kind: DQKind.inSet,
      columnName: 'STATUS',
      values: List<String>.from(statusCodes),
      severity: DQSeverity.warning,
      message: 'Status must be one of ACTIVE/INACTIVE/PENDING/CLOSED.',
    ),
  ]);
}
