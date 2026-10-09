import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../viewmodels/exercise/exercise_viewmodel.dart';
import '../../widgets/gradient_background.dart';
import '../workout/muscle_picker_view.dart';
import 'widgets/exercise_card.dart';
import 'widgets/exercise_details_sheet.dart';
import 'widgets/exercise_empty_placeholder.dart';
import 'widgets/exercise_filter_bar.dart';
import 'widgets/exercise_filter_modal.dart';
import 'widgets/exercise_segmented_switcher.dart';

class ExerciseView extends ConsumerStatefulWidget {
  const ExerciseView({super.key});

  @override
  ConsumerState<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends ConsumerState<ExerciseView>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: All Exercises, 1: 3D Body Model
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _filterAnimationController;
  late final Animation<double> _filterAnimation;
  double _lastScrollOffset = 0.0;
  bool _isFilterVisible = true;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilter() {
    if (!_isFilterVisible) {
      _isFilterVisible = true;
      _filterAnimationController.forward();
    }
  }

  void _hideFilter() {
    if (_isFilterVisible) {
      _isFilterVisible = false;
      _filterAnimationController.reverse();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final current = _scrollController.offset;
    final delta = current - _lastScrollOffset;
    _lastScrollOffset = current;

    // At top of scrollable area: always show filter buttons
    if (current <= 15) {
      _showFilter();
    } else if (delta > 8 && current > 30) {
      // User is scrolling down
      _hideFilter();
    } else if (delta < -8) {
      // User is scrolling back up
      _showFilter();
    }

    // Infinite scroll trigger: load next batch when within 300px of bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (current >= maxScroll - 300) {
      ref.read(exerciseListViewModelProvider.notifier).loadMore();
    }
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      // User dragged finger upwards (scrolling down the list)
      if (_scrollController.hasClients && _scrollController.offset > 20) {
        _hideFilter();
      }
    } else if (notification.direction == ScrollDirection.forward) {
      // User dragged finger downwards (scrolling up the list)
      _showFilter();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseListViewModelProvider);
    final viewModel = ref.read(exerciseListViewModelProvider.notifier);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Exercises Library',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.velocityTextPrimary,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppTheme.velocityTextPrimary,
            ),
            tooltip: 'Filter Exercises',
            onPressed: () {
              ExerciseFilterModal.show(
                context,
                selectedMuscle: state.selectedMuscle,
                selectedEquipment: state.selectedEquipment,
                selectedCategory: state.selectedCategory,
                onApply: (muscle, equipment, category) {
                  viewModel.setAdvancedFilters(
                    muscle: muscle,
                    equipment: equipment,
                    category: category,
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ExerciseSegmentedSwitcher(
            selectedTab: _selectedTab,
            onTabChanged: (tab) {
              setState(() => _selectedTab = tab);
              if (tab == 0) _showFilter();
            },
          ),
          Expanded(
            child: _selectedTab == 1
                ? const MusclePickerView(isEmbedded: true)
                : _buildCatalogContent(state, viewModel),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCatalogContent(
    ExerciseListState state,
    ExerciseListViewModel viewModel,
  ) {
    return NotificationListener<UserScrollNotification>(
      onNotification: _handleUserScroll,
      child: Column(
        children: [
          // Collapsible Animated Search & Filter Bar
          ExerciseFilterBar(
            animation: _filterAnimation,
            searchController: _searchController,
            searchQuery: state.searchQuery,
            selectedMuscle: state.selectedMuscle,
            selectedEquipment: state.selectedEquipment,
            onSearchChanged: viewModel.setSearchQuery,
            onClearSearch: () {
              _searchController.clear();
              viewModel.setSearchQuery('');
            },
            onMuscleSelected: viewModel.setMuscle,
            onEquipmentSelected: viewModel.setEquipment,
          ),
          Expanded(
            child: state.isLoading && state.exercises.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.velocityLime,
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.velocityDark,
                    backgroundColor: AppTheme.velocityLime,
                    onRefresh: viewModel.refresh,
                    child: _buildExerciseCardsList(state, viewModel),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCardsList(
    ExerciseListState state,
    ExerciseListViewModel viewModel,
  ) {
    final exercises = state.filteredExercises;

    if (exercises.isEmpty && !state.isLoading) {
      return ExerciseEmptyPlaceholder(
        hasActiveFilters: state.hasActiveFilters,
        onResetFilters: () {
          _searchController.clear();
          viewModel.clearFilters();
        },
      );
    }

    final totalDisplay = state.total > 0 ? state.total : exercises.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${exercises.length} of $totalDisplay moves',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              if (state.hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    viewModel.clearFilters();
                  },
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
            itemCount: exercises.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == exercises.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.velocityLime,
                      ),
                    ),
                  ),
                );
              }

              final exercise = exercises[index];
              return ExerciseCard(
                exercise: exercise,
                onTapDetails: () {
                  ExerciseDetailsSheet.show(
                    context,
                    exercise,
                    onSelectVariation: (alt) {
                      _searchController.text = alt;
                      viewModel.setSearchQuery(alt);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
