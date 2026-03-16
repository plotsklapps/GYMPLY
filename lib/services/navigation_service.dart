import 'package:gymply/services/nostr_service.dart';
import 'package:signals/signals_flutter.dart';

// Logical Enum for all tabs.
enum AppTab { feed, stats, workout, exercise, search }

// Computed value for Feed visibility.
final Computed<bool> cShowFeed = Computed<bool>(
  () => nostrService.sNpub.value != null,
  debugLabel: 'cShowFeed',
);

// Signal<int> to track current PHYSICAL tab index.
// Defaulting to the index of Statistics (which is 1 if feed is shown, 0 if not).
final Signal<int> sCurrentTab = Signal<int>(
  nostrService.sNpub.value != null ? 1 : 0,
  debugLabel: 'sCurrentTab',
);

/// Helper to switch tabs using the logical [AppTab] enum.
/// This handles the index shift automatically if the Feed is visible.
void navigateToTab(AppTab tab) {
  final bool showFeed = cShowFeed.value;

  final int targetIndex = switch (tab) {
    AppTab.feed => 0,
    AppTab.stats => showFeed ? 1 : 0,
    AppTab.workout => showFeed ? 2 : 1,
    AppTab.exercise => showFeed ? 3 : 2,
    AppTab.search => showFeed ? 4 : 3,
  };

  sCurrentTab.value = targetIndex;
}

/// Legacy helper for cases where we still need a direct index jump.
void navigateToPhysicalIndex(int index) {
  sCurrentTab.value = index;
}

/// Deprecated: Use the [AppTab] enum with [navigateToTab] instead.
class AppTabs {
  static const int stats = 0;
  static const int workout = 1;
  static const int exercise = 2;
  static const int search = 3;
}
