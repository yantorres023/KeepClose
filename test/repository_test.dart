import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/data/database.dart';
import 'package:keepclose/data/repository.dart';
import 'package:keepclose/domain/local_date.dart';
import 'package:keepclose/domain/reminder_engine.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;
  late KeepCloseRepository repo;

  setUp(() {
    env = TestEnv.create();
    repo = env.repo;
  });
  tearDown(() => env.close());

  group('people', () {
    test('name is required and trimmed', () async {
      expect(
        () => repo.addPerson(name: '   '),
        throwsA(isA<ValidationException>()),
      );
      final id = await repo.addPerson(name: '  Ana  ', note: '  ', phone: '');
      final p = await repo.personById(id);
      expect(p!.name, 'Ana');
      expect(p.note, isNull);
      expect(p.phone, isNull);
    });

    test(
      'long names are rejected past the limit, accepted at the limit',
      () async {
        final max = 'x' * KeepCloseRepository.maxNameLength;
        await repo.addPerson(name: max);
        expect(
          () => repo.addPerson(name: '${max}y'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('special characters and emoji survive a round trip', () async {
      const name = "Zoë O'Brien-Łukasz 李雷 👩🏽‍🦱";
      const note = 'Likes "quotes"; drop tables? \'); DROP TABLE people;--';
      final id = await repo.addPerson(name: name, note: note);
      final p = await repo.personById(id);
      expect(p!.name, name);
      expect(p.note, note);
      expect(await repo.allPeople(), hasLength(1));
    });

    test('people are listed case-insensitively by name', () async {
      await repo.addPerson(name: 'bruno');
      await repo.addPerson(name: 'Ana');
      await repo.addPerson(name: 'Carla');
      expect((await repo.allPeople()).map((p) => p.name), [
        'Ana',
        'bruno',
        'Carla',
      ]);
    });

    test('duplicate detection by name and phone digits', () async {
      await repo.addPerson(name: 'Ana Souza', phone: '+55 (11) 99999-0000');
      expect(
        await repo.findDuplicate(name: 'ana souza', phone: '+5511999990000'),
        isNotNull,
      );
      expect(await repo.findDuplicate(name: 'Ana Souza'), isNotNull);
      expect(
        await repo.findDuplicate(name: 'Ana Souza', phone: '+1 555 0100'),
        isNull,
      );
      expect(await repo.findDuplicate(name: 'Bruno'), isNull);
    });

    test('deleting a person cascades to everything about them', () async {
      final id = await repo.addPerson(name: 'Ana');
      final other = await repo.addPerson(name: 'Bruno');
      await repo.addFollowUp(personId: id, body: 'exam', due: testToday);
      await repo.addFollowUp(personId: other, body: 'trip', due: testToday);
      await repo.addBirthday(personId: id, month: 1, day: 2);
      await repo.logMoment(personId: id, kind: MomentKind.talked);
      await repo.deletePerson(id);
      final db = env.db;
      expect(await db.select(db.followUps).get(), hasLength(1));
      expect(await db.select(db.importantDates).get(), isEmpty);
      expect(await db.select(db.moments).get(), isEmpty);
      expect(await repo.personDetail(id), isNull);
    });
  });

  group('follow-ups', () {
    late int ana;
    setUp(() async => ana = await repo.addPerson(name: 'Ana'));

    test('validation', () async {
      expect(
        () => repo.addFollowUp(personId: ana, body: ' ', due: testToday),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addFollowUp(
          personId: ana,
          body: 'x' * (KeepCloseRepository.maxFollowUpLength + 1),
          due: testToday,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addFollowUp(
          personId: ana,
          body: 'a',
          due: testToday.addDays(-1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('complete records a moment; undo restores both', () async {
      final id = await repo.addFollowUp(
        personId: ana,
        body: 'interview',
        due: testToday,
      );
      final momentId = await repo.completeFollowUp(id);
      var detail = await repo.personDetail(ana);
      expect(detail!.openFollowUps, isEmpty);
      expect(detail.moments.single.kind, MomentKind.followedUp);
      expect(detail.moments.single.note, 'interview');

      await repo.undoCompleteFollowUp(id, momentId);
      detail = await repo.personDetail(ana);
      expect(detail!.openFollowUps.single.id, id);
      expect(detail.moments, isEmpty);
    });

    test('snooze moves the due date; dismiss + restore round-trips', () async {
      final id = await repo.addFollowUp(
        personId: ana,
        body: 'x',
        due: testToday,
      );
      await repo.snoozeFollowUp(id, testToday.addDays(7));
      expect((await repo.followUpById(id))!.dueDate, testToday.addDays(7));
      expect(
        () => repo.snoozeFollowUp(id, testToday.addDays(-1)),
        throwsA(isA<ValidationException>()),
      );

      final original = (await repo.followUpById(id))!;
      await repo.dismissFollowUp(id);
      expect((await repo.personDetail(ana))!.openFollowUps, isEmpty);
      await repo.restoreFollowUp(original);
      expect((await repo.personDetail(ana))!.openFollowUps, hasLength(1));
    });

    test('completing a follow-up that was deleted fails gently', () async {
      final id = await repo.addFollowUp(
        personId: ana,
        body: 'x',
        due: testToday,
      );
      await repo.deleteFollowUp(id);
      expect(
        () => repo.completeFollowUp(id),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('dates', () {
    late int ana;
    setUp(() async => ana = await repo.addPerson(name: 'Ana'));

    test('birthday validation including leap day', () async {
      await repo.addBirthday(personId: ana, month: 2, day: 29);
      await repo.addBirthday(personId: ana, month: 2, day: 29, year: 2000);
      expect(
        () => repo.addBirthday(personId: ana, month: 2, day: 29, year: 2001),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addBirthday(personId: ana, month: 4, day: 31),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addBirthday(personId: ana, month: 13, day: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addBirthday(personId: ana, month: 1, day: 1, year: 2099),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addBirthday(
          personId: ana,
          month: 1,
          day: 1,
          notifyDaysBefore: 31,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('events must be named and not in the past', () async {
      expect(
        () => repo.addEvent(personId: ana, label: '', date: testToday),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.addEvent(
          personId: ana,
          label: 'x',
          date: testToday.addDays(-1),
        ),
        throwsA(isA<ValidationException>()),
      );
      await repo.addEvent(personId: ana, label: 'move', date: testToday);
    });

    test(
      'acknowledge hides this occurrence; unacknowledge restores it',
      () async {
        final id = await repo.addBirthday(personId: ana, month: 9, day: 25);
        await repo.acknowledgeDate(id, testToday);
        var e = ReminderEngine(await repo.loadSnapshot());
        expect(e.today(testToday), isEmpty);
        await repo.unacknowledgeDate(id);
        e = ReminderEngine(await repo.loadSnapshot());
        expect(e.today(testToday), hasLength(1));
      },
    );
  });

  group('check-ins and moments', () {
    test('setting a rhythm anchors it today; moments reset it', () async {
      final ana = await repo.addPerson(name: 'Ana');
      await repo.setCheckIn(ana, 30);
      var d = (await repo.personDetail(ana))!;
      expect(d.nextCheckIn, testToday.addDays(30));
      expect(
        () => repo.setCheckIn(ana, 0),
        throwsA(isA<ValidationException>()),
      );

      await repo.logMoment(
        personId: ana,
        kind: MomentKind.talked,
        date: testToday,
        note: 'coffee',
      );
      d = (await repo.personDetail(ana))!;
      expect(d.nextCheckIn, testToday.addDays(30));

      await repo.setCheckIn(ana, null);
      d = (await repo.personDetail(ana))!;
      expect(d.nextCheckIn, isNull);
    });

    test('future moments are rejected', () async {
      final ana = await repo.addPerson(name: 'Ana');
      expect(
        () => repo.logMoment(
          personId: ana,
          kind: MomentKind.talked,
          date: testToday.addDays(1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('snapshot carries the latest moment per person', () async {
      final ana = await repo.addPerson(name: 'Ana');
      await repo.logMoment(
        personId: ana,
        kind: MomentKind.talked,
        date: testToday.addDays(-10),
      );
      await repo.logMoment(
        personId: ana,
        kind: MomentKind.talked,
        date: testToday.addDays(-2),
      );
      final s = await repo.loadSnapshot();
      expect(s.lastMomentByPerson[ana], testToday.addDays(-2));
    });

    test('skip and snooze check-in, then restore', () async {
      final ana = await repo.addPerson(name: 'Ana');
      await repo.setCheckIn(ana, 14);
      final before = (await repo.personById(ana))!;
      await repo.snoozeCheckIn(ana, testToday.addDays(20));
      expect(
        (await repo.personDetail(ana))!.nextCheckIn,
        testToday.addDays(20),
      );
      await repo.restoreCheckIn(before);
      expect(
        (await repo.personDetail(ana))!.nextCheckIn,
        testToday.addDays(14),
      );
    });
  });

  group('settings', () {
    test('defaults are privacy-preserving', () async {
      final s = await repo.loadSettings();
      expect(s.notificationDetail, NotificationDetail.private);
      expect(s.notificationsEnabled, isTrue);
      expect(s.reminderMinutes, 9 * 60);
      expect(s.onboardingDone, isFalse);
    });

    test('round trip and validation', () async {
      await repo.setReminderMinutes(19 * 60 + 30);
      await repo.setNotificationDetail(NotificationDetail.names);
      await repo.setNotificationsEnabled(false);
      final s = await repo.loadSettings();
      expect(s.reminderMinutes, 19 * 60 + 30);
      expect(s.notificationDetail, NotificationDetail.names);
      expect(s.notificationsEnabled, isFalse);
      expect(
        () => repo.setReminderMinutes(24 * 60),
        throwsA(isA<ValidationException>()),
      );
    });

    test('corrupt values fall back to defaults', () {
      final s = AppSettings.fromMap({
        'reminder_minutes': 'abc',
        'notification_detail': 'everything',
      });
      expect(s.reminderMinutes, AppSettings.defaultReminderMinutes);
      expect(s.notificationDetail, NotificationDetail.private);
    });
  });

  test('deleteAllData wipes everything', () async {
    final ana = await repo.addPerson(name: 'Ana');
    await repo.addFollowUp(personId: ana, body: 'x', due: testToday);
    await repo.setOnboardingDone();
    await repo.deleteAllData();
    expect(await repo.allPeople(), isEmpty);
    expect((await repo.loadSettings()).onboardingDone, isFalse);
    expect(await env.db.select(env.db.followUps).get(), isEmpty);
  });

  test('schema v1 creates tables, indexes and enforces foreign keys', () async {
    final db = env.db;
    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
        )
        .get();
    expect(indexes.map((r) => r.read<String>('name')), hasLength(4));
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
    expect(
      () => db
          .into(db.followUps)
          .insert(
            FollowUpsCompanion.insert(
              personId: 999,
              body: 'orphan',
              dueDate: testToday,
              status: FollowUpStatus.open,
              createdAt: DateTime(2026),
            ),
          ),
      throwsA(anything),
    );
    expect(db.schemaVersion, 1);
  });

  test('watchSnapshot emits after writes', () async {
    final emissions = <int>[];
    final sub = repo.watchSnapshot().listen(
      (s) => emissions.add(s.people.length),
    );
    await pumpEventQueue();
    await repo.addPerson(name: 'Ana');
    await pumpEventQueue();
    await sub.cancel();
    expect(emissions.first, 0);
    expect(emissions.last, 1);
  });

  test('stored dates are timezone-independent integers', () async {
    final ana = await repo.addPerson(name: 'Ana');
    await repo.addFollowUp(
      personId: ana,
      body: 'x',
      due: LocalDate(2026, 10, 25),
    );
    final row = await env.db
        .customSelect('SELECT due_date FROM follow_ups')
        .getSingle();
    expect(row.read<int>('due_date'), 20261025);
  });
}
