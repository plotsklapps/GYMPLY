import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/modals/menu_modal.dart';
import 'package:gymply/modals/quitgymply_modal.dart';
import 'package:gymply/modals/saveplannedworkout_modal.dart';
import 'package:gymply/modals/saveworkout_modal.dart';
import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/modals/selectplanneddate_modal.dart';
import 'package:gymply/modals/weeklysummary_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/exercisescreen/exercise_screen.dart';
import 'package:gymply/screens/feedscreen/feed_screen.dart';
import 'package:gymply/screens/statisticsscreen/statistics_screen.dart';
import 'package:gymply/screens/workout_screen.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/signals/workouthistory_signal.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:gymply/theme/icons.dart';
import 'package:gymply/widgets/resttimer_widget.dart';
import 'package:gymply/widgets/totaltimer_widget.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

class HomeScreen extends SignalStatefulWidget {
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

    // Auto-check for weekly summary on new week start.
    _checkAndShowWeeklySummary();
  }

  void _checkAndShowWeeklySummary() {
    final DateTime now = DateTime.now();
    // Monday of the current week (Monday = 1, Sunday = 7).
    final DateTime currentWeekMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    // Previous week Monday & Sunday.
    final DateTime prevWeekMonday = currentWeekMonday.subtract(
      const Duration(days: 7),
    );
    final DateTime prevWeekSunday = prevWeekMonday.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    final String prevWeekKey =
        '${prevWeekMonday.year}_W${_getWeekOfYear(prevWeekMonday)}';

    if (sLastShownWeeklySummaryKey.value == prevWeekKey) {
      return;
    }

    final List<Workout> history = sWorkoutHistory.value;
    final List<Workout> prevWeekWorkouts = history.where((Workout w) {
      return w.dateTime.isAfter(
            prevWeekMonday.subtract(const Duration(seconds: 1)),
          ) &&
          w.dateTime.isBefore(prevWeekSunday.add(const Duration(seconds: 1)));
    }).toList();

    if (prevWeekWorkouts.isNotEmpty) {
      unawaited(settingsService.updateLastShownWeeklySummaryKey(prevWeekKey));

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await ModalService.showModal(
            context: context,
            child: WeeklySummaryModal(
              startDate: prevWeekMonday,
              endDate: prevWeekSunday,
              workouts: prevWeekWorkouts,
            ),
          );
        }
      });
    }
  }

  int _getWeekOfYear(DateTime date) {
    final int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
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
    final bool showFeed = cShowFeed.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final bool confirm = await ModalService.showModal(
          context: context,
          child: const QuitGymplyModal(),
        );

        if (confirm) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 160,
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[TotalTimerWidget(), RestTimerWidget()],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32),
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.zero,
              tabs: <Widget>[
                if (showFeed) const Tab(icon: Icon(IconUtils.feed, size: 20)),
                const Tab(icon: Icon(IconUtils.trendUp, size: 20)),
                const Tab(icon: Icon(IconUtils.dumbbell, size: 20)),
                const Tab(icon: Icon(IconUtils.edit, size: 20)),
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
                  await HapticFeedback.mediumImpact();

                  if (context.mounted) {
                    // Open menu modal.
                    await ModalService.showModal(
                      context: context,
                      child: const MenuModal(),
                    );
                  }
                },
                child: const Icon(IconUtils.chevronUp),
              ),
              const Spacer(),
              Text(
                'GYMPLY.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              FloatingActionButton(
                heroTag: 'saveFAB',
                elevation: 0,
                onPressed: () async {
                  // Give a bigger bzzz.
                  await HapticFeedback.mediumImpact();

                  if (context.mounted) {
                    if (TotalTimer.sTotalTimerRunning.value) {
                      // Live session: save completed workout.
                      await ModalService.showModal(
                        context: context,
                        child: const SaveWorkoutModal(),
                      );
                    } else {
                      // Stopped session: save planned/scheduled workout.
                      await ModalService.showModal(
                        context: context,
                        child: const SavePlannedWorkoutModal(),
                      );
                    }
                  }
                },
                child: const Icon(IconUtils.stop),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'newFAB',
                elevation: 0,
                onPressed: () async {
                  // Give a little bzzz.
                  await HapticFeedback.mediumImpact();

                  if (context.mounted) {
                    if (TotalTimer.sTotalTimerRunning.value) {
                      // Live session: search/add exercises to active workout.
                      await showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return const SearchModal();
                        },
                      );
                    } else {
                      // Stopped session: select future date to plan workout.
                      await ModalService.showModal(
                        context: context,
                        child: const SelectPlannedDateModal(),
                      );
                    }
                  }
                },
                child: const Icon(IconUtils.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
