import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/export.dart';
import '../models/oracle_source.dart';
import 'add_table_dialog.dart';
import 'column_editor.dart';

class TablePage extends StatelessWidget {
  const TablePage({super.key, required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    final table = store.tableById(tableId);
    if (table == null) {
      return const Scaffold(body: Center(child: Text('Table not found')));
    }
    final schema = store.source.schemaById(table.schemaId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${schema?.name ?? ''}.${table.name}'),
          actions: [
            IconButton(
              tooltip: 'Regenerate data',
              icon: const Icon(Icons.auto_fix_high_outlined),
              onPressed: () {
                store.regenerateRows(tableId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Regenerated ${table.rowCountTarget} rows')),
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (action) async {
                switch (action) {
                  case 'edit':
                    final res = await showDialog<({String name, int rows})>(
                      context: context,
                      builder: (_) => AddTableDialog(
                        initialName: table.name,
                        initialRows: table.rowCountTarget,
                      ),
                    );
                    if (res != null) {
                      store.updateTable(
                        tableId,
                        name: res.name,
                        rowCountTarget: res.rows,
                      );
                    }
                    break;
                  case 'export':
                    if (!context.mounted) return;
                    _showSql(context, exportTableSql(store.source, table));
                    break;
                  case 'delete':
                    final ok = await _confirm(
                      context,
                      title: 'Delete ${table.name}?',
                      body: 'This deletes the table and its synthetic rows.',
                    );
                    if (ok && context.mounted) {
                      store.deleteTable(tableId);
                      Navigator.of(context).pop();
                    }
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit table')),
                PopupMenuItem(value: 'export', child: Text('Export SQL')),
                PopupMenuItem(value: 'delete', child: Text('Delete table')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.view_column_outlined), text: 'Columns'),
              Tab(icon: Icon(Icons.grid_on_outlined), text: 'Data'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ColumnsTab(table: table),
            _DataTab(table: table),
          ],
        ),
      ),
    );
  }
}

class _ColumnsTab extends StatelessWidget {
  const _ColumnsTab({required this.table});
  final OracleTable table;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    return Scaffold(
      body: table.columns.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_column_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No columns yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _addColumn(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add column'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: table.columns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final c = table.columns[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.primaryKey
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: c.primaryKey
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                      child: Icon(
                        c.primaryKey ? Icons.key : Icons.label_outline,
                        size: 18,
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text(_subtitleFor(c)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editColumn(context, c),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await _confirm(
                              context,
                              title: 'Drop column ${c.name}?',
                              body:
                                  'Removes the column and its values from existing rows.',
                            );
                            if (ok && context.mounted) {
                              store.deleteColumn(table.id, c.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: table.columns.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addColumn(context),
              icon: const Icon(Icons.add),
              label: const Text('Add column'),
            ),
    );
  }

  String _subtitleFor(OracleColumn c) {
    final flags = [
      if (!c.nullable) 'NOT NULL',
      if (c.primaryKey) 'PK',
      if (c.unique && !c.primaryKey) 'UNIQUE',
      if (c.synthHint != null && c.synthHint!.isNotEmpty) 'synth=${c.synthHint}',
    ];
    final base = c.renderType();
    return flags.isEmpty ? base : '$base · ${flags.join(' · ')}';
  }

  Future<void> _addColumn(BuildContext context) async {
    final col = await showDialog<OracleColumn>(
      context: context,
      builder: (_) => const ColumnEditorDialog(),
    );
    if (col == null || !context.mounted) return;
    SourceStoreScope.of(context).addColumn(table.id, col);
  }

  Future<void> _editColumn(BuildContext context, OracleColumn existing) async {
    final updated = await showDialog<OracleColumn>(
      context: context,
      builder: (_) => ColumnEditorDialog(initial: existing),
    );
    if (updated == null || !context.mounted) return;
    SourceStoreScope.of(context).updateColumn(table.id, updated);
  }
}

class _DataTab extends StatelessWidget {
  const _DataTab({required this.table});
  final OracleTable table;

  @override
  Widget build(BuildContext context) {
    final store = SourceStoreScope.of(context);
    if (table.columns.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Add columns first, then regenerate data.'),
        ),
      );
    }
    if (table.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dataset_outlined, size: 48),
              const SizedBox(height: 12),
              Text('No rows. Try regenerating.',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => store.regenerateRows(table.id),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: Text('Generate ${table.rowCountTarget} rows'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 24,
              columns: [
                const DataColumn(label: Text('#')),
                ...table.columns.map(
                  (c) => DataColumn(
                    label: Tooltip(
                      message: c.renderType(),
                      child: Text(c.name),
                    ),
                  ),
                ),
                const DataColumn(label: Text('')),
              ],
              rows: [
                for (int i = 0; i < table.rows.length; i++)
                  DataRow(
                    cells: [
                      DataCell(Text('${i + 1}')),
                      ...table.columns.map((c) => DataCell(
                            _CellText(value: table.rows[i][c.name]),
                            onTap: () => _editCell(context, i, c),
                          )),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => store.deleteRow(table.id, i),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => store.addEmptyRow(table.id),
        icon: const Icon(Icons.add),
        label: const Text('Add row'),
      ),
    );
  }

  Future<void> _editCell(BuildContext context, int rowIdx, OracleColumn col) async {
    final store = SourceStoreScope.of(context);
    final current = table.rows[rowIdx][col.name];
    final controller = TextEditingController(text: current?.toString() ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${col.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: col.renderType(),
            hintText: col.nullable ? '(leave empty for NULL)' : '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null) return;
    final parsed = _parseValue(res, col);
    store.updateCell(table.id, rowIdx, col.name, parsed);
  }

  dynamic _parseValue(String raw, OracleColumn col) {
    if (raw.isEmpty) return null;
    switch (col.type) {
      case OracleType.integer:
        return int.tryParse(raw) ?? raw;
      case OracleType.number:
        return double.tryParse(raw) ?? raw;
      case OracleType.boolean:
        final lower = raw.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'y') return 1;
        if (lower == 'false' || lower == '0' || lower == 'n') return 0;
        return raw;
      default:
        return raw;
    }
  }
}

class _CellText extends StatelessWidget {
  const _CellText({required this.value});
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text(
        'NULL',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Text(
        value.toString(),
        overflow: TextOverflow.ellipsis,
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

void _showSql(BuildContext context, String sql) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Generated SQL')),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_all_outlined),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sql));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    sql,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
