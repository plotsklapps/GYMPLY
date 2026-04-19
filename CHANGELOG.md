# Changelog

All notable changes to this project will be documented in this file.

## [0.0.5] - 2026-04-19
- **Muscle Activation Heatmaps:**
    - Integrated `flutter_body_atlas` to provide visual muscle activation heatmaps on the `StatisticsScreen`, displaying worked muscles on front and back views.
    - Implemented `AtlasService` and `AtlasMapper` for efficient mapping of internal muscle groups to atlas-specific IDs.
- **Enhanced Progress Visualization:**
    - Refactored `ProgressChart` into a `StatefulWidget` to support dynamic timescale switching (30 Days, 6 Months, 1 Year, All Time).
    - Added bar and line chart visualization support with interactive Y-axis dynamic scaling.
- **User Experience & Attributions:**
    - Introduced `AttributionsModal` and added it to the `AboutModal` to provide proper credit for anatomical assets, theme engines, and state management libraries.
    - Standardized UI components and cleaned up internal code structure, including removing redundant `Builder` patterns and refining logging practices.
    - Improved robustness of workout filtering logic to prevent duplicate data rendering.
- **Internal Refactoring:**
    - Cleaned up `progresschart_widget.dart` and `exercisehistory_modal.dart` with more descriptive variable names and improved structural clarity.
    - Updated project version to 0.0.5+53.

## [0.0.5] - 2026-04-14
- **UI/UX & Navigation:** 
    - Refactored exercise search functionality from a standalone screen to a modal-based implementation (`SearchModal`) to simplify `HomeScreen` navigation.
    - Updated `home_screen.dart` to launch `SearchModal` directly via FAB, removing the dedicated search tab.
    - Refined navigation and icons across `MenuModal`, `AboutModal`, and `Nostr Onboarding`, standardizing on `circleChevronRight`.
    - Added `AboutModal` to centralize app info, update checks, changelogs, and license links, streamlining the main settings menu.
- **Service & Modal Logic:** 
    - Enhanced `ModalService` to improve system inset handling (keyboard/navigation bar) with dynamic padding and optional `SingleChildScrollView` support.
    - Improved `addimage_modal.dart` and `exercisedetail_modal.dart` with `useSafeArea` and refined bottom padding for better responsiveness.
    - Standardized modal interaction patterns, including automatic modal closing upon exercise selection.
- **Architecture & Build:** 
    - Migrated `WorkoutScreen` reordering to the standard `onReorder` callback for Flutter Stable compatibility.
    - Added `android.builtInKotlin` and `android.newDsl` to `gradle.properties` for Flutter's built-in Kotlin migration.
    - Bumped min Flutter SDK to `3.41.0` and updated internal dependencies (`analyzer`, `meta`, `vm_service`, `motor`, `stupid_simple_sheet`).
- **Cleanup & Polish:** 
    - Updated UI components (`ProfileHeader`, `BodyMetricsModal`, `ThemeSettingsModal`) for improved spacing and aesthetics.
    - Standardized choice chip styling by removing redundant text styles.
    - Enhanced visual elements, including exercise name gradients for better contrast and adding new icons to `MenuModal`.
    - Corrected various typos and refined title labeling across modals.

## [0.0.5] - 2026-04-13
- **Cleanup & Maintenance:** Removed `flutter_animate` and `flutter_shaders` to streamline dependencies. Updated project version to 0.0.5+51 and refined exercise result card styling.

## [0.0.5] - 2026-04-09
- **Notification Service:** Implemented a new foreground notification service for more reliable background timers, including integrated state management for live workout tracking.
- **Code Quality:** Applied widespread linting fixes, cleaned up imports, and improved documentation and comment clarity across timer and notification services.

## [0.0.5] - 2026-04-08
- **Background Reliability:** Replaced legacy activity tracking permissions with battery optimization requests to improve timer stability. Added support for foreground data synchronization.
- **Documentation:** Added a comprehensive `PRIVACY_POLICY.md` and polished `README.md`, `CONTRIBUTING.md`, and `LICENSE.md` for better clarity and professional presentation.

