# VALIDATION DEBT

No users, interviews or usage data exist. Everything below is a plan. Thresholds are
**experimental gates chosen by judgement**, not scientifically derived benchmarks.
Recommended first beta: 30–60 people recruited from the ICP (busy adults 25–45 who
self-report forgetting follow-ups), TestFlight + Play internal testing, with an opt-in
instrumented beta build (ANALYTICS.md) plus a 5-question in-app/email survey at day 14.

| # | Hypothesis | Metric | Pass | Fail | Cheapest test |
|---|---|---|---|---|---|
| 1 | Onboarding is clear and short | % installs completing onboarding | ≥ 80% | < 60% | Beta analytics; 5 moderated remote sessions (think-aloud) |
| 2 | Users will add a small circle | Median people added by day 7 | ≥ 3 | ≤ 1 | Beta analytics |
| 3 | The follow-up is a natural capture | % activated users creating ≥ 2 follow-ups in 14 days | ≥ 40% | < 20% | Beta analytics + diary prompt |
| 4 | Reminders are opened | % of digest notifications followed by an app open that day | ≥ 30% | < 15% | Beta analytics |
| 5 | Reminders lead to real outreach | % of Today items resolved with "Asked"/"Done" (self-report) | ≥ 40% | < 20% | Beta analytics + day-14 survey ("Did you actually reach out?") |
| 6 | People come back | Week-2 retention (any open in days 8–14) | ≥ 35% | < 20% | Beta analytics |
| 7 | Notifications don't annoy | % disabling notifications or denying permission by day 14 | ≤ 15% | > 30% | Beta analytics + survey ("How did the reminders feel?" 1–5) |
| 8 | Willingness to pay exists | % of week-4 retained users tapping a painted-door "Plus $4.99" | ≥ 5% | < 2% | Painted-door button (no charge) with honest "not available yet" message |
| 9 | It beats phone Reminders | % of survey respondents preferring KeepClose over their reminders app for this job | ≥ 60% | < 40% | Day-14 survey |
| 10 | Privacy stance matters | % citing privacy among top-2 reasons for choosing it | ≥ 25% | < 10% | Landing page A/B (privacy-led vs. benefit-led hero) + survey |

## Beta stop rules (experimental gates)
- **Activation gate:** ≥ 40% of installs add ≥ 3 people AND create ≥ 1 follow-up within 7 days.
- **Behavior gate:** ≥ 30% of activated users mark at least one reminder "Asked"/"Done" in 14 days.
- **Retention gate:** week-2 retention ≥ 25%.
- **Notification health gate:** ≤ 20% disable notifications by day 14.

## Kill / pivot conditions
- Activation < 25% AND behavior < 15% → **STOP** (people don't capture follow-ups).
- Activation OK but behavior < 15% → pivot toward the awkwardness barrier (conversation
  starters / "what to say"), still without AI-drafted sending.
- Behavior OK but week-2 retention < 15% → test a share-sheet/widget capture (reduce
  capture friction) before killing; if still < 15% after one iteration → STOP.
- Notification disable rate > 35% → revisit digest design (weekly digest option) before
  any other work.
- Test 9 fails (< 40% prefer KeepClose over Reminders) → STOP as a standalone product.

## Next 3 experiments
1. **Fake-door landing page** (landing/) with two hero variants; measure email sign-ups per
   visitor from friendship/productivity content. Cost: hours.
2. **30-person closed beta** with the instrumented build for 21 days; gates above.
3. **Capture friction test**: compare in-app capture vs. share-sheet/widget capture among
   beta users (activation and follow-ups/week).
