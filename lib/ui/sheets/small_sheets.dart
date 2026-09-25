import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../widgets/common.dart';
import 'person_sheet.dart';

/// Chooses how often to gently suggest checking in. Returns true if changed.
Future<bool?> showRhythmSheet(BuildContext context, Person person) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<int?>(
            groupValue: person.checkInDays,
            onChanged: (value) async {
              final ok = await guardedWrite(
                context,
                () => AppScope.of(
                  context,
                ).repository.setCheckIn(person.id, value),
              );
              if (ok && context.mounted) Navigator.pop(context, true);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Check in with ${Copy.firstName(person.name)} now and then',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'We\'ll gently suggest reaching out. Marking that you talked resets it.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                for (final option in Copy.rhythmOptions)
                  RadioListTile<int?>(
                    value: option,
                    title: Text(Copy.rhythmLabel(option)),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Logs that the user talked to / reached out to [person]. Returns true if saved.
Future<bool?> showMomentSheet(BuildContext context, Person person) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MomentSheet(person: person),
  );
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet({required this.person});

  final Person person;

  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet> {
  MomentKind _kind = MomentKind.talked;
  final _note = TextEditingController();
  LocalDate? _date;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = AppScope.of(context).repository;
    final ok = await guardedWrite(
      context,
      () => repo.logMoment(
        personId: widget.person.id,
        kind: _kind,
        date: _date,
        note: _note.text,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = AppScope.of(context).today;
    final date = _date ?? today;
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
              'A moment with ${Copy.firstName(widget.person.name)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('We talked'),
                  selected: _kind == MomentKind.talked,
                  onSelected: (_) => setState(() => _kind = MomentKind.talked),
                ),
                ChoiceChip(
                  label: const Text('I reached out'),
                  selected: _kind == MomentKind.reachedOut,
                  onSelected: (_) =>
                      setState(() => _kind = MomentKind.reachedOut),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('moment-note'),
              controller: _note,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Anything to remember? (optional)',
                hintText: 'Got the job! Starts in March',
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final picked = await pickDate(
                  context,
                  initial: date,
                  first: today.addDays(-365 * 5),
                  last: today,
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(date == today ? 'Today' : Copy.longDate(date)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('moment-save'),
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks an existing person (or adds someone new). Returns the person.
Future<Person?> choosePerson(BuildContext context) async {
  final repo = AppScope.of(context).repository;
  final people = await repo.allPeople();
  if (!context.mounted) return null;
  if (people.isEmpty) {
    final id = await showPersonSheet(context);
    if (id == null) return null;
    return repo.personById(id);
  }
  final choice = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Who is it about?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: const Text('Someone new'),
            onTap: () => Navigator.pop(context, 'new'),
          ),
          for (final p in people)
            ListTile(
              leading: PersonAvatar(name: p.name),
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, p),
            ),
        ],
      ),
    ),
  );
  if (choice is Person) return choice;
  if (choice == 'new' && context.mounted) {
    final id = await showPersonSheet(context);
    if (id == null) return null;
    return repo.personById(id);
  }
  return null;
}
