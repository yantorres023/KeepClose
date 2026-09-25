import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../../domain/reminder_engine.dart';
import '../sheets/person_sheet.dart';
import '../widgets/common.dart';
import 'person_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String _query = '';

  Future<void> _add() async {
    final id = await showPersonSheet(context);
    if (id != null && mounted) await openPerson(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final today = AppScope.of(context).today;
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-people',
        key: const Key('fab-add-person'),
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add someone'),
      ),
      body: Watch<ReminderSnapshot>(
        stream: (deps) => deps.repository.watchSnapshot(),
        builder: (context, snapshot) {
          if (snapshot.people.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'Who matters to you?',
              message:
                  'Start with one or two people. You can add more any time.',
              action: FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add someone'),
              ),
            );
          }
          final people = [...snapshot.people]
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          final q = _query.trim().toLowerCase();
          final visible = q.isEmpty
              ? people
              : people.where((p) => p.name.toLowerCase().contains(q)).toList();
          final engine = ReminderEngine(snapshot);
          final next = <int, ReminderItem>{};
          for (final item in [
            ...engine.today(today),
            ...engine.upcoming(today, days: 60),
          ]) {
            next.putIfAbsent(item.person.id, () => item);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (people.length > 8)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No one matches that search.'),
                ),
              for (final p in visible)
                ListTile(
                  key: ValueKey('person-${p.id}'),
                  leading: PersonAvatar(name: p.name),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _subtitle(next[p.id], p.note, today),
                  onTap: () => openPerson(context, p.id),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _subtitle(ReminderItem? item, String? note, LocalDate today) {
    if (item != null) {
      final when = Copy.relativeDay(item.date, today);
      final text = switch (item.kind) {
        ReminderKind.followUp =>
          item.isLateOn(today)
              ? 'Ask about ${item.text}'
              : 'Ask about ${item.text} · $when',
        ReminderKind.checkIn => 'Check in $when',
        ReminderKind.birthday => 'Birthday $when',
        ReminderKind.event => '${item.text} $when',
      };
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (note != null && note.isNotEmpty) {
      return Text(note, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return null;
  }
}
