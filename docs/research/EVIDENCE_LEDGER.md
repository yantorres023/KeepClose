# EVIDENCE LEDGER

Labels: **FACT** (reported by a cited source) · **INFERENCE** (our reasoning from facts) ·
**HYPOTHESIS** (untested belief) · **UNVALIDATED_WITH_REAL_USERS** (no user contact in this run).
Source IDs refer to `SOURCES.md`. Repeated press coverage of the same study counts as ONE source.

Important caveat for all rows: no interviews, surveys or usage data were collected. Nothing
here is validated with real users.

---

## A1. Adults unintentionally lose touch with people they care about
- SUPPORTING: FACT — 47% of US adults report losing touch with at least a few friends in the past 12 months [S4]. FACT — Roberts & Dunbar: emotional closeness to friends declines when contact stops; kin ties are more robust [S3]. FACT — Surgeon General advisory frames disconnection as a population-level issue [S5].
- CONTRARY: FACT — [S4] also reports nearly as many made a new friend in the same period (churn, not only loss). INFERENCE — some drift is natural and not experienced as a problem to solve.
- SOURCE DATES: 2011/2015, 2021, 2023.
- CONFIDENCE: HIGH (that drift happens) / LOW (that people want an app for it).
- STATUS: SUPPORTED (phenomenon) · UNVALIDATED_WITH_REAL_USERS (demand).
- FALSIFY: target users say drift is acceptable/natural and decline to add anyone after onboarding.

