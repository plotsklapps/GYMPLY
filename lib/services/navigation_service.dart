import 'package:signals/signals_flutter.dart';

// Signal<int> to track current tab.
final Signal<int> sCurrentTab = Signal<int>(0, debugLabel: 'sCurrentTab');

// Helper to switch tabs.
void navigateToTab(int index) {
  sCurrentTab.value = index;
}

// Constants for Tab indexes.
class AppTabs {
  static const int stats = 0;
  static const int workout = 1;
  static const int exercise = 2;
  static const int search = 3;
}
