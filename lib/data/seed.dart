import '../models/dq_rule.dart';
import '../models/oracle_source.dart';
import '../models/oracle_type.dart';
import 'lookups.dart';
import 'synth.dart';

/// A default Oracle-style source mirroring the classic HR + SALES sample
/// schemas plus a `SAP_MIRROR` schema that ports the SAP entities and
/// data-quality rule bank used by the ConnectorExpenses reference console.
OracleSource buildDefaultSource() {
  final source = OracleSource(
    name: 'ORACLE_DEV',
    host: 'localhost',
    port: 1521,
    serviceName: 'ORCLPDB1',
  );

  _seedHr(source);
  _seedSales(source);
  _seedSapMirror(source);

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
// SAP_MIRROR — port of the ConnectorExpenses entities + DQ rule bank
// ---------------------------------------------------------------------------

void _seedSapMirror(OracleSource source) {
  final sap = OracleSchema(
    name: 'SAP_MIRROR',
    description:
        'Oracle mirror of canonical SAP entities (customer, material, '
        'sales_order, pricing_condition, ...) with their data-quality rules.',
  );
  source.schemas.add(sap);

  final customer = OracleTable(
    name: 'CUSTOMER',
    schemaId: sap.id,
    rowCountTarget: 60,
    synthSeed: 3001,
    columns: [
      OracleColumn(name: 'KUNNR', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'NAME1', type: OracleType.varchar2, length: 40, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'LAND1', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'KTOKD', type: OracleType.char, length: 4),
      OracleColumn(name: 'STCEG', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'ERDAT', type: OracleType.date),
    ],
  );

  final material = OracleTable(
    name: 'MATERIAL',
    schemaId: sap.id,
    rowCountTarget: 80,
    synthSeed: 3002,
    columns: [
      OracleColumn(name: 'MATNR', type: OracleType.varchar2, length: 18, primaryKey: true, nullable: false),
      OracleColumn(name: 'MAKTX', type: OracleType.varchar2, length: 40, nullable: false),
      OracleColumn(name: 'MATKL', type: OracleType.varchar2, length: 9),
      OracleColumn(name: 'MEINS', type: OracleType.char, length: 3),
      OracleColumn(name: 'MTART', type: OracleType.char, length: 4),
    ],
  );

  final vendor = OracleTable(
    name: 'VENDOR',
    schemaId: sap.id,
    rowCountTarget: 40,
    synthSeed: 3003,
    columns: [
      OracleColumn(name: 'LIFNR', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'NAME1', type: OracleType.varchar2, length: 40, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'LAND1', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'STCEG', type: OracleType.varchar2, length: 20),
    ],
  );

  final salesOrg = OracleTable(
    name: 'SALES_ORG',
    schemaId: sap.id,
    rowCountTarget: 3,
    synthSeed: 3004,
    columns: [
      OracleColumn(name: 'VKORG', type: OracleType.char, length: 4, primaryKey: true, nullable: false),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 30, nullable: false),
      OracleColumn(name: 'WAERS', type: OracleType.char, length: 5, synthHint: 'currency'),
    ],
  );

  final salesOrder = OracleTable(
    name: 'SALES_ORDER',
    schemaId: sap.id,
    rowCountTarget: 150,
    synthSeed: 3005,
    columns: [
      OracleColumn(name: 'VBELN', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'KUNNR', type: OracleType.varchar2, length: 10, nullable: false),
      OracleColumn(name: 'AUDAT', type: OracleType.date, nullable: false),
      OracleColumn(name: 'NETWR', type: OracleType.number, precision: 13, scale: 2, synthHint: 'amount'),
      OracleColumn(name: 'WAERK', type: OracleType.char, length: 5, synthHint: 'currency'),
      OracleColumn(name: 'VKORG', type: OracleType.char, length: 4),
    ],
  );

  final salesOrderItem = OracleTable(
    name: 'SALES_ORDER_ITEM',
    schemaId: sap.id,
    rowCountTarget: 400,
    synthSeed: 3006,
    columns: [
      OracleColumn(name: 'VBELN', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'POSNR', type: OracleType.varchar2, length: 6, primaryKey: true, nullable: false),
      OracleColumn(name: 'MATNR', type: OracleType.varchar2, length: 18),
      OracleColumn(name: 'KWMENG', type: OracleType.number, precision: 13, scale: 3),
      OracleColumn(name: 'NETWR', type: OracleType.number, precision: 13, scale: 2, synthHint: 'amount'),
      OracleColumn(name: 'WAERK', type: OracleType.char, length: 5, synthHint: 'currency'),
    ],
  );

  final purchaseOrder = OracleTable(
    name: 'PURCHASE_ORDER',
    schemaId: sap.id,
    rowCountTarget: 90,
    synthSeed: 3007,
    columns: [
      OracleColumn(name: 'EBELN', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'LIFNR', type: OracleType.varchar2, length: 10, nullable: false),
      OracleColumn(name: 'BEDAT', type: OracleType.date, nullable: false),
      OracleColumn(name: 'WAERS', type: OracleType.char, length: 5, synthHint: 'currency'),
    ],
  );

  final delivery = OracleTable(
    name: 'DELIVERY',
    schemaId: sap.id,
    rowCountTarget: 120,
    synthSeed: 3008,
    columns: [
      OracleColumn(name: 'VBELN', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'LFART', type: OracleType.char, length: 4),
      OracleColumn(name: 'LFDAT', type: OracleType.date, nullable: false),
      OracleColumn(name: 'KUNNR', type: OracleType.varchar2, length: 10),
    ],
  );

  final pricingCondition = OracleTable(
    name: 'PRICING_CONDITION',
    schemaId: sap.id,
    rowCountTarget: 60,
    synthSeed: 3009,
    columns: [
      OracleColumn(name: 'KNUMH', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'KSCHL', type: OracleType.char, length: 4, nullable: false),
      OracleColumn(name: 'DATAB', type: OracleType.date, nullable: false),
      OracleColumn(name: 'DATBI', type: OracleType.date, nullable: false),
      OracleColumn(name: 'KBETR', type: OracleType.number, precision: 11, scale: 2, synthHint: 'amount'),
    ],
  );

  final inventoryStock = OracleTable(
    name: 'INVENTORY_STOCK',
    schemaId: sap.id,
    rowCountTarget: 200,
    synthSeed: 3010,
    columns: [
      OracleColumn(name: 'MATNR', type: OracleType.varchar2, length: 18, primaryKey: true, nullable: false),
      OracleColumn(name: 'WERKS', type: OracleType.char, length: 4, primaryKey: true, nullable: false),
      OracleColumn(name: 'LABST', type: OracleType.number, precision: 13, scale: 3),
      OracleColumn(name: 'MEINS', type: OracleType.char, length: 3),
    ],
  );

  final glAccount = OracleTable(
    name: 'GL_ACCOUNT',
    schemaId: sap.id,
    rowCountTarget: 40,
    synthSeed: 3011,
    columns: [
      OracleColumn(name: 'SAKNR', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'TXT50', type: OracleType.varchar2, length: 50, nullable: false),
      OracleColumn(name: 'BUKRS', type: OracleType.char, length: 4),
    ],
  );

  final costCenter = OracleTable(
    name: 'COST_CENTER',
    schemaId: sap.id,
    rowCountTarget: 24,
    synthSeed: 3012,
    columns: [
      OracleColumn(name: 'KOSTL', type: OracleType.varchar2, length: 10, primaryKey: true, nullable: false),
      OracleColumn(name: 'KTEXT', type: OracleType.varchar2, length: 40, nullable: false, synthHint: 'department'),
      OracleColumn(name: 'BUKRS', type: OracleType.char, length: 4),
    ],
  );

  source.tables.addAll([
    customer, material, vendor, salesOrg, salesOrder, salesOrderItem,
    purchaseOrder, delivery, pricingCondition, inventoryStock, glAccount,
    costCenter,
  ]);

  // ----- Rule bank (ported from RULE_BANK in ConnectorExpenses) -----------
  source.rules.addAll([
    DQRule(
      code: 'V-CUST-001',
      tableId: customer.id,
      kind: DQKind.notNull,
      columnName: 'NAME1',
      severity: DQSeverity.error,
      message: 'Every customer must have a non-empty name.',
    ),
    DQRule(
      code: 'V-CUST-002',
      tableId: customer.id,
      kind: DQKind.inSet,
      columnName: 'LAND1',
      values: List<String>.from(isoCountryCodes),
      severity: DQSeverity.warning,
      message:
          'Primary address country code does not resolve to a known ISO code.',
    ),
    DQRule(
      code: 'V-CUST-003',
      tableId: customer.id,
      kind: DQKind.inSet,
      columnName: 'KTOKD',
      values: List<String>.from(customerAccountGroups),
      severity: DQSeverity.warning,
      message: 'Customer account group (KTOKD) is not a known value.',
    ),
    DQRule(
      code: 'V-MAT-001',
      tableId: material.id,
      kind: DQKind.notNull,
      columnName: 'MATKL',
      severity: DQSeverity.warning,
      message: 'Material group is empty for an active material.',
    ),
    DQRule(
      code: 'V-MAT-002',
      tableId: material.id,
      kind: DQKind.inSet,
      columnName: 'MEINS',
      values: List<String>.from(sapUoms),
      severity: DQSeverity.error,
      message: 'Base unit of measure does not resolve to a known UoM.',
    ),
    DQRule(
      code: 'V-MAT-003',
      tableId: material.id,
      kind: DQKind.inSet,
      columnName: 'MTART',
      values: List<String>.from(materialTypes),
      severity: DQSeverity.warning,
      message: 'Material type (MTART) is not a known value.',
    ),
    DQRule(
      code: 'V-SO-001',
      tableId: salesOrder.id,
      kind: DQKind.foreignKey,
      columnName: 'KUNNR',
      refTableName: 'CUSTOMER',
      refColumnName: 'KUNNR',
      severity: DQSeverity.error,
      message: 'Customer reference does not exist in the customer master.',
    ),
    DQRule(
      code: 'V-SO-002',
      tableId: salesOrderItem.id,
      kind: DQKind.positive,
      columnName: 'KWMENG',
      severity: DQSeverity.error,
      message: 'Line quantity is not strictly positive.',
    ),
    DQRule(
      code: 'V-PRICE-001',
      tableId: pricingCondition.id,
      kind: DQKind.datesOrdered,
      columnName: 'DATAB',
      secondColumn: 'DATBI',
      severity: DQSeverity.critical,
      message:
          'Pricing condition validity dates are out of order (DATAB > DATBI).',
    ),
    DQRule(
      code: 'V-PRICE-002',
      tableId: pricingCondition.id,
      kind: DQKind.inSet,
      columnName: 'KSCHL',
      values: List<String>.from(conditionTypes),
      severity: DQSeverity.warning,
      message: 'Pricing condition type (KSCHL) is not a known code.',
    ),
    DQRule(
      code: 'V-STOCK-001',
      tableId: inventoryStock.id,
      kind: DQKind.range,
      columnName: 'LABST',
      min: 0,
      severity: DQSeverity.error,
      message: 'Inventory stock quantity is negative.',
    ),
    DQRule(
      code: 'V-VENDOR-001',
      tableId: vendor.id,
      kind: DQKind.regex,
      columnName: 'STCEG',
      pattern: r'^[A-Z]{2}[A-Z0-9]{2,12}$',
      severity: DQSeverity.warning,
      message: 'Vendor tax ID does not match the expected country format.',
    ),
  ]);
}
