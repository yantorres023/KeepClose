# DECISIONS LOG

Format: DECISION / OPTIONS / RATIONALE / CONSEQUENCES.

---

## D-001 Install Flutter stable in the container
- DECISION: Install Flutter stable (3.47.5) under /opt/sdk for this session.
- OPTIONS: (a) install SDK locally; (b) rely only on CI.
- RATIONALE: Mission requires `dart format`, `flutter analyze`, `flutter test` to actually run. CI alone gives no fast feedback.
- CONSEQUENCES: SDK is ephemeral; CI workflows pin a Flutter version so results are reproducible.

## D-002 Research method: search-excerpt triangulation
- DECISION: Use web-search result excerpts as the evidence base; label everything by strength.
- OPTIONS: (a) full-page reads of Reddit/HN/store reviews; (b) search excerpts; (c) skip research.
- RATIONALE: The environment's egress policy blocked direct fetches of Reddit, HN, App Store, Play, NCBI and most publishers. (a) was impossible; (c) violates the mission.
- CONSEQUENCES: Confidence capped at MEDIUM for most claims; no review counts or verbatim quotes. Documented in SOURCES.md.

## D-003 PIVOT to the follow-up wedge (Thesis B)
- DECISION: Primary promise = "Remember to ask" (follow-ups). Birthdays/events (C) and optional check-in rhythm (A) are supporting features.
- OPTIONS: A (cadence maintenance), B (follow-ups), C (important dates), adjacent "what to say" starters.
- RATIONALE: A is crowded (12+ near-identical apps) and fights the hesitation barrier (Sandstrom/Aknin 2024) with a content-free nudge; C is an OS commodity. B has a natural external trigger, needs one field, and carries its own reason to reach out.
- CONSEQUENCES: Weakest *direct* demand evidence of the three — top validation priority.

## D-004 No contacts permission; OS contact picker only
- DECISION: flutter_native_contact_picker (ACTION_PICK / CNContactPickerViewController).
- OPTIONS: flutter_contacts with READ_CONTACTS; picker; manual only.
- RATIONALE: Picker gives exactly one user-chosen contact with no permission; best privacy and no permission-denied failure mode.
- CONSEQUENCES: No stable contact ID → duplicates detected by name+phone; no birthday import from contacts.

## D-005 One daily digest notification, inexact, private by default
- DECISION: ≤1 notification/day at a user-chosen time, `inexactAllowWhileIdle`, lock-screen text without names by default; 30-day horizon, full resync on every change and resume.
- OPTIONS: per-item notifications; exact alarms; full-detail default.
- RATIONALE: Minimizes annoyance and lock-screen leakage; avoids Android 14 exact-alarm permission and Play policy review; 30 < iOS's 64 pending cap.
- CONSEQUENCES: Delivery may drift by minutes; after a timezone change, pending notifications use the old zone until the app is opened.

## D-006 No state-management package
- DECISION: drift streams + StreamBuilder (`Watch` widget) + an InheritedWidget for dependencies.
- OPTIONS: Riverpod, Bloc, Provider.
- RATIONALE: App has one data source and few screens; avoids dependency bloat.
- CONSEQUENCES: If the app grows substantially, revisit.

## D-007 Dates stored as civil `yyyymmdd` integers
- DECISION: All reminder math on a `LocalDate` value type; wall-clock applied only when scheduling.
- RATIONALE: DST- and timezone-proof by construction; easy to test.
- CONSEQUENCES: Reminders are day-level (no "remind me at 3pm") — intentional for V1.

## D-008 Missed items stay but are never re-announced
- DECISION: A past-due follow-up/check-in stays in Today ("Still want to…?") but no new notification is sent for it.
- RATIONALE: Avoids nagging/guilt loops.

## D-009 Local toolchain: no Android SDK in the container
- DECISION: Build Android and iOS only in GitHub Actions.
- RATIONALE: dl.google.com (Android SDK downloads) is blocked by the environment's network policy; iOS requires macOS.
- CONSEQUENCES: Local verification = format/analyze/test only.

## D-010 Free V1, no paywall
- DECISION: Ship the beta free; test a one-time unlock later.
- RATIONALE: No WTP evidence; category norms are free/≤$25 lifetime; paywalling people count punishes the core behavior.

## D-011 Keep "KeepClose" as working name
- DECISION: Keep code/working name; store name "KeepClose: Remember to Ask"; final name after trademark search.
- RATIONALE: Conflicts exist ("Keep Close" bereavement app; "Check Up: Keep Friends Close"), but renaming code repeatedly is wasteful.
