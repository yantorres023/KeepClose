# MONETIZATION

Status: HYPOTHESIS. No willingness-to-pay data exists (EVIDENCE_LEDGER A10 = WEAK).

## Competitor price points (as reported 2025–2026; verify before use)
| Product | Model | Price |
|---|---|---|
| Dex | Subscription | ~$12/mo Premium, ~$20/mo Professional (annual) |
| Mesh (ex-Clay) | Subscription | ~$10/mo |
| Monica | Hosted subscription / free self-host | $9/mo or $90/yr |
| Queue | Subscription | $7.99/mo or $79.99/yr |
| Garden | Sub + lifetime | $0.99/mo, $9.99/yr, $24.99 lifetime |
| Catchup (Friendship Tracker) | Freemium, 2 contacts free | Upgrade (price not verified) |
| CatchUp: Keep in Touch | Free, tips | Tips |
| Pals | Freemium, 10 contacts free | Premium (price not verified) |
| Name Reminder | One-time | $9.99 |

Pattern: professional/networking tools sustain subscriptions; friend/family tools cluster
at free, tips, or ≤$25 lifetime.

## Options assessed
| Model | Fit | Objections |
|---|---|---|
| Free forever | Maximizes adoption & trust for a validation beta | No revenue |
| Freemium with contact cap (e.g., 5 people) | Common in category | Punishes the core behavior (adding people); feels like paying to care about friends |
| One-time unlock (~$9.99) | Matches zero marginal cost (no backend); matches category norms | Low LTV; no recurring revenue |
| Annual subscription | Only justified by ongoing cost (sync) | "Subscription to remember my friends" is a strong objection; V1 has no ongoing service |
| Premium customization (themes, icons, widgets) | Low-pressure, non-core | Modest conversion |
| Encrypted backup/sync (future) | Real ongoing cost → could justify a small annual fee | Requires backend, changes privacy story |
| Ads | Rejected | Incompatible with privacy promise |
| Data monetization | Rejected | Never |

## Recommendation
1. **V1 beta: completely free, no paywall.** The only goal is to validate the core loop.
2. **If retention gates pass (see VALIDATION_DEBT.md): one-time "KeepClose Plus" at $9.99**
   (test $4.99 vs $9.99), unlocking non-core extras: widgets, themes, encrypted export/
   import, share-sheet capture. Core loop stays free with no people cap.
3. **Subscription only if** optional end-to-end-encrypted sync ships; price ≈ $1–2/mo or
   $12/yr, and never gate existing local features behind it.

## Realistic objections (anticipated, unvalidated)
- "My phone's Reminders app does this for free."
- "I don't want to pay to be a good friend."
- "I'll use it for a few weeks, then stop."
- "What happens to my data if the app dies?" (→ export matters for trust)

## Kill criteria for monetization
If <2% of week-4-retained beta users choose a $4.99 one-time option in a painted-door test,
treat KeepClose as a free/tip-supported side product rather than a business.
