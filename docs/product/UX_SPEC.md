# UX SPEC

Guiding question for every screen: *does this help the user care for a relationship, or
does it create administrative work?*

## Information architecture
```
Onboarding (first run only)
└─ Main (bottom navigation)
   ├─ Today            ← default tab
   ├─ People
   │   └─ Person detail
   │       ├─ Edit person (sheet/page)
   │       ├─ Add follow-up (sheet)
   │       ├─ Add date (sheet)
   │       ├─ Check-in rhythm (sheet)
   │       └─ Log moment (sheet)
   └─ Settings
       └─ Privacy (page)
```
Global primary action: FAB "Remember to ask" on Today and People → person chooser → Add follow-up.

## Navigation
Material 3 `NavigationBar` with 3 destinations: Today, People, Settings. Sheets for all
create flows (fast to dismiss). Notification tap → Today.

## Onboarding (3 short pages, skippable after page 1)
1. **"Remember to ask."** "When someone tells you about an interview, a move, or a hard week, jot it down. We'll remind you to ask how it went."
2. **"Private by design."** "Everything stays on this phone. No account. We never read your messages or upload your contacts."
3. **"When should we nudge you?"** Time picker (default 9:00). "At most one gentle reminder a day, only when there's something to remember." Button "Get started".
No permission prompts during onboarding.

## Today
- Header: date ("Thursday, 25 September").
- Section "Today": items due today or earlier (open), birthdays/events today, check-ins due.
- Section "Coming up": next 14 days, lighter style, no actions except tap → person.
- Item card: leading avatar initial; title in user's words; subtitle = person name + kind.
  - Follow-up (due today): "Ask Mariana: how the interview went"
  - Follow-up (earlier): "Still want to ask Mariana about how the interview went?"
  - Birthday: "Ana's birthday" (+ "turns 30" only if year known)
  - Event: "Lucas: moving day"
  - Check-in: "Thinking of Lucas?"
- Actions (text buttons, ≥48dp): **Done** · **Later** · overflow **Let go**. Done on a follow-up → snackbar "Nice. Add what you learned?" (action opens Log moment prefilled). Every action has Undo.
- Empty state: "Nothing to remember today. When someone mentions something coming up, tap Remember to ask."

## People
- Alphabetical list; search field appears when > 8 people.
- Row: name, second line = next thing ("Ask about the interview · Fri") or note snippet. No "last contacted" dates.
- FAB "Add someone" → sheet: Name field, "Pick from contacts" button, optional note ("How do you know them? Anything to remember?").
- Empty: "Who matters to you? Start with one or two people."

## Person detail
- Name (large), note (tap to edit).
- Reach out row (only if phone saved): Message, Call.
- "Remember to ask" list (open follow-ups) + "Add".
- "Dates" list + "Add".
- "Check in now and then": off / "About every month" (tap to change).
- "Moments": last 10 (date + kind + note). Button "We talked".
- App bar overflow: Edit, Delete (destructive, confirm).

## Add follow-up (sheet)
- Title: "Remember to ask {Name}…"
- Text field, placeholder "how the interview went", autofocus, max 200.
- Chips: Tomorrow · In 3 days · Next week · In 2 weeks · Pick date. "Tomorrow" is preselected; the save button label always states the chosen day ("Remind me tomorrow", "Remind me Fri 3 Oct") so the date is never a surprise.
- Save → close → snackbar "We'll remind you {Friday}". If notifications not yet requested, request here (just-in-time).

## Add date (sheet)
- Segmented: Birthday | Event.
- Birthday: month + day pickers, optional year.
- Event: label ("moving day"), full date.
- "Heads-up": On the day / 1 day before / 3 days before / 1 week before.

## Check-in rhythm (sheet)
Radio: Off · Every 2 weeks · Every month · Every 2 months · Every 3 months · Every 6 months.
Explainer: "We'll gently suggest reaching out. Logging a moment resets it."

## Log moment (sheet)
Kind chips: We talked · I reached out. Optional note (one line). Date: today (tap to change).

## Notification flow
- One digest per day at chosen time when ≥1 item is due that day.
- Private (default): title "KeepClose", body "You have 2 gentle reminders today." (singular: "a gentle reminder").
- Names only: "Mariana, Lucas".
- Full details: first item text, "+1 more".
- Tap → app opens on Today.

## Settings
- Reminders: Daily reminder time; Notifications on/off; Lock-screen detail (Private / Names only / Full details); status hint if OS permission denied with "Open system settings".
- Privacy: "How your data is handled" page.
- Data: Delete all data (typed confirmation).
- About: version, licences.

## Permissions
- Contacts: never requested. OS picker only.
- Notifications: requested after the first saved reminder source; re-request only from Settings.

## Empty & error states
- DB failure: "Something went wrong opening your data. Try again." + retry.
- Picker failure: snackbar.
- No SMS/phone app: snackbar "No app available to message."

## Accessibility
- All icon buttons have tooltips/semantic labels. Cards expose a merged semantic label ("Follow-up for Mariana: how the interview went. Due today.").
- Supports text scale up to 2.0 (tested in widget tests); no fixed-height text containers.
- Tap targets ≥48dp; contrast via Material 3 color scheme; status conveyed with text ("Today", "Coming up"), not just color.
- No decorative animations; honours `MediaQuery.disableAnimations`.

## Destructive actions
- Let go (dismiss follow-up): undo snackbar.
- Delete person: dialog "Delete Mariana? This removes their reminders, dates and moments from this phone." [Cancel] [Delete].
- Delete all data: dialog with text field requiring "DELETE".
