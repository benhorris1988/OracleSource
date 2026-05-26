import 'package:flutter/material.dart';

import '../app.dart';
import '../models/oracle_source.dart';
import 'add_schema_dialog.dart';
import 'add_table_dialog.dart';
import 'table_page.dart';

class SchemaPage extends StatelessWidget {
  const SchemaPage({super.key, required this.schemaId});

  final String schemaId;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    final schema = store.source.schemaById(schemaId);

    if (schema == null) {
      return const Scaffold(body: Center(child: Text('Schema not found')));
    }

    final tables = store.source.tablesIn(schemaId);

    return Scaffold(
      appBar: AppBar(
        title: Text(schema.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) async {
              switch (action) {
                case 'rename':
                  final updated =
                      await showDialog<({String name, String description})>(
                    context: context,
                    builder: (_) => AddSchemaDialog(
                      initialName: schema.name,
                      initialDescription: schema.description,
                    ),
                  );
                  if (updated != null) {
                    store.renameSchema(
                      schemaId,
                      updated.name,
                      description: updated.description,
                    );
                  }
                  break;
                case 'delete':
                  final confirmed = await _confirm(
                    context,
                    title: 'Delete ${schema.name}?',
                    body:
                        'This removes the schema and ${tables.length} table(s) with their synthetic data.',
                  );
                  if (confirmed && context.mounted) {
                    store.deleteSchema(schemaId);
                    Navigator.of(context).pop();
                  }
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete schema')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTable(context, schemaId),
        icon: const Icon(Icons.add),
        label: const Text('New table'),
      ),
      body: tables.isEmpty
          ? _EmptyTables(onAdd: () => _addTable(context, schemaId))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tables.length,
              itemBuilder: (_, i) => _TableCard(table: tables[i]),
            ),
    );
  }

  Future<void> _addTable(BuildContext context, String schemaId) async {
    final result = await showDialog<({String name, int rows})>(
      context: context,
      builder: (_) => const AddTableDialog(),
    );
    if (result == null || !context.mounted) return;
    final store = SourceStoreScope.of(context);
    final t = store.addTable(
      schemaId: schemaId,
      name: result.name,
      rowCountTarget: result.rows,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TablePage(tableId: t.id)),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});
  final OracleTable table;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.table_chart_outlined),
        title: Text(table.name),
        subtitle: Text(
          '${table.columns.length} columns · ${table.rows.length} rows',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TablePage(tableId: table.id)),
          );
        },
      ),
    );
  }
}

class _EmptyTables extends StatelessWidget {
  const _EmptyTables({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_chart_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'No tables in this schema',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New table'),
            ),
          ],
        ),
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
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return res ?? false;
}
