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
  late final TextEditingController _ownerUser;
  late final TextEditingController _company;
  late final TextEditingController _site;
  late final TextEditingController _currency;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _host = TextEditingController();
    _port = TextEditingController();
    _service = TextEditingController();
    _ownerUser = TextEditingController();
    _company = TextEditingController();
    _site = TextEditingController();
    _currency = TextEditingController();
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
    _ownerUser.text = s.ownerUser;
    _company.text = s.companyCode;
    _site.text = s.defaultSite;
    _currency.text = s.defaultCurrency;
    _initialised = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _service.dispose();
    _ownerUser.dispose();
    _company.dispose();
    _site.dispose();
    _currency.dispose();
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
                  Text('Connection',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Display name'),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('IFS identity',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'These anchor values shape generated data. Change them and '
                    'tap "Regenerate all data" to refill every table.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerUser,
                    decoration: const InputDecoration(
                      labelText: 'Owner user',
                      helperText:
                          'IFSAPP-style schema owner. Used for OWNER_USER, CREATED_BY, BUYER_CODE, …',
                    ),
                    onChanged: (v) =>
                        store.updateSourceMeta(ownerUser: v.toUpperCase()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _company,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            helperText: 'COMPANY anchor (e.g. 10)',
                          ),
                          onChanged: (v) =>
                              store.updateSourceMeta(companyCode: v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _site,
                          decoration: const InputDecoration(
                            labelText: 'Site / Contract',
                            helperText: 'e.g. S001',
                          ),
                          onChanged: (v) =>
                              store.updateSourceMeta(defaultSite: v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            helperText: 'ISO 4217',
                          ),
                          onChanged: (v) => store.updateSourceMeta(
                              defaultCurrency: v.toUpperCase()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Regenerate all data'),
                    onPressed: () async {
                      await store.regenerateAll();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Re-synthesized every table using current anchors')),
                      );
                    },
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
                  subtitle: const Text(
                      'CREATE USER, CREATE TABLE, INSERT statements'),
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
                  subtitle: const Text(
                      'Discards your edits and reloads the IFSAPP sample schema'),
                  onTap: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Reset to default?',
                      body:
                          'All schemas, tables and rows you added will be lost.',
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
