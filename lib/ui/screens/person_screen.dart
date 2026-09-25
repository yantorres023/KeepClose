import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../sheets/date_sheet.dart';
import '../sheets/person_sheet.dart';
import '../sheets/small_sheets.dart';
import '../widgets/common.dart';
import 'today_screen.dart';

Future<void> openPerson(BuildContext context, int id) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: id)));
}

class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context) {
    return Watch<PersonDetail?>(
      stream: (deps) => deps.repository.watchPersonDetail(personId),
      loading: const Scaffold(body: SizedBox.shrink()),
      builder: (context, detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'This person was removed',
              message: 'They are no longer in KeepClose.',
            ),
          );
        }
        return _PersonView(detail: detail);
      },
    );
  }
}

class _PersonView extends StatelessWidget {
  const _PersonView({required this.detail});

  final PersonDetail detail;

  Person get person => detail.person;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${person.name}?'),
        content: const Text(
          'This removes their reminders, dates and moments from this phone. '
          'It can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await guardedWrite(
      context,
      () => AppScope.of(context).repository.deletePerson(person.id),
    );
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${person.name} was deleted.')),
      );
    }
  }

  Future<void> _launch(BuildContext context, bool call) async {
    final launcher = AppScope.of(context).launcher;
    final phone = person.phone!;
    final ok = call
        ? await launcher.call(phone)
        : await launcher.message(phone);
    if (!ok && context.mounted) {
      showMessage(context, 'No app available for that on this phone.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deps = AppScope.of(context);
    final today = deps.today;
    final repo = deps.repository;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showPersonSheet(context, existing: person),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'delete') _delete(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-person-remember'),
        onPressed: () => rememberToAsk(context, person: person),
        icon: const Icon(Icons.edit_note),
        label: const Text('Remember to ask'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                PersonAvatar(name: person.name, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      person.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (person.note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(person.note!, style: theme.textTheme.bodyLarge),
            ),
          if (person.phone != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _launch(context, false),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Message'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launch(context, true),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                ],
              ),
            ),
          const SectionHeader('Remember to ask'),
          if (detail.openFollowUps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text('Nothing right now.'),
            ),
          for (final f in detail.openFollowUps)
            ListTile(
              key: ValueKey('fu-${f.id}'),
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(f.body),
              subtitle: Text(
                f.dueDate.isBefore(today)
                    ? 'Whenever you\'re ready'
                    : 'Reminder ${Copy.relativeDay(f.dueDate, today)}',
              ),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final ok = await guardedWrite(
                    context,
                    () => repo.dismissFollowUp(f.id),
                  );
                  if (ok && context.mounted) {
                    showUndo(
                      context,
                      'Removed.',
                      () => repo.restoreFollowUp(f),
                    );
                  }
                },
              ),
            ),
          const SectionHeader('Dates'),
          for (final d in detail.dates)
            ListTile(
              key: ValueKey('date-${d.id}'),
              leading: Icon(
                d.kind == DateKind.birthday
                    ? Icons.cake_outlined
                    : Icons.event_outlined,
              ),
              title: Text(
                d.kind == DateKind.birthday
                    ? 'Birthday · ${Copy.monthDay(d.month, d.day)}'
                    : '${d.label} · ${Copy.shortDate(LocalDate(d.year!, d.month, d.day))}',
              ),
              subtitle: d.notifyDaysBefore > 0
                  ? Text('Heads-up ${Copy.headsUpLabel(d.notifyDaysBefore)}')
                  : null,
              trailing: IconButton(
                tooltip: 'Delete date',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    guardedWrite(context, () => repo.deleteDate(d.id)),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                onPressed: () async {
                  final saved = await showDateSheet(context, person);
                  if ((saved ?? false) && context.mounted) {
                    await maybeAskForNotifications(context);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add a date'),
              ),
            ),
          ),
          const SectionHeader('Check in now and then'),
          ListTile(
            leading: const Icon(Icons.waving_hand_outlined),
            title: Text(Copy.rhythmLabel(person.checkInDays)),
            subtitle: detail.nextCheckIn == null
                ? const Text('Optional gentle suggestions to reach out')
                : Text(
                    'Next suggestion ${Copy.relativeDay(detail.nextCheckIn!.isBefore(today) ? today : detail.nextCheckIn!, today)}',
                  ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final changed = await showRhythmSheet(context, person);
              if ((changed ?? false) &&
                  person.checkInDays == null &&
                  context.mounted) {
                await maybeAskForNotifications(context);
              }
            },
          ),
          SectionHeader(
            'Moments',
            trailing: TextButton.icon(
              onPressed: () => showMomentSheet(context, person),
              icon: const Icon(Icons.add),
              label: const Text('We talked'),
            ),
          ),
          if (detail.moments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'When you catch up, you can note anything worth remembering.',
              ),
            ),
          for (final m in detail.moments)
            ListTile(
              key: ValueKey('moment-${m.id}'),
              leading: Icon(switch (m.kind) {
                MomentKind.talked => Icons.forum_outlined,
                MomentKind.reachedOut => Icons.send_outlined,
                MomentKind.followedUp => Icons.check_circle_outline,
              }),
              title: Text(switch (m.kind) {
                MomentKind.talked => m.note ?? 'We talked',
                MomentKind.reachedOut => m.note ?? 'I reached out',
                MomentKind.followedUp => 'Asked about ${m.note ?? 'something'}',
              }),
              subtitle: Text(
                m.date == today ? 'Today' : Copy.shortDate(m.date),
              ),
              trailing: IconButton(
                tooltip: 'Delete moment',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    guardedWrite(context, () => repo.deleteMoment(m.id)),
              ),
            ),
        ],
      ),
    );
  }
}
