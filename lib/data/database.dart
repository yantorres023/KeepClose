import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/local_date.dart';

part 'database.g.dart';

/// Stores a [LocalDate] as a `yyyymmdd` integer.
class LocalDateConverter extends TypeConverter<LocalDate, int> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(int fromDb) => LocalDate.fromKey(fromDb);

  @override
  int toSql(LocalDate value) => value.key;
}

enum FollowUpStatus { open, done, dismissed }

enum DateKind { birthday, event }

enum MomentKind { talked, reachedOut, followedUp }

@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get note => text().nullable()();
  TextColumn get phone => text().nullable()();

  /// Opaque identifier from the OS contact picker, used only to detect
  /// duplicates. Never synced anywhere.
  TextColumn get contactRef => text().nullable()();

  /// Optional gentle check-in rhythm in days. Null means off.
  IntColumn get checkInDays => integer().nullable()();
  IntColumn get checkInAnchor =>
      integer().map(const LocalDateConverter()).nullable()();
  IntColumn get checkInSnoozedUntil =>
      integer().map(const LocalDateConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class FollowUps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId =>
      integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text().withLength(min: 1, max: 200)();
  IntColumn get dueDate => integer().map(const LocalDateConverter())();
  TextColumn get status => textEnum<FollowUpStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

class ImportantDates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId =>
      integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<DateKind>()();
  TextColumn get label => text().nullable()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();

  /// Birth year (optional) for birthdays; required for events.
  IntColumn get year => integer().nullable()();
  IntColumn get notifyDaysBefore => integer().withDefault(const Constant(0))();

  /// The occurrence the user already marked as done, hiding it until the next
  /// one.
  IntColumn get acknowledgedFor =>
      integer().map(const LocalDateConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Moments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId =>
      integer().references(People, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer().map(const LocalDateConverter())();
  TextColumn get kind => textEnum<MomentKind>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [People, FollowUps, ImportantDates, Moments, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'keepclose'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Add stepwise migrations here, e.g. `if (from < 2) { ... }`.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_follow_ups_person ON follow_ups (person_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_follow_ups_status_due ON follow_ups (status, due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dates_person ON important_dates (person_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_moments_person_date ON moments (person_id, date)',
    );
  }
}
