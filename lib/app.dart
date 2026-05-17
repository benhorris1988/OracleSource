import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'state/source_store.dart';

class OracleSourceApp extends StatefulWidget {
  const OracleSourceApp({super.key, required this.store});

  final SourceStore store;

  @override
  State<OracleSourceApp> createState() => _OracleSourceAppState();
}

class _OracleSourceAppState extends State<OracleSourceApp> {
  ThemeMode _mode = ThemeMode.system;

  void _toggleMode() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFFC74634); // Oracle red-ish accent.
    return MaterialApp(
      title: 'Oracle Source',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SourceStoreScope(
        store: widget.store,
        child: HomePage(onToggleTheme: _toggleMode),
      ),
    );
  }
}

/// Inherited widget that exposes the store + repaints children when it
/// changes. Simpler than pulling in a state-management package.
class SourceStoreScope extends StatefulWidget {
  const SourceStoreScope({
    super.key,
    required this.store,
    required this.child,
  });

  final SourceStore store;
  final Widget child;

  static SourceStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SourceStoreInherited>();
    assert(scope != null, 'SourceStoreScope missing in widget tree');
    return scope!.store;
  }

  @override
  State<SourceStoreScope> createState() => _SourceStoreScopeState();
}

class _SourceStoreScopeState extends State<SourceStoreScope> {
  int _version = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_bump);
  }

  @override
  void dispose() {
    widget.store.removeListener(_bump);
    super.dispose();
  }

  void _bump() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    return _SourceStoreInherited(
      store: widget.store,
      version: _version,
      child: widget.child,
    );
  }
}

class _SourceStoreInherited extends InheritedWidget {
  const _SourceStoreInherited({
    required this.store,
    required this.version,
    required super.child,
  });

  final SourceStore store;
  final int version;

  @override
  bool updateShouldNotify(_SourceStoreInherited oldWidget) =>
      version != oldWidget.version;
}
