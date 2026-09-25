# SECURITY & PRIVACY REVIEW (V1)

Scope: the Flutter app as of this commit. Reviewer: automated build agent (not a
professional security audit). Threat model: lost/stolen/unlocked phone, shoulder-surfing
the lock screen, OS backups, third-party SDKs, accidental data leaks in logs.

| Area | Finding | Decision / mitigation | Residual risk |
|---|---|---|---|
| Network | App code makes no network calls. No analytics/crash SDKs. Android release manifest has no INTERNET permission (Flutter adds it only to debug/profile). | Keep it that way; any future network feature needs a new review. | Low |
| Contacts | Uses the OS contact picker (`ACTION_PICK` / `CNContactPickerViewController`). No READ_CONTACTS / NSContactsUsageDescription. App receives only the picked person's name + phone. | Only name + optional phone stored. Nothing uploaded. | Low |
| Messages | Never reads SMS/iMessage/WhatsApp/call logs. "Message"/"Call" open `sms:`/`tel:` with a number; the user sends manually. | — | None |
| Local database | SQLite file in the app's private sandbox (`drift_flutter` default location). Not encrypted at rest by the app; relies on OS file-based encryption (iOS Data Protection, Android FBE) which protects it while the device is locked. | Accept for V1. Future: SQLCipher option if users request it. | Medium on rooted/jailbroken devices |
| Lock-screen notifications | Notes can be sensitive (health, relationships). | **Default "Private"**: body says only "You have N gentle reminders today." Android channel visibility = `private`. "Names only"/"Full details" are opt-in and explained in Settings. | Low |
| Notification volume | — | ≤1 per day, inexact alarm, no exact-alarm permission. | Low |
| OS backups | iCloud/Google device backups may include the DB. | Disclosed in-app (Privacy screen) and in privacy policy. Android `allowBackup` left at default (true) so users don't lose data when switching phones; Google backups are E2E-encrypted with the screen lock on Android 9+. | Medium (user-controlled) |
| Exports | No export in V1 → no plaintext files leaving the sandbox. | Future export must be user-initiated and warn about sensitivity. | None |
| Logs | `debugPrint` is used only for error *types* (`runtimeType`), never for names or notes. It also prints in release builds, which is why user content is never passed to it. | Code review rule: never log user content. | Low |
| Deletion | Person delete cascades (FK `ON DELETE CASCADE`, `PRAGMA foreign_keys=ON`, tested). "Delete all data" wipes all tables and cancels notifications. Uninstall removes sandbox. Delete-all runs `VACUUM` so freed pages are not left in the file. | Single-person deletes do not vacuum (acceptable). | Low |
| Input handling | All writes validated (length limits, dates); drift uses parameterized queries (SQL injection test with a hostile note string passes). | — | Low |
| Third-party packages | drift, drift_flutter/sqlite3, flutter_local_notifications, flutter_timezone, timezone, flutter_native_contact_picker, url_launcher — all widely used; none transmit data. | Pin via pubspec.lock; review on upgrade. | Low |
| App-switcher snapshot | OS may show a screenshot of the app in the task switcher. | Accept for V1; future option "hide content in app switcher". | Low |
| Screen lock inside app | None. | Future: optional biometric lock. | Medium for shared-phone users |

## Conservative defaults summary
Private notifications · no contacts permission · no network · no account · notification
permission requested only after the first reminder is created.

## Action items (post-V1)
1. Optional app lock (biometrics).
2. Optional "hide in app switcher".
3. Consider SQLCipher if sensitive-use feedback warrants.
