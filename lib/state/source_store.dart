import 'package:flutter/foundation.dart';

import '../data/persistence.dart';
import '../data/seed.dart';
import '../data/synth.dart';
import '../models/dq_rule.dart';
import '../models/oracle_source.dart';

class SourceStore extends ChangeNotifier {
  SourceStore({SourcePersistence? persistence})
      : _persistence = persistence ?? SourcePersistence();

  final SourcePersistence _persistence;

  OracleSource? _source;
  OracleSource get source {
    final s = _source;
    if (s == null) {
      throw StateError('SourceStore.load() must complete before use');
    }
    return s;
  }

  bool get isLoaded => _source != null;

  Future<void> load() async {
    _source = await _persistence.load() ?? buildDefaultSource();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_source != null) await _persistence.save(_source!);
  }

  // -- Source-level ---------------------------------------------------------

  void updateSourceMeta({
    String? name,
    String? host,
    int? port,
    String? serviceName,
    String? ownerUser,
    String? companyCode,
    String? defaultSite,
    String? defaultCurrency,
  }) {
    final s = source;
    if (name != null) s.name = name;
    if (host != null) s.host = host;
    if (port != null) s.port = port;
    if (serviceName != null) s.serviceName = serviceName;
    if (ownerUser != null) s.ownerUser = ownerUser;
    if (companyCode != null) s.companyCode = companyCode;
    if (defaultSite != null) s.defaultSite = defaultSite;
    if (defaultCurrency != null) s.defaultCurrency = defaultCurrency;
    notifyListeners();
    _persist();
  }

  Future<void> resetToDefault() async {
    _source = buildDefaultSource();
    await _persist();
    notifyListeners();
  }

  // -- Schemas --------------------------------------------------------------

  OracleSchema addSchema({required String name, String description = ''}) {
    final s = OracleSchema(name: name.toUpperCase(), description: description);
    source.schemas.add(s);
    notifyListeners();
    _persist();
    return s;
  }

  void renameSchema(String id, String name, {String? description}) {
    final s = source.schemaById(id);
    if (s == null) return;
    s.name = name.toUpperCase();
    if (description != null) s.description = description;
    notifyListeners();
    _persist();
  }

  void deleteSchema(String id) {
    source.schemas.removeWhere((s) => s.id == id);
    source.tables.removeWhere((t) => t.schemaId == id);
    notifyListeners();
    _persist();
  }

  // -- Tables ---------------------------------------------------------------

  OracleTable addTable({
    required String schemaId,
    required String name,
    int rowCountTarget = 50,
    List<OracleColumn>? columns,
  }) {
    final t = OracleTable(
      schemaId: schemaId,
      name: name.toUpperCase(),
      rowCountTarget: rowCountTarget,
      columns: columns ?? [],
    );
    source.tables.add(t);
    notifyListeners();
    _persist();
    return t;
  }

  void deleteTable(String tableId) {
    source.tables.removeWhere((t) => t.id == tableId);
    notifyListeners();
    _persist();
  }

  void updateTable(
    String tableId, {
    String? name,
    int? rowCountTarget,
    int? synthSeed,
  }) {
    final t = source.tables.where((t) => t.id == tableId).firstOrNull;
    if (t == null) return;
    if (name != null) t.name = name.toUpperCase();
    if (rowCountTarget != null) t.rowCountTarget = rowCountTarget;
    if (synthSeed != null) t.synthSeed = synthSeed;
    notifyListeners();
    _persist();
  }

  OracleTable? tableById(String id) =>
      source.tables.where((t) => t.id == id).firstOrNull;

  // -- Columns --------------------------------------------------------------

  void addColumn(String tableId, OracleColumn column) {
    final t = tableById(tableId);
    if (t == null) return;
    t.columns.add(column);
    for (final row in t.rows) {
      row.putIfAbsent(column.name, () => null);
    }
    notifyListeners();
    _persist();
  }

  void updateColumn(String tableId, OracleColumn updated) {
    final t = tableById(tableId);
    if (t == null) return;
    final idx = t.columns.indexWhere((c) => c.id == updated.id);
    if (idx < 0) return;
    final old = t.columns[idx];
    t.columns[idx] = updated;
    if (old.name != updated.name) {
      for (final row in t.rows) {
        if (row.containsKey(old.name)) {
          row[updated.name] = row.remove(old.name);
        }
      }
    }
    notifyListeners();
    _persist();
  }

  void deleteColumn(String tableId, String columnId) {
    final t = tableById(tableId);
    if (t == null) return;
    final col = t.columns.where((c) => c.id == columnId).firstOrNull;
    if (col == null) return;
    t.columns.removeWhere((c) => c.id == columnId);
    for (final row in t.rows) {
      row.remove(col.name);
    }
    notifyListeners();
    _persist();
  }

  // -- Rows -----------------------------------------------------------------

  void regenerateRows(String tableId) {
    final t = tableById(tableId);
    if (t == null) return;
    synthesizeRows(t, anchors: SynthAnchors.fromSource(source));
    notifyListeners();
    _persist();
  }

  /// Re-synthesize every table in the source using the current identity
  /// anchors. Use this after editing owner / company / site / currency on
  /// the source settings so generated data picks up the new values.
  Future<void> regenerateAll() async {
    final anchors = SynthAnchors.fromSource(source);
    for (final t in source.tables) {
      synthesizeRows(t, anchors: anchors);
    }
    notifyListeners();
    await _persist();
  }

  void addEmptyRow(String tableId) {
    final t = tableById(tableId);
    if (t == null) return;
    final row = <String, dynamic>{for (final c in t.columns) c.name: null};
    t.rows.add(row);
    notifyListeners();
    _persist();
  }

  void updateCell(String tableId, int rowIdx, String columnName, dynamic value) {
    final t = tableById(tableId);
    if (t == null) return;
    if (rowIdx < 0 || rowIdx >= t.rows.length) return;
    t.rows[rowIdx][columnName] = value;
    notifyListeners();
    _persist();
  }

  void deleteRow(String tableId, int rowIdx) {
    final t = tableById(tableId);
    if (t == null) return;
    if (rowIdx < 0 || rowIdx >= t.rows.length) return;
    t.rows.removeAt(rowIdx);
    notifyListeners();
    _persist();
  }

  // -- DQ rules -------------------------------------------------------------

  List<DQRule> rulesFor(String tableId) => source.rulesFor(tableId);

  void addRule(DQRule rule) {
    source.rules.add(rule);
    notifyListeners();
    _persist();
  }

  void updateRule(DQRule rule) {
    final idx = source.rules.indexWhere((r) => r.id == rule.id);
    if (idx < 0) return;
    source.rules[idx] = rule;
    notifyListeners();
    _persist();
  }

  void deleteRule(String ruleId) {
    source.rules.removeWhere((r) => r.id == ruleId);
    notifyListeners();
    _persist();
  }
}

