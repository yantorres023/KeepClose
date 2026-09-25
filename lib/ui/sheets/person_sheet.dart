import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../services/contact_picker.dart';
import '../widgets/common.dart';

/// Adds a new person (returns their id) or edits [existing].
Future<int?> showPersonSheet(BuildContext context, {Person? existing}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PersonSheet(existing: existing),
  );
}

class PersonSheet extends StatefulWidget {
  const PersonSheet({super.key, this.existing});

  final Person? existing;

  @override
  State<PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<PersonSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _note = TextEditingController(text: widget.existing?.note);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final deps = AppScope.of(context);
    PickedContact? picked;
    try {
      picked = await deps.contactPicker.pick();
    } on ContactPickerException {
      if (mounted) {
        showMessage(
          context,
          'Couldn\'t open contacts. You can add them by name.',
        );
      }
      return;
    }
    if (picked == null || !mounted) return;
    final existing = await deps.repository.findDuplicate(
      name: picked.name,
      phone: picked.phone,
    );
    if (!mounted) return;
    if (existing != null) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${existing.name} is already here'),
          content: const Text('Open their page instead of adding them twice?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Add anyway'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (open ?? false) {
        Navigator.pop(context, existing.id);
        return;
      }
    }
    setState(() {
      if (picked!.name.isNotEmpty) _name.text = picked.name;
      _phone.text = picked.phone ?? '';
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = AppScope.of(context).repository;
    int? id;
    final ok = await guardedWrite(context, () async {
      if (_isEdit) {
        await repo.updatePerson(
          widget.existing!.id,
          name: _name.text,
          note: _note.text,
          phone: _phone.text,
        );
        id = widget.existing!.id;
      } else {
        id = await repo.addPerson(
          name: _name.text,
          note: _note.text,
          phone: _phone.text,
        );
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit ${widget.existing!.name}' : 'Add someone',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              OutlinedButton.icon(
                onPressed: _pickContact,
                icon: const Icon(Icons.contacts_outlined),
                label: const Text('Pick from contacts'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  'Only the person you pick is shared with KeepClose.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            TextField(
              key: const Key('person-name'),
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              maxLength: KeepCloseRepository.maxNameLength,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('person-note'),
              controller: _note,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'How you know them, things to remember',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('person-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                helperText: 'Lets you open a message or call from their page.',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('person-save'),
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
