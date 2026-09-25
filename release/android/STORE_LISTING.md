# Google Play listing — KeepClose (draft)

Verified 2026-09-25 via search: new apps/updates must target API 36 from 31 Aug 2026
(app targets 36 via Flutter 3.47 defaults); new *personal* developer accounts must run a
closed test with ≥12 opted-in testers for 14 consecutive days before production access.
Re-verify in Play Console before submission.

- **App name (≤30):** KeepClose: Remember to Ask
- **Short description (≤80):** Remember the small things that show people you care. Private, no account.
- **Category:** Lifestyle (alternative: Productivity)
- **Tags:** friendship, reminders, relationships
- **Contact email:** [SUPPORT_EMAIL] (required) · **Privacy policy URL:** [host legal/PRIVACY_POLICY.md]

## Full description (≤4000)
When a friend tells you about a job interview, a move, or a hard week, KeepClose helps
you remember to ask how it went.

Jot it down in seconds — "ask Mariana how the interview went", Friday — and KeepClose
will gently remind you on the day. That's it. No profiles to fill in, no scores, no
streaks, no guilt.

• Remember to ask: one line and a day. The reminder uses your own words.
• Dates that matter: birthdays and one-off moments like moving day or an exam.
• Check in now and then (optional): a gentle nudge for people you'd like to keep close.
• Today: everything worth remembering, in one calm list. Done, Later, or Let go.
• Moments: when you catch up, note anything worth remembering for next time.
• One notification a day, at most — and only when there's something to remember.

Private by design
• Everything stays on your phone. No account. No server.
• KeepClose never reads your messages and never asks for access to your contacts —
  pick one person from your contacts and only that person is shared with the app.
• Lock-screen reminders don't show names or notes unless you choose to.
• No ads, no analytics, no tracking.

KeepClose doesn't send messages for you. It just helps you remember — the caring part
is yours.

## Data safety form (answers for V1)
- Does the app collect or share user data? **No** (all data stays on device; nothing is transmitted to the developer or third parties).
- Is data encrypted in transit? **N/A** (no transmission).
- Can users request deletion? In-app: Settings → Delete all data; uninstall removes all data.
- Note: data entered by the user is stored locally only; per Play definitions, on-device-only processing is not "collection".

## Permissions explanation
| Permission | Why |
|---|---|
| POST_NOTIFICATIONS | Optional daily reminder; requested only after you create your first reminder. |
| RECEIVE_BOOT_COMPLETED | Keeps scheduled reminders after the phone restarts. |
| (none for contacts) | The system contact picker is used; no contacts permission. |

## Content rating
IARC questionnaire: no violence, sexual content, gambling, user-to-user communication,
location sharing, or purchases → expected rating **Everyone / PEGI 3**.

## Target audience
18+ primary (13+ acceptable). Not designed for children; do not opt into Families.

## Screenshot plan (phone, 1080×2400, 4–8)
1. Today with a follow-up and a birthday — caption "Remember to ask."
2. Add follow-up sheet — "One line and a day. That's it."
3. Person page — "Context when you need it."
4. Privacy screen — "Everything stays on your phone."
5. Settings lock-screen options — "Private notifications by default."
6. People list — "Just the people who matter."
Use demo data only (fictional names). Goldens in test/golden/goldens are layout references, not store assets.

## Feature graphic
1024×500, sage background, tagline "Remember to ask.", no device frames with real data.

## Support requirements
Support email, privacy policy URL, and a minimal support page (FAQ from /landing).
