# COMPETITORS

Method: search-result excerpts only (full review pages were not reachable). Review volumes
could not be verified and are therefore omitted rather than guessed. Prices are as reported in
sources dated 2025–2026 and may be out of date.

## Category map

| Segment | Examples | Core job | Our read |
|---|---|---|---|
| Networking personal CRMs | Dex, Mesh (ex-Clay), UpHabit, Covve | Professional network, LinkedIn/email sync | Not our market; UpHabit pivoted to sales [S22] |
| Friend/family personal CRMs | Monica, Contacts Journal, Hippo, Queue | Detailed records about people | Powerful, data-entry heavy |
| Cadence "stay in touch" apps | Garden, Catchup, Check Up, Hey!, Amigos, Frenzz, Linc, Friend Reminder, SoonCall, Keep n Touch, Pals, Catch Up | "Remind me every N days" | Crowded, commoditized, several free |
| People-notes apps | Name Reminder, Remember Them, Revere, Notami | Remember names/details | Notes-first; reminders mostly cadence/birthday |
| Birthday apps | HBD, Birthdays Reminder, birthdays.app | Dates | Commodity, OS-native alternatives |
| Platform features | iOS Contacts+Calendar birthdays; iOS 26 suggested follow-ups from Mail/Messages [S26] | Dates; AI-extracted tasks | Free, default, growing |
| Generic tools | Reminders, Google Calendar, Notes, Todoist | Anything | The real incumbent |

## Profiles

### Dex [S10, S12]
- Target: professionals, founders, investors. Positioning: "Rolodex and personal CRM".
- Features: LinkedIn/Gmail/calendar sync, keep-in-touch reminders, browser extension, AI.
- Price: ~$12/mo Premium, ~$20/mo Professional (annual). Web, iOS, Android. Funding ~$9.4M.
- Positive themes: concept, LinkedIn import saves manual entry.
- Negative themes: import/sync glitches, some cancelled subscriptions.
- Privacy: cloud, imports social data. Relevance: shows automation is how CRMs fight data-entry fatigue.

### Mesh (formerly Clay) [S13]
- Target: broad "CRM for everyone"; acquired by Automattic June 2025; Android launched Aug 2026.
- Features: automatic enrichment from email/calendar/social. ~$10/mo.
- Relevance: large, well-resourced; heavy integration burden and privacy trade-off.

### Monica [S11]
- Target: people who want a detailed private record of friends/family. Open source (AGPL, ~21K stars).
- Price: free self-host; $9/mo or $90/yr hosted. Web only.
- Themes: loved by privacy-minded technical users; very form-heavy (many fields, activities, gifts, debts).
- Relevance: proves "remember details about friends" resonates with a niche; also illustrates "CRM for friends feels like work".

### Garden [S14]
- Target: friends/family/network. Cadence reminders + notes. iOS.
- Price: reported $0.99/mo, $9.99/yr, $24.99 lifetime.
- Themes: long-term fans; some "annoying" notification complaints.

### Catchup (two different apps) [S15]
- Friendship Tracker: freemium, 2 contacts free, widget. Keep in Touch: free, tip-supported.
- Relevance: price anchor near zero for cadence reminders.

### Queue [S16]
- "Nice, simple personal CRM"; $7.99/mo or $79.99/yr. Cadence + notes + search.

### Pals [S17]
- Privacy-first (no account, local notifications), interaction log, map of meetups, relationship status "New/Active/Fading/Dormant". Free up to 10 contacts.
- Relevance: already occupies "local-first cadence" — privacy alone is not a differentiator. Its status labels are the kind of scoring we deliberately avoid.

### Check Up, Hey!, Amigos, Frenzz, Linc, Friend Reminder, SoonCall, Keep n Touch, Catch Up (Android) [S18, S19]
- All variations of "set how often, get nudged". Several freemium with contact caps.

### Name Reminder / Remember Them / Revere / Hippo / Notami / Contacts Journal [S20]
- Notes-first. Name Reminder Pro $9.99 one-time. Remember Them uses AI to split notes.
- Gap: details are stored but rarely turned into a *dated prompt* ("ask about X on Friday").

### Birthday apps [S21]
- Free, contact-import based. Commodity.

### Platform: Apple iOS 26 Reminders [S26]
- AI-suggested reminders/follow-ups from Mail and Messages. Biggest long-term threat for the follow-up wedge; but it is task-generic, requires Apple Intelligence, and scans message content (which KeepClose refuses to do).

## Why personal CRMs feel like work (synthesis — INFERENCE)
1. **Blank-database problem**: value appears only after you enter many people and fields.
2. **Maintenance tax**: every interaction should be logged or the data rots.
3. **Wrong frame**: "contacts, pipelines, last-touch dates" turns friends into accounts.
4. **Cadence guilt**: fixed intervals produce a growing "overdue" list, which feels like a debt.
5. **Integration burden**: automation needs cloud access to email/social → privacy cost.
6. **No clear moment of use**: nothing in daily life tells you to open the app.

## Implications for KeepClose
- Don't compete on cadence reminders (A) or birthdays (C) — both commodities.
- Compete on the **moment of capture**: right after a friend tells you something ("my interview is Thursday"), capture one line + a day in <10 seconds. That moment is a natural trigger (fixes #6), requires one field (fixes #1), and the reminder carries its own reason to reach out (softens the awkwardness barrier in [S1]).
- Stay on-device (table stakes vs Pals, not a moat).
