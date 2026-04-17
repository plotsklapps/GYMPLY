import 'package:flutter/material.dart';
import 'package:gymply/modals/searchmodal/equipmentchoicechips.dart';
import 'package:gymply/modals/searchmodal/exercisesgrid_results.dart';
import 'package:gymply/modals/searchmodal/exerciseslist_results.dart';
import 'package:gymply/modals/searchmodal/musclegroupchoicechips.dart';
import 'package:gymply/modals/searchmodal/workouttypechoicechips.dart';
import 'package:gymply/models/exercise_model.dart';
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

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  @override
  State<SearchModal> createState() {
    return _SearchModalState();
  }
}

class _SearchModalState extends State<SearchModal> {
  final SearchController searchController = SearchController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
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

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'SEARCH EXERCISES.',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.circleX),
              ),
            ],
          ),
        ),
        const Divider(height: 4),
        Expanded(
          child: CustomScrollView(
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
                          icon: const Icon(LucideIcons.circleChevronUp),
                        ),
                      ),
                  ],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 82),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            WorkoutTypeChoiceChips(workoutType: workoutType),
                            if (showMuscleGroups)
                              MuscleGroupChoiceChips(
                                selectedMuscleGroup: selectedMuscleGroup,
                              ),
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
        ),
      ],
    );
  }
}
