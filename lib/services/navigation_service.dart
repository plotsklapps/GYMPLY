import 'package:gymply/services/connectivity_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:signals/signals_flutter.dart';

// Logical Enum for all tabs.
enum AppTab { feed, stats, workout, exercise }

// Computed Signal for Feed visibility.
// Shows only if user has a pubkey AND is online.
final Computed<bool> cShowFeed = Computed<bool>(
  () {
    return nostrService.sNpub.value != null && sIsOnline.value;
  },
  debugLabel: 'cShowFeed',
);

// Int Signal to track current physical tab index. Default to 1 (Statistics).
final Signal<int> sCurrentTab = Signal<int>(1, debugLabel: 'sCurrentTab');

// Helper to switch tabs using AppTab enum. Feed tab is conditionally showing.
void navigateToTab(AppTab tab) {
  final bool showFeed = cShowFeed.value;

  final int targetIndex = switch (tab) {
    AppTab.feed => 0,
    AppTab.stats => showFeed ? 1 : 0,
    AppTab.workout => showFeed ? 2 : 1,
    AppTab.exercise => showFeed ? 3 : 2,
  };

  sCurrentTab.value = targetIndex;
}
