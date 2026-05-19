import '../models/dq_rule.dart';
import '../models/oracle_source.dart';
import '../models/oracle_type.dart';
import 'lookups.dart';
import 'synth.dart';

/// A default IFS-style source seeded with a representative mix of IFSAPP
/// tables (master + transactional), populated with deterministic synthetic
/// rows that respect the source-level identity anchors (owner user, company,
/// site, currency) and a small bank of IFS-flavoured data-quality rules.
OracleSource buildDefaultSource() {
  final source = OracleSource(
    name: 'IFS_DEV',
    host: 'localhost',
    port: 1521,
    serviceName: 'IFSPRD',
    ownerUser: 'IFSAPP',
    companyCode: '10',
    defaultSite: 'S001',
    defaultCurrency: 'USD',
  );

  _seedIfs(source);
  _seedRules(source);

  final anchors = SynthAnchors.fromSource(source);
  for (final t in source.tables) {
    synthesizeRows(t, anchors: anchors);
  }
  return source;
}

void _seedIfs(OracleSource source) {
  final ifs = OracleSchema(
    name: 'IFSAPP',
    description:
        'IFS Applications owner schema — companies, sites, parts, orders.',
  );
  source.schemas.add(ifs);

  // -- Master data ----------------------------------------------------------

  source.tables.add(OracleTable(
    name: 'COMPANY_TAB',
    schemaId: ifs.id,
    rowCountTarget: 3,
    synthSeed: 1001,
    columns: [
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, primaryKey: true, nullable: false, synthHint: 'company_master'),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 100, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'ASSOCIATION_NO', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'COUNTRY', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'CURRENCY_CODE', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
      OracleColumn(name: 'CREATED', type: OracleType.timestamp),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'SITE_TAB',
    schemaId: ifs.id,
    rowCountTarget: 3,
    synthSeed: 1002,
    columns: [
      OracleColumn(name: 'SITE', type: OracleType.varchar2, length: 5, primaryKey: true, nullable: false, synthHint: 'site_master'),
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, nullable: false, synthHint: 'site_master'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, nullable: false, synthHint: 'company_ref'),
      OracleColumn(name: 'DESCRIPTION', type: OracleType.varchar2, length: 100, synthHint: 'city'),
      OracleColumn(name: 'COUNTRY_CODE', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'TIME_ZONE', type: OracleType.varchar2, length: 40),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'PERSON_INFO_TAB',
    schemaId: ifs.id,
    rowCountTarget: 40,
    synthSeed: 1003,
    columns: [
      OracleColumn(name: 'PERSON_ID', type: OracleType.varchar2, length: 20, primaryKey: true, nullable: false, synthHint: 'id_code'),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 100, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'FIRST_NAME', type: OracleType.varchar2, length: 50, synthHint: 'first_name'),
      OracleColumn(name: 'LAST_NAME', type: OracleType.varchar2, length: 50, synthHint: 'last_name'),
      OracleColumn(name: 'EMAIL', type: OracleType.varchar2, length: 100, synthHint: 'email'),
      OracleColumn(name: 'PHONE', type: OracleType.varchar2, length: 30, synthHint: 'phone'),
      OracleColumn(name: 'COUNTRY', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, synthHint: 'company_ref'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'USER_ALLOWED_SITE_TAB',
    schemaId: ifs.id,
    rowCountTarget: 30,
    synthSeed: 1004,
    columns: [
      OracleColumn(name: 'USER_ALLOWED_SITE_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'IDENTITY', type: OracleType.varchar2, length: 30, nullable: false, synthHint: 'owner_user'),
      OracleColumn(name: 'SITE', type: OracleType.varchar2, length: 5, nullable: false, synthHint: 'site_ref'),
      OracleColumn(name: 'DEFAULT_SITE', type: OracleType.varchar2, length: 5, synthHint: 'flag'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'CUSTOMER_INFO_TAB',
    schemaId: ifs.id,
    rowCountTarget: 60,
    synthSeed: 2001,
    columns: [
      OracleColumn(name: 'CUSTOMER_ID', type: OracleType.varchar2, length: 20, primaryKey: true, nullable: false, synthHint: 'id_code'),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 100, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'ASSOCIATION_NO', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'COUNTRY', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, synthHint: 'company_ref'),
      OracleColumn(name: 'CURRENCY_CODE', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'CATEGORY', type: OracleType.varchar2, length: 20, synthHint: 'status'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
      OracleColumn(name: 'CREATED', type: OracleType.timestamp),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'SUPPLIER_INFO_TAB',
    schemaId: ifs.id,
    rowCountTarget: 40,
    synthSeed: 2002,
    columns: [
      OracleColumn(name: 'SUPPLIER_ID', type: OracleType.varchar2, length: 20, primaryKey: true, nullable: false, synthHint: 'id_code'),
      OracleColumn(name: 'NAME', type: OracleType.varchar2, length: 100, nullable: false, synthHint: 'full_name'),
      OracleColumn(name: 'ASSOCIATION_NO', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'COUNTRY', type: OracleType.char, length: 2, synthHint: 'country'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, synthHint: 'company_ref'),
      OracleColumn(name: 'CURRENCY_CODE', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'INVENTORY_PART_TAB',
    schemaId: ifs.id,
    rowCountTarget: 80,
    synthSeed: 2003,
    columns: [
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, primaryKey: true, nullable: false, synthHint: 'site_ref'),
      OracleColumn(name: 'PART_NO', type: OracleType.varchar2, length: 25, primaryKey: true, nullable: false, synthHint: 'part_no'),
      OracleColumn(name: 'DESCRIPTION', type: OracleType.varchar2, length: 100),
      OracleColumn(name: 'UNIT_MEAS', type: OracleType.varchar2, length: 10),
      OracleColumn(name: 'PART_STATUS', type: OracleType.varchar2, length: 10, synthHint: 'status'),
      OracleColumn(name: 'PLANNER_BUYER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
      OracleColumn(name: 'INVENTORY_VALUATION_METHOD', type: OracleType.varchar2, length: 20),
      OracleColumn(name: 'TYPE_CODE', type: OracleType.varchar2, length: 5),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  // -- Transactional --------------------------------------------------------

  source.tables.add(OracleTable(
    name: 'CUSTOMER_ORDER_TAB',
    schemaId: ifs.id,
    rowCountTarget: 120,
    synthSeed: 3001,
    columns: [
      OracleColumn(name: 'ORDER_NO', type: OracleType.varchar2, length: 12, primaryKey: true, nullable: false, synthHint: 'order_no'),
      OracleColumn(name: 'CUSTOMER_NO', type: OracleType.varchar2, length: 20, nullable: false),
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, nullable: false, synthHint: 'site_ref'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, synthHint: 'company_ref'),
      OracleColumn(name: 'CURRENCY', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'WANTED_DELIVERY_DATE', type: OracleType.date),
      OracleColumn(name: 'ORDER_DATE', type: OracleType.date, nullable: false),
      OracleColumn(name: 'AUTHORIZE_CODE', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'CUSTOMER_ORDER_LINE_TAB',
    schemaId: ifs.id,
    rowCountTarget: 200,
    synthSeed: 3002,
    columns: [
      OracleColumn(name: 'LINE_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'ORDER_NO', type: OracleType.varchar2, length: 12, nullable: false),
      OracleColumn(name: 'LINE_NO', type: OracleType.varchar2, length: 4),
      OracleColumn(name: 'REL_NO', type: OracleType.varchar2, length: 4),
      OracleColumn(name: 'CATALOG_NO', type: OracleType.varchar2, length: 25, synthHint: 'part_no'),
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, synthHint: 'site_ref'),
      OracleColumn(name: 'BUY_QTY_DUE', type: OracleType.number, precision: 14, scale: 3),
      OracleColumn(name: 'SALE_UNIT_PRICE', type: OracleType.number, precision: 14, scale: 2, synthHint: 'amount'),
      OracleColumn(name: 'CURRENCY', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'WANTED_DELIVERY_DATE', type: OracleType.date),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'PURCHASE_ORDER_TAB',
    schemaId: ifs.id,
    rowCountTarget: 80,
    synthSeed: 4001,
    columns: [
      OracleColumn(name: 'ORDER_NO', type: OracleType.varchar2, length: 12, primaryKey: true, nullable: false, synthHint: 'po_no'),
      OracleColumn(name: 'SUPPLIER_NO', type: OracleType.varchar2, length: 20, nullable: false),
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, nullable: false, synthHint: 'site_ref'),
      OracleColumn(name: 'COMPANY', type: OracleType.varchar2, length: 20, synthHint: 'company_ref'),
      OracleColumn(name: 'CURRENCY_CODE', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'ORDER_DATE', type: OracleType.date, nullable: false),
      OracleColumn(name: 'WANTED_RECEIPT_DATE', type: OracleType.date),
      OracleColumn(name: 'BUYER_CODE', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
      OracleColumn(name: 'OWNER_USER', type: OracleType.varchar2, length: 30, synthHint: 'owner_user'),
    ],
  ));

  source.tables.add(OracleTable(
    name: 'PURCHASE_ORDER_LINE_TAB',
    schemaId: ifs.id,
    rowCountTarget: 160,
    synthSeed: 4002,
    columns: [
      OracleColumn(name: 'LINE_ID', type: OracleType.integer, primaryKey: true, nullable: false),
      OracleColumn(name: 'ORDER_NO', type: OracleType.varchar2, length: 12, nullable: false),
      OracleColumn(name: 'LINE_NO', type: OracleType.varchar2, length: 4),
      OracleColumn(name: 'RELEASE_NO', type: OracleType.varchar2, length: 4),
      OracleColumn(name: 'PART_NO', type: OracleType.varchar2, length: 25, synthHint: 'part_no'),
      OracleColumn(name: 'CONTRACT', type: OracleType.varchar2, length: 5, synthHint: 'site_ref'),
      OracleColumn(name: 'BUY_QTY_DUE', type: OracleType.number, precision: 14, scale: 3),
      OracleColumn(name: 'BUY_UNIT_PRICE', type: OracleType.number, precision: 14, scale: 2, synthHint: 'amount'),
      OracleColumn(name: 'CURRENCY_CODE', type: OracleType.char, length: 3, synthHint: 'currency_ref'),
      OracleColumn(name: 'WANTED_RECEIPT_DATE', type: OracleType.date),
      OracleColumn(name: 'OBJSTATE', type: OracleType.varchar2, length: 20, synthHint: 'objstate'),
    ],
  ));
}

// ---------------------------------------------------------------------------
// IFS-flavoured data-quality rules
// ---------------------------------------------------------------------------

void _seedRules(OracleSource source) {
  final company = source.tables.firstWhere((t) => t.name == 'COMPANY_TAB');
  final site = source.tables.firstWhere((t) => t.name == 'SITE_TAB');
  final person = source.tables.firstWhere((t) => t.name == 'PERSON_INFO_TAB');
  final customer = source.tables.firstWhere((t) => t.name == 'CUSTOMER_INFO_TAB');
  final supplier = source.tables.firstWhere((t) => t.name == 'SUPPLIER_INFO_TAB');
  final part = source.tables.firstWhere((t) => t.name == 'INVENTORY_PART_TAB');
  final coHdr = source.tables.firstWhere((t) => t.name == 'CUSTOMER_ORDER_TAB');
  final coLine = source.tables.firstWhere((t) => t.name == 'CUSTOMER_ORDER_LINE_TAB');
  final poHdr = source.tables.firstWhere((t) => t.name == 'PURCHASE_ORDER_TAB');
  final poLine = source.tables.firstWhere((t) => t.name == 'PURCHASE_ORDER_LINE_TAB');

  source.rules.addAll([
    // COMPANY_TAB
    DQRule(
      code: 'R-CMP-001',
      tableId: company.id,
      kind: DQKind.notNull,
      columnName: 'NAME',
      severity: DQSeverity.error,
      message: 'Company name must be set.',
    ),
    DQRule(
      code: 'R-CMP-002',
      tableId: company.id,
      kind: DQKind.inSet,
      columnName: 'CURRENCY_CODE',
      values: List<String>.from(currencyCodes),
      severity: DQSeverity.warning,
      message: 'Currency must be a known ISO 4217 code.',
    ),

    // SITE_TAB
    DQRule(
      code: 'R-SIT-001',
      tableId: site.id,
      kind: DQKind.notNull,
      columnName: 'COMPANY',
      severity: DQSeverity.error,
      message: 'Site must belong to a company.',
    ),
    DQRule(
      code: 'R-SIT-002',
      tableId: site.id,
      kind: DQKind.foreignKey,
      columnName: 'COMPANY',
      refTableName: 'COMPANY_TAB',
      refColumnName: 'COMPANY',
      severity: DQSeverity.error,
      message: 'Company must exist in IFSAPP.COMPANY_TAB.',
    ),

    // PERSON_INFO_TAB
    DQRule(
      code: 'R-PER-001',
      tableId: person.id,
      kind: DQKind.regex,
      columnName: 'EMAIL',
      pattern: emailPattern,
      severity: DQSeverity.warning,
      message: 'Email must look like name@host.tld.',
    ),
    DQRule(
      code: 'R-PER-002',
      tableId: person.id,
      kind: DQKind.inSet,
      columnName: 'COUNTRY',
      values: List<String>.from(isoCountryCodes),
      severity: DQSeverity.warning,
      message: 'Country must be a known ISO code.',
    ),

    // CUSTOMER_INFO_TAB
    DQRule(
      code: 'R-CUS-001',
      tableId: customer.id,
      kind: DQKind.notNull,
      columnName: 'NAME',
      severity: DQSeverity.error,
      message: 'Customer name must be set.',
    ),
    DQRule(
      code: 'R-CUS-002',
      tableId: customer.id,
      kind: DQKind.inSet,
      columnName: 'CURRENCY_CODE',
      values: List<String>.from(currencyCodes),
      severity: DQSeverity.warning,
      message: 'Currency must be a known ISO 4217 code.',
    ),

    // SUPPLIER_INFO_TAB
    DQRule(
      code: 'R-SUP-001',
      tableId: supplier.id,
      kind: DQKind.notNull,
      columnName: 'NAME',
      severity: DQSeverity.error,
      message: 'Supplier name must be set.',
    ),

    // INVENTORY_PART_TAB
    DQRule(
      code: 'R-PRT-001',
      tableId: part.id,
      kind: DQKind.foreignKey,
      columnName: 'CONTRACT',
      refTableName: 'SITE_TAB',
      refColumnName: 'SITE',
      severity: DQSeverity.error,
      message: 'Site (CONTRACT) must exist in IFSAPP.SITE_TAB.',
    ),

    // CUSTOMER_ORDER_TAB
    DQRule(
      code: 'R-COH-001',
      tableId: coHdr.id,
      kind: DQKind.foreignKey,
      columnName: 'CUSTOMER_NO',
      refTableName: 'CUSTOMER_INFO_TAB',
      refColumnName: 'CUSTOMER_ID',
      severity: DQSeverity.error,
      message: 'Customer must exist in IFSAPP.CUSTOMER_INFO_TAB.',
    ),
    DQRule(
      code: 'R-COH-002',
      tableId: coHdr.id,
      kind: DQKind.foreignKey,
      columnName: 'CONTRACT',
      refTableName: 'SITE_TAB',
      refColumnName: 'SITE',
      severity: DQSeverity.error,
      message: 'Site (CONTRACT) must exist in IFSAPP.SITE_TAB.',
    ),
    DQRule(
      code: 'R-COH-003',
      tableId: coHdr.id,
      kind: DQKind.datesOrdered,
      columnName: 'ORDER_DATE',
      secondColumn: 'WANTED_DELIVERY_DATE',
      severity: DQSeverity.warning,
      message: 'Order date must be on or before the wanted delivery date.',
    ),

    // CUSTOMER_ORDER_LINE_TAB
    DQRule(
      code: 'R-COL-001',
      tableId: coLine.id,
      kind: DQKind.foreignKey,
      columnName: 'ORDER_NO',
      refTableName: 'CUSTOMER_ORDER_TAB',
      refColumnName: 'ORDER_NO',
      severity: DQSeverity.error,
      message: 'Line must reference an existing customer order.',
    ),
    DQRule(
      code: 'R-COL-002',
      tableId: coLine.id,
      kind: DQKind.positive,
      columnName: 'SALE_UNIT_PRICE',
      severity: DQSeverity.warning,
      message: 'Sale unit price should be strictly positive.',
    ),

    // PURCHASE_ORDER_TAB
    DQRule(
      code: 'R-POH-001',
      tableId: poHdr.id,
      kind: DQKind.foreignKey,
      columnName: 'SUPPLIER_NO',
      refTableName: 'SUPPLIER_INFO_TAB',
      refColumnName: 'SUPPLIER_ID',
      severity: DQSeverity.error,
      message: 'Supplier must exist in IFSAPP.SUPPLIER_INFO_TAB.',
    ),
    DQRule(
      code: 'R-POH-002',
      tableId: poHdr.id,
      kind: DQKind.datesOrdered,
      columnName: 'ORDER_DATE',
      secondColumn: 'WANTED_RECEIPT_DATE',
      severity: DQSeverity.warning,
      message: 'Order date must be on or before the wanted receipt date.',
    ),

    // PURCHASE_ORDER_LINE_TAB
    DQRule(
      code: 'R-POL-001',
      tableId: poLine.id,
      kind: DQKind.foreignKey,
      columnName: 'ORDER_NO',
      refTableName: 'PURCHASE_ORDER_TAB',
      refColumnName: 'ORDER_NO',
      severity: DQSeverity.error,
      message: 'Line must reference an existing purchase order.',
    ),
    DQRule(
      code: 'R-POL-002',
      tableId: poLine.id,
      kind: DQKind.positive,
      columnName: 'BUY_UNIT_PRICE',
      severity: DQSeverity.warning,
      message: 'Buy unit price should be strictly positive.',
    ),
  ]);
}
