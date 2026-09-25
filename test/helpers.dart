import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/app.dart';
import 'package:keepclose/app_scope.dart';
import 'package:keepclose/data/database.dart';
import 'package:keepclose/data/repository.dart';
import 'package:keepclose/domain/local_date.dart';
import 'package:keepclose/services/contact_picker.dart';
import 'package:keepclose/services/launcher.dart';
import 'package:keepclose/services/notification_service.dart';
import 'package:keepclose/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzReady = false;

void initTimezones([String name = 'UTC']) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  tz.setLocalLocation(tz.getLocation(name));
}

class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permission = PermissionState.granted});

  PermissionState permission;
  int requestCount = 0;
  int cancelAllCount = 0;
  final scheduled = <PlannedNotification>[];
  bool throwOnSchedule = false;

  @override
  Future<void> init({void Function()? onTap}) async {}

  @override
  Future<bool> refreshTimezone() async => false;

  @override
  Future<PermissionState> permissionState() async => permission;

  @override
  Future<PermissionState> requestPermission() async {
    requestCount++;
    return permission;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(PlannedNotification n) async {
    if (throwOnSchedule) throw StateError('boom');
    scheduled.add(n);
  }

  @override
  Future<bool> launchedFromNotification() async => false;
}

class FakeContactPicker implements ContactPicker {
  PickedContact? next;
  bool fail = false;
  int calls = 0;

  @override
  Future<PickedContact?> pick() async {
    calls++;
    if (fail) throw ContactPickerException();
    return next;
  }
}

class FakeLauncher implements Launcher {
  final launched = <String>[];
  bool succeed = true;

  @override
  Future<bool> call(String phone) async {
    launched.add('tel:$phone');
    return succeed;
  }

  @override
  Future<bool> message(String phone) async {
    launched.add('sms:$phone');
    return succeed;
  }
}

/// A fixed "today" used across tests: Friday 25 September 2026.
final testToday = LocalDate(2026, 9, 25);

class TestEnv {
  TestEnv._(this.db, this.deps, this.notifications, this.picker, this.launcher);

  final AppDatabase db;
  final AppDependencies deps;
  final FakeNotificationService notifications;
  final FakeContactPicker picker;
  final FakeLauncher launcher;

  KeepCloseRepository get repo => deps.repository;

  static TestEnv create({
    LocalDate? today,
    DateTime? now,
    PermissionState permission = PermissionState.granted,
  }) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    initTimezones();
    final day = today ?? testToday;
    final clock = now ?? DateTime(day.year, day.month, day.day, 8);
    final db = AppDatabase(NativeDatabase.memory());
    final repo = KeepCloseRepository(db, today: () => day, now: () => clock);
    final notifications = FakeNotificationService(permission: permission);
    final picker = FakeContactPicker();
    final launcher = FakeLauncher();
    final deps = AppDependencies(
      repository: repo,
      notifications: notifications,
      scheduler: ReminderScheduler(
        repository: repo,
        notifications: notifications,
        now: () => clock,
      ),
      contactPicker: picker,
      launcher: launcher,
    );
    return TestEnv._(db, deps, notifications, picker, launcher);
  }

  Future<void> close() => db.close();
}

/// Pumps the full app. Set [onboarded] to skip onboarding.
Future<TestEnv> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  TestEnv? env,
  Future<void> Function(TestEnv env)? seed,
}) async {
  final e = env ?? TestEnv.create();
  await tester.runAsync(() async {
    if (onboarded) await e.repo.setOnboardingDone();
    if (seed != null) await seed(e);
  });
  await tester.pumpWidget(KeepCloseApp(deps: e.deps));
  await settle(tester);
  return e;
}

/// Lets drift stream queries deliver and the UI settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Disposes the widget tree and closes the database cleanly.
Future<void> tearDownApp(WidgetTester tester, TestEnv env) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Let drift's stream-cleanup timers fire in fake time before closing.
  await tester.pump(const Duration(seconds: 1));
  await env.deps.scheduler.stop();
  await tester.runAsync(env.close);
  await tester.pump(const Duration(seconds: 1));
}
