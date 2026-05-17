import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/oracle_source.dart';
import '../models/oracle_type.dart';

class ColumnEditorDialog extends StatefulWidget {
  const ColumnEditorDialog({super.key, this.initial});

  /// Pass an existing column to edit, or null to create a new one.
  final OracleColumn? initial;

  @override
  State<ColumnEditorDialog> createState() => _ColumnEditorDialogState();
}

class _ColumnEditorDialogState extends State<ColumnEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _length;
  late final TextEditingController _precision;
  late final TextEditingController _scale;
  late final TextEditingController _defaultValue;
  late final TextEditingController _synthHint;

  late OracleType _type;
  late bool _nullable;
  late bool _primaryKey;
  late bool _unique;

  final _formKey = GlobalKey<FormState>();

  static const _hintOptions = <String>[
    '',
    'first_name',
    'last_name',
    'full_name',
    'email',
    'phone',
    'city',
    'country',
    'department',
    'job_title',
    'currency',
    'status',
    'salary',
    'amount',
    'sequence',
    'boolean',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c?.name ?? '');
    _length = TextEditingController(text: c?.length?.toString() ?? '');
    _precision = TextEditingController(text: c?.precision?.toString() ?? '');
    _scale = TextEditingController(text: c?.scale?.toString() ?? '');
    _defaultValue = TextEditingController(text: c?.defaultValue ?? '');
    _synthHint = TextEditingController(text: c?.synthHint ?? '');
    _type = c?.type ?? OracleType.varchar2;
    _nullable = c?.nullable ?? true;
    _primaryKey = c?.primaryKey ?? false;
    _unique = c?.unique ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _precision.dispose();
    _scale.dispose();
    _defaultValue.dispose();
    _synthHint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New column' : 'Edit column'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Column name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(v.trim())) {
                      return 'Letters, digits, underscores; start with a letter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<OracleType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: OracleType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.sqlName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                if (_type.takesLength) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _length,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Length'),
                  ),
                ],
                if (_type.takesPrecisionScale) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _precision,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Precision'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _scale,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Scale'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _hintOptions.contains(_synthHint.text)
                      ? _synthHint.text
                      : '',
                  decoration: const InputDecoration(
                    labelText: 'Synth hint',
                    helperText: 'Steers fake-data generation for this column',
                  ),
                  items: _hintOptions
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(h.isEmpty ? 'auto (infer from name)' : h),
                          ))
                      .toList(),
                  onChanged: (v) => _synthHint.text = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _defaultValue,
                  decoration: const InputDecoration(
                    labelText: 'Default (optional)',
                    hintText: "e.g. 'ACTIVE' or SYSDATE",
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nullable'),
                  value: _nullable,
                  onChanged: (v) => setState(() => _nullable = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Primary key'),
                  value: _primaryKey,
                  onChanged: (v) => setState(() {
                    _primaryKey = v;
                    if (v) _nullable = false;
                  }),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Unique'),
                  value: _unique,
                  onChanged: (v) => setState(() => _unique = v),
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
            final result = OracleColumn(
              id: widget.initial?.id,
              name: _name.text.trim().toUpperCase(),
              type: _type,
              length: int.tryParse(_length.text.trim()),
              precision: int.tryParse(_precision.text.trim()),
              scale: int.tryParse(_scale.text.trim()),
              nullable: _nullable,
              primaryKey: _primaryKey,
              unique: _unique,
              defaultValue: _defaultValue.text.trim().isEmpty
                  ? null
                  : _defaultValue.text.trim(),
              synthHint:
                  _synthHint.text.trim().isEmpty ? null : _synthHint.text.trim(),
            );
            Navigator.of(context).pop(result);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