## A2. The bottleneck is remembering/noticing (a reminder helps)
- SUPPORTING: HYPOTHESIS/INFERENCE from the large number of reminder apps [S14–S19] (supply signal, not demand proof). FACT — WSJ/Inc. reported people miss birthdays more as Facebook notifications decline, i.e., external cues matter [S8].
- CONTRARY: FACT — Sandstrom/Aknin 2024: fewer than one third sent a message to an old friend *even when* they wanted to, had contact info, and were given time — barriers were awkwardness, fear the friend wouldn't want to hear from them, guilt [S1]. So *remembering is not the main bottleneck for dormant ties*; hesitation is.
- CONFIDENCE: MEDIUM.
- STATUS: WEAK for dormant ties; plausible for active ties.
- FALSIFY: reminder open rate high but acted-on rate very low (users see the reminder and still don't reach out).

## A3. Reaching out is valued more than people expect
- SUPPORTING: FACT — Liu et al. 2022, >5,900 participants, initiators underestimate recipients' appreciation; more surprising contact is appreciated more [S2]. FACT — [S1] participants mostly felt happier after messaging.
- CONTRARY: none found. Lab/field effects may not transfer to app-prompted outreach.
- CONFIDENCE: HIGH (effect exists) / LOW (app can trigger it).
- STATUS: SUPPORTED.
- FALSIFY: n/a for the product; can be used in copy only as a cited, non-exaggerated fact.

## A4. Personal CRMs feel like work (manual data entry → churn)
- SUPPORTING: FACT — personal-CRM market repeatedly moves toward automation (LinkedIn/email sync, AI) to avoid manual entry [S10, S12, S13]; review snippets cite sync/import glitches [S12]; Contacts Journal reviewers called sync "a manual chore" [S20]. FACT — UpHabit pivoted to sales [S22]; Clay was acquired after raising $8M [S13] (ambiguous signal). INFERENCE — the category's most-funded players aim at networkers/professionals, not friends/family.
- CONTRARY: FACT — some cadence apps have long-term fans ("I've been using this app for years") [S14].
- CONFIDENCE: MEDIUM.
- STATUS: SUPPORTED (directionally).
- FALSIFY: users happily fill multi-field profiles in tests.

## A5. Cadence-based "stay in touch" reminders are a crowded, commoditized category
- SUPPORTING: FACT — at least 12 near-identical apps found in a few searches (Garden, Catchup ×2, Check Up, Hey!, Amigos, Frenzz, Linc, Friend Reminder, SoonCall, Keep n Touch, Pals, Catch Up) [S14–S19]; several are free/tip-supported [S15]. Pals already offers the privacy-first local-only angle [S17].
- CONTRARY: none.
- CONFIDENCE: HIGH.
- STATUS: SUPPORTED → implies Thesis A alone lacks differentiation.
- FALSIFY: n/a (market fact).

## A6. Birthday/important-date reminders are already solved "well enough"
- SUPPORTING: FACT — OS contacts+calendar support birthdays; many free birthday apps exist [S21]. INFERENCE — hard to charge for or differentiate on.
- CONTRARY: FACT — people forget birthdays more without Facebook [S8]; INFERENCE — setup friction (birthdays not in contacts) keeps the problem alive.
- CONFIDENCE: MEDIUM.
- STATUS: SUPPORTED (as commodity) → Thesis C is a feature, not a wedge.
- FALSIFY: users rate birthday reminders as the most valuable feature in beta.

## A7. People forget to follow up on things friends shared (interview, appointment, exam)
- SUPPORTING: INFERENCE — follow-up is a common piece of friendship advice [S25]; existing people-notes apps store details but mostly lack dated "ask about" prompts [S20]. FACT — Apple added AI-suggested follow-ups from Mail/Messages in iOS 26 [S26], suggesting platform owners see follow-ups as a real job (and also a competitive threat).
- CONTRARY: No direct public demand evidence found (search for "forgot to ask how it went" returned no strong community threads). Generic reminder apps can do this already.
- CONFIDENCE: LOW–MEDIUM.
- STATUS: UNVALIDATED_WITH_REAL_USERS.
- FALSIFY: in beta, <30% of activated users create a second follow-up within 14 days.

## A8. A follow-up prompt lowers the awkwardness barrier (it gives you something to say)
- SUPPORTING: INFERENCE — [S1] names awkwardness and "they may not want to hear from me" as barriers; a follow-up is a *reason* to reach out and signals care about something the friend raised. [S2] suggests the recipient values it.
- CONTRARY: none found; untested.
- CONFIDENCE: LOW.
- STATUS: HYPOTHESIS · UNVALIDATED_WITH_REAL_USERS.
- FALSIFY: follow-up reminders are acted on no more often than generic "check in with X" reminders.

## A9. Privacy/"creepiness" matters for this category
- SUPPORTING: FACT — several newer entrants lead with "no account, on-device" (Pals, Catch Up, Notami) [S17, S19, S20], indicating perceived demand. INFERENCE — notes about friends are sensitive (health, relationships); lock-screen notifications could leak them.
- CONTRARY: Dex/Mesh grow with cloud sync + social imports [S12, S13]; many users trade privacy for convenience.
- CONFIDENCE: MEDIUM.
- STATUS: SUPPORTED (as a design constraint, not proven as a purchase driver).
- FALSIFY: users repeatedly ask for cloud sync above all else.

## A10. Users will pay
- SUPPORTING: FACT — prices exist: Monica $9/mo, Dex $12–20/mo, Queue $7.99/mo, Garden $9.99/yr or $24.99 lifetime, Name Reminder $9.99 one-time [S11, S12, S14, S16, S20].
- CONTRARY: FACT — many free/tip-supported alternatives [S15]; OS tools are free. No revenue figures found for friend-focused apps. Paying segments skew to professionals/networkers (Dex).
- CONFIDENCE: LOW.
- STATUS: WEAK · UNVALIDATED_WITH_REAL_USERS.
- FALSIFY: <2% of week-4 retained beta users choose a paid option at a $9.99 one-time price.

## A11. Notifications can feel guilt-inducing or annoying
- SUPPORTING: FACT — Garden review snippet complains of "annoying" notifications [S14]. FACT — Pals shows "Fading/Dormant" statuses [S17] — an example of scoring language we deem risky. FACT — Android 13+ requires runtime opt-in; opt-in rates are materially below 100% (vendor data) [S31].
- CONTRARY: users of cadence apps explicitly want to be nudged.
- CONFIDENCE: MEDIUM.
- STATUS: SUPPORTED (as a risk).
- FALSIFY: in beta, <10% disable notifications by week 2.
