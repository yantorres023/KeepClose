import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../widgets/common.dart';

/// "Remember to ask {name}…" — the core capture flow. Returns true if saved.
Future<bool?> showFollowUpSheet(BuildContext context, Person person) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FollowUpSheet(person: person),
  );
}

class FollowUpSheet extends StatefulWidget {
  const FollowUpSheet({super.key, required this.person});

  final Person person;

  @override
  State<FollowUpSheet> createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends State<FollowUpSheet> {
  final _text = TextEditingController();
  late LocalDate _today;
  late LocalDate _due;
  int _choice = 0;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _today = AppScope.of(context).today;
    if (_choice == 0) _due = _today.addDays(1);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<(String, int)> get _quick => const [
    ('Tomorrow', 1),
    ('In 3 days', 3),
    ('Next week', 7),
    ('In 2 weeks', 14),
  ];

  Future<void> _pickDay() async {
    final picked = await pickDate(context, initial: _due);
    if (picked != null) {
      setState(() {
        _due = picked;
        _choice = -1;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final deps = AppScope.of(context);
    final ok = await guardedWrite(
      context,
      () => deps.repository.addFollowUp(
        personId: widget.person.id,
        body: _text.text,
        due: _due,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    final messenger = ScaffoldMessenger.of(context);
    final when = Copy.relativeDay(_due, _today);
    Navigator.pop(context, true);
    messenger.showSnackBar(SnackBar(content: Text('We\'ll remind you $when.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = Copy.firstName(widget.person.name);
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
            Text('Remember to ask $name…', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('follow-up-text'),
              controller: _text,
              autofocus: true,
              maxLength: KeepCloseRepository.maxFollowUpLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: 'how the interview went',
              ),
            ),
            const SizedBox(height: 8),
            Text('When?', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, (label, days)) in _quick.indexed)
                  ChoiceChip(
                    label: Text(label),
                    selected: _choice == i,
                    onSelected: (_) => setState(() {
                      _choice = i;
                      _due = _today.addDays(days);
                    }),
                  ),
                ChoiceChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _choice == -1 ? Copy.shortDate(_due) : 'Pick a day',
                  ),
                  selected: _choice == -1,
                  onSelected: (_) => _pickDay(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('follow-up-save'),
              onPressed: _saving ? null : _save,
              child: Text('Remind me ${Copy.relativeDay(_due, _today)}'),
            ),
          ],
        ),
      ),
    );
  }
}
