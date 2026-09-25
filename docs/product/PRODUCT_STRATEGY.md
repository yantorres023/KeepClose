# PRODUCT STRATEGY

Decision: **PIVOT** from "stay close to everyone (cadence reminders)" to a
**follow-up-first** product. See `docs/research/RED_TEAM.md`.

## ICP (HYPOTHESIS)
Adults ~25–45 who care about a handful of people, are in a busy or transitional life
stage (new job, new city, new parent, long-distance), and have had the experience of
forgetting to ask about something a friend told them. They use a smartphone reminder app
occasionally but don't want a "system".

## TRIGGER
A conversation in which someone mentions something upcoming in their life
("I have the interview Thursday", "Mom's surgery is next week", "we move on the 3rd").

## JTBD
"When someone tells me about something coming up, help me remember to ask about it
afterwards, so they know I was listening."

## CORE PROBLEM
Good intentions get lost between the moment someone shares something and the moment it
would be kind to follow up.

## CURRENT ALTERNATIVE
Memory; the phone's generic Reminders app; nothing.

## CORE PROMISE
**"Remember to ask."** — Remember the small things that show people you care.
Private, on your phone, no account.

## AHA MOMENT
The first reminder that says, in the user's own words, "Ask Mariana how the interview
went" — on the right day — and the user sends that message.

## CORE LOOP
Friend shares something → user captures one line + a day (≤10 s) → app stays silent →
on the day, one gentle digest notification → user opens Today, taps "Message"/"Call" or
reaches out elsewhere → taps "Done — I asked" (optionally adds a one-line note of what
they learned, which can spawn the next follow-up) → richer context next time.

Supporting loops (deliberately lightweight):
- Important dates (birthdays, one-off events) surface in the same Today list.
- Optional gentle check-in: per person, "Remind me to check in every ~N weeks" — off by default.

## ACTIVATION (HYPOTHESIS)
Within the first session: add ≥1 person and create ≥1 follow-up.
Strong activation within 7 days: ≥3 people and ≥2 follow-ups.

## RETENTION HYPOTHESIS
Retention is driven by *new conversations*, not by the app nagging. Users who capture a
follow-up in week 1 and act on its reminder will capture again in week 2.

## MONETIZATION HYPOTHESIS
V1 free, no paywall, no ads. Later test a one-time "Supporter / Plus" unlock
(e.g., themes, encrypted export/import, widgets) at ~$9.99. Subscription only if sync is
ever added (real ongoing cost). See `docs/business/MONETIZATION.md`.

## DISTRIBUTION HYPOTHESIS
Short-form content around the concrete, relatable moment ("the friend who remembers to
ask about your interview"), friendship/long-distance creators, Reddit communities where
self-promotion is allowed, and word of mouth. See `docs/business/GROWTH.md`.

## RISKS
1. It's "just a reminder app" and users stay with Reminders.
2. Capture moment happens mid-conversation; opening an app may feel rude → capture must work later from memory too, and be fast.
3. Low willingness to pay.
4. OS vendors ship AI follow-ups.
5. Notification permission denied → app becomes a passive list.

## UNVALIDATED ASSUMPTIONS
See `docs/research/EVIDENCE_LEDGER.md` A7, A8, A10, A11 and `docs/research/VALIDATION_DEBT.md`.

## WHAT WE WILL NOT BUILD
Relationship scores, streaks, "days since" counters, AI companions, auto-sending,
message scanning, social import, accounts, cloud sync (V1).
