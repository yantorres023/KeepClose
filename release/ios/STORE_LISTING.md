# App Store listing — KeepClose (draft)

Re-verify current App Store Review Guidelines and SDK requirements in App Store Connect
before submission.

- **Name (≤30):** KeepClose: Remember to Ask
- **Subtitle (≤30):** Small things that show you care
- **Primary category:** Lifestyle · **Secondary:** Productivity
- **Keywords (≤100, comma-separated):** friends,follow up,remember,reminder,birthday,relationships,check in,keep in touch,friendship
- **Promotional text (≤170):** Jot down what friends tell you — an interview, a move, a hard week — and get one gentle reminder to ask how it went. Private, no account.
- **Description:** reuse release/android/STORE_LISTING.md full description.
- **Support URL:** [SUPPORT_URL] · **Privacy Policy URL:** [PRIVACY_URL]
- **Bundle ID:** app.keepclose (must be registered in the owner's Apple Developer account)

## App Privacy ("nutrition label")
**Data Not Collected.** The app stores data only on-device and has no analytics or
third-party SDKs that collect data.

## Export compliance
`ITSAppUsesNonExemptEncryption = false` is set in Info.plist (no custom encryption; no network).

## Permissions / usage descriptions
- Notifications: system prompt shown only after the first reminder is created (no Info.plist string needed).
- Contacts: **none** — `CNContactPickerViewController` requires no permission or usage description.

## Age rating
Answer "None" to all content questions → expected **4+**. (App is not directed at children; don't use the Kids category.)

## Screenshot plan
6.9" (1320×2868) and 6.5" sets; same six scenes as Android. Demo data only.

## Review notes (for App Review)
"KeepClose stores all data locally. No login is required. To test: add a person, tap
'Remember to ask', enter a note and choose 'Tomorrow'. Today shows reminders due today;
use Settings to change the daily reminder time."

## Guideline risk check
- 4.2 Minimum functionality: native app with local notifications, contact picker, persistence — OK.
- 5.1.1 Data collection: none — OK.
- 4.3 Spam: the "stay in touch" category is crowded; differentiation (follow-ups) should be explicit in the description and screenshots.

## Signing / TestFlight — HUMAN ACTION REQUIRED
Requires an Apple Developer Program membership ($99/yr), a registered bundle ID, signing
certificate and provisioning profile (Xcode automatic signing is simplest), then
`flutter build ipa` on a Mac and upload via Xcode Organizer or Transporter.
