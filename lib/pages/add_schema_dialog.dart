import 'package:flutter/material.dart';

class AddSchemaDialog extends StatefulWidget {
  const AddSchemaDialog({super.key, this.initialName, this.initialDescription});

  final String? initialName;
  final String? initialDescription;

  @override
  State<AddSchemaDialog> createState() => _AddSchemaDialogState();
}

class _AddSchemaDialogState extends State<AddSchemaDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: widget.initialDescription ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'New schema' : 'Edit schema'),
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
                labelText: 'Schema name',
                hintText: 'e.g. HR, SALES, FINANCE',
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
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
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
              (name: _name.text.trim(), description: _desc.text.trim()),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
