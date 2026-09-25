# PROJECT STATE — KeepClose

_Last updated: 2026-09-25_

## CURRENT PHASE
Release preparation complete for what's possible autonomously. Next phase: human actions
(signing, store accounts, icon, legal) and a first real-user beta.

## CURRENT PRODUCT THESIS
**PIVOT → "Remember to ask."** Capture what someone told you (an interview, a move, a hard
week) in one line and a day; get one gentle, private reminder to ask how it went.
Supporting features: birthdays/events, and an optional check-in rhythm.

## VALIDATED ASSUMPTIONS
None with real users. Supported by public evidence (problem-level only): adults lose touch
unintentionally; outreach is appreciated more than people expect; cadence apps are a
crowded commodity.

## UNVALIDATED ASSUMPTIONS
- People will capture follow-ups (A7): top risk.
- A follow-up prompt lowers the barrier to reaching out (A8).
- It beats the phone's Reminders app for this job.
- Willingness to pay (A10).
- One daily digest is not annoying (A11).

## REJECTED ASSUMPTIONS
- Cadence "stay in touch" reminders as the primary wedge (crowded; hesitation, not memory, is the barrier for dormant ties).
- Birthdays/dates as the primary wedge (OS commodity).
- Contacts permission / bulk import is needed (OS picker suffices).

## DECISIONS
D-001 … D-011 in docs/DECISIONS.md.

## COMPLETED WORK
- Research: EVIDENCE_LEDGER, MARKET, COMPETITORS, CUSTOMER_LANGUAGE, JTBD, SOURCES, RED_TEAM (PIVOT), FINAL_RED_TEAM, VALIDATION_DEBT.
- Product: PRODUCT_STRATEGY, PRD, UX_SPEC, ANALYTICS, BRAND.
- Engineering: TECHNICAL_PLAN, SECURITY; Flutter app (drift DB, reminder engine, scheduler, all screens); 99 tests passing; analyzer clean.
- CI: ci.yml (format/analyze/test/APK/AAB), ios.yml (test + no-codesign build).
- Business: MONETIZATION, GROWTH. Release: store listings, signing notes. Legal drafts. Landing page.
- RELEASE_REPORT.md.

## KNOWN PROBLEMS
- No local Android SDK (network policy blocks dl.google.com). Android/iOS builds are verified only in CI.
- Default app icon.
- No export/import.
- Pending notifications keep the old timezone until the app is reopened after travel.

## EXTERNAL BLOCKERS
Apple/Google developer accounts and signing, app icon and screenshots, legal review, trademark search, support email and hosting, beta testers.

## NEXT HIGHEST-PRIORITY TASK
Run the fake-door landing test and the 30-person closed beta (docs/research/VALIDATION_DEBT.md).
Engineering next: encrypted export/import and share-sheet capture.
