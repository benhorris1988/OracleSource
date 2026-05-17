import 'package:flutter/material.dart';

import '../models/dq_rule.dart';
import '../models/oracle_source.dart';

class RuleEditorDialog extends StatefulWidget {
  const RuleEditorDialog({
    super.key,
    required this.table,
    required this.allTables,
    this.initial,
  });

  final OracleTable table;
  final List<OracleTable> allTables;
  final DQRule? initial;

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  late final TextEditingController _code;
  late final TextEditingController _message;
  late final TextEditingController _pattern;
  late final TextEditingController _values;
  late final TextEditingController _min;
  late final TextEditingController _max;

  late DQKind _kind;
  late DQSeverity _severity;
  late String _column;
  String? _secondColumn;
  String? _refTableName;
  String? _refColumnName;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _code = TextEditingController(text: r?.code ?? _suggestCode());
    _message = TextEditingController(text: r?.message ?? '');
    _pattern = TextEditingController(text: r?.pattern ?? '');
    _values = TextEditingController(text: r?.values.join(', ') ?? '');
    _min = TextEditingController(text: r?.min?.toString() ?? '');
    _max = TextEditingController(text: r?.max?.toString() ?? '');
    _kind = r?.kind ?? DQKind.notNull;
    _severity = r?.severity ?? DQSeverity.error;
    _column = r?.columnName ??
        (widget.table.columns.isNotEmpty ? widget.table.columns.first.name : '');
    _secondColumn = r?.secondColumn;
    _refTableName = r?.refTableName;
    _refColumnName = r?.refColumnName;
  }

  String _suggestCode() {
    final prefix = widget.table.name.length >= 4
        ? widget.table.name.substring(0, 4)
        : widget.table.name;
    return 'V-$prefix-001';
  }

  @override
  void dispose() {
    _code.dispose();
    _message.dispose();
    _pattern.dispose();
    _values.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.table.columns;
    return AlertDialog(
      title: Text(widget.initial == null ? 'New rule' : 'Edit rule'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Rule code',
                    hintText: 'e.g. V-CUST-001',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DQKind>(
                  value: _kind,
                  decoration: const InputDecoration(labelText: 'Kind'),
                  items: DQKind.values
                      .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _kind = v ?? _kind),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cols.any((c) => c.name == _column) ? _column : null,
                  decoration: const InputDecoration(labelText: 'Column'),
                  items: cols
                      .map((c) => DropdownMenuItem(
                            value: c.name,
                            child: Text('${c.name}  ${c.renderType()}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _column = v ?? _column),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                if (_kind == DQKind.datesOrdered) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cols.any((c) => c.name == _secondColumn)
                        ? _secondColumn
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Second column (must be ≥ first)',
                    ),
                    items: cols
                        .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _secondColumn = v),
                  ),
                ],
                if (_kind == DQKind.foreignKey) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: widget.allTables.any((t) => t.name == _refTableName)
                        ? _refTableName
                        : null,
                    decoration:
                        const InputDecoration(labelText: 'Referenced table'),
                    items: widget.allTables
                        .where((t) => t.id != widget.table.id)
                        .map((t) => DropdownMenuItem(
                              value: t.name,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _refTableName = v;
                      _refColumnName = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (_) {
                    final refTable = widget.allTables
                        .where((t) => t.name == _refTableName)
                        .firstOrNull;
                    final refCols = refTable?.columns ?? const <OracleColumn>[];
                    return DropdownButtonFormField<String>(
                      value: refCols.any((c) => c.name == _refColumnName)
                          ? _refColumnName
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Referenced column',
                      ),
                      items: refCols
                          .map((c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _refColumnName = v),
                    );
                  }),
                ],
                if (_kind == DQKind.regex) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pattern,
                    decoration: const InputDecoration(
                      labelText: 'Pattern',
                      hintText: r'^[A-Z]{2}[A-Z0-9]+$',
                    ),
                  ),
                ],
                if (_kind == DQKind.inSet) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _values,
                    decoration: const InputDecoration(
                      labelText: 'Allowed values (comma-separated)',
                      hintText: 'GB, US, DE, FR',
                    ),
                    maxLines: 2,
                  ),
                ],
                if (_kind == DQKind.range) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _min,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(labelText: 'Min'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _max,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(labelText: 'Max'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<DQSeverity>(
                  value: _severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: DQSeverity.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _severity = v ?? _severity),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _message,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Shown when the rule is violated',
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final rule = DQRule(
              id: widget.initial?.id,
              code: _code.text.trim(),
              tableId: widget.table.id,
              kind: _kind,
              columnName: _column,
              secondColumn: _secondColumn,
              refTableName: _refTableName,
              refColumnName: _refColumnName,
              values: _values.text
                  .split(RegExp(r'[,\n]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
              pattern: _pattern.text.trim().isEmpty ? null : _pattern.text.trim(),
              min: double.tryParse(_min.text.trim()),
              max: double.tryParse(_max.text.trim()),
              severity: _severity,
              message: _message.text.trim(),
            );
            Navigator.of(context).pop(rule);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
