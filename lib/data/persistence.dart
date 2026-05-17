import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/oracle_source.dart';

class SourcePersistence {
  static const _key = 'oracle_source_v1';

  Future<OracleSource?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OracleSource.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(OracleSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(source.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
