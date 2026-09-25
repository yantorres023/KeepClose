# ANALYTICS

**V1 collects and transmits nothing.** There is no analytics SDK, no network code, and no
local event log. This document defines the taxonomy a future *opt-in* beta build would
use, so validation tests (VALIDATION_DEBT.md) are measurable.

## Principles for any future instrumentation
- Opt-in, clearly explained, off by default in store builds.
- Never send names, notes, follow-up text, phone numbers or dates' labels. Counts and
  enums only.
- Random install ID, resettable; no device fingerprinting; no ad IDs.
- Prefer a privacy-preserving tool (e.g., self-hosted, aggregate-only) and a beta-only build flavor.

## Event taxonomy
| Event | When | Properties (no personal content) |
|---|---|---|
| onboarding_completed | "Get started" or Skip | skipped: bool, reminder_hour: int |
| person_added | Person saved | source: manual \| contact_picker, has_note: bool, has_phone: bool |
| contact_imported | Picker returned a contact | duplicate_detected: bool |
| contact_pick_cancelled | Picker dismissed | — |
| followup_created | Follow-up saved | due_in_days: int, chip: tomorrow \| 3d \| 1w \| 2w \| custom, entry_point: today_fab \| person_fab |
| important_date_created | Date saved | kind: birthday \| event, lead_days: int, has_year: bool |
| checkin_rhythm_set | Rhythm changed | days: int \| off |
| reminder_scheduled | Digest scheduled (per sync) | days_with_items: int |
| notification_permission_result | After JIT request | result: granted \| denied \| unknown |
| reminder_opened | App opened from notification | — |
| reminder_snoozed | "Later" | kind, snooze_days: int |
| reminder_dismissed | "Let go" | kind |
| reconnect_action_started | Tapped Message / Call | channel: sms \| call |
| reconnect_action_confirmed | "Asked"/"Done" on follow-up or check-in | kind, was_late: bool |
| interaction_logged | "We talked"/"I reached out" | kind, has_note: bool |
| person_deleted / all_data_deleted | Destructive actions | — |
| notifications_disabled | Setting turned off | — |

## North-star (HYPOTHESIS)
**User-confirmed reconnects per weekly active user** =
count(reconnect_action_confirmed + interaction_logged) / WAU.
Caveat: "Asked" is a user self-report; the app cannot verify a conversation happened
and we must not claim it did.

## Derived metrics
- Activation: ≥1 person AND ≥1 follow-up within first session; strong activation: ≥3 people AND ≥2 follow-ups in 7 days.
- Reminder action rate: reconnect_action_confirmed / items that reached Today.
- Notification health: % of users with notifications_disabled or permission denied.
- Retention: D7, D14 (week-2), D30 returning users.
