import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddTableDialog extends StatefulWidget {
  const AddTableDialog({super.key, this.initialName, this.initialRows});

  final String? initialName;
  final int? initialRows;

  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _rows =
      TextEditingController(text: (widget.initialRows ?? 50).toString());
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'New table' : 'Edit table'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Table name',
                hintText: 'e.g. EMPLOYEES',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(v.trim())) {
                  return 'Letters, digits, underscores; start with a letter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rows,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Target row count',
                helperText: 'How many synthetic rows to generate',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0 || n > 10000) return '0 – 10000';
                return null;
              },
            ),
          ],
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
            Navigator.of(context).pop(
              (name: _name.text.trim(), rows: int.parse(_rows.text.trim())),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
