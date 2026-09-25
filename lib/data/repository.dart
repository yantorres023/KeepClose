import 'dart:async';

import 'package:drift/drift.dart';

import '../domain/local_date.dart';
import '../domain/reminder_engine.dart';
import 'database.dart';

/// How much a notification reveals on the lock screen.
enum NotificationDetail { private, names, full }

class AppSettings {
  const AppSettings({
    this.reminderMinutes = defaultReminderMinutes,
    this.notificationDetail = NotificationDetail.private,
    this.notificationsEnabled = true,
    this.onboardingDone = false,
    this.notificationPermissionAsked = false,
  });

  static const defaultReminderMinutes = 9 * 60;

  /// Minutes after local midnight for the daily digest.
  final int reminderMinutes;
  final NotificationDetail notificationDetail;
  final bool notificationsEnabled;
  final bool onboardingDone;
  final bool notificationPermissionAsked;

  static AppSettings fromMap(Map<String, String> m) {
    final minutes = int.tryParse(m['reminder_minutes'] ?? '');
    return AppSettings(
      reminderMinutes: minutes != null && minutes >= 0 && minutes < 24 * 60
          ? minutes
          : defaultReminderMinutes,
      notificationDetail: NotificationDetail.values.firstWhere(
        (d) => d.name == m['notification_detail'],
        orElse: () => NotificationDetail.private,
      ),
      notificationsEnabled: m['notifications_enabled'] != 'false',
      onboardingDone: m['onboarding_done'] == 'true',
      notificationPermissionAsked: m['notification_permission_asked'] == 'true',
    );
  }
}

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Everything a person-detail screen shows.
class PersonDetail {
  const PersonDetail({
    required this.person,
    required this.openFollowUps,
    required this.dates,
    required this.moments,
    required this.nextCheckIn,
  });

  final Person person;
  final List<FollowUp> openFollowUps;
  final List<ImportantDate> dates;
  final List<Moment> moments;
  final LocalDate? nextCheckIn;
}

/// Single access point for all local data. All writes validate input.
class KeepCloseRepository {
  KeepCloseRepository(
    this.db, {
    LocalDate Function()? today,
    DateTime Function()? now,
  }) : _today = today ?? LocalDate.today,
       _now = now ?? DateTime.now;

  final AppDatabase db;
  final LocalDate Function() _today;
  final DateTime Function() _now;

  static const maxNameLength = 80;
  static const maxFollowUpLength = 200;
  static const maxNoteLength = 1000;
  static const maxLabelLength = 60;

  LocalDate get today => _today();

  // ---------------------------------------------------------------- people

  Stream<List<Person>> watchPeople() =>
      (db.select(
            db.people,
          )..orderBy([(p) => OrderingTerm.asc(p.name.collate(Collate.noCase))]))
          .watch();

  Future<List<Person>> allPeople() => (db.select(
    db.people,
  )..orderBy([(p) => OrderingTerm.asc(p.name.collate(Collate.noCase))])).get();

