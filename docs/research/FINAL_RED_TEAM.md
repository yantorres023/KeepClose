# FINAL RED TEAM (post-build)

"If this launches tomorrow, what are the 10 most likely reasons it fails?"

| # | Reason | Class | Mitigation status |
|---|---|---|---|
| 1 | Users never form the capture habit; the conversation moment passes and they don't open the app | RETENTION | Partially mitigated (FAB on every main screen, one-field capture). **Actionable next:** share-sheet/widget capture (Experiment 3). |
| 2 | "My Reminders app already does this" — no perceived advantage | MARKET | Person context + gentle copy + Today view. Unproven; validation test 9 is a STOP gate. |
| 3 | Discovery: nobody finds it in a crowded store category | DISTRIBUTION | Content plan in GROWTH.md; store name includes "Remember to Ask". Unmitigated until executed. |
| 4 | Notification permission denied → app becomes a passive list | UX | JIT request after first reminder; Today works without notifications; Settings hint. Mitigated as far as possible. |
| 5 | Low willingness to pay | MONETIZATION | Free V1; zero backend cost; one-time unlock later. Accepted risk. |
| 6 | Data loss on phone change (no export, relies on OS backup) | TECHNICAL / PRIVACY | Disclosed in-app. **Actionable next:** encrypted export/import. Not built in V1. |
| 7 | Lock-screen privacy leak | PRIVACY | Private notification text by default; tested. Mitigated. |
| 8 | Reminders arrive at the wrong time after travel | TECHNICAL | Day-level math is TZ-proof; notifications re-synced on resume. Residual: until the app is opened in the new zone. Documented. |
| 9 | Feels like a chore/guilt app after a busy week (pile-up in Today) | PRODUCT | No counts, no "overdue", no re-notification, one-tap "Let go". Mitigated in design; untested with users. |
| 10 | Default icon / unfinished branding looks untrustworthy | UX / DISTRIBUTION | **Blocker for store launch**: icon brief in BRAND.md; needs a designer. |

Actions taken in this pass: fixed stale "Today" after midnight resume; VACUUM on delete-all;
removed unused dependency. Items 1, 6 and 10 are the highest-value next engineering/design work.
