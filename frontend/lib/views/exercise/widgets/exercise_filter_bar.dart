import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import 'exercise_types.dart';

class ExerciseFilterBar extends StatelessWidget {
  final Animation<double>? animation;
  final double shrinkProgress;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedMuscle;
  final String selectedEquipment;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onMuscleSelected;
  final ValueChanged<String> onEquipmentSelected;

  const ExerciseFilterBar({
    super.key,
    this.animation,
    this.shrinkProgress = 0.0,
    required this.searchController,
    required this.searchQuery,
    required this.selectedMuscle,
    required this.selectedEquipment,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onMuscleSelected,
    required this.onEquipmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    // If animation is provided, use it; otherwise fallback to shrinkProgress for compatibility
    final effectiveAnimation = animation ??
        AlwaysStoppedAnimation<double>(
          (1.0 - shrinkProgress).clamp(0.0, 1.0),
        );

    return AnimatedBuilder(
      animation: effectiveAnimation,
      builder: (context, _) {
        final t = effectiveAnimation.value.clamp(0.0, 1.0);

        // Clean, modern search bar metrics matching app dark aesthetic
        const searchHeight = 42.0;
        const searchRadius = 14.0;
        const searchMarginH = 16.0;
        final searchMarginV = lerpDouble(3.0, 6.0, t)!;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.velocityBackground.withValues(alpha: 0.96),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.velocityBorder.withValues(
                  alpha: lerpDouble(0.7, 0.4, t)!,
                ),
                width: 1,
              ),
            ),
            boxShadow: t < 0.98
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18 * (1.0 - t)),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Clean, Modern Search Bar (Consistent with App Dark UI & Colors)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: searchMarginH,
                  vertical: searchMarginV,
                ),
                child: Container(
                  height: searchHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.velocitySurfaceMuted,
                    borderRadius: BorderRadius.circular(searchRadius),
                    border: Border.all(
                      color: searchQuery.isNotEmpty
                          ? AppTheme.velocityLime.withValues(alpha: 0.6)
                          : AppTheme.velocityBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      if (searchQuery.isNotEmpty)
                        BoxShadow(
                          color: AppTheme.velocityLime.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Prefix Search Icon (animates to lime when query entered)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 10.0),
                        child: Icon(
                          Icons.search_rounded,
                          size: 19.0,
                          color: searchQuery.isNotEmpty
                              ? AppTheme.velocityLime
                              : AppTheme.velocityTextMuted,
                        ),
                      ),

                      // Text Input Field
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          cursorColor: AppTheme.velocityLime,
                          cursorWidth: 1.8,
                          cursorRadius: const Radius.circular(2),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.velocityTextPrimary,
                            letterSpacing: 0.1,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Search exercises, muscles...',
                            hintStyle: TextStyle(
                              color: AppTheme.velocityTextMuted,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      // Clear Button (visible when text is entered)
                      if (searchQuery.isNotEmpty) ...[
                        GestureDetector(
                          onTap: onClearSearch,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.velocityBorder.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: AppTheme.velocityTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. Collapsible Filter Buttons (Slide Up & Disappear / Slide Down & Reappear)
              ClipRect(
                child: SizeTransition(
                  sizeFactor: effectiveAnimation,
                  axis: Axis.vertical,
                  alignment: Alignment.topCenter,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.65),
                      end: Offset.zero,
                    ).animate(effectiveAnimation),
                    child: FadeTransition(
                      opacity: effectiveAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 6),
                          // Muscle Filter Chips ("filtering buttons")
                          SizedBox(
                            height: 38.0,
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: searchMarginH,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: kMuscleOptions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final option = kMuscleOptions[index];
                                final isSelected = selectedMuscle == option.name;
                                final activeColor = option.name == 'All'
                                    ? AppTheme.velocityLime
                                    : option.color;

                                return InkWell(
                                  onTap: () => onMuscleSelected(option.name),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? activeColor
                                          : AppTheme.velocitySurfaceMuted,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? activeColor
                                            : AppTheme.velocityBorder,
                                        width: 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: activeColor.withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          option.icon,
                                          size: 15,
                                          color: isSelected
                                              ? (option.name == 'All'
                                                  ? AppTheme.velocityDark
                                                  : Colors.white)
                                              : option.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          option.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? (option.name == 'All'
                                                    ? AppTheme.velocityDark
                                                    : Colors.white)
                                                : AppTheme.velocityTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Equipment Filter Chips
                          if (kEquipmentOptions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32.0,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: searchMarginH,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: kEquipmentOptions.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final equip = kEquipmentOptions[index];
                                  final isSelected = selectedEquipment == equip;
                                  return InkWell(
                                    onTap: () => onEquipmentSelected(equip),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.velocityLime
                                            : AppTheme.velocitySurfaceMuted,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.velocityLime
                                              : AppTheme.velocityBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          equip,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? AppTheme.velocityDark
                                                : AppTheme.velocityTextSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle bottom spacing
              SizedBox(height: lerpDouble(4.0, 2.0, t)!),
            ],
          ),
        );
      },
    );
  }
}
