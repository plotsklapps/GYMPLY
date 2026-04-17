import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/menu_modal.dart';
import 'package:gymply/modals/saveworkout_modal.dart';
import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/screens/exercisescreen/exercise_screen.dart';
import 'package:gymply/screens/feedscreen/feed_screen.dart';
import 'package:gymply/screens/statisticsscreen/statistics_screen.dart';
import 'package:gymply/screens/workout_screen.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late EffectCleanup _tabSubscription;
  late EffectCleanup _feedToggleSubscription;

  @override
  void initState() {
    super.initState();
    // Determine initial length based on whether we show the feed.
    final int initialLength = cShowFeed.value ? 4 : 3;
    _tabController = TabController(
      length: initialLength,
      vsync: this,
      initialIndex: _getClampedIndex(sCurrentTab.value, initialLength),
    );

    // Sync TabController with sCurrentTab Signal.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        sCurrentTab.value = _tabController.index;
      }
    });

    // Listen to sCurrentTab changes (Manual navigation via code).
    _tabSubscription = sCurrentTab.subscribe((int index) {
      final int target = _getClampedIndex(index, _tabController.length);
      if (_tabController.index != target) {
        _tabController.animateTo(
          target,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });

    // Listen for Nostr login/logout to recreate the TabController.
    _feedToggleSubscription = cShowFeed.subscribe((bool showFeed) {
      final int newLength = showFeed ? 4 : 3;
      if (_tabController.length != newLength) {
        _recreateTabController(newLength);
      }
    });
  }

  int _getClampedIndex(int index, int length) {
    if (index >= length) return length - 1;
    if (index < 0) return 0;
    return index;
  }

  void _recreateTabController(int newLength) {
    final int oldIndex = _tabController.index;
    _tabController.dispose();
    setState(() {
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: _getClampedIndex(oldIndex, newLength),
      );
      // Re-attach listener to the new controller.
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          sCurrentTab.value = _tabController.index;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabSubscription();
    _feedToggleSubscription();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showFeed = cShowFeed.watch(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 160,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TotalTimerWidget(),
            RestTimerWidget(),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: TabBar(
            // Use TabAlignment.fill for non-scrollable tab bars.
            tabAlignment: TabAlignment.fill,
            indicatorColor: theme.colorScheme.secondary,
            controller: _tabController,
            labelPadding: EdgeInsets.zero,
            tabs: <Widget>[
              if (showFeed)
                const Tab(
                  icon: Icon(LucideIcons.rss),
                ),
              const Tab(
                icon: Icon(LucideIcons.trendingUp),
              ),
              const Tab(
                icon: Icon(LucideIcons.dumbbell),
              ),
              const Tab(
                icon: Icon(LucideIcons.notebookPen),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          if (showFeed) const FeedScreen(),
          const StatisticsScreen(),
          const WorkoutScreen(),
          const ExerciseScreen(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'menuFAB',
              elevation: 0,
              onPressed: () async {
                // Give a little bzzz.
                await HapticFeedback.lightImpact();

                if (context.mounted) {
                  // Open menu modal.
                  await ModalService.showModal(
                    context: context,
                    child: const MenuModal(),
                  );
                }
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
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'saveFAB',
            elevation: 0,
            onPressed: () async {
              // Give a bigger bzzz.
              await HapticFeedback.mediumImpact();

              if (context.mounted) {
                // Open save workout modal.
                await ModalService.showModal(
                  context: context,
                  child: const SaveWorkoutModal(),
                );
              }
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

              if (context.mounted) {
                // Do not use ModalService here because of entirely different
                // layout and scrollability.
                await showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return const SearchModal();
                  },
                );
              }
            },
            child: const Icon(LucideIcons.circlePlus),
          ),
        ],
      ),
    );
  }
}
