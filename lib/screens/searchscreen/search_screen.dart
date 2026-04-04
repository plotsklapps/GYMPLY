import 'package:flutter/material.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/screens/searchscreen/equipmentchoicechips.dart';
import 'package:gymply/screens/searchscreen/exercisesgrid_results.dart';
import 'package:gymply/screens/searchscreen/exerciseslist_results.dart';
import 'package:gymply/screens/searchscreen/musclegroupchoicechips.dart';
import 'package:gymply/screens/searchscreen/workouttypechoicechips.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/signals/exercisesgridmode_signal.dart';
import 'package:gymply/signals/favoriteexercises_signal.dart';
import 'package:gymply/signals/search_signal.dart';
import 'package:gymply/signals/searchquery_signal.dart';
import 'package:gymply/signals/selectedequipment_signal.dart';
import 'package:gymply/signals/selectedmusclegroup_signal.dart';
import 'package:gymply/signals/selectedworkouttype_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchController searchController = SearchController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // Conditionally show a scrollToTop icon.
    _scrollController.addListener(() {
      final bool show = _scrollController.offset > 80;
      if (show != _showScrollToTop) {
        setState(() {
          _showScrollToTop = show;
        });
      }
    });
  }

  @override
  void dispose() {
    // Kill all controllers and nodes.
    searchController.dispose();
    searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final WorkoutType? workoutType = sSelectedWorkoutType.watch(context);
    final MuscleGroup? selectedMuscleGroup = sSelectedMuscleGroup.watch(
      context,
    );
    final Equipment? selectedEquipment = sSelectedEquipment.watch(context);
    final String searchQuery = sSearchQuery.watch(context);

    final bool showMuscleGroups = filterService.sShowMuscleGroups.watch(
      context,
    );
    final bool showEquipment = filterService.sShowEquipment.watch(context);
    final List<ExercisePath> filteredExercises = filterService
        .cFilteredExercises
        .watch(context);
    final bool isLoading = sSearchLoading.watch(context);
    final List<int> favorites = sFavoriteExercises.watch(context);
    final bool isGridMode = sExercisesGridMode.watch(context);

    // Calculate dynamic height for floating chips header.
    double chipsHeight = 52;
    if (showMuscleGroups) chipsHeight += 52.0;
    if (showEquipment) chipsHeight += 52.0;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            centerTitle: false,
            automaticallyImplyLeading: false,
            primary: false,
            backgroundColor: theme.colorScheme.surface,
            toolbarHeight: 82,
            expandedHeight: 82 + chipsHeight + 8,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            title: Row(
              children: <Widget>[
                // PINNED SEARCH BAR.
                Expanded(
                  child: Container(
                    height: 82,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: SearchBar(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onTapOutside: (PointerDownEvent event) {
                        searchFocusNode.unfocus();
                      },
                      leading: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                sSearchQuery.value = '';
                                searchFocusNode.unfocus();
                              },
                              icon: const Icon(LucideIcons.searchX),
                            )
                          : IconButton(
                              onPressed: () {},
                              icon: const Icon(LucideIcons.search),
                            ),
                      onChanged: (String value) {
                        sSearchQuery.value = value;
                      },
                    ),
                  ),
                ),
                // TOGGLE VIEW MODE BUTTON.
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: settingsService.toggleExerciseViewMode,
                    icon: Icon(
                      isGridMode
                          ? LucideIcons.layoutList
                          : LucideIcons.layoutGrid,
                    ),
                  ),
                ),
                // CONDITIONAL SCROLL TO TOP BUTTON.
                if (_showScrollToTop)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      onPressed: () async {
                        await _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(
                        LucideIcons.circleChevronUp,
                      ),
                    ),
                  ),
              ],
            ),
            // SNAPPING FILTERS.
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 82,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // WORKOUT TYPE CHOICE CHIPS.
                        WorkoutTypeChoiceChips(
                          workoutType: workoutType,
                        ),
                        // CONDITIONAL MUSCLEGROUP CHOICE CHIPS.
                        if (showMuscleGroups)
                          MuscleGroupChoiceChips(
                            selectedMuscleGroup: selectedMuscleGroup,
                          ),
                        // CONDITIONAL EQUIPMENT CHOICE CHIPS.
                        if (showEquipment)
                          EquipmentChoiceChips(
                            workoutType: workoutType,
                            selectedEquipment: selectedEquipment,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // EXERCISE GRID OR STATE.
          if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredExercises.isEmpty &&
              (workoutType != null || searchQuery.isNotEmpty))
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No exercises found matching these filters.'),
              ),
            )
          else if (isGridMode)
            ExercisesGridResults(
              exercises: filteredExercises,
              favorites: favorites,
              searchFocusNode: searchFocusNode,
            )
          else
            ExercisesListResults(
              exercises: filteredExercises,
              favorites: favorites,
              searchFocusNode: searchFocusNode,
            ),
        ],
      ),
    );
  }
}
