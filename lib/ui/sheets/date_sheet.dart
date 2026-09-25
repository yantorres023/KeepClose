import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../widgets/common.dart';

/// Adds a birthday or a one-off date for [person]. Returns true if saved.
Future<bool?> showDateSheet(BuildContext context, Person person) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DateSheet(person: person),
  );
}

class DateSheet extends StatefulWidget {
  const DateSheet({super.key, required this.person});

  final Person person;

  @override
  State<DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<DateSheet> {
  DateKind _kind = DateKind.birthday;
  int _month = 1;
  int _day = 1;
  final _year = TextEditingController();
  final _label = TextEditingController();
  LocalDate? _eventDate;
  int _lead = 0;
  bool _saving = false;

  @override
  void dispose() {
    _year.dispose();
    _label.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      _month == 2 ? 29 : DateTime.utc(2001, _month + 1, 0).day;

  Future<void> _save() async {
    if (_saving) return;
    final repo = AppScope.of(context).repository;
    setState(() => _saving = true);
    final ok = await guardedWrite(context, () async {
      if (_kind == DateKind.birthday) {
        final yearText = _year.text.trim();
        final year = yearText.isEmpty ? null : int.tryParse(yearText);
        if (yearText.isNotEmpty && year == null) {
          throw ValidationException('Year should be a number, like 1990.');
        }
        await repo.addBirthday(
          personId: widget.person.id,
          month: _month,
          day: _day,
          year: year,
          notifyDaysBefore: _lead,
        );
      } else {
        final date = _eventDate;
        if (date == null) throw ValidationException('Pick a day.');
        await repo.addEvent(
          personId: widget.person.id,
          label: _label.text,
          date: date,
          notifyDaysBefore: _lead,
        );
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = AppScope.of(context).today;
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
              'A date for ${Copy.firstName(widget.person.name)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<DateKind>(
              segments: const [
                ButtonSegment(
                  value: DateKind.birthday,
                  label: Text('Birthday'),
                  icon: Icon(Icons.cake_outlined),
                ),
                ButtonSegment(
                  value: DateKind.event,
                  label: Text('Something else'),
                  icon: Icon(Icons.event_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            if (_kind == DateKind.birthday) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      key: const Key('birthday-month'),
                      initialValue: _month,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(Copy.monthNames[m - 1]),
                          ),
                      ],
                      onChanged: (m) => setState(() {
                        _month = m ?? 1;
                        if (_day > _daysInMonth) _day = _daysInMonth;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('birthday-day-$_month'),
                      initialValue: _day,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: [
                        for (var d = 1; d <= _daysInMonth; d++)
                          DropdownMenuItem(value: d, child: Text('$d')),
                      ],
                      onChanged: (d) => setState(() => _day = d ?? 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _year,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Year (optional)',
                  counterText: '',
                ),
              ),
            ] else ...[
              TextField(
                key: const Key('event-label'),
                controller: _label,
                maxLength: KeepCloseRepository.maxLabelLength,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'What is it?',
                  hintText: 'moving day, exam, surgery',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickDate(
                    context,
                    initial: _eventDate ?? today.addDays(7),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _eventDate == null
                      ? 'Pick a day'
                      : Copy.longDate(_eventDate!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _lead,
              decoration: const InputDecoration(labelText: 'Remind me'),
              items: [
                for (final d in Copy.headsUpOptions)
                  DropdownMenuItem(value: d, child: Text(Copy.headsUpLabel(d))),
              ],
              onChanged: (d) => setState(() => _lead = d ?? 0),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('date-save'),
              onPressed: _saving ? null : _save,
              child: const Text('Save date'),
            ),
          ],
        ),
      ),
    );
  }
}
