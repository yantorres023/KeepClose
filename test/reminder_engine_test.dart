import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/data/database.dart';
import 'package:keepclose/domain/local_date.dart';
import 'package:keepclose/domain/reminder_engine.dart';

import 'builders.dart';

ReminderEngine engine({
  List<Person> people = const [],
  List<FollowUp> followUps = const [],
  List<ImportantDate> dates = const [],
  Map<int, LocalDate> moments = const {},
}) => ReminderEngine(
  ReminderSnapshot(
    people: people,
    openFollowUps: followUps,
    dates: dates,
    lastMomentByPerson: moments,
  ),
);

void main() {
  final today = LocalDate(2026, 9, 25);
  final mariana = person(1, 'Mariana Silva');
  final lucas = person(2, 'Lucas');

  group('follow-ups', () {
    test('appear in Today on their due day, and in Coming up before', () {
      final e = engine(
        people: [mariana],
        followUps: [
          followUp(1, 1, 'how the interview went', today),
          followUp(2, 1, 'the new flat', today.addDays(3)),
        ],
      );
      expect(e.today(today).map((i) => i.sourceId), [1]);
      expect(e.upcoming(today).map((i) => i.sourceId), [2]);
    });

    test('past-due open follow-ups stay in Today, marked late', () {
      final e = engine(
        people: [mariana],
        followUps: [followUp(1, 1, 'exam', today.addDays(-5))],
      );
      final items = e.today(today);
      expect(items, hasLength(1));
      expect(items.single.isLateOn(today), isTrue);
    });

    test('done and dismissed follow-ups never appear', () {
      final e = engine(
        people: [mariana],
        followUps: [
          followUp(1, 1, 'a', today, status: FollowUpStatus.done),
          followUp(2, 1, 'b', today, status: FollowUpStatus.dismissed),
        ],
      );
      expect(e.today(today), isEmpty);
      expect(e.digestPlan(today, 30), isEmpty);
    });

    test('follow-ups of a deleted person are ignored', () {
      final e = engine(
        people: [lucas],
        followUps: [followUp(1, 1, 'x', today)],
      );
      expect(e.today(today), isEmpty);
    });

    test('beyond the 14-day window they are not "coming up"', () {
      final e = engine(
        people: [mariana],
        followUps: [followUp(1, 1, 'x', today.addDays(15))],
      );
      expect(e.upcoming(today), isEmpty);
      expect(e.upcoming(today, days: 15), hasLength(1));
    });
  });

  group('birthdays', () {
    test('show on the day with age when year is known', () {
      final e = engine(
        people: [mariana],
        dates: [birthday(1, 1, 9, 25, year: 1996)],
      );
      final item = e.today(today).single;
      expect(item.kind, ReminderKind.birthday);
      expect(item.turning, 30);
    });

    test('heads-up days bring the birthday into Today early', () {
      final e = engine(
        people: [mariana],
        dates: [birthday(1, 1, 9, 28, lead: 3)],
      );
      final item = e.today(today).single;
      expect(item.date, LocalDate(2026, 9, 28));
      expect(item.activeFrom, today);
      final plan = e.digestPlan(today, 7);
      expect(plan.keys, containsAll([today, LocalDate(2026, 9, 28)]));
    });

    test('passed birthdays drop off Today', () {
      final e = engine(people: [mariana], dates: [birthday(1, 1, 9, 24)]);
      expect(e.today(today), isEmpty);
    });

    test('Feb 29 birthday is celebrated on Feb 28 in non-leap years', () {
      final e = engine(people: [mariana], dates: [birthday(1, 1, 2, 29)]);
      expect(
        e.today(LocalDate(2027, 2, 28)).single.date,
        LocalDate(2027, 2, 28),
      );
      expect(e.today(LocalDate(2027, 3, 1)), isEmpty);
      expect(e.today(LocalDate(2028, 2, 28)), isEmpty);
      expect(
        e.today(LocalDate(2028, 2, 29)).single.date,
        LocalDate(2028, 2, 29),
      );
    });

    test('year-end wraparound for upcoming', () {
      final dec30 = LocalDate(2026, 12, 30);
      final e = engine(people: [mariana], dates: [birthday(1, 1, 1, 2)]);
      expect(e.upcoming(dec30).single.date, LocalDate(2027, 1, 2));
    });

    test('acknowledged occurrence is hidden, next year returns', () {
      final e = engine(
        people: [mariana],
        dates: [birthday(1, 1, 9, 25, ack: today)],
      );
      expect(e.today(today), isEmpty);
      expect(e.today(LocalDate(2027, 9, 25)), hasLength(1));
    });
  });

  group('events', () {
    test('happen once', () {
      final moveDay = LocalDate(2026, 10, 3);
      final e = engine(
        people: [lucas],
        dates: [event(1, 2, 'moving day', moveDay, lead: 1)],
      );
      expect(e.today(LocalDate(2026, 10, 2)).single.text, 'moving day');
      expect(e.today(moveDay), hasLength(1));
      expect(e.today(LocalDate(2026, 10, 4)), isEmpty);
      expect(e.today(LocalDate(2027, 10, 3)), isEmpty);
    });
  });

  group('check-ins', () {
    test('off by default', () {
      final e = engine(people: [mariana]);
      expect(e.today(today), isEmpty);
      expect(ReminderEngine.nextCheckIn(mariana, null), isNull);
    });

    test('due rhythm days after anchor, reset by later moments', () {
      final p = person(
        1,
        'Ana',
        checkInDays: 30,
        anchor: LocalDate(2026, 8, 1),
      );
      expect(ReminderEngine.nextCheckIn(p, null), LocalDate(2026, 8, 31));
      expect(
        ReminderEngine.nextCheckIn(p, LocalDate(2026, 9, 10)),
        LocalDate(2026, 10, 10),
      );
      // A moment older than the anchor does not move it back.
      expect(
        ReminderEngine.nextCheckIn(p, LocalDate(2026, 7, 1)),
        LocalDate(2026, 8, 31),
      );
    });

    test('snooze pushes it later but never earlier', () {
      final p = person(
        1,
        'Ana',
        checkInDays: 30,
        anchor: LocalDate(2026, 8, 1),
        snoozed: LocalDate(2026, 9, 30),
      );
      expect(ReminderEngine.nextCheckIn(p, null), LocalDate(2026, 9, 30));
      final early = person(
        1,
        'Ana',
        checkInDays: 30,
        anchor: LocalDate(2026, 8, 1),
        snoozed: LocalDate(2026, 8, 5),
      );
      expect(ReminderEngine.nextCheckIn(early, null), LocalDate(2026, 8, 31));
    });

    test('a missed check-in stays in Today but is not re-announced', () {
      final p = person(
        1,
        'Ana',
        checkInDays: 14,
        anchor: LocalDate(2026, 9, 1),
      );
      final e = engine(people: [p]);
      expect(e.today(today).single.kind, ReminderKind.checkIn);
      expect(e.digestPlan(today, 30), isEmpty);
    });
  });

  group('digest plan', () {
    test('groups items by day and never includes past-due items', () {
      final e = engine(
        people: [mariana, lucas],
        followUps: [
          followUp(1, 1, 'late', today.addDays(-1)),
          followUp(2, 1, 'a', today),
          followUp(3, 2, 'b', today),
          followUp(4, 2, 'c', today.addDays(2)),
        ],
      );
      final plan = e.digestPlan(today, 30);
      expect(plan[today]!.map((i) => i.sourceId), [3, 2]);
      expect(plan[today.addDays(2)]!.single.sourceId, 4);
      expect(plan.length, 2);
    });

    test('respects the horizon', () {
      final e = engine(
        people: [mariana],
        followUps: [followUp(1, 1, 'a', today.addDays(30))],
      );
      expect(e.digestPlan(today, 30), isEmpty);
      expect(e.digestPlan(today, 31), hasLength(1));
    });

    test('is deterministic', () {
      final e = engine(
        people: [mariana, lucas],
        followUps: [followUp(1, 1, 'a', today), followUp(2, 2, 'b', today)],
        dates: [birthday(1, 2, 9, 25)],
      );
      expect(
        e.digestPlan(today, 30)[today].toString(),
        e.digestPlan(today, 30)[today].toString(),
      );
    });
  });

  test('handles 500 people and 5,000 items quickly', () {
    final people = [
      for (var i = 1; i <= 500; i++) person(i, 'Person $i', checkInDays: 30),
    ];
    final followUps = [
      for (var i = 1; i <= 4000; i++)
        followUp(i, (i % 500) + 1, 'thing $i', today.addDays(i % 40)),
    ];
    final dates = [
      for (var i = 1; i <= 1000; i++)
        birthday(i, (i % 500) + 1, (i % 12) + 1, (i % 28) + 1),
    ];
    final e = engine(people: people, followUps: followUps, dates: dates);
    final sw = Stopwatch()..start();
    e.today(today);
    e.upcoming(today);
    e.digestPlan(today, 30);
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(1500));
  });
}
