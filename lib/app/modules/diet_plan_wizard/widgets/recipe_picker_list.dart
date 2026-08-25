import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

const _primaryColor = Color(0xff851653);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _tileBg = Color(0xffFAFAFB);
const _sideAccent = Color(0xff2F7D5E);
const _saladAccent = Color(0xff3E7C4A);

/// Groups a recipe list into Mains (untagged) / Sides / Salads sections,
/// each under its own heading - a side/salad accompaniment cross-listed
/// into an eligible slot (see uploadRecipieController.js's
/// SIDE_SALAD_ELIGIBLE_SLOTS broadening, GET /recipes) would otherwise sit
/// anonymously mixed into the slot's own main-dish options with no
/// indication of what it actually is. Used by both the Add Recipe and Swap
/// Recipe pickers (Step 2's generate_review_view.dart and Step 3's
/// refine_portions_step_view.dart) so the two stay visually consistent.
///
/// Rows render as tappable rounded cards (not a bare ListTile+Divider) with
/// a category-tinted leading icon, matching this app's existing card
/// language elsewhere (see patients/widgets/food_card_widget.dart) rather
/// than the plain list styling this replaced.
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
      padding: const EdgeInsets.only(bottom: 4),
      children: [
        ..._tiles(mains, icon: Icons.restaurant_menu, accent: _primaryColor),
        if (sides.isNotEmpty) ..._section('Sides', Icons.eco_outlined, _sideAccent, sides),
        if (salads.isNotEmpty) ..._section('Salads', Icons.spa_outlined, _saladAccent, salads),
      ],
    );
  }

  List<Widget> _section(String heading, IconData icon, Color accent, List<RecipeListItem> items) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            CustomText(
              text: heading.toUpperCase(),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: accent,
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(height: 1, color: accent.withOpacity(0.25))),
          ],
        ),
      ),
      ..._tiles(items, icon: icon, accent: accent),
    ];
  }

  List<Widget> _tiles(List<RecipeListItem> items, {required IconData icon, required Color accent}) {
    return items
        .map(
          (recipe) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _tileBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(recipe),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                        child: Icon(icon, size: 17, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(text: recipe.name, fontWeight: FontWeight.w600, fontSize: 14, color: _bodyColor),
                            if (showCalories && recipe.calories != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CustomText(text: '${recipe.calories} Cal', fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: _mutedColor.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}
