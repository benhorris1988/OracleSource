import '../models/oracle_source.dart';
import '../models/oracle_type.dart';

/// Mulberry32 — small, fast, seedable PRNG (port of the JS routine used in
/// the ConnectorExpenses reference). Deterministic per seed so regenerating
/// a table reproduces the same rows.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  double nextDouble() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _state;
    t = _imul(t ^ (t >>> 15), t | 1) & 0xFFFFFFFF;
    t = (t ^ (t + _imul(t ^ (t >>> 7), t | 61))) & 0xFFFFFFFF;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 0x100000000;
  }

  int nextInt(int lo, int hi) => lo + (nextDouble() * (hi - lo + 1)).floor();

  T pick<T>(List<T> list) => list[(nextDouble() * list.length).floor()];

  bool chance(double p) => nextDouble() < p;
}

int _imul(int a, int b) {
  final int aHi = (a >>> 16) & 0xFFFF;
  final int aLo = a & 0xFFFF;
  final int bHi = (b >>> 16) & 0xFFFF;
  final int bLo = b & 0xFFFF;
  return ((aLo * bLo) + (((aHi * bLo + aLo * bHi) & 0xFFFF) << 16)) & 0xFFFFFFFF;
}

const _firstNames = [
  'James', 'Mary', 'Robert', 'Patricia', 'John', 'Jennifer', 'Michael',
  'Linda', 'David', 'Elizabeth', 'William', 'Barbara', 'Richard', 'Susan',
  'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Christopher', 'Karen',
  'Anjali', 'Ravi', 'Wei', 'Yuki', 'Olu', 'Chioma', 'Mateo', 'Sofia',
];
const _lastNames = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
  'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
  'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
  'Patel', 'Nguyen', 'Kumar', 'Singh', 'Chen', 'Wang', 'Kim', 'Okafor',
];
const _cities = [
  'London', 'Manchester', 'Berlin', 'Munich', 'Paris', 'Lyon',
  'New York', 'Chicago', 'San Francisco', 'Toronto', 'Sydney', 'Singapore',
  'Mumbai', 'Bangalore', 'Tokyo', 'Seoul', 'Lagos', 'São Paulo',
];
const _countries = [
  'GB', 'US', 'DE', 'FR', 'IN', 'JP', 'AU', 'CA', 'BR', 'NG', 'SG', 'KR',
];
const _departments = [
  'Engineering', 'Sales', 'Marketing', 'Finance', 'HR', 'Operations',
  'Customer Success', 'Research', 'Legal', 'IT', 'Procurement', 'Logistics',
];
const _jobTitles = [
  'Engineer', 'Senior Engineer', 'Manager', 'Director', 'VP', 'Analyst',
  'Specialist', 'Coordinator', 'Architect', 'Lead', 'Principal', 'Assistant',
];
const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD'];
const _statuses = ['ACTIVE', 'INACTIVE', 'PENDING', 'CLOSED'];

dynamic _synthValue(OracleColumn col, SeededRandom r, int rowIdx) {
  final hint = (col.synthHint ?? _inferHint(col.name)).toLowerCase();

  switch (hint) {
    case 'first_name':
      return r.pick(_firstNames);
    case 'last_name':
      return r.pick(_lastNames);
    case 'full_name':
      return '${r.pick(_firstNames)} ${r.pick(_lastNames)}';
    case 'email':
      final first = r.pick(_firstNames).toLowerCase();
      final last = r.pick(_lastNames).toLowerCase();
      return '$first.$last@example.com';
    case 'phone':
      return '+${r.nextInt(1, 99)}-${r.nextInt(100, 999)}-${r.nextInt(1000, 9999)}';
    case 'city':
      return r.pick(_cities);
    case 'country':
      return r.pick(_countries);
    case 'department':
      return r.pick(_departments);
    case 'job_title':
      return r.pick(_jobTitles);
    case 'currency':
      return r.pick(_currencies);
    case 'status':
      return r.pick(_statuses);
    case 'salary':
      return (30000 + r.nextInt(0, 220) * 1000).toDouble();
    case 'amount':
      return double.parse((r.nextDouble() * 10000).toStringAsFixed(2));
    case 'sequence':
      return rowIdx + 1;
    case 'boolean':
    case 'flag':
      return r.chance(0.5) ? 1 : 0;
  }

  switch (col.type) {
    case OracleType.integer:
      return r.nextInt(1, 100000);
    case OracleType.number:
      final scale = col.scale ?? 2;
      return double.parse((r.nextDouble() * 1000).toStringAsFixed(scale));
    case OracleType.varchar2:
    case OracleType.char:
    case OracleType.clob:
      final len = col.length ?? 16;
      final target = (len / 6).clamp(1, 6).toInt();
      final words = List.generate(target, (_) => r.pick(_lastNames)).join(' ');
      return words.length > len ? words.substring(0, len) : words;
    case OracleType.date:
    case OracleType.timestamp:
      final daysBack = r.nextInt(0, 365 * 5);
      final dt = DateTime.utc(2026, 1, 1).subtract(Duration(days: daysBack));
      return dt.toIso8601String();
    case OracleType.boolean:
      return r.chance(0.5) ? 1 : 0;
    case OracleType.raw:
    case OracleType.blob:
      return '0x${r.nextInt(0, 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}

String _inferHint(String columnName) {
  final n = columnName.toUpperCase();
  if (n.contains('FIRST_NAME') || n == 'FNAME') return 'first_name';
  if (n.contains('LAST_NAME') || n == 'LNAME') return 'last_name';
  if (n == 'NAME' || n.contains('FULL_NAME')) return 'full_name';
  if (n.contains('EMAIL')) return 'email';
  if (n.contains('PHONE')) return 'phone';
  if (n.contains('CITY')) return 'city';
  if (n.contains('COUNTRY')) return 'country';
  if (n.contains('DEPARTMENT') || n.contains('DEPT')) return 'department';
  if (n.contains('JOB') || n.contains('TITLE')) return 'job_title';
  if (n.contains('CURRENCY')) return 'currency';
  if (n.contains('STATUS')) return 'status';
  if (n.contains('SALARY')) return 'salary';
  if (n.contains('AMOUNT') || n.contains('PRICE') || n.contains('TOTAL')) {
    return 'amount';
  }
  if (n.endsWith('_ID') || n == 'ID') return 'sequence';
  if (n.startsWith('IS_') || n.startsWith('HAS_') || n.endsWith('_FLAG')) {
    return 'boolean';
  }
  return '';
}

/// Replace `table.rows` with newly synthesized data based on its columns,
/// row target and seed.
void synthesizeRows(OracleTable table) {
  final seed = table.synthSeed ?? table.name.hashCode;
  final rnd = SeededRandom(seed);
  final newRows = <Map<String, dynamic>>[];

  final pkCols = table.columns.where((c) => c.primaryKey).toList();

  for (int i = 0; i < table.rowCountTarget; i++) {
    final row = <String, dynamic>{};
    for (final col in table.columns) {
      if (col.primaryKey && pkCols.length == 1) {
        row[col.name] = i + 1;
        continue;
      }
      if (col.nullable && rnd.chance(0.04)) {
        row[col.name] = null;
        continue;
      }
      row[col.name] = _synthValue(col, rnd, i);
    }
    newRows.add(row);
  }

  table.rows = newRows;
}
