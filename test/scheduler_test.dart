import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/data/database.dart';
import 'package:keepclose/data/repository.dart';
import 'package:keepclose/domain/local_date.dart';
import 'package:keepclose/domain/reminder_engine.dart';
import 'package:keepclose/services/notification_service.dart';
import 'package:keepclose/services/reminder_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';
import 'builders.dart';

ReminderSnapshot snap({
  List<Person> people = const [],
  List<FollowUp> followUps = const [],
  List<ImportantDate> dates = const [],
}) => ReminderSnapshot(
  people: people,
  openFollowUps: followUps,
  dates: dates,
  lastMomentByPerson: const {},
);

void main() {
  setUpAll(initTimezones);

  final ana = person(1, 'Ana Lima');
  final bruno = person(2, 'Bruno');

  group('plan', () {
    test('one notification per day with items, at the chosen local time', () {
      final loc = tz.getLocation('Europe/Lisbon');
      final now = tz.TZDateTime(loc, 2026, 9, 25, 8);
      final today = LocalDate(2026, 9, 25);
      final planned = ReminderScheduler.plan(
        snapshot: snap(
          people: [ana, bruno],
          followUps: [
            followUp(1, 1, 'interview', today),
            followUp(2, 2, 'trip', today),
            followUp(3, 2, 'exam', today.addDays(4)),
          ],
        ),
        settings: const AppSettings(),
        now: now,
      );
      expect(planned, hasLength(2));
      expect(planned[0].when, tz.TZDateTime(loc, 2026, 9, 25, 9));
      expect(planned[1].when, tz.TZDateTime(loc, 2026, 9, 29, 9));
      expect(planned[0].id, 20260925);
      expect(planned.map((p) => p.id).toSet(), hasLength(2));
    });

    test('skips today when the reminder time has passed', () {
      final loc = tz.getLocation('UTC');
      final today = LocalDate(2026, 9, 25);
      final planned = ReminderScheduler.plan(
        snapshot: snap(people: [ana], followUps: [followUp(1, 1, 'x', today)]),
        settings: const AppSettings(),
        now: tz.TZDateTime(loc, 2026, 9, 25, 10),
      );
      expect(planned, isEmpty);
    });

    test('nothing is scheduled when notifications are disabled', () {
      final today = LocalDate(2026, 9, 25);
      final planned = ReminderScheduler.plan(
        snapshot: snap(people: [ana], followUps: [followUp(1, 1, 'x', today)]),
        settings: const AppSettings(notificationsEnabled: false),
        now: tz.TZDateTime(tz.UTC, 2026, 9, 25, 1),
      );
      expect(planned, isEmpty);
    });

    test('keeps 09:00 wall-clock across a DST change (New York, Nov 2026)', () {
      final ny = tz.getLocation('America/New_York');
      final start = LocalDate(2026, 10, 30);
      final planned = ReminderScheduler.plan(
        snapshot: snap(
          people: [ana],
          followUps: [
            for (var i = 0; i < 5; i++)
              followUp(i + 1, 1, 'x$i', start.addDays(i)),
          ],
        ),
        settings: const AppSettings(),
        now: tz.TZDateTime(ny, 2026, 10, 30, 0, 30),
      );
      expect(planned, hasLength(5));
      for (final p in planned) {
        expect(p.when.hour, 9);
        expect(p.when.minute, 0);
      }
      // The UTC instant shifts by one hour after the transition on 1 Nov.
      expect(planned.first.when.toUtc().hour, 13);
      expect(planned.last.when.toUtc().hour, 14);
    });

    test(
      'a reminder time inside the spring-forward gap still fires that day',
      () {
        final ny = tz.getLocation('America/New_York');
        final gapDay = LocalDate(2027, 3, 14); // 02:00 -> 03:00
        final planned = ReminderScheduler.plan(
          snapshot: snap(
            people: [ana],
            followUps: [followUp(1, 1, 'x', gapDay)],
          ),
          settings: const AppSettings(reminderMinutes: 2 * 60 + 30),
          now: tz.TZDateTime(ny, 2027, 3, 13, 12),
        );
        expect(planned, hasLength(1));
        final when = planned.single.when;
        expect(LocalDate(when.year, when.month, when.day), gapDay);
        expect(when.hour, anyOf(1, 3));
      },
    );

    test('follows the device timezone after it changes', () {
      final today = LocalDate(2026, 9, 26);
      for (final name in [
        'Asia/Tokyo',
        'America/Los_Angeles',
        'Australia/Lord_Howe',
      ]) {
        final loc = tz.getLocation(name);
        final planned = ReminderScheduler.plan(
          snapshot: snap(
            people: [ana],
            followUps: [followUp(1, 1, 'x', today)],
          ),
          settings: const AppSettings(reminderMinutes: 18 * 60 + 15),
          now: tz.TZDateTime(loc, 2026, 9, 25, 12),
        );
        expect(planned.single.when.location.name, name);
        expect(planned.single.when.hour, 18);
        expect(planned.single.when.minute, 15);
      }
    });

    test('never exceeds the 30-day horizon (iOS pending cap is 64)', () {
      final today = LocalDate(2026, 9, 25);
      final planned = ReminderScheduler.plan(
        snapshot: snap(
          people: [ana],
          followUps: [
            for (var i = 0; i < 100; i++)
              followUp(i + 1, 1, 'x', today.addDays(i)),
          ],
        ),
        settings: const AppSettings(),
        now: tz.TZDateTime(tz.UTC, 2026, 9, 25, 1),
      );
      expect(planned.length, ReminderScheduler.horizonDays);
    });
  });

  group('notification content', () {
    final today = LocalDate(2026, 9, 25);
    List<PlannedNotification> planWith(NotificationDetail d) =>
        ReminderScheduler.plan(
          snapshot: snap(
            people: [ana, bruno],
            followUps: [
              followUp(1, 1, 'her biopsy results', today),
              followUp(2, 2, 'the divorce hearing', today),
            ],
            dates: [birthday(1, 2, 9, 25)],
          ),
          settings: AppSettings(notificationDetail: d),
          now: tz.TZDateTime(tz.UTC, 2026, 9, 25, 1),
        );

    test('private by default: no names or notes on the lock screen', () {
      final n = planWith(const AppSettings().notificationDetail).single;
      expect(n.body, 'You have 3 gentle reminders today.');
      for (final secret in ['Ana', 'Bruno', 'biopsy', 'divorce', 'birthday']) {
        expect(n.title.contains(secret) || n.body.contains(secret), isFalse);
      }
    });

    test('names only reveals first names but not notes', () {
      final n = planWith(NotificationDetail.names).single;
      expect(n.body, 'Thinking of Ana, Bruno today.');
      expect(n.body.contains('biopsy'), isFalse);
    });

    test('full details shows the first item and a count', () {
      final n = planWith(NotificationDetail.full).single;
      expect(n.body, startsWith('Ask Ana: her biopsy results'));
      expect(n.body, endsWith('(+2 more)'));
    });

    test('never uses shaming language', () {
      for (final d in NotificationDetail.values) {
        final body = planWith(d).single.body.toLowerCase();
        for (final word in [
          'overdue',
          'days since',
          'haven\'t',
          'streak',
          'score',
        ]) {
          expect(body.contains(word), isFalse, reason: '$d: $body');
        }
      }
    });
  });

  group('sync', () {
    test('cancels and reschedules from repository data', () async {
      final env = TestEnv.create();
      final id = await env.repo.addPerson(name: 'Ana');
      await env.repo.addFollowUp(personId: id, body: 'x', due: testToday);
      await env.repo.addFollowUp(
        personId: id,
        body: 'y',
        due: testToday.addDays(1),
      );
      await env.deps.scheduler.sync();
      expect(env.notifications.cancelAllCount, 1);
      expect(env.notifications.scheduled, hasLength(2));

      await env.repo.setNotificationsEnabled(false);
      await env.deps.scheduler.sync();
      expect(env.notifications.scheduled, isEmpty);
      await env.close();
    });

    test('schedules even when permission is denied, without asking', () async {
      final env = TestEnv.create(permission: PermissionState.denied);
      final id = await env.repo.addPerson(name: 'Ana');
      await env.repo.addFollowUp(personId: id, body: 'x', due: testToday);
      await env.deps.scheduler.sync();
      expect(env.notifications.requestCount, 0);
      expect(env.notifications.scheduled, hasLength(1));
      await env.close();
    });

    test('a failing platform call does not break later syncs', () async {
      final env = TestEnv.create();
      final id = await env.repo.addPerson(name: 'Ana');
      await env.repo.addFollowUp(personId: id, body: 'x', due: testToday);
      env.notifications.throwOnSchedule = true;
      await env.deps.scheduler.sync();
      env.notifications.throwOnSchedule = false;
      await env.deps.scheduler.sync();
      expect(env.notifications.scheduled, hasLength(1));
      await env.close();
    });

    test('start() resyncs automatically after data changes', () async {
      final env = TestEnv.create();
      env.deps.scheduler.start();
      final id = await env.repo.addPerson(name: 'Ana');
      await env.repo.addFollowUp(
        personId: id,
        body: 'x',
        due: testToday.addDays(2),
      );
      for (var i = 0; i < 20 && env.notifications.scheduled.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(env.notifications.scheduled, hasLength(1));
      await env.deps.scheduler.stop();
      await env.close();
    });
  });
}
