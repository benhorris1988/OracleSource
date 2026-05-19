import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oracle_source/app.dart';
import 'package:oracle_source/state/source_store.dart';

void main() {
  testWidgets('App boots and shows the schemas home page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SourceStore();
    await store.load();

    await tester.pumpWidget(OracleSourceApp(store: store));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
