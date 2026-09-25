# RED TEAM — "Assume KeepClose is a bad idea"

Each attack is rated: **LETHAL** (kills the broad thesis), **SERIOUS** (must be designed
around), **MANAGEABLE**.

| # | Attack | Evidence | Rating | Response |
|---|---|---|---|---|
| 1 | People won't manually maintain relationship data | CRM data-entry fatigue; category moves to auto-sync [A4] | SERIOUS | Only ask for name + one line + a day. No profiles, no required fields, no interaction logging required. |
| 2 | Contacts/Calendar/Reminders already solve it | They do for birthdays and generic reminders [A6]; iOS 26 suggests follow-ups [S26] | **LETHAL for A and C alone**; SERIOUS for B | Differentiate on person-centric context and capture speed; accept that some users will just use Reminders. |
| 3 | Reminders feel robotic | Cadence reminders are content-free ("contact X") | SERIOUS for A | Follow-up reminders carry the user's own words ("ask how the interview went") — inherently specific. |
| 4 | Notifications become annoying | Garden snippet [S14]; opt-in not guaranteed [S31] | SERIOUS | Max one daily digest notification at a user-chosen time; nothing else. Easy off switch. |
| 5 | Users feel judged | Cadence lists grow "overdue"; status labels like "Fading" [S17] | SERIOUS | No overdue counts, no scores, no day counters; items past due are phrased "Still want to…?" and can be let go with one tap. |
| 6 | It's creepy | Notes about friends are sensitive | SERIOUS | On-device only, no account, no message access, no contact upload; private lock-screen text by default. |
| 7 | Contact import creates privacy concerns | — | MANAGEABLE | Use the OS contact *picker* (no contacts permission; the user hands over one contact). |
| 8 | Users won't pay | Many free apps [S15]; no WTP evidence [A10] | SERIOUS | Ship free V1 with no paywall; test one-time unlock later. Architecture keeps costs ~0. |
| 9 | Retention will be poor | Category-typical; no trigger for A | SERIOUS | B has an external trigger (conversations). Measure; gates in VALIDATION_DEBT.md. |
| 10 | Competitors already tried this | 12+ cadence apps; Monica; Dex/Mesh | **LETHAL for A** | Don't build another cadence app. |
| 11 | Glorified reminder app | True structurally | SERIOUS | Accept it honestly: it *is* a reminder app, organized around people. Value = speed of capture + person context + humane copy. If beta shows no advantage over Reminders → STOP. |
| 12 | Guilt-driven install then churn | Plausible for A (install after feeling bad) | SERIOUS | B's value is in-the-moment and positive ("I listened"), not guilt about the past. No re-engagement pushes. |
| 13 | Hesitation, not memory, is the bottleneck [S1] | Strong study | SERIOUS for A | B supplies a reason/topic to reach out, which plausibly lowers awkwardness (HYPOTHESIS A8). |
| 14 | Apple/Google ship this natively with AI | iOS 26 suggestions [S26] | SERIOUS long-term | Their approach requires reading messages; ours is explicit and private. Keep V1 cheap so the downside is small. |

## Verdict per thesis
- **A — Relationship maintenance as primary promise:** does not survive (crowded, no natural trigger, hesitation not memory, guilt dynamics).
- **C — Important moments as primary promise:** does not survive (commodity; OS-native).
- **B — Follow-ups as primary promise, with light A and C as supporting features:** survives with SERIOUS risks; weakest direct evidence but best structural answers to attacks 1, 3, 5, 12, 13.

The broad "stay close" (A-led) thesis is repositioned to a narrower, follow-up-led product.
Two adjacent pivots were considered: (1) follow-ups (B) — selected; (2) "what to say"
conversation starters — rejected for V1 because it drifts toward AI-drafted messages.

## DECISION

PIVOT
