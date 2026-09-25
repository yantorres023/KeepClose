import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../../domain/reminder_engine.dart';
import '../sheets/follow_up_sheet.dart';
import '../sheets/person_sheet.dart';
import '../sheets/small_sheets.dart';
import '../widgets/common.dart';
import 'person_screen.dart';

/// Starts the core flow from anywhere: choose a person, then capture.
Future<void> rememberToAsk(BuildContext context, {Person? person}) async {
  final who = person ?? await choosePerson(context);
  if (who == null || !context.mounted) return;
  final saved = await showFollowUpSheet(context, who);
  if ((saved ?? false) && context.mounted) {
    await maybeAskForNotifications(context);
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-remember'),
        onPressed: () => rememberToAsk(context),
        icon: const Icon(Icons.edit_note),
        label: const Text('Remember to ask'),
      ),
      body: Watch<ReminderSnapshot>(
        stream: (deps) => deps.repository.watchSnapshot(),
        builder: (context, snapshot) {
          final today = deps.today;
          final engine = ReminderEngine(snapshot);
          final now = engine.today(today);
          final upcoming = engine.upcoming(today);
          if (snapshot.people.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: 'Who matters to you?',
              message:
                  'Add one or two people. When they tell you about something '
                  'coming up, jot it down and we\'ll remind you to ask.',
              action: FilledButton.icon(
                onPressed: () => showPersonSheet(context),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add someone'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  Copy.longDate(today),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SectionHeader('Today'),
              if (now.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Nothing to remember today. When someone mentions something '
                    'coming up, tap Remember to ask.',
                  ),
                ),
              for (final item in now)
                ReminderCard(
                  key: ValueKey(item.identity),
                  item: item,
                  today: today,
                ),
              if (upcoming.isNotEmpty) ...[
                const SectionHeader('Coming up'),
                for (final item in upcoming)
                  UpcomingTile(
                    key: ValueKey('up-${item.identity}'),
                    item: item,
                    today: today,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.item, required this.today});

  final ReminderItem item;
  final LocalDate today;

  bool get _isDate =>
      item.kind == ReminderKind.birthday || item.kind == ReminderKind.event;

  IconData get _icon => switch (item.kind) {
    ReminderKind.followUp => Icons.chat_bubble_outline,
    ReminderKind.checkIn => Icons.waving_hand_outlined,
    ReminderKind.birthday => Icons.cake_outlined,
    ReminderKind.event => Icons.event_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Copy.title(item, today);
    final subtitle = '${Copy.kindLabel(item.kind)} · ${item.person.name}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: '$title. $subtitle. Opens ${item.person.name}.',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => openPerson(context, item.person.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Icon(_icon, color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (!_isDate)
                  TextButton(
                    onPressed: () => _later(context),
                    child: const Text('Later'),
                  ),
                if (!_isDate)
                  TextButton(
                    onPressed: () => _letGo(context),
                    child: const Text('Let go'),
                  ),
                FilledButton.tonal(
                  onPressed: () => _done(context),
                  child: Text(
                    item.kind == ReminderKind.followUp ? 'Asked' : 'Done',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _done(BuildContext context) async {
    final repo = AppScope.of(context).repository;
    switch (item.kind) {
      case ReminderKind.followUp:
        int? momentId;
        final ok = await guardedWrite(
          context,
          () async => momentId = await repo.completeFollowUp(item.sourceId),
        );
        if (ok && context.mounted) {
          showUndo(
            context,
            'Nice. Saved to ${Copy.firstName(item.person.name)}\'s moments.',
            () => repo.undoCompleteFollowUp(item.sourceId, momentId!),
          );
        }
      case ReminderKind.checkIn:
        int? momentId;
        final ok = await guardedWrite(
          context,
          () async => momentId = await repo.logMoment(
            personId: item.person.id,
            kind: MomentKind.reachedOut,
          ),
        );
        if (ok && context.mounted) {
          showUndo(context, 'Lovely.', () => repo.deleteMoment(momentId!));
        }
      case ReminderKind.birthday:
      case ReminderKind.event:
        final ok = await guardedWrite(
          context,
          () => repo.acknowledgeDate(item.sourceId, item.date),
        );
        if (ok && context.mounted) {
          showUndo(
            context,
            'Done.',
            () => repo.unacknowledgeDate(item.sourceId),
          );
        }
    }
  }

  Future<void> _later(BuildContext context) async {
    final repo = AppScope.of(context).repository;
    final until = await pickLater(context);
    if (until == null || !context.mounted) return;
    final when = Copy.relativeDay(until, today);
    if (item.kind == ReminderKind.followUp) {
      final original = await repo.followUpById(item.sourceId);
      if (original == null || !context.mounted) return;
      final ok = await guardedWrite(
        context,
        () => repo.snoozeFollowUp(item.sourceId, until),
      );
      if (ok && context.mounted) {
        showUndo(
          context,
          'Moved to $when.',
          () => repo.restoreFollowUp(original),
        );
      }
    } else if (item.kind == ReminderKind.checkIn) {
      final ok = await guardedWrite(
        context,
        () => repo.snoozeCheckIn(item.person.id, until),
      );
      if (ok && context.mounted) {
        showUndo(
          context,
          'We\'ll suggest it $when.',
          () => repo.restoreCheckIn(item.person),
        );
      }
    }
  }

  Future<void> _letGo(BuildContext context) async {
    final repo = AppScope.of(context).repository;
    if (item.kind == ReminderKind.followUp) {
      final original = await repo.followUpById(item.sourceId);
      if (original == null || !context.mounted) return;
      final ok = await guardedWrite(
        context,
        () => repo.dismissFollowUp(item.sourceId),
      );
      if (ok && context.mounted) {
        showUndo(context, 'Let go.', () => repo.restoreFollowUp(original));
      }
    } else if (item.kind == ReminderKind.checkIn) {
      final ok = await guardedWrite(
        context,
        () => repo.skipCheckIn(item.person.id),
      );
      if (ok && context.mounted) {
        showUndo(
          context,
          'Skipped this time.',
          () => repo.restoreCheckIn(item.person),
        );
      }
    }
  }
}

class UpcomingTile extends StatelessWidget {
  const UpcomingTile({super.key, required this.item, required this.today});

  final ReminderItem item;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final String title;
    switch (item.kind) {
      case ReminderKind.followUp:
        title = 'Ask ${Copy.firstName(item.person.name)}: ${item.text}';
      case ReminderKind.checkIn:
        title = 'Check in with ${Copy.firstName(item.person.name)}';
      case ReminderKind.birthday:
      case ReminderKind.event:
        title = Copy.title(item, today);
    }
    final when = Copy.relativeDay(item.activeFrom, today);
    return ListTile(
      leading: PersonAvatar(name: item.person.name, radius: 16),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: switch (item.kind) {
        ReminderKind.followUp || ReminderKind.checkIn => Text('Reminder $when'),
        _ when item.activeFrom != item.date => Text('Heads-up $when'),
        _ => null,
      },
      onTap: () => openPerson(context, item.person.id),
    );
  }
}
