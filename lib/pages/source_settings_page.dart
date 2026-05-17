import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/export.dart';

class SourceSettingsPage extends StatefulWidget {
  const SourceSettingsPage({super.key});

  @override
  State<SourceSettingsPage> createState() => _SourceSettingsPageState();
}

class _SourceSettingsPageState extends State<SourceSettingsPage> {
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _service;

  @override
  void initState() {
    super.initState();
    // initialised in didChangeDependencies once the inherited store is reachable
    _name = TextEditingController();
    _host = TextEditingController();
    _port = TextEditingController();
    _service = TextEditingController();
  }

  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    final s = SourceStoreScope.of(context).source;
    _name.text = s.name;
    _host.text = s.host;
    _port.text = s.port.toString();
    _service.text = s.serviceName;
    _initialised = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Source settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    onChanged: (v) => store.updateSourceMeta(name: v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _host,
                    decoration: const InputDecoration(labelText: 'Host'),
                    onChanged: (v) => store.updateSourceMeta(host: v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _port,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Port'),
                          onChanged: (v) => store.updateSourceMeta(
                              port: int.tryParse(v) ?? 1521),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _service,
                          decoration:
                              const InputDecoration(labelText: 'Service name'),
                          onChanged: (v) =>
                              store.updateSourceMeta(serviceName: v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export full SQL script'),
                  subtitle: const Text('CREATE USER, CREATE TABLE, INSERT statements'),
                  onTap: () {
                    final sql = exportSourceSql(store.source);
                    Clipboard.setData(ClipboardData(text: sql));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SQL copied to clipboard')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.restart_alt,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Reset to default seed'),
                  subtitle:
                      const Text('Discards your edits and reloads HR + SALES'),
                  onTap: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Reset to default?',
                      body: 'All schemas, tables and rows you added will be lost.',
                    );
                    if (ok) await store.resetToDefault();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  return res ?? false;
}
