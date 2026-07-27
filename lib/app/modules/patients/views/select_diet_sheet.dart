import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/food_card_widget.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectDietSheet extends StatefulWidget {
  final String patientId;
  final String dietPlanId;
  // Which week of the plan this screen reviews - needed so a cold load (see
  // initState) can re-fetch the right week's draft options; normal in-app
  // navigation already has this implicitly via controller.selectedWeek, but
  // that's exactly the in-memory state a browser refresh wipes out.
  final int week;
  const SelectDietSheet({
    super.key,
    required this.dietPlanId,
    required this.patientId,
    required this.week,
  });

  @override
  State<SelectDietSheet> createState() => _SelectDietSheetState();
}

class _SelectDietSheetState extends State<SelectDietSheet>
    with SingleTickerProviderStateMixin {
  // Get.find alone would throw "PatientsController not found" whenever this
  // screen is the very first thing built - e.g. a browser refresh landing
  // directly on this route, with no prior screen having Get.put() it. Get.put
  // otherwise would blow away the already-populated controller (selections,
  // draft options) on every *normal* navigation into this screen, since
  // Get.put always registers a fresh instance - so only fall back to it when
  // nothing is registered yet.
  final PatientsController controller = Get.isRegistered<PatientsController>()
      ? Get.find<PatientsController>()
      : Get.put(PatientsController());

  late final TabController _tabController;

  // keep consistent order with your ButtonsTabBar tabs
  // Must match the backend's servingTime enum values exactly (singular
  // "Evening Snack", not "Evening Snacks") - this list doubles as both the
  // tab labels AND the filter value compared against each meal's
  // servingTime in updateShiftMeals, so a mismatch here silently hides a
  // whole tab's meals even when the plan has real data for that slot.
  final List<String> _shifts = [
    "Breakfast",
    "Morning Drink",
    "Lunch",
    "Brunch",
    // "Morning Snacks",
    "Dinner",
    "Evening Snack",
    "Night Drink",
    // Browsing-only pseudo-slot (see buildServingTimeOptions in
    // dietPlanOptions.js) - lists every supplement recipe regardless of
    // its own real servingTime; a selection here still persists under
    // that real servingTime, never under "Supplements" itself.
    "Supplements",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _shifts.length, vsync: this);

    // Normal navigation here already ran getDraftDietOptions right before
    // Get.toNamed (see show_diet_level_sheet.dart), so draftDietOptions is
    // already the right plan/week - don't discard that in-memory state (and
    // any selections already applied from it) with a redundant refetch. Only
    // a cold load (e.g. browser refresh landing directly on this route, with
    // no prior screen's fetch) needs this.
    final existing = controller.draftDietOptions.value;
    if (existing == null ||
        existing.dietPlanId != widget.dietPlanId ||
        existing.week != widget.week) {
      controller.getDraftDietOptions(
        widget.patientId,
        widget.dietPlanId,
        widget.week,
      );
    }

    // set initial selectedShift from default
    controller.updateShiftOptions(_shifts[0]);

    // listen to tab changes and update controller
    _tabController.addListener(() {
      // only trigger when index changed (not while animating)
      if (!_tabController.indexIsChanging) {
        final shift = _shifts[_tabController.index];
        controller.updateShiftOptions(shift);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final RecipeService _recipeService = RecipeService();

  /// Fetches the recipe's full detail and opens it in a bottom sheet -
  /// mirrors the exact pattern already used to open RecipeDetailsScreen
  /// elsewhere in the app (see receipes/views/view_added_receipes.dart).
  Future<void> _openRecipeDetails(String recipeId) async {
    final fullRecipe = await _recipeService.getRecipeById(recipeId);
    if (fullRecipe == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, sheetScrollController) {
            return RecipeDetailsScreen(
              fromAddRecipeScreen: false,
              scrollController: sheetScrollController,
              recipePreview: fullRecipe,
            );
          },
        );
      },
    );
  }

  /// Human-friendly tab label for a day-group value - the underlying value
  /// sent to the backend is always the canonical 'Monday'/'Tuesday'/
  /// 'Wednesday'/'Thursday'.
  String _dayGroupLabel(String dayGroup) {
    switch (dayGroup) {
      case 'Monday':
        return 'Mon & Fri';
      case 'Tuesday':
        return 'Tue & Sat';
      case 'Wednesday':
        return 'Wed & Sun';
      case 'Thursday':
        return 'Thu';
      default:
        return dayGroup;
    }
  }

  List<String> getWeeksOfCurrentMonth() {
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;

    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0);

    int weekCount = 1;
    DateTime current = firstDay;

    List<String> weeks = [];

    while (current.isBefore(lastDay) || current.isAtSameMomentAs(lastDay)) {
      weeks.add("Week $weekCount");
      current = current.add(const Duration(days: 7));
      weekCount++;
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _shifts.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xff1F2A37)),
          title: Obx(
            () => CustomText(
              text: controller.selectedWeek.value,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: const Color(0xff1F2A37),
            ),
          ),
        ),
        body: Column(
          children: [
            // Day-group selector + serving-time tabs are pinned right below
            // the app bar (not inside the scrollable body below) so they
            // stay visible while the recipe list scrolls underneath.
            const SizedBox(height: 10),
            // Day-group selector - Monday's meals repeat on Friday,
            // Tuesday's on Saturday, Wednesday's on Sunday, Thursday
            // is unique (see backend utils/dayGroups.js). Switching
            // groups is a pure client-side filter (all 4 were
            // bundled into one fetch), so it's instant and never
            // loses in-progress selections in the other groups.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final current = controller.selectedDayGroup.value;
                return Row(
                  children: PatientsController.dayGroups.map((dg) {
                    final isSelected = dg == current;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.updateSelectedDayGroup(dg),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xff851653)
                                : Color(0xffFCE7F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Color(0xff851653)
                                  : Color(0xffEF45B2),
                            ),
                          ),
                          child: CustomText(
                            text: _dayGroupLabel(dg),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : Color(0xff851653),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),

            SizedBox(height: 12),

            PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: ButtonsTabBar(
                  controller: _tabController,
                  radius: 8,
                  height: 38,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: const Color(0xffFCCEEF),
                  borderWidth: 1,
                  borderColor: const Color(0xffFCCEEF),
                  labelStyle: GoogleFonts.roboto(
                    color: Color(0xff530630),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.roboto(
                    color: Color(0xff4D5761),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  unselectedBorderColor: const Color(0xffD2D6DB),
                  unselectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xffD2D6DB),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tabs: _shifts.map((s) => Tab(text: s)).toList(),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Obx(() {
                      final plan = controller.draftDietOptions.value;
                      final messages = [
                        ...?plan?.riskFlags.map(describeRiskFlag),
                        ...controller.filterStaleCalorieWarnings(
                          plan?.validationWarnings ?? const [],
                        ),
                      ];
                      if (messages.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF4E5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xffF0B429)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xffB54708),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  CustomText(
                                    text: 'Please review before finalizing',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: const Color(0xffB54708),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...messages.map(
                                (message) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: CustomText(
                                    text: '• $message',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: const Color(0xff92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // SHIFT-WISE RECIPE OPTIONS (the AI's own pick(s) plus every
                    // other matching recipe - incl. sides/salads cross-listed
                    // into Lunch/Dinner/Evening Snack - so the dietician can
                    // add more than just the AI's single choice, e.g. a
                    // Chapati + salad alongside the main dish for Lunch).
                    Obx(() {
                      final rawOptions = controller.shiftOptions;

                      int currentWeekNumber = int.parse(
                        controller.selectedWeek.value.split(" ").last,
                      );

                      final selectedRecipesForWeek =
                          controller.weekSelectedRecipes[currentWeekNumber] ??
                          [];
                      final shift = controller.selectedShift.value;

                      // A selected supplement used to be filtered OUT of this
                      // pseudo-slot's list entirely (the idea being it should
                      // only be toggled from its native real slot, e.g. Night
                      // Drink) - but since toggling happens in this exact Obx,
                      // that made the card vanish the instant it was tapped
                      // instead of showing a checked state, which read as
                      // "selecting it does nothing"/"it reverts". Keep it
                      // visible here too - toggling from either place still
                      // updates the same whole-week selection (see
                      // toggleMealSelection's supplement branch).
                      final options = rawOptions;

                      if (options.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "No items for ${controller.selectedShift.value}",
                            style: const TextStyle(color: Color(0xff4D5761)),
                          ),
                        );
                      }

                      final visibleOptions = controller.visibleShiftOptions(
                        options,
                        selectedRecipesForWeek,
                        shift,
                      );
                      final extraCount = controller.extraOptionsCount(
                        options,
                        selectedRecipesForWeek,
                      );
                      final isExpanded = controller.expandedShifts.contains(
                        shift,
                      );

                      return Column(
                        children: [
                          ...visibleOptions.map((recipe) {
                            final isSelected = selectedRecipesForWeek.contains(
                              recipe,
                            );
                            // Live quantity/nutrition - once selected, both
                            // the per-component steppers and the macro
                            // numbers reflect the dietician's actual +/-
                            // adjustment, not just the recipe's static base
                            // serving (otherwise a card showing "3x
                            // Chapati" would misleadingly still display
                            // 1-chapati's worth of calories). combinedRatio
                            // averages every component's own ratio, mirroring
                            // PatientsController._nutritionScaleRatio.
                            final liveComponents = isSelected
                                ? List<num>.generate(
                                    recipe.components.length,
                                    (i) => controller.componentServingsAt(
                                      recipe,
                                      i,
                                    ),
                                  )
                                : recipe.components
                                      .map((c) => c.quantity)
                                      .toList();
                            final combinedRatio = isSelected
                                ? List<num>.generate(
                                        recipe.components.length,
                                        (i) =>
                                            recipe.components[i].quantity > 0
                                            ? liveComponents[i] /
                                                  recipe.components[i].quantity
                                            : 1,
                                      ).reduce((a, b) => a + b) /
                                      recipe.components.length
                                : 1;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: FoodCard(
                                image: recipe.image,
                                name: recipe.name,
                                grams: "${liveComponents[0]}",
                                unit: recipe.servingUnit,
                                calorie:
                                    (recipe.nutrition.calories * combinedRatio)
                                        .toStringAsFixed(0),
                                protein:
                                    (recipe.nutrition.protein * combinedRatio)
                                        .toStringAsFixed(0),
                                fiber: (recipe.nutrition.fiber * combinedRatio)
                                    .toStringAsFixed(0),
                                carbs: (recipe.nutrition.carbs * combinedRatio)
                                    .toStringAsFixed(0),
                                fat: (recipe.nutrition.fats * combinedRatio)
                                    .toStringAsFixed(0),
                                supplementNutrientLabels: recipe
                                    .supplementFacts
                                    ?.nutrients
                                    .map((n) => n.displayLabel)
                                    .toList(),
                                isSelected: isSelected,
                                onSelect: () =>
                                    controller.toggleMealSelection(recipe),
                                onTapDetails: () =>
                                    _openRecipeDetails(recipe.id),
                                components: isSelected
                                    ? List<FoodCardComponentData>.generate(
                                        recipe.components.length,
                                        (i) => FoodCardComponentData(
                                          label: recipe.components[i].label,
                                          quantity: liveComponents[i],
                                          unit: recipe.components[i].unit,
                                          onIncrement: () => controller
                                              .incrementComponentServings(
                                                recipe,
                                                i,
                                              ),
                                          onDecrement: () => controller
                                              .decrementComponentServings(
                                                recipe,
                                                i,
                                              ),
                                        ),
                                      )
                                    : const [],
                              ),
                            );
                          }),
                          if (extraCount > 0 || isExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    controller.toggleShowMoreOptions(shift),
                                child: Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xffEF45B2),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CustomText(
                                    text: isExpanded
                                        ? "Show fewer options"
                                        : "Show $extraCount more options",
                                    color: Color(0xff851653),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    SizedBox(height: 16),
                    Obx(() {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: EdgeInsets.only(
                            top: 12,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Color(0xffFDF2FA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: 'Total Budget',
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xff851653),
                              ),

                              SizedBox(height: 14),
                              Divider(color: Color(0xffFCCEEF)),
                              SizedBox(height: 8),

                              ...(() {
                                final selected = controller.totalCalories.value;
                                final target =
                                    (controller.selectedCalorieStrategy['calorieBudget']
                                            as num?)
                                        ?.toDouble();
                                return [
                                  infoRow(
                                    "Selected Calories",
                                    "${selected.toStringAsFixed(0)} Cal",
                                    'assets/icons/diet_icon_1.png',
                                  ),
                                  if (target != null)
                                    infoRow(
                                      "Required Calories",
                                      "${target.toStringAsFixed(0)} Cal",
                                      'assets/icons/diet_icon_1.png',
                                    ),
                                  SizedBox(height: 4),
                                  Divider(color: Color(0xffFCCEEF), height: 1),
                                  SizedBox(height: 8),
                                ];
                              }()),

                              infoRow(
                                "Fat",
                                "${controller.totalFat.value.toStringAsFixed(0)} g",
                                'assets/icons/diet_icon_5.png',
                              ),

                              infoRow(
                                "Net Carbs",
                                "${controller.totalCarbs.value.toStringAsFixed(0)} g",
                                'assets/icons/diet_icon_6.png',
                              ),

                              infoRow(
                                "Protein",
                                "${controller.totalProtein.value.toStringAsFixed(0)} g",
                                'assets/icons/diet_icon_7.png',
                              ),

                              infoRow(
                                "Fiber",
                                "${controller.totalFiber.value.toStringAsFixed(0)} g",
                                'assets/icons/diet2.png',
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // button — finalize only the selected week
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => CustomButton(
                  isLoading: controller.showWeekDietSendingLoading.value,
                  onTap: () async {
                    // AI_EXECUTION_PLAN.md Phase 7, P7-05: publish
                    // confirmation - finalizing makes this week's plan
                    // visible to the patient and was previously one tap
                    // away with no confirmation, for what's normally a
                    // hard-to-walk-back action (the patient may already be
                    // logging meals against it by the time a mistake is
                    // noticed).
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(
                          'Finalize Week ${controller.selectedWeek.value}?',
                        ),
                        content: const Text(
                          "This makes the week's diet plan visible to the "
                          'patient. You can still make changes and '
                          're-finalize later, but the patient may already '
                          'be acting on it once published.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff851653),
                            ),
                            child: const Text('Finalize'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await controller.finalizeWeek(
                      widget.patientId,
                      widget.dietPlanId,
                      controller.selectedWeek.value,
                    );
                  },
                  text:
                      'Finalize Diet Plan for ${controller.selectedWeek.value}',
                  isOutline: false,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(icon, height: 13, width: 13, fit: BoxFit.contain),
          SizedBox(width: 10),
          CustomText(
            text: label,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xff851653),
          ),
          Spacer(),
          CustomText(
            text: value,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