  Stream<Person?> watchPerson(int id) =>
      (db.select(db.people)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<Person?> personById(int id) =>
      (db.select(db.people)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> addPerson({
    required String name,
    String? note,
    String? phone,
    String? contactRef,
  }) {
    final now = _now();
    return db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            name: _validName(name),
            note: Value(_optional(note, maxNoteLength)),
            phone: Value(_optional(phone, 40)),
            contactRef: Value(_optional(contactRef, 200)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updatePerson(
    int id, {
    required String name,
    String? note,
    String? phone,
  }) async {
    await (db.update(db.people)..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        name: Value(_validName(name)),
        note: Value(_optional(note, maxNoteLength)),
        phone: Value(_optional(phone, 40)),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Returns an existing person that looks like the same contact, if any.
  Future<Person?> findDuplicate({
    String? contactRef,
    required String name,
    String? phone,
  }) async {
    final people = await db.select(db.people).get();
    final normalizedName = name.trim().toLowerCase();
    final normalizedPhone = _digits(phone);
    for (final p in people) {
      if (contactRef != null && p.contactRef == contactRef) return p;
      if (p.name.trim().toLowerCase() == normalizedName &&
          (normalizedPhone.isEmpty || _digits(p.phone) == normalizedPhone)) {
        return p;
      }
    }
    return null;
  }

  /// Turns the optional check-in rhythm on (with [days]) or off (null).
  Future<void> setCheckIn(int personId, int? days) async {
    if (days != null && (days < 1 || days > 366)) {
      throw ValidationException('Choose a rhythm between 1 and 366 days.');
    }
    await (db.update(db.people)..where((p) => p.id.equals(personId))).write(
      PeopleCompanion(
        checkInDays: Value(days),
        checkInAnchor: Value(days == null ? null : today),
        checkInSnoozedUntil: const Value(null),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> snoozeCheckIn(int personId, LocalDate until) async {
    await (db.update(db.people)..where((p) => p.id.equals(personId))).write(
      PeopleCompanion(checkInSnoozedUntil: Value(until)),
    );
  }

  /// Restores check-in fields (used for undo).
  Future<void> restoreCheckIn(Person p) async {
    await (db.update(db.people)..where((x) => x.id.equals(p.id))).write(
      PeopleCompanion(
        checkInAnchor: Value(p.checkInAnchor),
        checkInSnoozedUntil: Value(p.checkInSnoozedUntil),
      ),
    );
  }

  /// "Let go" of this round: the next suggestion comes a full rhythm later.
  Future<void> skipCheckIn(int personId) async {
    await (db.update(db.people)..where((p) => p.id.equals(personId))).write(
      PeopleCompanion(
        checkInAnchor: Value(today),
        checkInSnoozedUntil: const Value(null),
      ),
    );
  }

  /// Deletes a person and (via cascade) all their reminders and moments.
  Future<void> deletePerson(int id) =>
      (db.delete(db.people)..where((p) => p.id.equals(id))).go();

  Stream<PersonDetail?> watchPersonDetail(int id) => _watch([
    db.people,
    db.followUps,
    db.importantDates,
    db.moments,
  ], () => personDetail(id));

  Future<PersonDetail?> personDetail(int id) async {
    final person = await personById(id);
    if (person == null) return null;
    final followUps =
        await (db.select(db.followUps)
              ..where(
                (f) =>
                    f.personId.equals(id) &
                    f.status.equalsValue(FollowUpStatus.open),
              )
              ..orderBy([(f) => OrderingTerm.asc(f.dueDate)]))
            .get();
    final dates =
        await (db.select(db.importantDates)
              ..where((d) => d.personId.equals(id))
              ..orderBy([
                (d) => OrderingTerm.asc(d.month),
                (d) => OrderingTerm.asc(d.day),
              ]))
            .get();
    final moments =
        await (db.select(db.moments)
              ..where((m) => m.personId.equals(id))
              ..orderBy([
                (m) => OrderingTerm.desc(m.date),
                (m) => OrderingTerm.desc(m.createdAt),
              ])
              ..limit(10))
            .get();
    final last = moments.isEmpty ? null : moments.first.date;
    return PersonDetail(
      person: person,
      openFollowUps: followUps,
      dates: dates,
      moments: moments,
      nextCheckIn: ReminderEngine.nextCheckIn(person, last),
    );
  }

  // ------------------------------------------------------------ follow-ups

  Future<int> addFollowUp({
    required int personId,
    required String body,
    required LocalDate due,
  }) {
    final text = body.trim();
    if (text.isEmpty) {
      throw ValidationException('Write what you want to ask about.');
    }
    if (text.length > maxFollowUpLength) {
      throw ValidationException('Keep it under $maxFollowUpLength characters.');
    }
    if (due.isBefore(today)) {
      throw ValidationException('Pick today or a later day.');
    }
    return db
        .into(db.followUps)
        .insert(
          FollowUpsCompanion.insert(
            personId: personId,
            body: text,
            dueDate: due,
            status: FollowUpStatus.open,
            createdAt: _now(),
          ),
        );
  }

  Future<FollowUp?> followUpById(int id) => (db.select(
    db.followUps,
  )..where((f) => f.id.equals(id))).getSingleOrNull();

  /// Marks a follow-up done and records it as a moment. Returns the moment id.
  Future<int> completeFollowUp(int id) => db.transaction(() async {
    final f = await followUpById(id);
    if (f == null) throw ValidationException('This reminder no longer exists.');
    await (db.update(db.followUps)..where((x) => x.id.equals(id))).write(
      FollowUpsCompanion(
        status: const Value(FollowUpStatus.done),
        resolvedAt: Value(_now()),
      ),
    );
    return db
        .into(db.moments)
        .insert(
          MomentsCompanion.insert(
            personId: f.personId,
            date: today,
            kind: MomentKind.followedUp,
            note: Value(f.body),
            createdAt: _now(),
          ),
        );
  });

  Future<void> undoCompleteFollowUp(int id, int momentId) =>
      db.transaction(() async {
        await (db.update(db.followUps)..where((x) => x.id.equals(id))).write(
          const FollowUpsCompanion(
            status: Value(FollowUpStatus.open),
            resolvedAt: Value(null),
          ),
        );
        await (db.delete(db.moments)..where((m) => m.id.equals(momentId))).go();
      });

  Future<void> snoozeFollowUp(int id, LocalDate until) async {
    if (until.isBefore(today)) {
      throw ValidationException('Pick today or a later day.');
    }
    await (db.update(db.followUps)..where((x) => x.id.equals(id))).write(
      FollowUpsCompanion(dueDate: Value(until)),
    );
  }

  Future<void> dismissFollowUp(int id) async {
    await (db.update(db.followUps)..where((x) => x.id.equals(id))).write(
      FollowUpsCompanion(
        status: const Value(FollowUpStatus.dismissed),
        resolvedAt: Value(_now()),
      ),
    );
  }

  /// Puts a follow-up back exactly as it was (used for undo).
  Future<void> restoreFollowUp(FollowUp original) async {
    await db.update(db.followUps).replace(original);
  }

  Future<void> deleteFollowUp(int id) =>
      (db.delete(db.followUps)..where((f) => f.id.equals(id))).go();

  // ------------------------------------------------------- important dates

  Future<int> addBirthday({
    required int personId,
    required int month,
    required int day,
    int? year,
    int notifyDaysBefore = 0,
  }) {
    _validateMonthDay(month, day, year ?? 2000);
    if (year != null && (year < 1900 || year > today.year)) {
      throw ValidationException('That birth year doesn\'t look right.');
    }
    return db
        .into(db.importantDates)
        .insert(
          ImportantDatesCompanion.insert(
            personId: personId,
            kind: DateKind.birthday,
            month: month,
            day: day,
            year: Value(year),
            notifyDaysBefore: Value(_validLead(notifyDaysBefore)),
            createdAt: _now(),
          ),
        );
  }

  Future<int> addEvent({
    required int personId,
    required String label,
    required LocalDate date,
    int notifyDaysBefore = 0,
  }) {
    final text = label.trim();
    if (text.isEmpty) throw ValidationException('Give the date a short name.');
    if (text.length > maxLabelLength) {
      throw ValidationException('Keep it under $maxLabelLength characters.');
    }
    if (date.isBefore(today)) {
      throw ValidationException('Pick today or a later day.');
    }
    return db
        .into(db.importantDates)
        .insert(
          ImportantDatesCompanion.insert(
            personId: personId,
            kind: DateKind.event,
            label: Value(text),
            month: date.month,
            day: date.day,
            year: Value(date.year),
            notifyDaysBefore: Value(_validLead(notifyDaysBefore)),
            createdAt: _now(),
          ),
        );
  }

  Future<void> acknowledgeDate(int id, LocalDate occurrence) async {
    await (db.update(db.importantDates)..where((d) => d.id.equals(id))).write(
      ImportantDatesCompanion(acknowledgedFor: Value(occurrence)),
    );
  }

  Future<void> unacknowledgeDate(int id) async {
    await (db.update(db.importantDates)..where((d) => d.id.equals(id))).write(
      const ImportantDatesCompanion(acknowledgedFor: Value(null)),
    );
  }

  Future<void> deleteDate(int id) =>
      (db.delete(db.importantDates)..where((d) => d.id.equals(id))).go();

  // --------------------------------------------------------------- moments

  Future<int> logMoment({
    required int personId,
    required MomentKind kind,
    LocalDate? date,
    String? note,
  }) {
    final d = date ?? today;
    if (d.isAfter(today)) {
      throw ValidationException('Moments can\'t be in the future.');
    }
    return db
        .into(db.moments)
        .insert(
          MomentsCompanion.insert(
            personId: personId,
            date: d,
            kind: kind,
            note: Value(_optional(note, maxNoteLength)),
            createdAt: _now(),
          ),
        );
  }

  Future<void> deleteMoment(int id) =>
      (db.delete(db.moments)..where((m) => m.id.equals(id))).go();

  // -------------------------------------------------------------- snapshot

  Future<ReminderSnapshot> loadSnapshot() async {
    final people = await db.select(db.people).get();
    final followUps = await (db.select(
      db.followUps,
    )..where((f) => f.status.equalsValue(FollowUpStatus.open))).get();
    final dates = await db.select(db.importantDates).get();
    final maxDate = db.moments.date.max();
    final rows =
        await (db.selectOnly(db.moments)
              ..addColumns([db.moments.personId, maxDate])
              ..groupBy([db.moments.personId]))
            .get();
    final last = <int, LocalDate>{
      for (final r in rows)
        if (r.read(maxDate) != null)
          r.read(db.moments.personId)!: LocalDate.fromKey(r.read(maxDate)!),
    };
    return ReminderSnapshot(
      people: people,
      openFollowUps: followUps,
      dates: dates,
      lastMomentByPerson: last,
    );
  }

  Stream<ReminderSnapshot> watchSnapshot() => _watch([
    db.people,
    db.followUps,
    db.importantDates,
    db.moments,
  ], loadSnapshot);

  // -------------------------------------------------------------- settings

  Future<AppSettings> loadSettings() async {
    final rows = await db.select(db.settings).get();
    return AppSettings.fromMap({for (final r in rows) r.key: r.value});
  }

  Stream<AppSettings> watchSettings() => db
      .select(db.settings)
      .watch()
      .map(
        (rows) => AppSettings.fromMap({for (final r in rows) r.key: r.value}),
      );

  Future<void> _set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> setReminderMinutes(int minutes) {
    if (minutes < 0 || minutes >= 24 * 60) {
      throw ValidationException('Invalid time.');
    }
    return _set('reminder_minutes', '$minutes');
  }

  Future<void> setNotificationDetail(NotificationDetail d) =>
      _set('notification_detail', d.name);

  Future<void> setNotificationsEnabled(bool enabled) =>
      _set('notifications_enabled', '$enabled');

  Future<void> setOnboardingDone() => _set('onboarding_done', 'true');

  Future<void> setNotificationPermissionAsked() =>
      _set('notification_permission_asked', 'true');

  /// Irreversibly removes every person, reminder, moment and setting.
  Future<void> deleteAllData() => db.transaction(() async {
    await db.delete(db.moments).go();
    await db.delete(db.importantDates).go();
    await db.delete(db.followUps).go();
    await db.delete(db.people).go();
    await db.delete(db.settings).go();
  });

  // --------------------------------------------------------------- helpers

  /// Emits [load] now and again after any change to [tables]. Bursts of
  /// changes are coalesced so a slow load never queues up stale work.
  Stream<T> _watch<T>(List<TableInfo> tables, Future<T> Function() load) {
    late final StreamController<T> controller;
    StreamSubscription<void>? updates;
    var loading = false;
    var dirty = false;

    Future<void> refresh() async {
      if (loading) {
        dirty = true;
        return;
      }
      loading = true;
      try {
        do {
          dirty = false;
          final value = await load();
          if (!controller.isClosed) controller.add(value);
        } while (dirty && !controller.isClosed);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        updates = db
            .tableUpdates(TableUpdateQuery.onAllTables(tables))
            .listen((_) => refresh());
        refresh();
      },
      onCancel: () {
        updates?.cancel();
        updates = null;
      },
    );
    return controller.stream;
  }

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Add a name.');
    if (n.length > maxNameLength) {
      throw ValidationException(
        'Keep the name under $maxNameLength characters.',
      );
    }
    return n;
  }

  static String? _optional(String? value, int max) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.length > max) {
      throw ValidationException(
        'That\'s a bit long — keep it under $max characters.',
      );
    }
    return v;
  }

  static String _digits(String? s) =>
      (s ?? '').replaceAll(RegExp(r'[^0-9]'), '');

  static int _validLead(int days) {
    if (days < 0 || days > 30) {
      throw ValidationException('Heads-up must be 0–30 days.');
    }
    return days;
  }

  static void _validateMonthDay(int month, int day, int year) {
    if (month < 1 || month > 12) throw ValidationException('Invalid month.');
    final maxDay = DateTime.utc(year, month + 1, 0).day;
    final allowed = month == 2 ? 29 : maxDay;
    if (day < 1 || day > allowed) throw ValidationException('Invalid day.');
    if (month == 2 && day == 29 && !LocalDate.isLeapYear(year)) {
      throw ValidationException('That year had no February 29.');
    }
  }
}
