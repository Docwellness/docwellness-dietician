import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/log_meal_container.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/progress_card_for_sheet.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/water_intake_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClintLogDataSheet extends StatefulWidget {
  final String patientId;

  const ClintLogDataSheet({super.key, required this.patientId});

  @override
  State<ClintLogDataSheet> createState() => _ClintLogDataSheetState();
}

class _ClintLogDataSheetState extends State<ClintLogDataSheet> {
  final PatientsController controller = Get.find<PatientsController>();

  static const List<String> _servingTimes = [
    'Breakfast',
    'Morning Drink',
    'Lunch',
    'Brunch',
    'Morning Snack',
    'Dinner',
    'Evening Snack',
    'Night Drink',
  ];

  @override
  void initState() {
    super.initState();
    controller.clientLogSelectedDate.value = DateTime.now();
    controller.fetchClientLogData(widget.patientId);
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _servingTimes.length,
      child: Obx(() {
        final isLoading = controller.isClientLogLoading.value;
        final stats = controller.clientMealStats;
        final summary = Map<String, dynamic>.from(stats['summary'] ?? {});
        final macros = Map<String, dynamic>.from(stats['macros'] ?? {});
        final consumed = Map<String, dynamic>.from(macros['consumed'] ?? {});
        final planned = Map<String, dynamic>.from(macros['planned'] ?? {});
        final waterData = controller.clientWaterData;
        final selectedDate = controller.clientLogSelectedDate.value;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Center(
                child: Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: const Color(0xff79747E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  CustomText(
                    text: 'Client Logged Data',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date navigator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    border: Border.all(color: Color(0xffFDF2FA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 21,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            controller.changeClientLogDate(
                              widget.patientId,
                              -1,
                            );
                          },
                          child: Image.asset(
                            'assets/icons/home_left_arrow.png',
                          ),
                        ),
                      ),
                      Spacer(),
                      CustomText(
                        text: _getDateLabel(selectedDate),
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        color: Color(0xff530630),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          right: 21,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            controller.changeClientLogDate(widget.patientId, 1);
                          },
                          child: Image.asset(
                            'assets/icons/home_right_arrow.png',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xffDE2493)),
                  ),
                )
              else ...[
                // Progress card with real data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProgressCard(
                    intake: _toInt(summary['totalConsumedCalories']),
                    remaining: _toInt(summary['remainingCalories']),
                    exercise: 0,
                    totalPlanned: _toInt(summary['totalPlannedCalories']),
                    carbsConsumed: _toDouble(consumed['carbs']),
                    carbsPlanned: _toDouble(planned['carbs']),
                    proteinConsumed: _toDouble(consumed['protein']),
                    proteinPlanned: _toDouble(planned['protein']),
                    fiberConsumed: _toDouble(consumed['fiber']),
                    fiberPlanned: _toDouble(planned['fiber']),
                    fatConsumed: _toDouble(consumed['fats']),
                    fatPlanned: _toDouble(planned['fats']),
                  ),
                ),
                const SizedBox(height: 16),

                // Water intake with real data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WaterIntakeContainer(
                    totalAmount: _toDouble(waterData['totalAmount']),
                    goal: _toDouble(waterData['goal']),
                  ),
                ),
                SizedBox(height: 23),

                // Meal tabs
                PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ButtonsTabBar(
                      radius: 8,
                      height: 38,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
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
                      onTap: (index) {
                        setState(() {});
                      },
                      tabs: _servingTimes.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),

                // Meal items rendered via TabBarView-like approach
                Builder(
                  builder: (context) {
                    final tabIndex = DefaultTabController.of(context).index;
                    final servingTime = _servingTimes[tabIndex];
                    final meals = controller.getMealsForServingTime(
                      servingTime,
                    );

                    if (meals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Center(
                          child: CustomText(
                            text: 'No meals planned for $servingTime',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xff6C737F),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: meals
                          .map(
                            (meal) => LogMealContainer(
                              name: meal['name'] ?? 'Unknown',
                              imageUrl: meal['image'],
                              plannedCalories: _toInt(meal['plannedCalories']),
                              caloriesConsumed: _toInt(
                                meal['caloriesConsumed'],
                              ),
                              loggedServings: _toInt(meal['loggedServings']),
                              isLogged: meal['isLogged'] == true,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                SizedBox(height: 30),
              ],
            ],
          ),
        );
      }),
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
