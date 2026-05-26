import 'dart:convert';

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
  late final TextEditingController _user;
  late final TextEditingController _pwd;
  late final TextEditingController _ownerUser;
  late final TextEditingController _company;
  late final TextEditingController _site;
  late final TextEditingController _currency;

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _host = TextEditingController();
    _port = TextEditingController();
    _service = TextEditingController();
    _user = TextEditingController();
    _pwd = TextEditingController();
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
    _user.text = s.username;
    _pwd.text = s.password;
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
    _user.dispose();
    _pwd.dispose();
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
          // -- Connection -----------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Connection',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'These are the values external consumers (BI tools, '
                    'ETL jobs, Connector services) use to reach the Oracle '
                    'container.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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

          // -- Credentials ----------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Credentials',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Used in the exported CREATE USER DDL and by the Docker '
                    'container at startup. Anything connecting to extract '
                    'data uses this username / password.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _user,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      helperText: 'Oracle login (typically the schema owner)',
                    ),
                    onChanged: (v) =>
                        store.updateSourceMeta(username: v.toUpperCase()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pwd,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText:
                          'Stored in shared_preferences + exported to config/source.json',
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        tooltip: _showPassword ? 'Hide' : 'Show',
                      ),
                    ),
                    onChanged: (v) => store.updateSourceMeta(password: v),
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final src = store.source;
                    final jdbc =
                        'jdbc:oracle:thin:${src.username}/${src.password}@//${src.host}:${src.port}/${src.serviceName}';
                    return _ConnectionStringBlock(jdbc: jdbc);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Identity anchors -----------------------------------------------
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

          // -- Export + reset -------------------------------------------------
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Copy config/source.json'),
                  subtitle: const Text(
                      'Paste into the project file so Docker + consumers pick up your changes'),
                  onTap: () {
                    final json = const JsonEncoder.withIndent('  ')
                        .convert(_sourceConfigJson(store.source));
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'config/source.json copied to clipboard')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Copy seed SQL (DDL + INSERTs)'),
                  subtitle: const Text(
                      'Paste into docker/init/01_seed.sql so Oracle loads it on startup'),
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

/// Inline read-only JDBC string display with a copy button. Keeps the
/// `jdbc:oracle:thin:` form so consumers can paste it straight into their
/// connection settings.
class _ConnectionStringBlock extends StatelessWidget {
  const _ConnectionStringBlock({required this.jdbc});
  final String jdbc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              jdbc,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy JDBC URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jdbc));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JDBC URL copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Just the connection metadata + identity anchors + credentials, formatted
/// to match the checked-in `config/source.json`. The (much larger) schema /
/// table / row / rule definitions stay in shared_preferences only.
Map<String, dynamic> _sourceConfigJson(source) => {
      'name': source.name,
      'host': source.host,
      'port': source.port,
      'serviceName': source.serviceName,
      'username': source.username,
      'password': source.password,
      'ownerUser': source.ownerUser,
      'companyCode': source.companyCode,
      'defaultSite': source.defaultSite,
      'defaultCurrency': source.defaultCurrency,
    };

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
