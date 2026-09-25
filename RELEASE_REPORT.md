# KeepClose Autonomous Build Report

_Date: 2026-09-25 · Branch: `claude/busy-einstein-8fr6o1`_

## Executive Summary
Public-evidence research (no interviews were possible) found the broad "stay close to
everyone" idea crowded and weakly differentiated, so the product was **pivoted** to a
narrower wedge: **"Remember to ask"**. You note what someone told you (an interview, a
move, a hard week) and get one gentle reminder to ask how it went. A working Flutter MVP
for Android and iOS was built: on-device only, no account, no contacts permission, at most
one notification a day, private lock-screen text by default. 99 automated tests pass
locally and `flutter analyze` is clean. Store signing, store accounts, an app icon and
real-user validation are still needed from a person.

## Decision
**PIVOT**: from cadence-based relationship maintenance (Thesis A) to follow-ups (Thesis B),
with important dates (C) and an optional check-in rhythm (A) as supporting features.

## Final Product Name
Working name **KeepClose**. Proposed store name "KeepClose: Remember to Ask". **Not
trademark-cleared.** Similar names exist ("Keep Close", a bereavement app; "Check Up:
Keep Friends Close"). Alternatives are in `docs/product/BRAND.md`.

## Market / ICP
Adults aged about 25–45 who care about a handful of people and are busy or going through a
transition (new job, new city, new parent, long distance). The problem is well documented:
47% of US adults lost touch with some friends in the past year, and friendship closeness
fades without contact. There is no evidence of willingness to pay. See
`docs/research/MARKET.md`.

## Selected Product Thesis
"When someone tells me about something coming up, help me remember to ask about it
afterwards, so they know I was listening."

## Why This Thesis Won
- It has a natural trigger (a conversation), so the app doesn't have to invent one.
- It needs one field and a day, not a CRM-style profile.
- The reminder carries its own reason to reach out ("ask how the interview went"). That
  may lower the awkwardness barrier: Sandstrom & Aknin (2024) found that fewer than a third
  of people messaged an old friend even when they wanted to.
- Thesis A is crowded: at least 12 near-identical cadence apps were found. Thesis C
  (dates) is already handled by the phone's own calendar and contacts.

## Evidence Strength
Low to medium. Evidence came from search-result excerpts only, because the environment
blocked direct access to Reddit, Hacker News, the app stores and most publishers (see
`docs/research/SOURCES.md`). The strongest evidence is academic and concerns the problem,
not demand for this product. The follow-up wedge itself has the **weakest direct demand
evidence** (ledger item A7).

## Major Contrary Evidence
- Hesitation, not memory, is often the bottleneck for reaching out (Sandstrom & Aknin 2024).
- Free alternatives are abundant, and iOS 26 suggests follow-ups using AI.
- There are no willingness-to-pay signals for friend-focused apps.
- Personal CRMs have a history of churn because data entry feels like work.

## Unvalidated Assumptions
All of the product assumptions are unvalidated, in particular: people will capture
follow-ups (A7), a follow-up prompt makes reaching out easier (A8), people will pay (A10),
and notifications won't annoy (A11). See `docs/research/EVIDENCE_LEDGER.md`.

## Product Built
- **Onboarding**: 3 pages (the promise, privacy, reminder time). No permission prompts.
- **People**: add by hand, or pick one contact through the system picker (no permission
  needed). Duplicate detection, edit, and delete with confirmation.
- **Remember to ask**: one line plus quick day chips (Tomorrow, 3 days, Next week,
  2 weeks, Pick).
- **Dates**: birthdays (year optional; Feb 29 handled) and one-off events, each with an
  optional heads-up.
- **Optional "check in now and then" rhythm**: off by default.
- **Today**: due items and Coming up (14 days). Actions are Asked/Done, Later and Let go,
  all undoable. Past items read "Still want to…?". There are no counts or day numbers.
- **Person page**: note, Message/Call (these open the phone's own apps and never send
  anything), open follow-ups, dates, rhythm, and moments ("We talked").
- **Settings**: reminder time, notifications on/off, lock-screen detail level
  (Private/Names/Full), privacy explainer, delete-all (type "DELETE" to confirm; also runs
  VACUUM), licences.

## Core User Flow
Add person → **Remember to ask** → type "how the interview went" → Tomorrow → (the
notification permission is requested now, once) → next day at 09:00 one private
notification → Today → Message → **Asked** (automatically saved as a moment).

## Architecture
Flutter 3.47.5 / Dart 3.13. drift (SQLite) with a coalescing stream watcher; a pure
`ReminderEngine` using civil `LocalDate` math; a `ReminderScheduler` that plans one digest
per day for 30 days and fully resyncs on every change and on resume. Platform services sit
behind interfaces (notifications, contact picker, launcher). There is no state-management
package. See `docs/engineering/TECHNICAL_PLAN.md`.

## Privacy Model
- Everything stays on the device.
- No network code, analytics, ads or AI.
- No contacts, SMS or exact-alarm permissions.
- Lock-screen notifications don't show names or notes by default.
- OS backups may include the database; the app discloses this.

Details are in `docs/engineering/SECURITY.md`. The legal drafts in `legal/` need a lawyer.

## Notification Model
- At most 1 notification a day, at a time the user chooses, and only on days with something
  new.
- Missed items are never announced again.
- Scheduling is inexact (`inexactAllowWhileIdle`).
- Notifications are rescheduled after a reboot (boot receiver).
- DST is handled, and the timezone is refreshed on resume.

## Tests
99 tests, all passing locally (`flutter test`); `dart format` and `flutter analyze` are clean:
- **Unit tests**: LocalDate (DST, leap years), reminder engine (heads-up, year wrap,
  snooze, acknowledgement, performance with 5,000 items), copy/tone (no "overdue", no day
  counts).
- **Persistence tests** (in-memory SQLite): cascade deletes, special characters and emoji,
  an SQL-injection string, validation, schema, indexes and foreign keys, stream updates.
- **Scheduler tests**:
  - New York DST fall-back.
  - A reminder time that falls in the spring-forward gap.
  - Timezone change (Tokyo, Los Angeles, Lord Howe).
  - The 30-day cap.
  - Privacy levels (the default text leaks nothing).
  - Permission denied.
  - Recovery after a platform error.
  - Automatic resync.
- **Widget tests**:
  - Onboarding.
  - Adding a person.
  - The core loop with Undo.
  - Later and Let go.
  - Permission denied.
  - Contact picker: cancel, failure, picked, duplicate.
  - Message launch.
  - Delete person and delete all.
  - Birthday.
  - Rhythm and moments.
  - Resuming on a new day.
- **Accessibility tests**: Android and iOS tap-target, labelled tap-target and contrast
  guidelines; semantics labels; text scale 1.5× and 2.0× on all main screens; onboarding at
  2.0× on a 320-pt-wide phone.
- **Goldens**: Today, People, Person detail, Add follow-up (generated on Linux with Roboto).

Tests found and fixed real bugs:
- Duplicate FAB hero tags crashed navigation.
- The delete-all dialog used a text controller after it had been disposed.
- The wording "Moved to on Fri".
- A stream watcher hung when cancelled.
- Today kept showing yesterday's date after resuming on a new day.

Limitations: automated UI tests run in the Flutter test environment, not on devices. In
goldens, elevation shadows render as black outlines (a test artefact). Real notification
delivery, the OS contact picker and SMS/phone intents cannot be exercised headlessly.

## Android
- **Local builds**: not possible. The container's network policy blocks
  `dl.google.com`, so the Android SDK can't be installed (`flutter build apk` → "No Android
  SDK found").
- **CI**: `.github/workflows/ci.yml` builds a release APK and AAB. Without an upload key
  they are debug-signed, so they are for verifying the build only.
- **CI status:** on commit `b39013d`, format, analyze, all tests (including goldens), the
  release APK and the release AAB **all passed** on GitHub Actions. An earlier run failed
  because of a Gradle Kotlin DSL error (`java.util` inside the `android {}` block); that is
  fixed in `cdc4835`.
- **Configuration**:
  - targetSdk 36 (meets Google Play's 31 Aug 2026 requirement), minSdk 24.
  - Core library desugaring enabled.
  - Permissions: only POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED.
  - applicationId `app.keepclose`.

## iOS
- `.github/workflows/ios.yml` runs on macOS: tests without goldens, then
  `flutter build ios --release --no-codesign`. **Both passed** on commit `b39013d`.
- **Configuration**:
  - Bundle ID `app.keepclose`, deployment target 15.0.
  - The notification delegate is set in AppDelegate.
  - `LSApplicationQueriesSchemes` includes sms and tel.
  - `ITSAppUsesNonExemptEncryption=false`.
- **External blockers**: signing and TestFlight.

## Monetization
V1 is free with no paywall. If the retention gates pass, test a one-time "Plus" unlock at
$4.99–$9.99 for extras (widgets, themes, encrypted export). Charge a subscription only if
optional sync ever ships. See `docs/business/MONETIZATION.md`.

## Distribution
- **Channels**: short-form video built around the relatable "they remembered to ask"
  moment, friendship and long-distance creators, Reddit where it's allowed, and SEO.
- **Planned content**: 10 video ideas and 10 SEO ideas, plus hypotheses for referrals and
  creator partnerships.
- **Rule**: never exploit loneliness.

No outreach was done. See `docs/business/GROWTH.md`.

## Landing Page
`landing/index.html` is a static page with no dependencies. It covers the problem, how it
works, privacy, an FAQ and a beta call to action. It has no fake testimonials or metrics.
It was checked at 375 px with no horizontal scroll. **The beta email address is a
placeholder (`beta@example.com`).**

## Known Bugs
None known after this pass. Known limitations:
- Notifications that are already scheduled keep the old timezone until the app is opened
  after travel.
- If the app stays open across midnight without being backgrounded, Today refreshes only on
  the next data change or on resume.
- The `contact_ref` column is unused because the picker returns no stable ID; it's
  reserved.
- Copy is English only.
- The app still has the default Flutter icon.

## Technical Debt
- No export/import.
- No app lock.
- No widgets or share-sheet capture.
- `restoreFollowUp` replaces the whole row. That's fine for Undo, but it would overwrite an
  edit made between the action and the Undo.
- Android release signing in CI isn't wired up (it needs secrets).
- Localization is hand-written English in `domain/copy.dart`.

## External Blockers
Apple Developer account and signing; Google Play developer account and upload key; an app
icon and store screenshots (design); legal review; trademark search; a support email and
hosting for the privacy policy; recruiting real beta users.

## HUMAN_ACTION_REQUIRED
1. **ACTION:** Create the Android upload key and signing config.
   **WHY:** CI builds are debug-signed and Play will reject them.
   **EXACT STEPS:** follow `release/android/SIGNING.md`, then run
   `flutter build appbundle --release`.
2. **ACTION:** Set up a Google Play Console account and closed test.
   **WHY:** Distribution. New personal accounts need 12 opted-in testers for 14 days before
   production access.
   **EXACT STEPS:**
   1. Create the developer account ($25).
   2. Create the app `app.keepclose`.
   3. Fill in Data safety ("no data collected") and the content rating from
      `release/android/STORE_LISTING.md`.
   4. Upload the AAB to Closed testing and invite at least 12 testers.
3. **ACTION:** Set up the Apple Developer Program and TestFlight.
   **WHY:** iOS distribution.
   **EXACT STEPS:**
   1. Enrol ($99/yr).
   2. Register the bundle ID `app.keepclose`.
   3. On a Mac, open `ios/Runner.xcworkspace`, set the Team and use automatic signing.
   4. Run `flutter build ipa`.
   5. Upload with Transporter or Xcode.
   6. Fill in App Privacy ("Data Not Collected") from `release/ios/STORE_LISTING.md`.
4. **ACTION:** Get an app icon and store screenshots.
   **WHY:** The default Flutter icon blocks a credible launch.
   **EXACT STEPS:**
   1. Commission art from the brief in `docs/product/BRAND.md`.
   2. Replace the icons, for example with `flutter_launcher_icons`.
   3. Capture screenshots with demo data, following the store listing plans.
5. **ACTION:** Get legal review.
   **WHY:** `legal/*.md` are drafts with placeholders.
   **EXACT STEPS:** Fill in `[PUBLISHER]`, `[SUPPORT_EMAIL]` and `[JURISDICTION]`, have a
   lawyer review the drafts, and host them at a public URL.
6. **ACTION:** Do a trademark and name check.
   **WHY:** "KeepClose" has nearby conflicts.
   **EXACT STEPS:** Search USPTO/EUIPO and the app stores, and pick the final name
   (alternatives are in BRAND.md).
7. **ACTION:** Recruit and run the first beta.
   **WHY:** Nothing is validated with real users.
   **EXACT STEPS:** Follow `docs/research/VALIDATION_DEBT.md`.
8. **ACTION:** Publish the landing page.
   **WHY:** A fake-door test is the cheapest demand signal.
   **EXACT STEPS:** Replace `beta@example.com` with a real address or a form, then host
   `landing/` (for example on GitHub Pages or Netlify).

## Real-User Validation Debt
There are 10 tests with pass/fail thresholds and the cheapest method for each, covering:
- Onboarding completion.
- How many people get added.
- Follow-up creation.
- Reminder opens.
- Reminders acted on.
- Week-2 retention.
- Notification annoyance.
- Willingness to pay (painted-door test).
- Preference over the phone's own Reminders app.
- Whether privacy matters to users.

See `docs/research/VALIDATION_DEBT.md`.

## Initial Beta Metrics
These are experimental gates, not proven benchmarks:
- **Activation**: at least 40% add 3 or more people and create at least 1 follow-up within
  7 days.
- **Behavior**: at least 30% of activated users resolve at least 1 reminder within 14 days.
- **Week-2 retention**: at least 25%.
- **Notifications**: no more than 20% disable them by day 14.

## Kill/Pivot Thresholds
- **STOP** if activation is under 25% and behavior is under 15%.
- **STOP** if under 40% prefer KeepClose over their Reminders app.
- **Pivot to conversation starters** if activation is fine but behavior is under 15%.
- **Try share-sheet capture once, then STOP** if week-2 retention is under 15%.
- **Redesign the digest first** if more than 35% disable notifications.

## Recommended First Beta
- **Who**: 30–60 people from the ICP.
- **Where**: TestFlight and a Play closed test (which also meets Play's 12-tester rule).
- **Length**: 21 days.
- **Measurement**: an opt-in instrumented build (see the ANALYTICS.md taxonomy) plus a
  5-question survey on day 14.

## Next 3 Experiments
1. A fake-door landing page testing two heroes (privacy-led vs benefit-led).
2. A 30-person closed beta against the gates above.
3. A capture-friction test: in-app capture vs share-sheet/widget capture.

## Files To Review First
1. `docs/research/RED_TEAM.md`, `docs/research/EVIDENCE_LEDGER.md`: why PIVOT.
2. `docs/product/PRODUCT_STRATEGY.md`, `docs/product/PRD.md`
3. `lib/domain/reminder_engine.dart`, `lib/services/reminder_scheduler.dart`: the core
   logic.
4. `lib/ui/screens/today_screen.dart`: the core UX.
5. `docs/engineering/SECURITY.md`
6. `docs/research/VALIDATION_DEBT.md`
7. `docs/research/FINAL_RED_TEAM.md`

## Final Repository Status
All work is committed and pushed to `claude/busy-einstein-8fr6o1`. No pull request was
opened. GitHub Actions on `b39013d`: **CI (format, analyze, test, APK, AAB) passed** and
**iOS (test, no-codesign release build) passed**. Locally: 99/99 tests pass and the
analyzer is clean.
