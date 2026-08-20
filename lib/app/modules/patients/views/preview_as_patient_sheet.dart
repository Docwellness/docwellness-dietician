import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

/// AI_EXECUTION_PLAN.md Phase 7, P7-05: preview-as-patient - a read-only
/// rendering of everything currently selected for one week, grouped by
/// day-group then serving time (the same two axes the editor itself uses,
/// just all shown together instead of one tab at a time), so the
/// dietician can sanity-check the whole week before finalizing it.
/// Deliberately read-only: no onTap/onSelect anywhere in this file.
class PreviewAsPatientSheet extends StatelessWidget {
  final PatientsController controller;
  final int weekNumber;

  const PreviewAsPatientSheet({
    super.key,
    required this.controller,
    required this.weekNumber,
  });

  // Real serving-time slots only - matches _shifts in select_diet_sheet.dart
  // minus 'Supplements', which is a browsing-only pseudo-slot there (see
  // that file's doc comment): a selected supplement's `servingTime` is
  // always its own real slot (e.g. 'Night Drink'), never 'Supplements'
  // itself, so every selected recipe already sorts correctly here without
  // that pseudo-slot in this list.
  static const List<String> _servingTimeOrder = [
    'Morning Drink',
    'Breakfast',
    'Brunch',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Night Drink',
  ];

  String _dayGroupLabel(String dayGroup) {
    switch (dayGroup) {
      case 'Monday':
        return 'Monday & Friday';
      case 'Tuesday':
        return 'Tuesday & Saturday';
      case 'Wednesday':
        return 'Wednesday & Sunday';
      case 'Thursday':
        return 'Thursday';
      default:
        return dayGroup;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekRecipes = controller.weekSelectedRecipes[weekNumber] ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: 'Preview as Patient - Week $weekNumber',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: const Color(0xff1F2A37),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: weekRecipes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No meals selected for this week yet.',
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: PatientsController.dayGroups.map((dg) {
                          final dayRecipes =
                              weekRecipes.where((r) => r.dayGroup == dg).toList()
                                ..sort(
                                  (a, b) => _servingTimeOrder
                                      .indexOf(a.servingTime)
                                      .compareTo(
                                        _servingTimeOrder.indexOf(b.servingTime),
                                      ),
                                );
                          return _DayGroupSection(
                            label: _dayGroupLabel(dg),
                            recipes: dayRecipes,
                            controller: controller,
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayGroupSection extends StatelessWidget {
  final String label;
  final List<Recipe> recipes;
  final PatientsController controller;

  const _DayGroupSection({
    required this.label,
    required this.recipes,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: label,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xff851653),
          ),
          const SizedBox(height: 8),
          ...recipes.map((r) => _RecipeRow(recipe: r, controller: controller)),
        ],
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final Recipe recipe;
  final PatientsController controller;

  const _RecipeRow({required this.recipe, required this.controller});

  @override
  Widget build(BuildContext context) {
    final quantity = controller.componentServingsAt(recipe, 0);
    final unit = recipe.components.isNotEmpty ? recipe.components[0].unit : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              image: recipe.image.isNotEmpty && recipe.image.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(recipe.image),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: (recipe.image.isEmpty || !recipe.image.startsWith('http'))
                  ? const Color(0xffFDF2FA)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: (recipe.image.isEmpty || !recipe.image.startsWith('http'))
                ? const Icon(Icons.restaurant, color: Color(0xffEF45B2), size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: recipe.servingTime,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: const Color(0xff9CA3AF),
                ),
                CustomText(
                  text: recipe.name,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xff1F2A37),
                ),
              ],
            ),
          ),
          CustomText(
            text: '$quantity $unit',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: const Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