## [0.0.4] - 2026-04-06
- **Architecture Refactor:** Migrated timer/notification logic from exact alarms to a robust Foreground Service architecture.
- **Data & Permissions:** Integrated `FlutterSecureStorage` for permission management and added granular notification controls within app settings.
- **Efficiency:** Reduced notification update frequency for high-precision timers to optimize performance.

## [0.0.4] - 2026-04-05
- **Background Timers:** Enhanced notification system to trigger only when the app is in the background. Improved audio playback reliability by standardizing on `.wav` format.
- **Exercise Features:** Added Cardio Exercise and Rest Timer services, along with duration picker modals for improved workout tracking.

## [0.0.4] - 2026-04-04
- **Exercise Tracking:** Added support for tracking repetitions in Cardio exercises.
- **UI & UX:** Introduced a toggleable grid/list view for exercise search results.
- **Service Decoupling:** Refactored architecture to separate data persistence (`HiveService`), user settings (`SettingsService`), and body metrics from the core `WorkoutService`.

## [0.0.4] - 2026-04-03
- **Timer Enhancements:** Introduced `StopwatchTimerModal` for manual duration entry and improved timer responsiveness.
- **Nostr Integration:** Implemented lazy initialization for Nostr services to improve app startup and performance.

## [0.0.4] - 2026-04-02
- **Workout Management:** Implemented the workout summary modal with copy and delete functionality.

## [0.0.4] - 2026-03-31
- **UI Overhaul:** Redesigned `SearchScreen` using `SliverAppBar` and introduced a new `BodyMetricsModal` for tracking health data like BMI and body fat using the Gallagher formula.
- **Offline Reliability:** Added `ConnectivityService` to ensure the app handles offline states gracefully.

## [0.0.4] - 2026-03-29
- **Feed Interaction:** Enhanced `CommentModal` with loading states to improve feedback during comment submission and prevent duplicate posts.

## [0.0.4] - 2026-03-28
- **Nostr Integration:** Launched a new comment system for the workout feed, including post/reply capabilities and expanded user profiles.

## [0.0.4] - 2026-03-25
- **Body Tracking:** Introduced comprehensive body metrics tracking (BMI, body fat) with historical visualization charts.
- **Onboarding:** Added a polished onboarding flow to introduce app features and privacy commitments.

## [0.0.4] - 2026-03-24
- **Architecture:** Refactored core services into singletons and modularized signals into standalone files for better maintainability.
- **Security:** Enhanced Nostr private key security by storing them in secure storage instead of raw memory.

## [0.0.4] - 2026-03-23
- **Performance Tracking:** Implemented a Personal Record (PR) system that detects and celebrates new strength achievements, including 1RM estimates.
- **Calorie Tracking:** Added MET-based calorie estimation for stretching and cardio exercises.

## [0.0.3] - 2026-03-20
- **Branding:** Standardized app icons and splash screens across all platforms (Android, iOS, Web, Windows).
- **Core Features:** Initial implementation of exercise screens (Strength, Cardio, Stretch) and statistics tracking.

## [0.0.2] - 2026-03-18
- **Social Feed:** Introduced a feed feature where users can post workout notes, react to other posts, and manage their own activity logs.

## [0.0.2] - 2026-03-17
- **Nostr Integration:** Initial implementation of Nostr-based decentralized identity and social profiles.

## [0.0.2] - 2026-03-13
- **Media Support:** Added `ImageService` to support capturing and attaching workout photos to log entries.
- **Backup System:** Replaced cloud-sync with a robust local ZIP backup and restoration system using system-native share sheets.

## [0.0.2] - 2026-03-12
- **UI/UX:** Polished the UI with `flex_color_scheme` for dynamic themes, improved modal navigation, and finalized splash screens.

## [0.0.1] - 2026-03-05
- **Project Pivot:** Complete rewrite from PWA to native APK to resolve audio/timer issues on Android.
- **Core Functionality:** Established basic timer services and workout logging capabilities.
