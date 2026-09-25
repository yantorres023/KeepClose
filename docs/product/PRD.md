# PRD — KeepClose V1 ("Remember to ask")

## VISION
Help people remember the small things that show others they care — privately, gently,
and without turning relationships into admin.

## ICP
See PRODUCT_STRATEGY.md.

## JTBD
"When someone tells me about something coming up, help me remember to ask about it
afterwards, so they know I was listening."

## NON-GOALS
AI features; accounts; cloud sync; analytics transmission; reading messages, call logs,
or social media; auto-sending messages; relationship scoring/streaks; networking/sales use
cases; widgets; tablets/web/desktop polish; localization beyond English (V1).

## FEATURES (V1 scope)
| ID | Feature | Priority |
|---|---|---|
| F1 | Onboarding (promise, privacy, reminder time) | P0 |
| F2 | Add person manually (name only required; optional short note, optional phone) | P0 |
| F3 | Add person from phone contacts via OS picker (no contacts permission) | P0 |
| F4 | Follow-up ("Remember to ask…") with quick day chips | P0 |
| F5 | Important dates (birthday yearly; one-off events) | P0 |
| F6 | Optional gentle check-in rhythm per person (off by default) | P1 |
| F7 | Deterministic reminder engine | P0 |
| F8 | Daily digest local notification, privacy-preserving by default | P0 |
| F9 | Today screen (today + coming up) with Done / Later / Let go | P0 |
| F10 | Person detail: note, open follow-ups, dates, recent moments | P0 |
| F11 | "Reach out" shortcuts (Message/Call via OS apps; user sends manually) | P1 |
| F12 | Quick moment log ("We talked" + optional one-line note) | P1 |
| F13 | Settings: reminder time, notification detail level, on/off, delete all data, privacy info | P0 |

## USER STORIES & ACCEPTANCE CRITERIA
**US1 (F2/F3)** As a user I can add someone in seconds.
- AC: Only name is required. Name trimmed; empty names rejected with inline message.
- AC: "From contacts" opens the OS picker; if cancelled, nothing changes; no permission prompt appears.
- AC: Picking a contact already added (same device contact id or same name+phone) offers to open the existing person instead of creating a duplicate.
- AC: Names up to 80 chars; emoji/special characters preserved.

**US2 (F4)** As a user I can capture "remember to ask about X" for a person with a day.
- AC: Text field (required, ≤200 chars) + chips: Tomorrow, In 3 days, Next week, In 2 weeks, Pick a date.
- AC: Saving takes ≤3 taps after typing. Due date may not be in the past (date picker min = today).
- AC: Reminder appears in Today on its day and is included in that day's digest notification.

**US3 (F9)** As a user I see what matters today without guilt.
- AC: Today lists due items grouped "Today" and "Coming up (next 14 days)". Past-due open items stay in "Today" labelled "Still want to…?" — never "overdue", never a day count.
- AC: Each item offers Done, Later (Tomorrow / Next week / pick), and Let go (dismiss). All are undoable via snackbar.
- AC: Empty state is encouraging and offers "Add someone".

**US4 (F5)** As a user I can save a birthday or a one-off date.
- AC: Birthday = month+day (year optional). Feb 29 birthdays show on Feb 28 in non-leap years.
- AC: One-off date appears once, then drops off after the day passes.
- AC: Birthday items appear on the day; optional "a few days before" heads-up (default off; 0/1/3/7 days).

**US5 (F6)** As a user I can opt into a gentle check-in rhythm.
- AC: Off by default. Options: every 2 weeks / month / 2 months / 3 months / 6 months.
- AC: Next check-in = last moment with that person (or when rhythm was set) + interval. Logging a moment or marking a check-in done resets it. "Later" pushes it.
- AC: Copy: "Thinking of Lucas?" — never how long it's been.

**US6 (F8)** As a user I get at most one notification per day.
- AC: One digest at user-chosen time (default 09:00 local) on days with ≥1 item; none otherwise.
- AC: Default lock-screen text contains no names or notes ("You have 2 gentle reminders today."). Settings offers "Names only" and "Full details".
- AC: Notifications can be turned off entirely; the app remains fully usable.
- AC: Notification permission is requested just-in-time (after the first follow-up/date/rhythm is saved), not at launch. Denial is respected; a non-blocking hint appears in Settings.
- AC: Tapping the notification opens Today.

**US7 (F10/F12)** As a user I can see context before reaching out.
- AC: Person detail shows note, open follow-ups, dates, rhythm, and the last ~10 moments.
- AC: "We talked" logs a moment for today with optional one-line note.
- AC: After marking a follow-up Done, the user may optionally add what they learned (saved as a moment) — skippable.

**US8 (F11)** As a user I can start a message or call.
- AC: If a phone number exists, Message/Call open the OS SMS/dialer with the number prefilled; KeepClose never sends anything.

**US9 (F13)** As a user I control my data.
- AC: Delete a person (confirmation dialog naming them; deletes their follow-ups, dates, moments).
- AC: "Delete all data" requires typed confirmation "DELETE", wipes DB and cancels notifications.
- AC: Privacy screen explains exactly what's stored and where.

## DATA MODEL
- `people`(id, name, note?, phone?, contact_ref?, check_in_days?, check_in_anchor?, check_in_snoozed_until?, created_at, updated_at)
- `follow_ups`(id, person_id→people CASCADE, text, due_date (local date), status open|done|dismissed, created_at, resolved_at?)
- `important_dates`(id, person_id→people CASCADE, kind birthday|event, label?, month, day, year?, notify_days_before, created_at)
- `moments`(id, person_id→people CASCADE, date (local date), kind talked|reached_out|followed_up, note?, created_at)
- `settings`(key, value) — reminder_minutes, notification_detail, notifications_enabled, onboarding_done.
Local calendar dates are stored as `yyyymmdd` integers (timezone/DST-proof for date-level reminders).

## PRIVACY
On-device only. No account, backend, analytics transmission, AI API, message access, or
contacts permission. See docs/engineering/SECURITY.md and legal/PRIVACY_POLICY.md.

## NOTIFICATIONS
Deterministic; ≤1/day digest; inexact scheduling (no exact-alarm permission); next 30 days
pre-scheduled and re-synced on every data change and on app start/resume.

## ANALYTICS
Event taxonomy defined in ANALYTICS.md; **V1 transmits nothing**. Optional local-only
counters are not implemented in V1.

## ERROR HANDLING
- DB open failure → full-screen error with "Try again" and support text; no crash loop.
- Notification scheduling failures are caught and logged in debug only; UI unaffected.
- Contact picker failure/unavailable → snackbar "Couldn't open contacts. You can add them by name." 
- URL launch failure (no SMS app) → snackbar.

## ACCESSIBILITY
Semantics labels on all icon buttons and list items; text scales to 200% without
clipping critical actions; tap targets ≥48dp; state never conveyed by color alone;
respects reduced motion (no decorative animations).

## PERFORMANCE
Cold start < 2 s on mid-range devices (target); Today query < 50 ms for 500 people /
5,000 items (tested with in-memory DB in unit tests).

## FUTURE FEATURES (not V1)
Encrypted export/import; widgets; share-sheet capture ("remember to ask" from any app);
Siri/Assistant shortcut; optional on-device NL date parsing; optional AI rewrite of a
reminder (opt-in, on-device preferred); localization; iPad.

## VALIDATION DEBT
See docs/research/VALIDATION_DEBT.md.
