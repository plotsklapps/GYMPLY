# Privacy Policy for GYMPLY

**Last updated: November 2026**

GYMPLY is a minimalistic, privacy‑first workout tracker.
This document explains what data the app does **not** collect, what permissions it uses, and why.

---

## 1. No Personal Data Collection

GYMPLY does **not** collect, store, share, or transmit any personal data.
The app does not use analytics, tracking tools, advertising SDKs, or remote servers.

Specifically, GYMPLY does **not**:

- collect personal information
- track user behavior
- store data on external servers
- share data with third parties
- use cookies or identifiers
- log usage or device information

All workout data stays **entirely on the user’s device**.

---

## 2. Local Data Storage Only

All information entered by the user (such as workouts, sets, reps, or timers) is stored **locally on the device**.
GYMPLY has no access to this data and cannot retrieve it.

If the user uninstalls the app, all locally stored data is removed from the device.

---

## 3. Required Permissions

GYMPLY uses only the minimum permissions required for core functionality.

### Foreground Service (Android)

GYMPLY uses a foreground service to ensure that:

- workout timers
- rest timers
- alarms and notifications

continue to function even when:

- the app is in the background
- the screen is locked
- the user switches to another app

This service runs **only while the user is actively using workout timers**.
It does **not** collect or transmit any data.

### Live Activities (iOS)

On iOS, GYMPLY uses Live Activities to display active workout timers on the Lock Screen and Dynamic Island. All timer state stays strictly on your device and is never sent to external servers.

### Notifications

Notifications are used solely to:

- alert the user when a timer or rest period ends
- keep timers running reliably in the background

Notifications are never used for marketing or tracking.

### Camera & Photo Library (Optional)

If you choose to attach photos to exercises or workouts, GYMPLY requests access to your camera or photo library. Any selected photos are stored locally on your device unless you explicitly choose to share them yourself.

---

## 4. In-App Subscriptions & Optional Cloud Backup Sync

### In-App Subscriptions

GYMPLY offers optional auto-renewable Supporter Subscriptions through the **Apple App Store** (iOS/iPadOS) and **Google Play** (Android) to unlock extra themes, fonts, and optional automatic Cloud Backup Sync.

- All billing, payment processing, and subscription management are handled exclusively by Apple or Google under their respective privacy policies.
- GYMPLY never receives, processes, or stores your payment details, name, or billing address.

### Optional Cloud Backup Sync (Google Drive & Apple iCloud)

Active Supporters may optionally enable automatic backup synchronization across their devices using their own personal cloud storage:

- **Android (Google Drive):** GYMPLY requests only the restricted `https://www.googleapis.com/auth/drive.appdata` scope, which grants access exclusively to a hidden, app-specific folder in your personal Google Drive. GYMPLY cannot view, read, modify, or delete any other files or photos in your Google Drive. GYMPLY's use and transfer of information received from Google APIs adheres to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements.
- **iOS / iPadOS (Apple iCloud):** GYMPLY stores backups exclusively in your personal private iCloud container (`iCloud.dev.plotsklapps.gymply`), managed by Apple under Apple's Privacy Policy.

Backup files are never uploaded to or stored on any server operated by GYMPLY. You can disable cloud sync or revoke access at any time in the app or via your Google / Apple account settings.

---

## 5. Optional Internet Communication

GYMPLY does not send your workout data to external servers by default.
The app accesses the internet **only** when needed for optional features:

- loading or publishing to the optional Nostr feed (only when initiated by the user)
- verifying or restoring optional App Store / Google Play supporter subscriptions
- syncing optional encrypted/archived backups directly with your personal Google Drive (`appDataFolder`) or Apple iCloud container (only when explicitly enabled by an active Supporter)
- opening external links such as this privacy policy, terms of service, or the GitHub project page

---

## 6. Children’s Privacy

GYMPLY does not collect any data from users of any age, including children.
The app is safe to use for all age groups.

---

## 7. Changes to This Policy

If GYMPLY’s functionality changes in a way that affects privacy, this policy will be updated.
The latest version will always be available on the official GitHub repository.

---

## 8. Contact

If you have questions about this privacy policy, you can contact the developer:

**Email:** plotsklapps@gmail.com
**GitHub:** https://github.com/plotsklapps
**X:** https://x.com/@plotsklapps

---

## Summary

GYMPLY is designed with a simple principle:
**Your data stays on your device. Always.**
