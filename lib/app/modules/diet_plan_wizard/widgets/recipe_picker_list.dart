import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);

/// Groups a recipe list into Mains (untagged) / Sides / Salads sections,
/// each under its own heading - a side/salad accompaniment cross-listed
/// into an eligible slot (see uploadRecipieController.js's
/// SIDE_SALAD_ELIGIBLE_SLOTS broadening, GET /recipes) would otherwise sit
/// anonymously mixed into the slot's own main-dish options with no
/// indication of what it actually is. Used by both the Add Recipe and Swap
/// Recipe pickers (Step 2's generate_review_view.dart and Step 3's
/// refine_portions_step_view.dart) so the two stay visually consistent.
class RecipePickerList extends StatelessWidget {
  final List<RecipeListItem> recipes;
  final void Function(RecipeListItem recipe) onSelect;
  // Step 2 must never show calories (spec: recipe name only) - Step 3
  // shows them freely. See each call site.
  final bool showCalories;

  const RecipePickerList({super.key, required this.recipes, required this.onSelect, this.showCalories = false});

  @override
  Widget build(BuildContext context) {
    final mains = recipes.where((r) => !r.isSide && !r.isSalad).toList();
    final sides = recipes.where((r) => r.isSide).toList();
    final salads = recipes.where((r) => r.isSalad).toList();

    return ListView(
      shrinkWrap: true,
      children: [
        ..._tiles(mains),
        if (sides.isNotEmpty) ..._section('Sides', sides),
        if (salads.isNotEmpty) ..._section('Salads', salads),
      ],
    );
  }

  List<Widget> _section(String heading, List<RecipeListItem> items) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: CustomText(text: heading, fontWeight: FontWeight.w600, fontSize: 13, color: _headerColor),
      ),
      const Divider(height: 1),
      ..._tiles(items),
    ];
  }

  List<Widget> _tiles(List<RecipeListItem> items) {
    return items
        .map(
          (recipe) => Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: CustomText(text: recipe.name, fontWeight: FontWeight.w500, fontSize: 14, color: _bodyColor),
                subtitle: showCalories && recipe.calories != null
                    ? CustomText(text: '${recipe.calories} Cal', fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor)
                    : null,
                onTap: () => onSelect(recipe),
              ),
              const Divider(height: 1),
            ],
          ),
        )
        .toList();
  }
}
