import '../models/oracle_source.dart';
import '../models/oracle_type.dart';
import 'synth.dart';

/// A default Oracle-style source mirroring the classic HR sample schema —
/// useful so the app has meaningful content the first time it loads.
OracleSource buildDefaultSource() {
  final source = OracleSource(
    name: 'ORACLE_DEV',
    host: 'localhost',
    port: 1521,
    serviceName: 'ORCLPDB1',
  );

  final hr = OracleSchema(
    name: 'HR',
    description: 'Human Resources — employees, departments, jobs.',
  );
  final sales = OracleSchema(
    name: 'SALES',
    description: 'Customer and order data.',
  );
  source.schemas.addAll([hr, sales]);

  final departments = OracleTable(
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
  );

  final jobs = OracleTable(
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
  );

  final employees = OracleTable(
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
  );

  final customers = OracleTable(
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
  );

  final orders = OracleTable(
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
  );

  source.tables.addAll([departments, jobs, employees, customers, orders]);
  for (final t in source.tables) {
    synthesizeRows(t);
  }
  return source;
}
