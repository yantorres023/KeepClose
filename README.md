# KeepClose — Remember to ask

A private, on-device Flutter app (Android + iOS) that helps you remember the small things
people tell you — an interview, a move, a hard week — and gently reminds you to ask how it
went. No account, no server, no contacts permission, at most one notification a day.

**Start here:** [`RELEASE_REPORT.md`](RELEASE_REPORT.md) · state: [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) · decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md)

## Develop
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing lib/data/database.dart
dart format lib test
flutter analyze
flutter test                          # all tests incl. Linux goldens
flutter test --exclude-tags golden    # on macOS/Windows
flutter test --update-goldens test/golden   # regenerate goldens (Linux only)
```

## Layout
```
lib/domain     LocalDate, deterministic reminder engine, copy/tone
lib/data       drift schema + repository
lib/services   notifications, scheduler, contact picker, launcher (all behind interfaces)
lib/ui         screens and sheets
test/          unit, persistence, scheduler, widget, accessibility, golden tests
docs/          research, product, engineering, business
release/       store listings and signing notes
legal/         draft privacy policy and terms (need legal review)
landing/       static landing page
```
