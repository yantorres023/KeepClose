# TECHNICAL PLAN

## Stack
- Flutter stable (3.47.x, Dart 3.13), Material 3.
- Persistence: **drift** (SQLite) + `drift_flutter` (bundled sqlite via `sqlite3` package) — typed queries, reactive streams, migrations, in-memory testing.
- Notifications: **flutter_local_notifications** + **timezone** + **flutter_timezone**.
- Contacts: **flutter_native_contact_picker** (OS picker; no READ_CONTACTS / NSContacts permission).
- Reach out: **url_launcher** (`sms:` / `tel:`).
- Date wording is hand-written English in `domain/copy.dart` (no `intl` dependency in V1; localization is future work).
- No state-management package: repositories expose drift `Stream`s; UI uses `StreamBuilder`; dependencies passed through a small `AppScope` InheritedWidget. Rationale in DECISIONS D-006.

## Architecture
```
lib/
  main.dart                 bootstrap (tz init, db open, notifications init)
  app.dart                  MaterialApp, theme, AppScope, routing
  data/
    database.dart           drift tables + migrations
    repository.dart         KeepCloseRepository (all reads/writes, streams)
  domain/
    local_date.dart         LocalDate value type (yyyymmdd)
    reminder_engine.dart    pure deterministic engine
    models.dart             ReminderItem etc.
  services/
    notification_service.dart   abstract + FLN implementation
    reminder_scheduler.dart     engine → notification plan → service
    contact_picker.dart         abstract + native implementation
    launcher.dart               abstract + url_launcher implementation
  ui/ (screens, sheets, widgets)
```
Platform-facing services are interfaces so tests use fakes (permission denied, picker cancelled, etc.).

## Reminder engine (pure Dart)
Input: people, open follow-ups, dates, moments, `today: LocalDate`, horizon.
Output: `List<ReminderItem>` for a date range, and `digestPlan(fromDay, days)` →
per-day counts/items. Rules:
- Follow-up open: due at `due_date`; if `< today` it's shown today as "still".
- Birthday: occurs yearly at (month, day); Feb 29 → Feb 28 in non-leap years; heads-up at `occurrence - notify_days_before`.
- Event: once at its date (+ heads-up).
- Check-in: `anchor = max(check_in_anchor, last moment date)`; due = `anchor + days`; if `snoozed_until > due` use snoozed; if due < today → today.
All date math on `LocalDate` (civil calendar), independent of timezone/DST.

## Notification scheduling
- `ReminderScheduler.sync()` runs on app start/resume and after every write.
- Cancels all pending, then schedules one digest per day for the next 30 days (≤30 < iOS 64 cap) at `reminder_minutes` local time, via `zonedSchedule` with `AndroidScheduleMode.inexactAllowWhileIdle` (no exact-alarm permission; ~minutes of drift acceptable for a gentle nudge).
- Timezone: `tz.local` set from `flutter_timezone` at start and on resume; since we reschedule on resume, a timezone change is corrected on next open. DST: `TZDateTime(local, y, m, d, h, min)` resolves wall-clock time properly; a nonexistent time (spring-forward gap) is normalized forward by the timezone package.
- Past times for "today" are skipped.
- Content by privacy level (private default).
- Android: `RECEIVE_BOOT_COMPLETED` + FLN's boot receiver re-register scheduled notifications.

## Data & migrations
- Schema v1; `MigrationStrategy` with `onUpgrade` stepwise; a migration test validates v1 schema creation and verifies foreign keys `ON DELETE CASCADE` with `PRAGMA foreign_keys = ON`.
- Backups: DB lives in app documents directory; included in OS-managed device backups (iCloud/Google, encrypted by OS). Documented in SECURITY.md. No in-app export in V1.

## Testing
- Unit: LocalDate, reminder engine (DST-irrelevance, leap day, past, snooze, rhythm), notification plan & content privacy, scheduler with fake service (permission denied, disabled).
- Persistence: repository against `NativeDatabase.memory()` (cascade deletes, special characters, long names, duplicates).
- Widget: Today, People, Person detail, Add follow-up, onboarding, settings; text scale 2.0; picker cancelled/failed.
- Golden: Today, People, Person detail, Add follow-up (Ahem font; Linux-generated goldens; CI runs them only on Linux).

## CI (GitHub Actions)
- `ci.yml` (ubuntu): format check, analyze, test, build APK (debug-signed release) + AAB.
- `ios.yml` (macos): test, `flutter build ios --release --no-codesign`.

## Android
- `minSdk 24`? Governed by Flutter default (currently 24+); `compileSdk`/`targetSdk` from Flutter defaults.
- Core library desugaring enabled (required by flutter_local_notifications).
- Permissions: POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED. No contacts, no exact alarms, no INTERNET needed at runtime (Flutter release builds don't add INTERNET; we don't either).
- `<queries>` for `sms`/`tel` intents (Android 11 package visibility).
- Release signing: external blocker (keystore).

## iOS
- Deployment target per Flutter default. No Info.plist usage descriptions needed for contacts picker (CNContactPickerViewController requires no permission). `LSApplicationQueriesSchemes` for sms/tel.
- Signing/TestFlight: external blocker.

## Privacy engineering
- No network code. No logging of user content (`debugPrint` only in debug for errors without payloads).
- Notification content defaults to private.
