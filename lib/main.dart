import 'package:flutter/material.dart';

import 'app.dart';
import 'state/source_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SourceStore();
  await store.load();
  runApp(OracleSourceApp(store: store));
}
