import 'package:flutter/material.dart';

import '../app.dart';
import '../models/oracle_source.dart';
import 'add_schema_dialog.dart';
import 'schema_page.dart';
import 'source_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    final source = store.source;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.storage_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text(source.name),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: onToggleTheme,
          ),
          IconButton(
            tooltip: 'Source settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SourceSettingsPage(),
              ));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSchema(context),
        icon: const Icon(Icons.add),
        label: const Text('New schema'),
      ),
      body: source.schemas.isEmpty
          ? _EmptyState(onAdd: () => _addSchema(context))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ConnectionCard(source: source),
                const SizedBox(height: 16),
                Text(
                  'Schemas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...source.schemas.map((s) => _SchemaCard(schema: s)),
              ],
            ),
    );
  }

  Future<void> _addSchema(BuildContext context) async {
    final result = await showDialog<({String name, String description})>(
      context: context,
      builder: (_) => const AddSchemaDialog(),
    );
    if (result == null) return;
    if (!context.mounted) return;
    SourceStoreScope.of(context).addSchema(
      name: result.name,
      description: result.description,
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.source});
  final OracleSource source;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lan_outlined),
        title: Text('${source.host}:${source.port}/${source.serviceName}'),
        subtitle: Text(
          '${source.schemas.length} schemas · ${source.tables.length} tables',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SourceSettingsPage(),
          ));
        },
      ),
    );
  }
}

class _SchemaCard extends StatelessWidget {
  const _SchemaCard({required this.schema});
  final OracleSchema schema;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    final tableCount = store.source.tablesIn(schema.id).length;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            schema.name.isEmpty ? '?' : schema.name[0],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(schema.name),
        subtitle: Text(
          schema.description.isEmpty
              ? '$tableCount tables'
              : '${schema.description} · $tableCount tables',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SchemaPage(schemaId: schema.id),
          ));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dataset_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'No schemas yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a schema to start defining tables and synthetic rows.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New schema'),
            ),
          ],
        ),
      ),
    );
  }
}
