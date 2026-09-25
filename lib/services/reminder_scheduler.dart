import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/repository.dart';
import '../domain/copy.dart';
import '../domain/local_date.dart';
import '../domain/reminder_engine.dart';
import 'notification_service.dart';

/// Turns the deterministic reminder plan into scheduled local notifications.
///
/// Policy: at most one digest notification per day, at the user's chosen time,
/// only on days with something to remember. The next [horizonDays] days are
/// pre-scheduled (well under iOS's 64 pending-notification cap) and fully
/// re-synced on every data change and on app resume.
class ReminderScheduler {
  ReminderScheduler({
    required this.repository,
    required this.notifications,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const horizonDays = 30;

  final KeepCloseRepository repository;
  final NotificationService notifications;
  final DateTime Function() _now;

  StreamSubscription<void>? _sub;
  Future<void> _chain = Future.value();

  /// Builds the notification plan. Pure given its inputs; used by [sync] and
  /// tests.
  static List<PlannedNotification> plan({
    required ReminderSnapshot snapshot,
    required AppSettings settings,
    required tz.TZDateTime now,
    int days = horizonDays,
  }) {
    if (!settings.notificationsEnabled) return const [];
    final location = now.location;
    final today = LocalDate(now.year, now.month, now.day);
    final byDay = ReminderEngine(snapshot).digestPlan(today, days);
    final hour = settings.reminderMinutes ~/ 60;
    final minute = settings.reminderMinutes % 60;
    final result = <PlannedNotification>[];
    final daysSorted = byDay.keys.toList()..sort();
    for (final day in daysSorted) {
      final items = byDay[day]!;
      if (items.isEmpty) continue;
      final when = tz.TZDateTime(
        location,
        day.year,
        day.month,
        day.day,
        hour,
        minute,
      );
      if (!when.isAfter(now)) continue;
      final text = Copy.digest(items, day, settings.notificationDetail);
      result.add(
        PlannedNotification(
          id: day.key,
          when: when,
          title: text.title,
          body: text.body,
        ),
      );
    }
    return result;
  }

  /// Starts listening to data/settings changes and keeps notifications in sync.
  void start() {
    _sub?.cancel();
    final controller = StreamController<void>();
    final subs = [
      repository.watchSnapshot().listen((_) => controller.add(null)),
      repository.watchSettings().listen((_) => controller.add(null)),
    ];
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    _sub = controller.stream.listen((_) => sync());
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Re-reads everything and reschedules. Calls are serialized.
  Future<void> sync() {
    _chain = _chain.then((_) => _syncNow()).catchError((Object e) {
      debugPrint('KeepClose: notification sync failed (${e.runtimeType})');
    });
    return _chain;
  }

  Future<void> _syncNow() async {
    await notifications.refreshTimezone();
    final settings = await repository.loadSettings();
    final snapshot = await repository.loadSnapshot();
    final now = tz.TZDateTime.from(_now(), tz.local);
    final planned = plan(snapshot: snapshot, settings: settings, now: now);
    await notifications.cancelAll();
    if (planned.isEmpty) return;
    // Scheduling without permission is harmless on both platforms (nothing
    // is shown), and means reminders appear once permission is granted later.
    for (final n in planned) {
      await notifications.schedule(n);
    }
  }
}
