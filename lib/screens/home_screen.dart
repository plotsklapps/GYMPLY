import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/screens/exercisescreen/exercise_screen.dart';
import 'package:gymply/screens/searchscreen/search_screen.dart';
import 'package:gymply/screens/statisticsscreen/statistics_screen.dart';
import 'package:gymply/screens/workout_screen.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/sheets/menu_sheet.dart';
import 'package:gymply/widgets/resttimer_widget.dart';
import 'package:gymply/widgets/totaltimer_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EffectCleanup _tabSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Sync TabController with sCurrentTab Signal.
    _tabController.index = sCurrentTab.value;

    // Update sCurrentTab on tap/swipe.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        sCurrentTab.value = _tabController.index;
      }
    });

    // Listen to sCurrentTab changes.
    _tabSubscription = sCurrentTab.subscribe((int index) {
      if (_tabController.index != index) {
        _tabController.animateTo(
          index,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Kill the TabController and clean up.
    _tabSubscription();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // Appbar with Timers.
      appBar: AppBar(
        toolbarHeight: 160,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TotalTimerWidget(),
            RestTimerWidget(),
          ],
        ),

        // TabBar with 4 tabs.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: TabBar(
            indicatorColor: theme.colorScheme.secondary,
            controller: _tabController,
            labelPadding: EdgeInsets.zero,
            tabs: const <Widget>[
              Tab(text: 'STATISTICS', height: 32),
              Tab(text: 'WORKOUT', height: 32),
              Tab(text: 'EXERCISE', height: 32),
              Tab(text: 'SEARCH', height: 32),
            ],
          ),
        ),
      ),

      // Main Content for current Tab.
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          StatisticsScreen(),
          WorkoutScreen(),
          ExerciseScreen(),
          SearchScreen(),
        ],
      ),

      // BottomAppBar with Menu and Title.
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'menuFAB',
              elevation: 0,
              onPressed: () async {
                // Give a little bzzz.
                await HapticFeedback.lightImpact();

                await SheetService.showSheet(
                  context: context,
                  child: const MenuSheet(),
                );
              },
              child: const Icon(LucideIcons.circleChevronUp),
            ),
            const SizedBox(width: 16),
            Text(
              'GYMPLY.',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontFamily: 'BebasNeue',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // Row FABs inside the BottomAppBar.
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'saveFAB',
            elevation: 0,
            onPressed: () async {
              // Give a bigger bzzz.
              await HapticFeedback.heavyImpact();

              // Save current workout.
              await workoutService.finishWorkout();
            },
            child: const Icon(LucideIcons.circleStop),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'newFAB',
            elevation: 0,
            onPressed: () async {
              // Give a little bzzz.
              await HapticFeedback.lightImpact();
              // Navigate to SearchScreen.
              sCurrentTab.value = 3;
            },
            child: const Icon(LucideIcons.circlePlus),
          ),
        ],
      ),
    );
  }
}
